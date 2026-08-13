// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SyntheticToken
/// @notice ERC20 token representing a synthetic stock (e.g., sSPY)
/// @dev Mint and burn controlled by a designated minter address (SyntheticMinter contract)
contract SyntheticToken is ERC20, Ownable {
    /// @notice Address authorized to mint and burn tokens
    address public minter;

    /// @notice Emitted when the minter address is updated
    /// @param oldMinter Previous minter address
    /// @param newMinter New minter address
    event MinterUpdated(address indexed oldMinter, address indexed newMinter);

    /// @notice Restricts function access to the minter address only
    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }

    /// @notice Creates a new SyntheticToken
    /// @param name_ Token name (e.g., "Synthetic S&P 500")
    /// @param symbol_ Token symbol (e.g., "sSPY")
    /// @param initialOwner Address that will own the contract
    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner
    ) ERC20(name_, symbol_) Ownable(initialOwner) {}

    /// @notice Sets the minter address
    /// @dev Only callable by the contract owner
    /// @param newMinter Address to set as the new minter
    function setMinter(address newMinter) external onlyOwner {
        address oldMinter = minter;
        minter = newMinter;
        emit MinterUpdated(oldMinter, newMinter);
    }

    /// @notice Mints tokens to a specified address
    /// @dev Only callable by the minter
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address
    /// @dev Only callable by the minter
    /// @param from Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burn(address from, uint256 amount) external onlyMinter {
        _burn(from, amount);
    }
}
