// Code generated — DO NOT EDIT.

package collateralization_monitor

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"reflect"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
	"github.com/ethereum/go-ethereum/rpc"
	"google.golang.org/protobuf/types/known/emptypb"

	pb2 "github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/chainlink-protos/cre/go/values/pb"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm/bindings"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

var (
	_ = bytes.Equal
	_ = errors.New
	_ = fmt.Sprintf
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
	_ = emptypb.Empty{}
	_ = pb.NewBigIntFromInt
	_ = pb2.AggregationType_AGGREGATION_TYPE_COMMON_PREFIX
	_ = bindings.FilterOptions{}
	_ = evm.FilterLogTriggerRequest{}
	_ = cre.ResponseBufferTooSmall
	_ = rpc.API{}
	_ = json.Unmarshal
	_ = reflect.Bool
)

var CollateralizationMonitorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"_forwarder\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"forwarder\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getLatestData\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"tuple\",\"internalType\":\"structCollateralizationMonitor.CollateralData\",\"components\":[{\"name\":\"price\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"reserves\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"ratio\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"isHealthy\",\"type\":\"bool\",\"internalType\":\"bool\"}]}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"latestData\",\"inputs\":[],\"outputs\":[{\"name\":\"price\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"reserves\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"ratio\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"isHealthy\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"minRatio\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"onReport\",\"inputs\":[{\"name\":\"\",\"type\":\"bytes\",\"internalType\":\"bytes\"},{\"name\":\"report\",\"type\":\"bytes\",\"internalType\":\"bytes\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"owner\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"setForwarder\",\"inputs\":[{\"name\":\"_newForwarder\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"setMinRatio\",\"inputs\":[{\"name\":\"_minRatio\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"pure\"},{\"type\":\"function\",\"name\":\"transferOwnership\",\"inputs\":[{\"name\":\"_newOwner\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"updateCollateral\",\"inputs\":[{\"name\":\"_price\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_reserves\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_ratio\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_timestamp\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"_isHealthy\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"CollateralUpdated\",\"inputs\":[{\"name\":\"price\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"reserves\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"ratio\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"isHealthy\",\"type\":\"bool\",\"indexed\":false,\"internalType\":\"bool\"},{\"name\":\"timestamp\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ForwarderUpdated\",\"inputs\":[{\"name\":\"previousForwarder\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newForwarder\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"MinRatioUpdated\",\"inputs\":[{\"name\":\"previousMinRatio\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"newMinRatio\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"OwnershipTransferred\",\"inputs\":[{\"name\":\"previousOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newOwner\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ThresholdBreached\",\"inputs\":[{\"name\":\"ratio\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"minRatio\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"NotForwarder\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"NotOwner\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReportTooShort\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZeroAddress\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZeroMinRatio\",\"inputs\":[]}]",
}

// Structs
type CollateralData struct {
	Price     *big.Int
	Reserves  *big.Int
	Ratio     *big.Int
	Timestamp *big.Int
	IsHealthy bool
}

// Contract Method Inputs
type OnReportInput struct {
	Arg0   []byte
	Report []byte
}

type SetForwarderInput struct {
	NewForwarder common.Address
}

type SetMinRatioInput struct {
	MinRatio *big.Int
}

type SupportsInterfaceInput struct {
	InterfaceId [4]byte
}

type TransferOwnershipInput struct {
	NewOwner common.Address
}

type UpdateCollateralInput struct {
	Price     *big.Int
	Reserves  *big.Int
	Ratio     *big.Int
	Timestamp *big.Int
	IsHealthy bool
}

// Contract Method Outputs
type LatestDataOutput struct {
	Price     *big.Int
	Reserves  *big.Int
	Ratio     *big.Int
	Timestamp *big.Int
	IsHealthy bool
}

// Errors
type NotForwarder struct {
}

type NotOwner struct {
}

type ReportTooShort struct {
}

type ZeroAddress struct {
}

type ZeroMinRatio struct {
}

// Events
// The <Event>Topics struct should be used as a filter (for log triggers).
// Note: It is only possible to filter on indexed fields.
// Indexed (string and bytes) fields will be of type common.Hash.
// They need to he (crypto.Keccak256) hashed and passed in.
// Indexed (tuple/slice/array) fields can be passed in as is, the Encode<Event>Topics function will handle the hashing.
//
// The <Event>Decoded struct will be the result of calling decode (Adapt) on the log trigger result.
// Indexed dynamic type fields will be of type common.Hash.

type CollateralUpdatedTopics struct {
}

type CollateralUpdatedDecoded struct {
	Price     *big.Int
	Reserves  *big.Int
	Ratio     *big.Int
	IsHealthy bool
	Timestamp *big.Int
}

type ForwarderUpdatedTopics struct {
	PreviousForwarder common.Address
	NewForwarder      common.Address
}

type ForwarderUpdatedDecoded struct {
	PreviousForwarder common.Address
	NewForwarder      common.Address
}

type MinRatioUpdatedTopics struct {
}

type MinRatioUpdatedDecoded struct {
	PreviousMinRatio *big.Int
	NewMinRatio      *big.Int
}

type OwnershipTransferredTopics struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type OwnershipTransferredDecoded struct {
	PreviousOwner common.Address
	NewOwner      common.Address
}

type ThresholdBreachedTopics struct {
}

type ThresholdBreachedDecoded struct {
	Ratio    *big.Int
	MinRatio *big.Int
}

// Main Binding Type for CollateralizationMonitor
type CollateralizationMonitor struct {
	Address common.Address
	Options *bindings.ContractInitOptions
	ABI     *abi.ABI
	client  *evm.Client
	Codec   CollateralizationMonitorCodec
}

type CollateralizationMonitorCodec interface {
	EncodeForwarderMethodCall() ([]byte, error)
	DecodeForwarderMethodOutput(data []byte) (common.Address, error)
	EncodeGetLatestDataMethodCall() ([]byte, error)
	DecodeGetLatestDataMethodOutput(data []byte) (CollateralData, error)
	EncodeLatestDataMethodCall() ([]byte, error)
	DecodeLatestDataMethodOutput(data []byte) (LatestDataOutput, error)
	EncodeMinRatioMethodCall() ([]byte, error)
	DecodeMinRatioMethodOutput(data []byte) (*big.Int, error)
	EncodeOnReportMethodCall(in OnReportInput) ([]byte, error)
	EncodeOwnerMethodCall() ([]byte, error)
	DecodeOwnerMethodOutput(data []byte) (common.Address, error)
	EncodeSetForwarderMethodCall(in SetForwarderInput) ([]byte, error)
	EncodeSetMinRatioMethodCall(in SetMinRatioInput) ([]byte, error)
	EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error)
	DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error)
	EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error)
	EncodeUpdateCollateralMethodCall(in UpdateCollateralInput) ([]byte, error)
	EncodeCollateralDataStruct(in CollateralData) ([]byte, error)
	CollateralUpdatedLogHash() []byte
	EncodeCollateralUpdatedTopics(evt abi.Event, values []CollateralUpdatedTopics) ([]*evm.TopicValues, error)
	DecodeCollateralUpdated(log *evm.Log) (*CollateralUpdatedDecoded, error)
	ForwarderUpdatedLogHash() []byte
	EncodeForwarderUpdatedTopics(evt abi.Event, values []ForwarderUpdatedTopics) ([]*evm.TopicValues, error)
	DecodeForwarderUpdated(log *evm.Log) (*ForwarderUpdatedDecoded, error)
	MinRatioUpdatedLogHash() []byte
	EncodeMinRatioUpdatedTopics(evt abi.Event, values []MinRatioUpdatedTopics) ([]*evm.TopicValues, error)
	DecodeMinRatioUpdated(log *evm.Log) (*MinRatioUpdatedDecoded, error)
	OwnershipTransferredLogHash() []byte
	EncodeOwnershipTransferredTopics(evt abi.Event, values []OwnershipTransferredTopics) ([]*evm.TopicValues, error)
	DecodeOwnershipTransferred(log *evm.Log) (*OwnershipTransferredDecoded, error)
	ThresholdBreachedLogHash() []byte
	EncodeThresholdBreachedTopics(evt abi.Event, values []ThresholdBreachedTopics) ([]*evm.TopicValues, error)
	DecodeThresholdBreached(log *evm.Log) (*ThresholdBreachedDecoded, error)
}

func NewCollateralizationMonitor(
	client *evm.Client,
	address common.Address,
	options *bindings.ContractInitOptions,
) (*CollateralizationMonitor, error) {
	parsed, err := abi.JSON(strings.NewReader(CollateralizationMonitorMetaData.ABI))
	if err != nil {
		return nil, err
	}
	codec, err := NewCodec()
	if err != nil {
		return nil, err
	}
	return &CollateralizationMonitor{
		Address: address,
		Options: options,
		ABI:     &parsed,
		client:  client,
		Codec:   codec,
	}, nil
}

type Codec struct {
	abi *abi.ABI
}

func NewCodec() (CollateralizationMonitorCodec, error) {
	parsed, err := abi.JSON(strings.NewReader(CollateralizationMonitorMetaData.ABI))
	if err != nil {
		return nil, err
	}
	return &Codec{abi: &parsed}, nil
}

func (c *Codec) EncodeForwarderMethodCall() ([]byte, error) {
	return c.abi.Pack("forwarder")
}

func (c *Codec) DecodeForwarderMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["forwarder"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeGetLatestDataMethodCall() ([]byte, error) {
	return c.abi.Pack("getLatestData")
}

func (c *Codec) DecodeGetLatestDataMethodOutput(data []byte) (CollateralData, error) {
	vals, err := c.abi.Methods["getLatestData"].Outputs.Unpack(data)
	if err != nil {
		return *new(CollateralData), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(CollateralData), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result CollateralData
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(CollateralData), fmt.Errorf("failed to unmarshal to CollateralData: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeLatestDataMethodCall() ([]byte, error) {
	return c.abi.Pack("latestData")
}

func (c *Codec) DecodeLatestDataMethodOutput(data []byte) (LatestDataOutput, error) {
	vals, err := c.abi.Methods["latestData"].Outputs.Unpack(data)
	if err != nil {
		return LatestDataOutput{}, err
	}
	if len(vals) != 5 {
		return LatestDataOutput{}, fmt.Errorf("expected 5 values, got %d", len(vals))
	}
	jsonData0, err := json.Marshal(vals[0])
	if err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to marshal ABI result 0: %w", err)
	}

	var result0 *big.Int
	if err := json.Unmarshal(jsonData0, &result0); err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData1, err := json.Marshal(vals[1])
	if err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to marshal ABI result 1: %w", err)
	}

	var result1 *big.Int
	if err := json.Unmarshal(jsonData1, &result1); err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData2, err := json.Marshal(vals[2])
	if err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to marshal ABI result 2: %w", err)
	}

	var result2 *big.Int
	if err := json.Unmarshal(jsonData2, &result2); err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData3, err := json.Marshal(vals[3])
	if err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to marshal ABI result 3: %w", err)
	}

	var result3 *big.Int
	if err := json.Unmarshal(jsonData3, &result3); err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}
	jsonData4, err := json.Marshal(vals[4])
	if err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to marshal ABI result 4: %w", err)
	}

	var result4 bool
	if err := json.Unmarshal(jsonData4, &result4); err != nil {
		return LatestDataOutput{}, fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return LatestDataOutput{
		Price:     result0,
		Reserves:  result1,
		Ratio:     result2,
		Timestamp: result3,
		IsHealthy: result4,
	}, nil
}

func (c *Codec) EncodeMinRatioMethodCall() ([]byte, error) {
	return c.abi.Pack("minRatio")
}

func (c *Codec) DecodeMinRatioMethodOutput(data []byte) (*big.Int, error) {
	vals, err := c.abi.Methods["minRatio"].Outputs.Unpack(data)
	if err != nil {
		return *new(*big.Int), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(*big.Int), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result *big.Int
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(*big.Int), fmt.Errorf("failed to unmarshal to *big.Int: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeOnReportMethodCall(in OnReportInput) ([]byte, error) {
	return c.abi.Pack("onReport", in.Arg0, in.Report)
}

func (c *Codec) EncodeOwnerMethodCall() ([]byte, error) {
	return c.abi.Pack("owner")
}

func (c *Codec) DecodeOwnerMethodOutput(data []byte) (common.Address, error) {
	vals, err := c.abi.Methods["owner"].Outputs.Unpack(data)
	if err != nil {
		return *new(common.Address), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(common.Address), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result common.Address
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(common.Address), fmt.Errorf("failed to unmarshal to common.Address: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeSetForwarderMethodCall(in SetForwarderInput) ([]byte, error) {
	return c.abi.Pack("setForwarder", in.NewForwarder)
}

func (c *Codec) EncodeSetMinRatioMethodCall(in SetMinRatioInput) ([]byte, error) {
	return c.abi.Pack("setMinRatio", in.MinRatio)
}

func (c *Codec) EncodeSupportsInterfaceMethodCall(in SupportsInterfaceInput) ([]byte, error) {
	return c.abi.Pack("supportsInterface", in.InterfaceId)
}

func (c *Codec) DecodeSupportsInterfaceMethodOutput(data []byte) (bool, error) {
	vals, err := c.abi.Methods["supportsInterface"].Outputs.Unpack(data)
	if err != nil {
		return *new(bool), err
	}
	jsonData, err := json.Marshal(vals[0])
	if err != nil {
		return *new(bool), fmt.Errorf("failed to marshal ABI result: %w", err)
	}

	var result bool
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return *new(bool), fmt.Errorf("failed to unmarshal to bool: %w", err)
	}

	return result, nil
}

func (c *Codec) EncodeTransferOwnershipMethodCall(in TransferOwnershipInput) ([]byte, error) {
	return c.abi.Pack("transferOwnership", in.NewOwner)
}

func (c *Codec) EncodeUpdateCollateralMethodCall(in UpdateCollateralInput) ([]byte, error) {
	return c.abi.Pack("updateCollateral", in.Price, in.Reserves, in.Ratio, in.Timestamp, in.IsHealthy)
}

func (c *Codec) EncodeCollateralDataStruct(in CollateralData) ([]byte, error) {
	tupleType, err := abi.NewType(
		"tuple", "",
		[]abi.ArgumentMarshaling{
			{Name: "price", Type: "uint256"},
			{Name: "reserves", Type: "uint256"},
			{Name: "ratio", Type: "uint256"},
			{Name: "timestamp", Type: "uint256"},
			{Name: "isHealthy", Type: "bool"},
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create tuple type for CollateralData: %w", err)
	}
	args := abi.Arguments{
		{Name: "collateralData", Type: tupleType},
	}

	return args.Pack(in)
}

func (c *Codec) CollateralUpdatedLogHash() []byte {
	return c.abi.Events["CollateralUpdated"].ID.Bytes()
}

func (c *Codec) EncodeCollateralUpdatedTopics(
	evt abi.Event,
	values []CollateralUpdatedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeCollateralUpdated decodes a log into a CollateralUpdated struct.
func (c *Codec) DecodeCollateralUpdated(log *evm.Log) (*CollateralUpdatedDecoded, error) {
	event := new(CollateralUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "CollateralUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["CollateralUpdated"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) ForwarderUpdatedLogHash() []byte {
	return c.abi.Events["ForwarderUpdated"].ID.Bytes()
}

func (c *Codec) EncodeForwarderUpdatedTopics(
	evt abi.Event,
	values []ForwarderUpdatedTopics,
) ([]*evm.TopicValues, error) {
	var previousForwarderRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PreviousForwarder).IsZero() {
			previousForwarderRule = append(previousForwarderRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.PreviousForwarder)
		if err != nil {
			return nil, err
		}
		previousForwarderRule = append(previousForwarderRule, fieldVal)
	}
	var newForwarderRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewForwarder).IsZero() {
			newForwarderRule = append(newForwarderRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewForwarder)
		if err != nil {
			return nil, err
		}
		newForwarderRule = append(newForwarderRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		previousForwarderRule,
		newForwarderRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeForwarderUpdated decodes a log into a ForwarderUpdated struct.
func (c *Codec) DecodeForwarderUpdated(log *evm.Log) (*ForwarderUpdatedDecoded, error) {
	event := new(ForwarderUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ForwarderUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ForwarderUpdated"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) MinRatioUpdatedLogHash() []byte {
	return c.abi.Events["MinRatioUpdated"].ID.Bytes()
}

func (c *Codec) EncodeMinRatioUpdatedTopics(
	evt abi.Event,
	values []MinRatioUpdatedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeMinRatioUpdated decodes a log into a MinRatioUpdated struct.
func (c *Codec) DecodeMinRatioUpdated(log *evm.Log) (*MinRatioUpdatedDecoded, error) {
	event := new(MinRatioUpdatedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "MinRatioUpdated", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["MinRatioUpdated"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) OwnershipTransferredLogHash() []byte {
	return c.abi.Events["OwnershipTransferred"].ID.Bytes()
}

func (c *Codec) EncodeOwnershipTransferredTopics(
	evt abi.Event,
	values []OwnershipTransferredTopics,
) ([]*evm.TopicValues, error) {
	var previousOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.PreviousOwner).IsZero() {
			previousOwnerRule = append(previousOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[0], v.PreviousOwner)
		if err != nil {
			return nil, err
		}
		previousOwnerRule = append(previousOwnerRule, fieldVal)
	}
	var newOwnerRule []interface{}
	for _, v := range values {
		if reflect.ValueOf(v.NewOwner).IsZero() {
			newOwnerRule = append(newOwnerRule, common.Hash{})
			continue
		}
		fieldVal, err := bindings.PrepareTopicArg(evt.Inputs[1], v.NewOwner)
		if err != nil {
			return nil, err
		}
		newOwnerRule = append(newOwnerRule, fieldVal)
	}

	rawTopics, err := abi.MakeTopics(
		previousOwnerRule,
		newOwnerRule,
	)
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeOwnershipTransferred decodes a log into a OwnershipTransferred struct.
func (c *Codec) DecodeOwnershipTransferred(log *evm.Log) (*OwnershipTransferredDecoded, error) {
	event := new(OwnershipTransferredDecoded)
	if err := c.abi.UnpackIntoInterface(event, "OwnershipTransferred", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["OwnershipTransferred"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c *Codec) ThresholdBreachedLogHash() []byte {
	return c.abi.Events["ThresholdBreached"].ID.Bytes()
}

func (c *Codec) EncodeThresholdBreachedTopics(
	evt abi.Event,
	values []ThresholdBreachedTopics,
) ([]*evm.TopicValues, error) {

	rawTopics, err := abi.MakeTopics()
	if err != nil {
		return nil, err
	}

	return bindings.PrepareTopics(rawTopics, evt.ID.Bytes()), nil
}

// DecodeThresholdBreached decodes a log into a ThresholdBreached struct.
func (c *Codec) DecodeThresholdBreached(log *evm.Log) (*ThresholdBreachedDecoded, error) {
	event := new(ThresholdBreachedDecoded)
	if err := c.abi.UnpackIntoInterface(event, "ThresholdBreached", log.Data); err != nil {
		return nil, err
	}
	var indexed abi.Arguments
	for _, arg := range c.abi.Events["ThresholdBreached"].Inputs {
		if arg.Indexed {
			if arg.Type.T == abi.TupleTy {
				// abigen throws on tuple, so converting to bytes to
				// receive back the common.Hash as is instead of error
				arg.Type.T = abi.BytesTy
			}
			indexed = append(indexed, arg)
		}
	}
	// Convert [][]byte → []common.Hash
	topics := make([]common.Hash, len(log.Topics))
	for i, t := range log.Topics {
		topics[i] = common.BytesToHash(t)
	}

	if err := abi.ParseTopics(event, indexed, topics[1:]); err != nil {
		return nil, err
	}
	return event, nil
}

func (c CollateralizationMonitor) Forwarder(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeForwarderMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeForwarderMethodOutput(response.Data)
	})

}

func (c CollateralizationMonitor) GetLatestData(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[CollateralData] {
	calldata, err := c.Codec.EncodeGetLatestDataMethodCall()
	if err != nil {
		return cre.PromiseFromResult[CollateralData](*new(CollateralData), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (CollateralData, error) {
		return c.Codec.DecodeGetLatestDataMethodOutput(response.Data)
	})

}

func (c CollateralizationMonitor) LatestData(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[LatestDataOutput] {
	calldata, err := c.Codec.EncodeLatestDataMethodCall()
	if err != nil {
		return cre.PromiseFromResult[LatestDataOutput](LatestDataOutput{}, err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (LatestDataOutput, error) {
		return c.Codec.DecodeLatestDataMethodOutput(response.Data)
	})

}

func (c CollateralizationMonitor) MinRatio(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	calldata, err := c.Codec.EncodeMinRatioMethodCall()
	if err != nil {
		return cre.PromiseFromResult[*big.Int](*new(*big.Int), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (*big.Int, error) {
		return c.Codec.DecodeMinRatioMethodOutput(response.Data)
	})

}

func (c CollateralizationMonitor) Owner(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[common.Address] {
	calldata, err := c.Codec.EncodeOwnerMethodCall()
	if err != nil {
		return cre.PromiseFromResult[common.Address](*new(common.Address), err)
	}

	var bn cre.Promise[*pb.BigInt]
	if blockNumber == nil {
		promise := c.client.HeaderByNumber(runtime, &evm.HeaderByNumberRequest{
			BlockNumber: bindings.FinalizedBlockNumber,
		})

		bn = cre.Then(promise, func(finalizedBlock *evm.HeaderByNumberReply) (*pb.BigInt, error) {
			if finalizedBlock == nil || finalizedBlock.Header == nil {
				return nil, errors.New("failed to get finalized block header")
			}
			return finalizedBlock.Header.BlockNumber, nil
		})
	} else {
		bn = cre.PromiseFromResult(pb.NewBigIntFromInt(blockNumber), nil)
	}

	promise := cre.ThenPromise(bn, func(bn *pb.BigInt) cre.Promise[*evm.CallContractReply] {
		return c.client.CallContract(runtime, &evm.CallContractRequest{
			Call:        &evm.CallMsg{To: c.Address.Bytes(), Data: calldata},
			BlockNumber: bn,
		})
	})
	return cre.Then(promise, func(response *evm.CallContractReply) (common.Address, error) {
		return c.Codec.DecodeOwnerMethodOutput(response.Data)
	})

}

func (c CollateralizationMonitor) WriteReportFromCollateralData(
	runtime cre.Runtime,
	input CollateralData,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	encoded, err := c.Codec.EncodeCollateralDataStruct(input)
	if err != nil {
		return cre.PromiseFromResult[*evm.WriteReportReply](nil, err)
	}
	promise := runtime.GenerateReport(&pb2.ReportRequest{
		EncodedPayload: encoded,
		EncoderName:    "evm",
		SigningAlgo:    "ecdsa",
		HashingAlgo:    "keccak256",
	})

	return cre.ThenPromise(promise, func(report *cre.Report) cre.Promise[*evm.WriteReportReply] {
		return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
			Receiver:  c.Address.Bytes(),
			Report:    report,
			GasConfig: gasConfig,
		})
	})
}

func (c CollateralizationMonitor) WriteReport(
	runtime cre.Runtime,
	report *cre.Report,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	return c.client.WriteReport(runtime, &evm.WriteCreReportRequest{
		Receiver:  c.Address.Bytes(),
		Report:    report,
		GasConfig: gasConfig,
	})
}

// DecodeNotForwarderError decodes a NotForwarder error from revert data.
func (c *CollateralizationMonitor) DecodeNotForwarderError(data []byte) (*NotForwarder, error) {
	args := c.ABI.Errors["NotForwarder"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &NotForwarder{}, nil
}

// Error implements the error interface for NotForwarder.
func (e *NotForwarder) Error() string {
	return fmt.Sprintf("NotForwarder error:")
}

// DecodeNotOwnerError decodes a NotOwner error from revert data.
func (c *CollateralizationMonitor) DecodeNotOwnerError(data []byte) (*NotOwner, error) {
	args := c.ABI.Errors["NotOwner"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &NotOwner{}, nil
}

// Error implements the error interface for NotOwner.
func (e *NotOwner) Error() string {
	return fmt.Sprintf("NotOwner error:")
}

// DecodeReportTooShortError decodes a ReportTooShort error from revert data.
func (c *CollateralizationMonitor) DecodeReportTooShortError(data []byte) (*ReportTooShort, error) {
	args := c.ABI.Errors["ReportTooShort"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ReportTooShort{}, nil
}

// Error implements the error interface for ReportTooShort.
func (e *ReportTooShort) Error() string {
	return fmt.Sprintf("ReportTooShort error:")
}

// DecodeZeroAddressError decodes a ZeroAddress error from revert data.
func (c *CollateralizationMonitor) DecodeZeroAddressError(data []byte) (*ZeroAddress, error) {
	args := c.ABI.Errors["ZeroAddress"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ZeroAddress{}, nil
}

// Error implements the error interface for ZeroAddress.
func (e *ZeroAddress) Error() string {
	return fmt.Sprintf("ZeroAddress error:")
}

// DecodeZeroMinRatioError decodes a ZeroMinRatio error from revert data.
func (c *CollateralizationMonitor) DecodeZeroMinRatioError(data []byte) (*ZeroMinRatio, error) {
	args := c.ABI.Errors["ZeroMinRatio"].Inputs
	values, err := args.Unpack(data[4:])
	if err != nil {
		return nil, fmt.Errorf("failed to unpack error: %w", err)
	}
	if len(values) != 0 {
		return nil, fmt.Errorf("expected 0 values, got %d", len(values))
	}

	return &ZeroMinRatio{}, nil
}

// Error implements the error interface for ZeroMinRatio.
func (e *ZeroMinRatio) Error() string {
	return fmt.Sprintf("ZeroMinRatio error:")
}

func (c *CollateralizationMonitor) UnpackError(data []byte) (any, error) {
	switch common.Bytes2Hex(data[:4]) {
	case common.Bytes2Hex(c.ABI.Errors["NotForwarder"].ID.Bytes()[:4]):
		return c.DecodeNotForwarderError(data)
	case common.Bytes2Hex(c.ABI.Errors["NotOwner"].ID.Bytes()[:4]):
		return c.DecodeNotOwnerError(data)
	case common.Bytes2Hex(c.ABI.Errors["ReportTooShort"].ID.Bytes()[:4]):
		return c.DecodeReportTooShortError(data)
	case common.Bytes2Hex(c.ABI.Errors["ZeroAddress"].ID.Bytes()[:4]):
		return c.DecodeZeroAddressError(data)
	case common.Bytes2Hex(c.ABI.Errors["ZeroMinRatio"].ID.Bytes()[:4]):
		return c.DecodeZeroMinRatioError(data)
	default:
		return nil, errors.New("unknown error selector")
	}
}

// CollateralUpdatedTrigger wraps the raw log trigger and provides decoded CollateralUpdatedDecoded data
type CollateralUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                           // Embed the raw trigger
	contract                        *CollateralizationMonitor // Keep reference for decoding
}

// Adapt method that decodes the log into CollateralUpdated data
func (t *CollateralUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[CollateralUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeCollateralUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode CollateralUpdated log: %w", err)
	}

	return &bindings.DecodedLog[CollateralUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *CollateralizationMonitor) LogTriggerCollateralUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []CollateralUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[CollateralUpdatedDecoded]], error) {
	event := c.ABI.Events["CollateralUpdated"]
	topics, err := c.Codec.EncodeCollateralUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for CollateralUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &CollateralUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *CollateralizationMonitor) FilterLogsCollateralUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.CollateralUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ForwarderUpdatedTrigger wraps the raw log trigger and provides decoded ForwarderUpdatedDecoded data
type ForwarderUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                           // Embed the raw trigger
	contract                        *CollateralizationMonitor // Keep reference for decoding
}

// Adapt method that decodes the log into ForwarderUpdated data
func (t *ForwarderUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ForwarderUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeForwarderUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ForwarderUpdated log: %w", err)
	}

	return &bindings.DecodedLog[ForwarderUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *CollateralizationMonitor) LogTriggerForwarderUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ForwarderUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ForwarderUpdatedDecoded]], error) {
	event := c.ABI.Events["ForwarderUpdated"]
	topics, err := c.Codec.EncodeForwarderUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ForwarderUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ForwarderUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *CollateralizationMonitor) FilterLogsForwarderUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ForwarderUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// MinRatioUpdatedTrigger wraps the raw log trigger and provides decoded MinRatioUpdatedDecoded data
type MinRatioUpdatedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                           // Embed the raw trigger
	contract                        *CollateralizationMonitor // Keep reference for decoding
}

// Adapt method that decodes the log into MinRatioUpdated data
func (t *MinRatioUpdatedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[MinRatioUpdatedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeMinRatioUpdated(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode MinRatioUpdated log: %w", err)
	}

	return &bindings.DecodedLog[MinRatioUpdatedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *CollateralizationMonitor) LogTriggerMinRatioUpdatedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []MinRatioUpdatedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[MinRatioUpdatedDecoded]], error) {
	event := c.ABI.Events["MinRatioUpdated"]
	topics, err := c.Codec.EncodeMinRatioUpdatedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for MinRatioUpdated: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &MinRatioUpdatedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *CollateralizationMonitor) FilterLogsMinRatioUpdated(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.MinRatioUpdatedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// OwnershipTransferredTrigger wraps the raw log trigger and provides decoded OwnershipTransferredDecoded data
type OwnershipTransferredTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                           // Embed the raw trigger
	contract                        *CollateralizationMonitor // Keep reference for decoding
}

// Adapt method that decodes the log into OwnershipTransferred data
func (t *OwnershipTransferredTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[OwnershipTransferredDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeOwnershipTransferred(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode OwnershipTransferred log: %w", err)
	}

	return &bindings.DecodedLog[OwnershipTransferredDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *CollateralizationMonitor) LogTriggerOwnershipTransferredLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []OwnershipTransferredTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[OwnershipTransferredDecoded]], error) {
	event := c.ABI.Events["OwnershipTransferred"]
	topics, err := c.Codec.EncodeOwnershipTransferredTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for OwnershipTransferred: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &OwnershipTransferredTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *CollateralizationMonitor) FilterLogsOwnershipTransferred(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.OwnershipTransferredLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}

// ThresholdBreachedTrigger wraps the raw log trigger and provides decoded ThresholdBreachedDecoded data
type ThresholdBreachedTrigger struct {
	cre.Trigger[*evm.Log, *evm.Log]                           // Embed the raw trigger
	contract                        *CollateralizationMonitor // Keep reference for decoding
}

// Adapt method that decodes the log into ThresholdBreached data
func (t *ThresholdBreachedTrigger) Adapt(l *evm.Log) (*bindings.DecodedLog[ThresholdBreachedDecoded], error) {
	// Decode the log using the contract's codec
	decoded, err := t.contract.Codec.DecodeThresholdBreached(l)
	if err != nil {
		return nil, fmt.Errorf("failed to decode ThresholdBreached log: %w", err)
	}

	return &bindings.DecodedLog[ThresholdBreachedDecoded]{
		Log:  l,        // Original log
		Data: *decoded, // Decoded data
	}, nil
}

func (c *CollateralizationMonitor) LogTriggerThresholdBreachedLog(chainSelector uint64, confidence evm.ConfidenceLevel, filters []ThresholdBreachedTopics) (cre.Trigger[*evm.Log, *bindings.DecodedLog[ThresholdBreachedDecoded]], error) {
	event := c.ABI.Events["ThresholdBreached"]
	topics, err := c.Codec.EncodeThresholdBreachedTopics(event, filters)
	if err != nil {
		return nil, fmt.Errorf("failed to encode topics for ThresholdBreached: %w", err)
	}

	rawTrigger := evm.LogTrigger(chainSelector, &evm.FilterLogTriggerRequest{
		Addresses:  [][]byte{c.Address.Bytes()},
		Topics:     topics,
		Confidence: confidence,
	})

	return &ThresholdBreachedTrigger{
		Trigger:  rawTrigger,
		contract: c,
	}, nil
}

func (c *CollateralizationMonitor) FilterLogsThresholdBreached(runtime cre.Runtime, options *bindings.FilterOptions) (cre.Promise[*evm.FilterLogsReply], error) {
	if options == nil {
		return nil, errors.New("FilterLogs options are required.")
	}
	return c.client.FilterLogs(runtime, &evm.FilterLogsRequest{
		FilterQuery: &evm.FilterQuery{
			Addresses: [][]byte{c.Address.Bytes()},
			Topics: []*evm.Topics{
				{Topic: [][]byte{c.Codec.ThresholdBreachedLogHash()}},
			},
			BlockHash: options.BlockHash,
			FromBlock: pb.NewBigIntFromInt(options.FromBlock),
			ToBlock:   pb.NewBigIntFromInt(options.ToBlock),
		},
	}), nil
}
