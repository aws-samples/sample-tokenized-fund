//go:build wasip1

package main

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"math/big"
	"time"

	"aws-oracle-cre/contracts/evm/src/generated/collateralization_monitor"
	"aws-oracle-cre/contracts/evm/src/generated/price_feed"
	"aws-oracle-cre/contracts/evm/src/generated/synthetic_minter"
	"aws-oracle-cre/contracts/evm/src/generated/synthetic_token"

	"github.com/ethereum/go-ethereum/common"
	pb "github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

const SecretName = "API_KEY"

// Config represents the workflow configuration loaded from config.json
type Config struct {
	Schedule                  string      `json:"schedule"`
	ApiUrl                    string      `json:"apiUrl"`
	StockPriceApiUrl          string      `json:"stockPriceApiUrl"`
	MinCollateralizationRatio float64     `json:"minCollateralizationRatio"`
	Evms                      []EvmConfig `json:"evms"`
}

// EvmConfig represents EVM chain-specific configuration
type EvmConfig struct {
	ChainName                       string `json:"chainName"`
	PriceFeedAddress                string `json:"priceFeedAddress"`
	CollateralizationMonitorAddress string `json:"collateralizationMonitorAddress"`
	SyntheticMinterAddress          string `json:"syntheticMinterAddress"`
	SyntheticTokenAddress           string `json:"syntheticTokenAddress"`
	GasLimit                        uint64 `json:"gasLimit"`
}

// WorkflowResult represents the result of a workflow execution
type WorkflowResult struct {
	Price                   float64 `json:"price"`
	Reserves                float64 `json:"reserves"`
	Ratio                   float64 `json:"ratio"`
	IsHealthy               bool    `json:"isHealthy"`
	PriceFeedTxHash         string  `json:"priceFeedTxHash"`
	CollateralMonitorTxHash string  `json:"collateralMonitorTxHash"`
}

// StockPriceResponse represents the API response for stock price from Lambda
type StockPriceResponse struct {
	Price     float64 `consensus_aggregation:"median" json:"price"`
	Timestamp string  `consensus_aggregation:"identical" json:"timestamp"`
	Symbol    string  `consensus_aggregation:"identical" json:"symbol"`
}

// AssetData represents combined data with calculated ratio
type AssetData struct {
	Price           float64
	CollateralValue float64
	TotalSupply     float64
	Ratio           float64
	Timestamp       time.Time
	IsHealthy       bool
}

// OnChainData represents data read from on-chain contracts
type OnChainData struct {
	CollateralValue *big.Int
	TotalSupply     *big.Int
}

// fetchLatestStockPriceWithKey fetches stock price from Lambda endpoint
func fetchLatestStockPriceWithKey(apiKey string) func(*Config, *slog.Logger, *http.SendRequester) (*StockPriceResponse, error) {
	return func(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*StockPriceResponse, error) {
		// Use stockPriceApiUrl if set, otherwise fall back to apiUrl
		baseUrl := config.StockPriceApiUrl
		if baseUrl == "" {
			baseUrl = config.ApiUrl
		}

		// Construct HTTP request for stock price endpoint
		req := &http.Request{
			Url:    baseUrl + "stock-price/latest",
			Method: "GET",
			Headers: map[string]string{
				"x-api-key": apiKey,
			},
		}

		logger.Info("Fetching latest stock price", "url", req.Url)

		// Send request
		resp, err := sendRequester.SendRequest(req).Await()
		if err != nil {
			logger.Error("Failed to fetch stock price", "error", err, "url", req.Url)
			return nil, fmt.Errorf("failed to fetch stock price: %w", err)
		}

		// Check status code
		if resp.StatusCode != 200 {
			logger.Error("API returned error status", "status", resp.StatusCode, "body", string(resp.Body))
			return nil, fmt.Errorf("API error: status %d", resp.StatusCode)
		}

		// Parse JSON response
		var stockResp StockPriceResponse
		if err = json.Unmarshal(resp.Body, &stockResp); err != nil {
			logger.Error("Failed to parse stock price response", "error", err, "body", string(resp.Body))
			return nil, fmt.Errorf("failed to parse stock price response: %w", err)
		}

		logger.Info("Successfully fetched stock price", "price", stockResp.Price, "symbol", stockResp.Symbol, "timestamp", stockResp.Timestamp)
		return &stockResp, nil
	}
}

// readCollateralValue reads the collateral value from SyntheticMinter contract on-chain
func readCollateralValue(config *Config, runtime cre.Runtime) (*big.Int, error) {
	logger := runtime.Logger()
	logger.Info("Reading collateral value from SyntheticMinter contract")

	// Get EVM configuration (use first chain)
	if len(config.Evms) == 0 {
		return nil, fmt.Errorf("no EVM configuration found")
	}
	evmCfg := config.Evms[0]

	// Check if SyntheticMinter address is configured
	if evmCfg.SyntheticMinterAddress == "" || evmCfg.SyntheticMinterAddress == "YOUR_SYNTHETIC_MINTER_ADDRESS" {
		logger.Warn("SyntheticMinter address not configured, returning zero")
		return big.NewInt(0), nil
	}

	// Create EVM client
	chainSelector, err := evm.ChainSelectorFromName(evmCfg.ChainName)
	if err != nil {
		return nil, fmt.Errorf("invalid chain name: %w", err)
	}
	evmClient := &evm.Client{
		ChainSelector: chainSelector,
	}

	// Instantiate contract binding
	contractAddress := common.HexToAddress(evmCfg.SyntheticMinterAddress)
	minter, err := synthetic_minter.NewSyntheticMinter(evmClient, contractAddress, nil)
	if err != nil {
		logger.Error("Failed to create SyntheticMinter contract instance",
			"error", err,
			"address", evmCfg.SyntheticMinterAddress)
		return nil, fmt.Errorf("failed to create SyntheticMinter contract: %w", err)
	}

	// Call totalLockedCollateral() at latest block (-1) - locked-based reserves
	collateralValue, err := minter.TotalLockedCollateral(runtime, big.NewInt(-1)).Await()
	if err != nil {
		logger.Error("Failed to read collateral value", "error", err)
		return nil, fmt.Errorf("failed to read collateral value: %w", err)
	}

	logger.Info("Successfully read collateral value",
		"collateralValue", collateralValue.String(),
		"contract", contractAddress.Hex())

	return collateralValue, nil
}

// readTotalSupply reads the total supply from SyntheticToken contract on-chain
func readTotalSupply(config *Config, runtime cre.Runtime) (*big.Int, error) {
	logger := runtime.Logger()
	logger.Info("Reading total supply from SyntheticToken contract")

	// Get EVM configuration (use first chain)
	if len(config.Evms) == 0 {
		return nil, fmt.Errorf("no EVM configuration found")
	}
	evmCfg := config.Evms[0]

	// Check if SyntheticToken address is configured
	if evmCfg.SyntheticTokenAddress == "" || evmCfg.SyntheticTokenAddress == "YOUR_SYNTHETIC_TOKEN_ADDRESS" {
		logger.Warn("SyntheticToken address not configured, returning zero")
		return big.NewInt(0), nil
	}

	// Create EVM client
	chainSelector, err := evm.ChainSelectorFromName(evmCfg.ChainName)
	if err != nil {
		return nil, fmt.Errorf("invalid chain name: %w", err)
	}
	evmClient := &evm.Client{
		ChainSelector: chainSelector,
	}

	// Instantiate contract binding
	contractAddress := common.HexToAddress(evmCfg.SyntheticTokenAddress)
	token, err := synthetic_token.NewSyntheticToken(evmClient, contractAddress, nil)
	if err != nil {
		logger.Error("Failed to create SyntheticToken contract instance",
			"error", err,
			"address", evmCfg.SyntheticTokenAddress)
		return nil, fmt.Errorf("failed to create SyntheticToken contract: %w", err)
	}

	// Call totalSupply() at latest block (-1)
	totalSupply, err := token.TotalSupply(runtime, big.NewInt(-1)).Await()
	if err != nil {
		logger.Error("Failed to read total supply", "error", err)
		return nil, fmt.Errorf("failed to read total supply: %w", err)
	}

	logger.Info("Successfully read total supply",
		"totalSupply", totalSupply.String(),
		"contract", contractAddress.Hex())

	return totalSupply, nil
}

// fetchAssetData fetches stock price from Lambda and reads on-chain state
func fetchAssetData(config *Config, runtime cre.Runtime) (*AssetData, error) {
	logger := runtime.Logger()
	logger.Info("Fetching asset data from Lambda and on-chain state")

	// Get API key from secret
	secretReq := &pb.SecretRequest{Id: SecretName}
	secret, err := runtime.GetSecret(secretReq).Await()
	if err != nil {
		logger.Error("Failed to get secret", "secretName", SecretName, "error", err)
		return nil, fmt.Errorf("failed to get secret %s: %w", SecretName, err)
	}

	apiKey := string(secret.Value)

	// Create HTTP client
	client := &http.Client{}

	// Fetch stock price from Lambda endpoint with consensus aggregation
	stockPricePromise := http.SendRequest(config, runtime, client, fetchLatestStockPriceWithKey(apiKey), cre.ConsensusAggregationFromTags[*StockPriceResponse]())

	// Await stock price result
	stockPrice, err := stockPricePromise.Await()
	if err != nil {
		logger.Error("Failed to fetch stock price data", "error", err)
		return nil, fmt.Errorf("failed to fetch stock price data: %w", err)
	}

	// Validate positive price
	if stockPrice.Price <= 0 {
		logger.Error("Invalid stock price value", "price", stockPrice.Price)
		return nil, fmt.Errorf("invalid stock price: %f", stockPrice.Price)
	}

	// Read on-chain collateral value from SyntheticMinter
	collateralValue, err := readCollateralValue(config, runtime)
	if err != nil {
		logger.Error("Failed to read collateral value", "error", err)
		return nil, fmt.Errorf("failed to read collateral value: %w", err)
	}

	// Read on-chain total supply from SyntheticToken
	totalSupply, err := readTotalSupply(config, runtime)
	if err != nil {
		logger.Error("Failed to read total supply", "error", err)
		return nil, fmt.Errorf("failed to read total supply: %w", err)
	}

	// Convert big.Int values to float64 for ratio calculation
	// CollateralValue is in USDC (6 decimals)
	// TotalSupply is in synthetic tokens (18 decimals)
	// Price is in USD (from API, no decimals adjustment needed)
	collateralValueFloat := new(big.Float).SetInt(collateralValue)
	collateralValueFloat.Quo(collateralValueFloat, big.NewFloat(1e6)) // USDC has 6 decimals

	totalSupplyFloat := new(big.Float).SetInt(totalSupply)
	totalSupplyFloat.Quo(totalSupplyFloat, big.NewFloat(1e18)) // Synthetic token has 18 decimals

	collateralUsd, _ := collateralValueFloat.Float64()
	totalSupplyVal, _ := totalSupplyFloat.Float64()

	// Calculate collateralization ratio
	// ratio = collateralValue / (totalSupply * stockPrice)
	var ratio float64
	if totalSupplyVal > 0 && stockPrice.Price > 0 {
		syntheticValueUsd := totalSupplyVal * stockPrice.Price
		ratio = collateralUsd / syntheticValueUsd
	} else {
		// If no synthetic tokens minted, ratio is infinite (healthy)
		// Use a large value to indicate fully collateralized
		ratio = 100.0
		logger.Info("No synthetic tokens minted, setting ratio to 100")
	}

	// Parse timestamp from stock price response
	timestamp, err := time.Parse(time.RFC3339, stockPrice.Timestamp)
	if err != nil {
		// Fall back to DON time if parsing fails. Use runtime.Now() (not time.Now())
		// so that all DON nodes observe the same timestamp and can reach consensus.
		timestamp = runtime.Now()
		logger.Warn("Failed to parse timestamp, using DON time from runtime.Now()", "error", err)
	}

	assetData := &AssetData{
		Price:           stockPrice.Price,
		CollateralValue: collateralUsd,
		TotalSupply:     totalSupplyVal,
		Ratio:           ratio,
		Timestamp:       timestamp,
	}

	logger.Info("Successfully fetched and calculated asset data",
		"price", assetData.Price,
		"collateralValue", assetData.CollateralValue,
		"totalSupply", assetData.TotalSupply,
		"ratio", assetData.Ratio)

	return assetData, nil
}

// validateCollateralizationThreshold compares the calculated ratio against the configured minimum threshold
// and sets the health status accordingly
func validateCollateralizationThreshold(config *Config, logger *slog.Logger, assetData *AssetData) *AssetData {
	logger.Info("Validating collateralization threshold",
		"ratio", assetData.Ratio,
		"minThreshold", config.MinCollateralizationRatio)

	// Compare calculated ratio against configured minimum threshold
	assetData.IsHealthy = assetData.Ratio >= config.MinCollateralizationRatio

	// Log warning if ratio is below threshold
	if !assetData.IsHealthy {
		logger.Warn("Collateralization ratio below threshold",
			"ratio", assetData.Ratio,
			"minThreshold", config.MinCollateralizationRatio,
			"deficit", config.MinCollateralizationRatio-assetData.Ratio)
	} else {
		logger.Info("Collateralization ratio is healthy",
			"ratio", assetData.Ratio,
			"minThreshold", config.MinCollateralizationRatio,
			"surplus", assetData.Ratio-config.MinCollateralizationRatio)
	}

	return assetData
}

// updatePriceFeed writes price data to the PriceFeed contract on-chain
func updatePriceFeed(config *Config, runtime cre.Runtime, assetData *AssetData) (string, error) {
	logger := runtime.Logger()
	logger.Info("Updating PriceFeed contract")

	// Get EVM configuration (use first chain)
	if len(config.Evms) == 0 {
		return "", fmt.Errorf("no EVM configuration found")
	}
	evmCfg := config.Evms[0]

	// Step 1: Create EVM client
	chainSelector, err := evm.ChainSelectorFromName(evmCfg.ChainName)
	if err != nil {
		return "", fmt.Errorf("invalid chain name: %w", err)
	}
	evmClient := &evm.Client{
		ChainSelector: chainSelector,
	}

	// Step 2: Instantiate contract binding
	contractAddress := common.HexToAddress(evmCfg.PriceFeedAddress)
	priceFeed, err := price_feed.NewPriceFeed(evmClient, contractAddress, nil)
	if err != nil {
		logger.Error("Failed to create PriceFeed contract instance",
			"error", err,
			"address", evmCfg.PriceFeedAddress)
		return "", fmt.Errorf("failed to create PriceFeed contract: %w", err)
	}

	// Step 3: Convert price and timestamp to big.Int
	// Price: multiply by 1e8 (8 decimals) using big.Float to avoid overflow
	priceFloat := new(big.Float).SetFloat64(assetData.Price)
	priceFloat.Mul(priceFloat, big.NewFloat(1e8))
	priceScaled, _ := priceFloat.Int(nil)
	// Timestamp: convert to Unix seconds
	timestampUnix := new(big.Int).SetInt64(assetData.Timestamp.Unix())

	logger.Info("Prepared data for PriceFeed",
		"priceScaled", priceScaled.String(),
		"timestamp", timestampUnix.String(),
		"originalPrice", assetData.Price)

	// Step 4: Prepare input data
	updateData := price_feed.UpdatePriceInput{
		Price:     priceScaled,
		Timestamp: timestampUnix,
	}

	// Step 5: Configure gas
	gasConfig := &evm.GasConfig{
		GasLimit: evmCfg.GasLimit,
	}

	logger.Info("Writing to PriceFeed contract",
		"address", contractAddress.Hex(),
		"chainName", evmCfg.ChainName,
		"gasLimit", evmCfg.GasLimit)

	// Step 6: Generate and encode report
	encoded, err := priceFeed.Codec.EncodeUpdatePriceMethodCall(updateData)
	if err != nil {
		logger.Error("Failed to encode updatePrice method call", "error", err)
		return "", fmt.Errorf("failed to encode method call: %w", err)
	}

	// Generate report
	reportPromise := runtime.GenerateReport(&pb.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	report, err := reportPromise.Await()
	if err != nil {
		logger.Error("Failed to generate report", "error", err)
		return "", fmt.Errorf("failed to generate report: %w", err)
	}

	// Step 7: Call write method
	writePromise := priceFeed.WriteReport(runtime, report, gasConfig)

	logger.Info("Waiting for PriceFeed write response")

	// Step 8: Await transaction
	resp, err := writePromise.Await()
	if err != nil {
		logger.Error("PriceFeed write failed",
			"error", err,
			"errorType", fmt.Sprintf("%T", err),
			"contract", contractAddress.Hex(),
			"chainName", evmCfg.ChainName)
		return "", fmt.Errorf("failed to write to PriceFeed contract: %w", err)
	}

	// Step 9: Extract transaction hash
	txHash := common.BytesToHash(resp.TxHash).Hex()
	logger.Info("PriceFeed transaction succeeded",
		"txHash", txHash,
		"price", assetData.Price,
		"timestamp", assetData.Timestamp)

	return txHash, nil
}

// updateCollateralizationMonitor writes collateral data to the CollateralizationMonitor contract on-chain
func updateCollateralizationMonitor(config *Config, runtime cre.Runtime, assetData *AssetData) (string, error) {
	logger := runtime.Logger()
	logger.Info("Updating CollateralizationMonitor contract")

	// Get EVM configuration (use first chain)
	if len(config.Evms) == 0 {
		return "", fmt.Errorf("no EVM configuration found")
	}
	evmCfg := config.Evms[0]

	// Step 1: Create EVM client
	chainSelector, err := evm.ChainSelectorFromName(evmCfg.ChainName)
	if err != nil {
		return "", fmt.Errorf("invalid chain name: %w", err)
	}
	evmClient := &evm.Client{
		ChainSelector: chainSelector,
	}

	// Step 2: Instantiate contract binding
	contractAddress := common.HexToAddress(evmCfg.CollateralizationMonitorAddress)
	collateralMonitor, err := collateralization_monitor.NewCollateralizationMonitor(evmClient, contractAddress, nil)
	if err != nil {
		logger.Error("Failed to create CollateralizationMonitor contract instance",
			"error", err,
			"address", evmCfg.CollateralizationMonitorAddress)
		return "", fmt.Errorf("failed to create CollateralizationMonitor contract: %w", err)
	}

	// Step 3: Convert all values to big.Int using big.Float to avoid overflow
	// Price: multiply by 1e8 (8 decimals)
	priceFloat := new(big.Float).SetFloat64(assetData.Price)
	priceFloat.Mul(priceFloat, big.NewFloat(1e8))
	priceScaled, _ := priceFloat.Int(nil)

	// Reserves (CollateralValue): multiply by 1e8 (8 decimals)
	reservesFloat := new(big.Float).SetFloat64(assetData.CollateralValue)
	reservesFloat.Mul(reservesFloat, big.NewFloat(1e8))
	reservesScaled, _ := reservesFloat.Int(nil)

	// Ratio: multiply by 100 (percentage)
	ratioFloat := new(big.Float).SetFloat64(assetData.Ratio)
	ratioFloat.Mul(ratioFloat, big.NewFloat(100))
	ratioScaled, _ := ratioFloat.Int(nil)

	// Timestamp: convert to Unix seconds
	timestampUnix := new(big.Int).SetInt64(assetData.Timestamp.Unix())

	logger.Info("Prepared data for CollateralizationMonitor",
		"priceScaled", priceScaled.String(),
		"reservesScaled", reservesScaled.String(),
		"ratioScaled", ratioScaled.String(),
		"timestamp", timestampUnix.String(),
		"isHealthy", assetData.IsHealthy,
		"originalPrice", assetData.Price,
		"originalReserves", assetData.CollateralValue,
		"originalRatio", assetData.Ratio)

	// Step 4: Prepare input data
	updateData := collateralization_monitor.UpdateCollateralInput{
		Price:     priceScaled,
		Reserves:  reservesScaled,
		Ratio:     ratioScaled,
		Timestamp: timestampUnix,
		IsHealthy: assetData.IsHealthy,
	}

	// Step 5: Configure gas
	gasConfig := &evm.GasConfig{
		GasLimit: evmCfg.GasLimit,
	}

	logger.Info("Writing to CollateralizationMonitor contract",
		"address", contractAddress.Hex(),
		"chainName", evmCfg.ChainName,
		"gasLimit", evmCfg.GasLimit)

	// Step 6: Generate and encode report
	encoded, err := collateralMonitor.Codec.EncodeUpdateCollateralMethodCall(updateData)
	if err != nil {
		logger.Error("Failed to encode updateCollateral method call", "error", err)
		return "", fmt.Errorf("failed to encode method call: %w", err)
	}

	// Generate report
	reportPromise := runtime.GenerateReport(&pb.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	report, err := reportPromise.Await()
	if err != nil {
		logger.Error("Failed to generate report", "error", err)
		return "", fmt.Errorf("failed to generate report: %w", err)
	}

	// Step 7: Call write method
	writePromise := collateralMonitor.WriteReport(runtime, report, gasConfig)

	logger.Info("Waiting for CollateralizationMonitor write response")

	// Step 8: Await transaction
	resp, err := writePromise.Await()
	if err != nil {
		logger.Error("CollateralizationMonitor write failed",
			"error", err,
			"errorType", fmt.Sprintf("%T", err),
			"contract", contractAddress.Hex(),
			"chainName", evmCfg.ChainName)
		return "", fmt.Errorf("failed to write to CollateralizationMonitor contract: %w", err)
	}

	// Step 9: Extract transaction hash
	txHash := common.BytesToHash(resp.TxHash).Hex()
	logger.Info("CollateralizationMonitor transaction succeeded",
		"txHash", txHash,
		"price", assetData.Price,
		"reserves", assetData.CollateralValue,
		"ratio", assetData.Ratio,
		"isHealthy", assetData.IsHealthy,
		"timestamp", assetData.Timestamp)

	return txHash, nil
}

// onCronTrigger is the main workflow handler that executes on each cron trigger
func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*WorkflowResult, error) {
	logger := runtime.Logger()
	logger.Info("Workflow triggered by cron", "schedule", config.Schedule)

	// Step 1: Fetch asset data (stock price from Lambda + on-chain state)
	logger.Info("Step 1: Fetching asset data from Lambda and on-chain state")
	assetData, err := fetchAssetData(config, runtime)
	if err != nil {
		logger.Error("Failed to fetch asset data", "error", err)
		return nil, fmt.Errorf("failed to fetch asset data: %w", err)
	}

	logger.Info("Asset data fetched successfully",
		"price", assetData.Price,
		"collateralValue", assetData.CollateralValue,
		"totalSupply", assetData.TotalSupply,
		"ratio", assetData.Ratio)

	// Step 2: Validate collateralization ratio and determine health status
	logger.Info("Step 2: Validating collateralization threshold")
	assetData = validateCollateralizationThreshold(config, logger, assetData)

	logger.Info("Collateralization validation complete",
		"ratio", assetData.Ratio,
		"minThreshold", config.MinCollateralizationRatio,
		"isHealthy", assetData.IsHealthy)

	// Step 3: Write price data to PriceFeed contract
	logger.Info("Step 3: Writing price data to PriceFeed contract")
	priceFeedTxHash, err := updatePriceFeed(config, runtime, assetData)
	if err != nil {
		logger.Error("Failed to update PriceFeed contract", "error", err)
		return nil, fmt.Errorf("failed to update PriceFeed: %w", err)
	}

	logger.Info("PriceFeed contract updated successfully", "txHash", priceFeedTxHash)

	// Step 4: Write collateral data to CollateralizationMonitor contract
	logger.Info("Step 4: Writing collateral data to CollateralizationMonitor contract")
	collateralMonitorTxHash, err := updateCollateralizationMonitor(config, runtime, assetData)
	if err != nil {
		logger.Error("Failed to update CollateralizationMonitor contract", "error", err)
		return nil, fmt.Errorf("failed to update CollateralizationMonitor: %w", err)
	}

	logger.Info("CollateralizationMonitor contract updated successfully", "txHash", collateralMonitorTxHash)

	// Step 5: Construct WorkflowResult with all data and transaction hashes
	result := &WorkflowResult{
		Price:                   assetData.Price,
		Reserves:                assetData.CollateralValue,
		Ratio:                   assetData.Ratio,
		IsHealthy:               assetData.IsHealthy,
		PriceFeedTxHash:         priceFeedTxHash,
		CollateralMonitorTxHash: collateralMonitorTxHash,
	}

	logger.Info("Workflow completed successfully",
		"price", result.Price,
		"reserves", result.Reserves,
		"ratio", result.Ratio,
		"isHealthy", result.IsHealthy,
		"priceFeedTxHash", result.PriceFeedTxHash,
		"collateralMonitorTxHash", result.CollateralMonitorTxHash)

	return result, nil
}

// InitWorkflow registers the cron trigger and wires the onCronTrigger handler
func InitWorkflow(config *Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*Config], error) {
	logger.Info("Initializing workflow", "schedule", config.Schedule)

	return cre.Workflow[*Config]{
		cre.Handler(cron.Trigger(&cron.Config{Schedule: config.Schedule}), onCronTrigger),
	}, nil
}

func main() {
	wasm.NewRunner(cre.ParseJSON[Config]).Run(InitWorkflow)
}
