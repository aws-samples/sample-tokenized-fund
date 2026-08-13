// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ICREPriceFeed
/// @notice Minimal interface for CRE price feed contracts
/// @dev Matches the existing PriceFeed.sol contract signature
interface ICREPriceFeed {
    /// @notice Returns the latest price and timestamp
    /// @return price The asset price (8 decimals, e.g., 18500000000 = $185.00)
    /// @return timestamp Unix timestamp when price was updated
    function getLatestPrice() external view returns (uint256 price, uint256 timestamp);
}
