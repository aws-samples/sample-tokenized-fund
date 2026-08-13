// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICREPriceFeed.sol";
import "./interfaces/ICRECollateralMonitor.sol";
import "./SyntheticToken.sol";

/// @title SyntheticMinter
/// @notice Manages USDC collateral deposits and synthetic stock token minting/burning
/// @dev Integrates with CRE oracle feeds for real-time stock prices and protocol health monitoring
contract SyntheticMinter is Ownable, Pausable, ReentrancyGuard {
    // ============ Constants ============

    /// @notice Decimals used by CRE price feed (8 decimals, e.g., 18500000000 = $185.00)
    uint256 public constant PRICE_DECIMALS = 8;

    /// @notice Decimals used by USDC token
    uint256 public constant USDC_DECIMALS = 6;

    /// @notice Decimals used by synthetic token
    uint256 public constant SYNTHETIC_DECIMALS = 18;

    /// @notice Basis points denominator (10000 = 100%)
    uint256 public constant BPS_DENOMINATOR = 10000;

    // ============ Feed Interfaces ============

    /// @notice CRE price feed for stock prices
    ICREPriceFeed public priceFeed;

    /// @notice CRE collateral monitor for protocol health
    ICRECollateralMonitor public collateralMonitor;

    // ============ Tokens ============

    /// @notice USDC token used as collateral
    IERC20 public immutable usdc;

    /// @notice Synthetic token that users mint/burn
    SyntheticToken public immutable syntheticToken;

    // ============ Risk Parameters ============

    /// @notice Minimum collateralization ratio as percentage (e.g., 150 = 150%)
    uint256 public minCollateralizationRatio;

    /// @notice Mint fee in basis points (e.g., 30 = 0.3%)
    uint256 public mintFeeBps;

    /// @notice Maximum age in seconds for feed data to be considered valid
    uint256 public stalenessWindow;

    // ============ User Position Mappings ============

    /// @notice Total USDC deposited by each user
    mapping(address => uint256) public totalCollateral;

    /// @notice USDC currently backing minted tokens for each user
    mapping(address => uint256) public lockedCollateral;

    /// @notice Total USDC currently locked backing minted tokens across all users
    uint256 public totalLockedCollateral;

    // ============ Fee State ============

    /// @notice Address that receives collected fees
    address public feeRecipient;

    /// @notice Total fees accumulated and not yet collected
    uint256 public accumulatedFees;

    // ============ Events ============

    /// @notice Emitted when collateral is deposited
    event CollateralDeposited(address indexed user, uint256 amount, uint256 priceAtDeposit);

    /// @notice Emitted when collateral is withdrawn
    event CollateralWithdrawn(address indexed user, uint256 amount);

    /// @notice Emitted when synthetic tokens are minted
    event SyntheticMinted(address indexed user, uint256 amount, uint256 priceUsed, uint256 collateralRatio);

    /// @notice Emitted when synthetic tokens are burned
    event SyntheticBurned(address indexed user, uint256 amount, uint256 priceUsed, uint256 collateralReleased);

    /// @notice Emitted when a feed address is updated
    event FeedUpdated(string indexed feedType, address oldAddress, address newAddress);

    /// @notice Emitted when risk parameters are updated
    event RiskParamsUpdated(string indexed param, uint256 oldValue, uint256 newValue);

    /// @notice Emitted when fees are collected
    event FeesCollected(address indexed recipient, uint256 amount);

    // ============ Constructor ============

    /// @notice Creates a new SyntheticMinter
    /// @param _usdc Address of the USDC token contract
    /// @param _syntheticToken Address of the SyntheticToken contract
    /// @param _initialOwner Address that will own the contract
    /// @param _feeRecipient Address that will receive collected fees
    constructor(
        address _usdc,
        address _syntheticToken,
        address _initialOwner,
        address _feeRecipient
    ) Ownable(_initialOwner) {
        require(_usdc != address(0), "Invalid USDC address");
        require(_syntheticToken != address(0), "Invalid synthetic token address");
        require(_feeRecipient != address(0), "Invalid fee recipient");

        usdc = IERC20(_usdc);
        syntheticToken = SyntheticToken(_syntheticToken);
        feeRecipient = _feeRecipient;

        // Set default risk parameters
        minCollateralizationRatio = 150; // 150%
        mintFeeBps = 30; // 0.3%
        stalenessWindow = 3600; // 1 hour
    }

    // ============ Admin Setters ============

    /// @notice Sets the price feed address
    /// @dev Only callable by owner
    /// @param _priceFeed Address of the new price feed contract
    function setPriceFeed(address _priceFeed) external onlyOwner {
        require(_priceFeed != address(0), "Invalid feed address");
        address oldAddress = address(priceFeed);
        priceFeed = ICREPriceFeed(_priceFeed);
        emit FeedUpdated("priceFeed", oldAddress, _priceFeed);
    }

    /// @notice Sets the collateral monitor address
    /// @dev Only callable by owner
    /// @param _collateralMonitor Address of the new collateral monitor contract
    function setCollateralMonitor(address _collateralMonitor) external onlyOwner {
        require(_collateralMonitor != address(0), "Invalid feed address");
        address oldAddress = address(collateralMonitor);
        collateralMonitor = ICRECollateralMonitor(_collateralMonitor);
        emit FeedUpdated("collateralMonitor", oldAddress, _collateralMonitor);
    }

    /// @notice Sets the minimum collateralization ratio
    /// @dev Only callable by owner
    /// @param _minCollateralizationRatio New minimum ratio as percentage
    function setMinCollateralizationRatio(uint256 _minCollateralizationRatio) external onlyOwner {
        uint256 oldValue = minCollateralizationRatio;
        minCollateralizationRatio = _minCollateralizationRatio;
        emit RiskParamsUpdated("minCollateralizationRatio", oldValue, _minCollateralizationRatio);
    }

    /// @notice Sets the mint fee in basis points
    /// @dev Only callable by owner, max 1000 bps (10%)
    /// @param _mintFeeBps New mint fee in basis points
    function setMintFeeBps(uint256 _mintFeeBps) external onlyOwner {
        require(_mintFeeBps <= 1000, "Fee exceeds maximum");
        uint256 oldValue = mintFeeBps;
        mintFeeBps = _mintFeeBps;
        emit RiskParamsUpdated("mintFeeBps", oldValue, _mintFeeBps);
    }

    /// @notice Sets the staleness window for feed data
    /// @dev Only callable by owner
    /// @param _stalenessWindow New staleness window in seconds
    function setStalenessWindow(uint256 _stalenessWindow) external onlyOwner {
        uint256 oldValue = stalenessWindow;
        stalenessWindow = _stalenessWindow;
        emit RiskParamsUpdated("stalenessWindow", oldValue, _stalenessWindow);
    }

    /// @notice Sets the fee recipient address
    /// @dev Only callable by owner
    /// @param _feeRecipient New fee recipient address
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    // ============ Pause Functions ============

    /// @notice Pauses the contract
    /// @dev Only callable by owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract
    /// @dev Only callable by owner
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ Internal Validation Functions ============

    /// @notice Validates the price feed and returns the current price
    /// @dev Checks feed is set, price is positive, and data is not stale
    /// @return price The validated price from the feed
    function _validatePriceFeed() internal view returns (uint256 price) {
        require(address(priceFeed) != address(0), "Feed not set");
        
        uint256 timestamp;
        (price, timestamp) = priceFeed.getLatestPrice();
        
        require(price > 0, "Invalid price");
        require(block.timestamp - timestamp <= stalenessWindow, "Price feed stale");
        
        return price;
    }

    /// @notice Validates the collateral monitor and returns the current data
    /// @dev Checks feed is set, data is not stale, and protocol is healthy
    /// @return data The validated CollateralData from the monitor
    function _validateCollateralMonitor() internal view returns (ICRECollateralMonitor.CollateralData memory data) {
        require(address(collateralMonitor) != address(0), "Feed not set");
        
        data = collateralMonitor.getLatestData();
        
        require(block.timestamp - data.timestamp <= stalenessWindow, "Collateral feed stale");
        require(data.isHealthy == true, "Protocol unhealthy");
        
        return data;
    }

    // ============ Collateral Management Functions ============

    /// @notice Deposits USDC as collateral
    /// @dev Requires prior approval of USDC transfer
    /// @param amount Amount of USDC to deposit (6 decimals)
    function depositCollateral(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        
        // Transfer USDC from user to contract
        bool success = usdc.transferFrom(msg.sender, address(this), amount);
        require(success, "USDC transfer failed");
        
        // Update user's total collateral
        totalCollateral[msg.sender] += amount;
        
        // Get current price for event (handle if feed not set yet)
        uint256 priceAtDeposit = 0;
        if (address(priceFeed) != address(0)) {
            try priceFeed.getLatestPrice() returns (uint256 price, uint256) {
                priceAtDeposit = price;
            } catch {
                // Price feed call failed, use 0
            }
        }
        
        emit CollateralDeposited(msg.sender, amount, priceAtDeposit);
    }

    /// @notice Withdraws unused USDC collateral
    /// @dev Allowed even when paused to enable user exits
    /// @param amount Amount of USDC to withdraw (6 decimals)
    function withdrawCollateral(uint256 amount) external nonReentrant {
        // Calculate available collateral (not backing any minted tokens)
        uint256 available = totalCollateral[msg.sender] - lockedCollateral[msg.sender];
        require(amount <= available, "Insufficient available collateral");
        
        // Update user's total collateral
        totalCollateral[msg.sender] -= amount;
        
        // Transfer USDC back to user
        bool success = usdc.transfer(msg.sender, amount);
        require(success, "USDC transfer failed");
        
        emit CollateralWithdrawn(msg.sender, amount);
    }

    // ============ Mint Function ============

    /// @notice Mints synthetic tokens by locking USDC collateral
    /// @dev Requires sufficient available collateral and valid CRE feeds
    /// @param syntheticAmount Amount of synthetic tokens to mint (18 decimals)
    function mint(uint256 syntheticAmount) external nonReentrant whenNotPaused {
        require(syntheticAmount > 0, "Amount must be greater than zero");
        
        // Validate feeds and get current price
        uint256 price = _validatePriceFeed();
        _validateCollateralMonitor();
        
        // Calculate required collateral in USDC (6 decimals)
        // Formula: (syntheticAmount * price * minCollateralizationRatio) / (100 * 10^PRICE_DECIMALS)
        // Adjust for decimal difference: synthetic (18) vs USDC (6) = divide by 10^12
        uint256 requiredCollateral = (syntheticAmount * price * minCollateralizationRatio) 
            / (100 * 10**PRICE_DECIMALS * 10**(SYNTHETIC_DECIMALS - USDC_DECIMALS));
        
        // Check available collateral
        uint256 available = totalCollateral[msg.sender] - lockedCollateral[msg.sender];
        require(available >= requiredCollateral, "Insufficient collateral");
        
        // Calculate fee and net amount
        uint256 fee = (syntheticAmount * mintFeeBps) / BPS_DENOMINATOR;
        uint256 netAmount = syntheticAmount - fee;
        
        // Update state
        lockedCollateral[msg.sender] += requiredCollateral;
        totalLockedCollateral += requiredCollateral;
        accumulatedFees += fee;
        
        // Mint synthetic tokens to user
        syntheticToken.mint(msg.sender, netAmount);
        
        // Calculate resulting collateral ratio for event
        // CR = (lockedCollateral * 100 * 10^PRICE_DECIMALS) / (syntheticBalance * price)
        uint256 syntheticBalance = syntheticToken.balanceOf(msg.sender);
        uint256 collateralRatio = 0;
        if (syntheticBalance > 0 && price > 0) {
            // Adjust for decimals: locked (6) vs synthetic (18)
            collateralRatio = (lockedCollateral[msg.sender] * 100 * 10**PRICE_DECIMALS * 10**(SYNTHETIC_DECIMALS - USDC_DECIMALS)) 
                / (syntheticBalance * price);
        }
        
        emit SyntheticMinted(msg.sender, netAmount, price, collateralRatio);
    }

    // ============ Burn Function ============

    /// @notice Burns synthetic tokens and releases proportional collateral
    /// @dev Requires valid price feed, releases collateral proportionally to burn amount
    /// @param syntheticAmount Amount of synthetic tokens to burn (18 decimals)
    function burn(uint256 syntheticAmount) external nonReentrant whenNotPaused {
        require(syntheticAmount > 0, "Amount must be greater than zero");
        
        // Validate price feed and get current price
        uint256 price = _validatePriceFeed();
        
        // Get user's synthetic balance
        uint256 userBalance = syntheticToken.balanceOf(msg.sender);
        require(syntheticAmount <= userBalance, "Insufficient balance");
        
        // Calculate collateral to release proportionally
        // collateralToRelease = lockedCollateral[user] * syntheticAmount / userBalance
        uint256 collateralToRelease = (lockedCollateral[msg.sender] * syntheticAmount) / userBalance;
        
        // Update state - decrement locked collateral
        lockedCollateral[msg.sender] -= collateralToRelease;
        totalLockedCollateral -= collateralToRelease;
        
        // Burn synthetic tokens from user
        syntheticToken.burn(msg.sender, syntheticAmount);
        
        emit SyntheticBurned(msg.sender, syntheticAmount, price, collateralToRelease);
    }

    // ============ View Functions ============

    /// @notice Returns the total USDC collateral held by the contract
    /// @dev Used by CRE workflow to read on-chain collateral state
    /// @return Total USDC balance of this contract
    function getCollateralValue() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /// @notice Returns the latest price from the CRE price feed with staleness check
    /// @dev Reverts if feed is not set, price is invalid, or data is stale
    /// @return price The current stock price (8 decimals)
    function getLatestPrice() external view returns (uint256 price) {
        return _validatePriceFeed();
    }

    /// @notice Returns the user's current collateralization ratio
    /// @dev CR = (lockedCollateral * 100 * 10^PRICE_DECIMALS) / (syntheticBalance * price)
    /// @param user The address of the user to query
    /// @return ratio The collateralization ratio as a percentage (e.g., 150 = 150%)
    function getUserCollateralRatio(address user) external view returns (uint256 ratio) {
        uint256 locked = lockedCollateral[user];
        uint256 syntheticBalance = syntheticToken.balanceOf(user);
        
        // If no position, return max uint (infinite CR)
        if (syntheticBalance == 0 || locked == 0) {
            return type(uint256).max;
        }
        
        // Get current price (with staleness check)
        uint256 price = _validatePriceFeed();
        
        // CR = (lockedCollateral * 100 * 10^PRICE_DECIMALS * 10^(SYNTHETIC_DECIMALS - USDC_DECIMALS)) / (syntheticBalance * price)
        // This adjusts for the decimal difference between USDC (6) and synthetic (18)
        ratio = (locked * 100 * 10**PRICE_DECIMALS * 10**(SYNTHETIC_DECIMALS - USDC_DECIMALS)) / (syntheticBalance * price);
        
        return ratio;
    }

    /// @notice Returns the user's available collateral (not backing any minted tokens)
    /// @param user The address of the user to query
    /// @return available The amount of USDC available for withdrawal or new mints (6 decimals)
    function getAvailableCollateral(address user) external view returns (uint256 available) {
        return totalCollateral[user] - lockedCollateral[user];
    }

    /// @notice Returns the maximum amount of synthetic tokens the user can mint
    /// @dev Based on available collateral, current price, and min collateralization ratio
    /// @param user The address of the user to query
    /// @return maxMintable The maximum synthetic tokens mintable (18 decimals)
    function getMaxMintable(address user) external view returns (uint256 maxMintable) {
        uint256 available = totalCollateral[user] - lockedCollateral[user];
        
        // If no available collateral, return 0
        if (available == 0) {
            return 0;
        }
        
        // Get current price (with staleness check)
        uint256 price = _validatePriceFeed();
        
        // Inverse of mint formula:
        // requiredCollateral = (syntheticAmount * price * minCollateralizationRatio) / (100 * 10^PRICE_DECIMALS * 10^12)
        // Therefore:
        // maxMintable = (available * 100 * 10^PRICE_DECIMALS * 10^12) / (price * minCollateralizationRatio)
        maxMintable = (available * 100 * 10**PRICE_DECIMALS * 10**(SYNTHETIC_DECIMALS - USDC_DECIMALS)) / (price * minCollateralizationRatio);
        
        return maxMintable;
    }

    /// @notice Returns the USD value of the user's synthetic token holdings
    /// @dev Value = syntheticBalance * price / 10^PRICE_DECIMALS
    /// @param user The address of the user to query
    /// @return value The USD value of the position (adjusted for decimals)
    function getPositionValue(address user) external view returns (uint256 value) {
        uint256 syntheticBalance = syntheticToken.balanceOf(user);
        
        // If no position, return 0
        if (syntheticBalance == 0) {
            return 0;
        }
        
        // Get current price (with staleness check)
        uint256 price = _validatePriceFeed();
        
        // Value = syntheticBalance * price / 10^PRICE_DECIMALS
        // Result is in synthetic token decimals (18) representing USD value
        value = (syntheticBalance * price) / 10**PRICE_DECIMALS;
        
        return value;
    }

    // ============ Fee Collection ============

    /// @notice Collects accumulated fees and transfers them to the fee recipient
    /// @dev Only callable by owner or feeRecipient
    function collectFees() external {
        require(msg.sender == owner() || msg.sender == feeRecipient, "Not authorized");
        
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees to collect");
        
        // Reset accumulated fees before transfer (checks-effects-interactions)
        accumulatedFees = 0;
        
        // Transfer fees to fee recipient
        // Note: Fees are accumulated in synthetic token units (18 decimals)
        // The fee recipient receives synthetic tokens
        syntheticToken.mint(feeRecipient, amount);
        
        emit FeesCollected(feeRecipient, amount);
    }
}
