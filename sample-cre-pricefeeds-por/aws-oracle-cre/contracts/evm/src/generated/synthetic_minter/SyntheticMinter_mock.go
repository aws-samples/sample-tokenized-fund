// Code generated — DO NOT EDIT.

//go:build !wasip1

package synthetic_minter

import (
	"errors"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	evmmock "github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm/mock"
)

var (
	_ = errors.New
	_ = fmt.Errorf
	_ = big.NewInt
	_ = common.Big1
)

// SyntheticMinterMock is a mock implementation of SyntheticMinter for testing.
type SyntheticMinterMock struct {
	BPSDENOMINATOR            func() (*big.Int, error)
	PRICEDECIMALS             func() (*big.Int, error)
	SYNTHETICDECIMALS         func() (*big.Int, error)
	USDCDECIMALS              func() (*big.Int, error)
	AccumulatedFees           func() (*big.Int, error)
	CollateralMonitor         func() (common.Address, error)
	FeeRecipient              func() (common.Address, error)
	GetAvailableCollateral    func(GetAvailableCollateralInput) (*big.Int, error)
	GetCollateralValue        func() (*big.Int, error)
	GetLatestPrice            func() (*big.Int, error)
	GetMaxMintable            func(GetMaxMintableInput) (*big.Int, error)
	GetPositionValue          func(GetPositionValueInput) (*big.Int, error)
	GetUserCollateralRatio    func(GetUserCollateralRatioInput) (*big.Int, error)
	LockedCollateral          func(LockedCollateralInput) (*big.Int, error)
	MinCollateralizationRatio func() (*big.Int, error)
	MintFeeBps                func() (*big.Int, error)
	Owner                     func() (common.Address, error)
	Paused                    func() (bool, error)
	PriceFeed                 func() (common.Address, error)
	StalenessWindow           func() (*big.Int, error)
	SyntheticToken            func() (common.Address, error)
	TotalCollateral           func(TotalCollateralInput) (*big.Int, error)
	TotalLockedCollateral     func() (*big.Int, error)
	Usdc                      func() (common.Address, error)
}

// NewSyntheticMinterMock creates a new SyntheticMinterMock for testing.
func NewSyntheticMinterMock(address common.Address, clientMock *evmmock.ClientCapability) *SyntheticMinterMock {
	mock := &SyntheticMinterMock{}

	codec, err := NewCodec()
	if err != nil {
		panic("failed to create codec for mock: " + err.Error())
	}

	abi := codec.(*Codec).abi
	_ = abi

	funcMap := map[string]func([]byte) ([]byte, error){
		string(abi.Methods["BPS_DENOMINATOR"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.BPSDENOMINATOR == nil {
				return nil, errors.New("BPS_DENOMINATOR method not mocked")
			}
			result, err := mock.BPSDENOMINATOR()
			if err != nil {
				return nil, err
			}
			return abi.Methods["BPS_DENOMINATOR"].Outputs.Pack(result)
		},
		string(abi.Methods["PRICE_DECIMALS"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.PRICEDECIMALS == nil {
				return nil, errors.New("PRICE_DECIMALS method not mocked")
			}
			result, err := mock.PRICEDECIMALS()
			if err != nil {
				return nil, err
			}
			return abi.Methods["PRICE_DECIMALS"].Outputs.Pack(result)
		},
		string(abi.Methods["SYNTHETIC_DECIMALS"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.SYNTHETICDECIMALS == nil {
				return nil, errors.New("SYNTHETIC_DECIMALS method not mocked")
			}
			result, err := mock.SYNTHETICDECIMALS()
			if err != nil {
				return nil, err
			}
			return abi.Methods["SYNTHETIC_DECIMALS"].Outputs.Pack(result)
		},
		string(abi.Methods["USDC_DECIMALS"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.USDCDECIMALS == nil {
				return nil, errors.New("USDC_DECIMALS method not mocked")
			}
			result, err := mock.USDCDECIMALS()
			if err != nil {
				return nil, err
			}
			return abi.Methods["USDC_DECIMALS"].Outputs.Pack(result)
		},
		string(abi.Methods["accumulatedFees"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.AccumulatedFees == nil {
				return nil, errors.New("accumulatedFees method not mocked")
			}
			result, err := mock.AccumulatedFees()
			if err != nil {
				return nil, err
			}
			return abi.Methods["accumulatedFees"].Outputs.Pack(result)
		},
		string(abi.Methods["collateralMonitor"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.CollateralMonitor == nil {
				return nil, errors.New("collateralMonitor method not mocked")
			}
			result, err := mock.CollateralMonitor()
			if err != nil {
				return nil, err
			}
			return abi.Methods["collateralMonitor"].Outputs.Pack(result)
		},
		string(abi.Methods["feeRecipient"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.FeeRecipient == nil {
				return nil, errors.New("feeRecipient method not mocked")
			}
			result, err := mock.FeeRecipient()
			if err != nil {
				return nil, err
			}
			return abi.Methods["feeRecipient"].Outputs.Pack(result)
		},
		string(abi.Methods["getAvailableCollateral"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetAvailableCollateral == nil {
				return nil, errors.New("getAvailableCollateral method not mocked")
			}
			inputs := abi.Methods["getAvailableCollateral"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetAvailableCollateralInput{
				User: values[0].(common.Address),
			}

			result, err := mock.GetAvailableCollateral(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getAvailableCollateral"].Outputs.Pack(result)
		},
		string(abi.Methods["getCollateralValue"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetCollateralValue == nil {
				return nil, errors.New("getCollateralValue method not mocked")
			}
			result, err := mock.GetCollateralValue()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getCollateralValue"].Outputs.Pack(result)
		},
		string(abi.Methods["getLatestPrice"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetLatestPrice == nil {
				return nil, errors.New("getLatestPrice method not mocked")
			}
			result, err := mock.GetLatestPrice()
			if err != nil {
				return nil, err
			}
			return abi.Methods["getLatestPrice"].Outputs.Pack(result)
		},
		string(abi.Methods["getMaxMintable"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetMaxMintable == nil {
				return nil, errors.New("getMaxMintable method not mocked")
			}
			inputs := abi.Methods["getMaxMintable"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetMaxMintableInput{
				User: values[0].(common.Address),
			}

			result, err := mock.GetMaxMintable(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getMaxMintable"].Outputs.Pack(result)
		},
		string(abi.Methods["getPositionValue"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetPositionValue == nil {
				return nil, errors.New("getPositionValue method not mocked")
			}
			inputs := abi.Methods["getPositionValue"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetPositionValueInput{
				User: values[0].(common.Address),
			}

			result, err := mock.GetPositionValue(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getPositionValue"].Outputs.Pack(result)
		},
		string(abi.Methods["getUserCollateralRatio"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.GetUserCollateralRatio == nil {
				return nil, errors.New("getUserCollateralRatio method not mocked")
			}
			inputs := abi.Methods["getUserCollateralRatio"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := GetUserCollateralRatioInput{
				User: values[0].(common.Address),
			}

			result, err := mock.GetUserCollateralRatio(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["getUserCollateralRatio"].Outputs.Pack(result)
		},
		string(abi.Methods["lockedCollateral"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.LockedCollateral == nil {
				return nil, errors.New("lockedCollateral method not mocked")
			}
			inputs := abi.Methods["lockedCollateral"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := LockedCollateralInput{
				Arg0: values[0].(common.Address),
			}

			result, err := mock.LockedCollateral(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["lockedCollateral"].Outputs.Pack(result)
		},
		string(abi.Methods["minCollateralizationRatio"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.MinCollateralizationRatio == nil {
				return nil, errors.New("minCollateralizationRatio method not mocked")
			}
			result, err := mock.MinCollateralizationRatio()
			if err != nil {
				return nil, err
			}
			return abi.Methods["minCollateralizationRatio"].Outputs.Pack(result)
		},
		string(abi.Methods["mintFeeBps"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.MintFeeBps == nil {
				return nil, errors.New("mintFeeBps method not mocked")
			}
			result, err := mock.MintFeeBps()
			if err != nil {
				return nil, err
			}
			return abi.Methods["mintFeeBps"].Outputs.Pack(result)
		},
		string(abi.Methods["owner"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.Owner == nil {
				return nil, errors.New("owner method not mocked")
			}
			result, err := mock.Owner()
			if err != nil {
				return nil, err
			}
			return abi.Methods["owner"].Outputs.Pack(result)
		},
		string(abi.Methods["paused"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.Paused == nil {
				return nil, errors.New("paused method not mocked")
			}
			result, err := mock.Paused()
			if err != nil {
				return nil, err
			}
			return abi.Methods["paused"].Outputs.Pack(result)
		},
		string(abi.Methods["priceFeed"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.PriceFeed == nil {
				return nil, errors.New("priceFeed method not mocked")
			}
			result, err := mock.PriceFeed()
			if err != nil {
				return nil, err
			}
			return abi.Methods["priceFeed"].Outputs.Pack(result)
		},
		string(abi.Methods["stalenessWindow"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.StalenessWindow == nil {
				return nil, errors.New("stalenessWindow method not mocked")
			}
			result, err := mock.StalenessWindow()
			if err != nil {
				return nil, err
			}
			return abi.Methods["stalenessWindow"].Outputs.Pack(result)
		},
		string(abi.Methods["syntheticToken"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.SyntheticToken == nil {
				return nil, errors.New("syntheticToken method not mocked")
			}
			result, err := mock.SyntheticToken()
			if err != nil {
				return nil, err
			}
			return abi.Methods["syntheticToken"].Outputs.Pack(result)
		},
		string(abi.Methods["totalCollateral"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.TotalCollateral == nil {
				return nil, errors.New("totalCollateral method not mocked")
			}
			inputs := abi.Methods["totalCollateral"].Inputs

			values, err := inputs.Unpack(payload)
			if err != nil {
				return nil, errors.New("Failed to unpack payload")
			}
			if len(values) != 1 {
				return nil, errors.New("expected 1 input value")
			}

			args := TotalCollateralInput{
				Arg0: values[0].(common.Address),
			}

			result, err := mock.TotalCollateral(args)
			if err != nil {
				return nil, err
			}
			return abi.Methods["totalCollateral"].Outputs.Pack(result)
		},
		string(abi.Methods["totalLockedCollateral"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.TotalLockedCollateral == nil {
				return nil, errors.New("totalLockedCollateral method not mocked")
			}
			result, err := mock.TotalLockedCollateral()
			if err != nil {
				return nil, err
			}
			return abi.Methods["totalLockedCollateral"].Outputs.Pack(result)
		},
		string(abi.Methods["usdc"].ID[:4]): func(payload []byte) ([]byte, error) {
			if mock.Usdc == nil {
				return nil, errors.New("usdc method not mocked")
			}
			result, err := mock.Usdc()
			if err != nil {
				return nil, err
			}
			return abi.Methods["usdc"].Outputs.Pack(result)
		},
	}

	evmmock.AddContractMock(address, clientMock, funcMap, nil)
	return mock
}
