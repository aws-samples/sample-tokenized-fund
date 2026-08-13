// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ICRECollateralMonitor
/// @notice Minimal interface for CRE collateral monitoring contracts
/// @dev Matches the existing CollateralizationMonitor.sol contract signature
interface ICRECollateralMonitor {
    /// @notice Collateral health data structure
    /// @param price Current asset price
    /// @param reserves Total reserves value
    /// @param ratio Collateralization ratio as percentage
    /// @param timestamp Unix timestamp when data was updated
    /// @param isHealthy Whether protocol meets minimum health threshold
    struct CollateralData {
        uint256 price;
        uint256 reserves;
        uint256 ratio;
        uint256 timestamp;
        bool isHealthy;
    }

    /// @notice Returns the latest collateral health data
    /// @return data The CollateralData struct with current metrics
    function getLatestData() external view returns (CollateralData memory data);
}
