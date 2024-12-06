// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title IERC1155Asteroid Interface
 * @dev Interface for ERC1155Asteroid contract
 */
interface IERC1155Asteroid {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function fundsWallet(uint256 _id) external view returns (address);

    function buy(
        address userAddress,
        uint256 id,
        uint256 amount
    ) external returns (bool);

    function tokenMinAmounts(uint256 _id) external view returns (uint256);

    function tokenMaxAmounts(uint256 _id) external view returns (uint256);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) external;
}

/**
 * @title LaunchPadAsteroidV2
 * @dev Advanced version of LaunchPad contract with per-token purchase limits
 */
contract LaunchPadAsteroidV2 is
    Ownable,
    ReentrancyGuard,
    Pausable,
    ERC1155Holder
{
    using SafeERC20 for IERC20Metadata;

    // Contract state variables
    IERC20Metadata public paymentCoin;
    IERC1155Asteroid public iERC1155Asteroid;

    // Custom errors
    error InvalidContract();
    error InvalidParameters();
    error InvalidAmount(uint256 minAmount, uint256 maxAmount, uint256 amount);
    error InsufficientBalance(uint256 required, uint256 available);
    error InvalidConfiguration();
    error InvalidTokenAmounts();

    // Purchase limit configuration per token
    struct PurchaseLimit {
        uint256 timeWindow; // Time window in seconds
        uint256 maxPurchases; // Maximum purchases allowed in time window
        bool enabled; // Whether the limit is enabled
    }

    // User purchase record
    struct PurchaseRecord {
        uint256 lastPurchaseTime; // Last purchase timestamp
        uint256 purchaseCount; // Number of purchases in time window
    }

    // Mapping for token-specific purchase limits
    mapping(uint256 => PurchaseLimit) public purchaseLimits;

    // User purchase records mapping: user => tokenId => record
    mapping(address => mapping(uint256 => PurchaseRecord))
        private purchaseRecords;

    // Events
    event AsteroidCreated(
        address contractAddress,
        uint256 tokenId,
        address paymentAddress,
        uint256 totalSupply,
        uint256 totalAmounts,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 timestamp
    );

    event AsteroidPurchased(
        address contractAddress,
        uint256 tokenId,
        address paymentAddress,
        uint256 amount,
        uint256 timestamp
    );

    event PurchaseLimitSet(
        uint256 tokenId,
        uint256 timeWindow,
        uint256 maxPurchases,
        bool enabled
    );

    /**
     * @dev Contract constructor
     * @param _initialPayment Initial payment token address
     */
    constructor(address _initialPayment) Ownable(_msgSender()) {
        require(
            _initialPayment != address(0),
            "Invalid initialPayment address"
        );
        paymentCoin = IERC20Metadata(_initialPayment);
    }

    /**
     * @dev Original purchase function using buy method
     * @param id Token ID to purchase
     * @param amount Amount of payment tokens
     * @return success Whether the purchase was successful
     */
    function purchased(uint256 id, uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (bool success)
    {
        require(
            address(iERC1155Asteroid) != address(0),
            "LaunchPadAsteroid#purchased: The ERC1155Asteroid contract is not initialized"
        );
        require(
            id > 0 && amount > 0,
            "LaunchPadAsteroid#purchased: Invalid parameter"
        );

        // Check purchase limit
        _checkPurchaseLimit(id);

        address userAddress = _msgSender();
        uint256 decimal = paymentCoin.decimals();
        require(
            decimal > 0,
            "LaunchPadAsteroid#purchased: Invalid stablecoins"
        );

        uint256 balance = paymentCoin.balanceOf(userAddress);
        (, uint256 realAmount) = Math.tryMul(amount, 10**decimal);
        require(
            balance >= realAmount,
            "LaunchPadAsteroid#purchased: Insufficient amount"
        );

        address fundsWallet = iERC1155Asteroid.fundsWallet(id);
        require(
            fundsWallet != address(0),
            "LaunchPadAsteroid#purchased: Invalid fundsWallet"
        );

        paymentCoin.safeTransferFrom(userAddress, fundsWallet, realAmount);
        bool succ = iERC1155Asteroid.buy(userAddress, id, amount);

        emit AsteroidPurchased(
            address(iERC1155Asteroid),
            id,
            address(paymentCoin),
            amount,
            block.timestamp
        );

        return succ;
    }

    /**
     * @dev New purchase function with direct transfer
     * @param id Token ID to purchase
     * @param amount Amount of payment tokens
     * @return success Whether the purchase was successful
     */
    function purchaseWithTransfer(uint256 id, uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (bool success)
    {
        // Basic validation
        if (address(iERC1155Asteroid) == address(0)) revert InvalidContract();
        if (id == 0 || amount == 0) revert InvalidParameters();

        // Check purchase limit
        _checkPurchaseLimit(id);

        // Get payment parameters
        address userAddress = _msgSender();
        uint256 decimal = paymentCoin.decimals();
        if (decimal == 0) revert InvalidConfiguration();

        // Validate amounts
        uint256 minAmount = iERC1155Asteroid.tokenMinAmounts(id);
        uint256 maxAmount = iERC1155Asteroid.tokenMaxAmounts(id);

        // Check amount configuration
        if (minAmount == 0 || maxAmount == 0 || maxAmount < minAmount) {
            revert InvalidTokenAmounts();
        }

        // Check amount range
        if (amount < minAmount || amount > maxAmount) {
            revert InvalidAmount(minAmount, maxAmount, amount);
        }

        // Calculate and check balances
        (, uint256 realAmount)  = Math.tryMul(amount, 10**decimal);
        uint256 balance = paymentCoin.balanceOf(userAddress);
        if (balance < realAmount) {
            revert InsufficientBalance(realAmount, balance);
        }

        // Calculate transfer quantity
        (, uint256 quantity) = Math.tryDiv(amount, minAmount);
        if (quantity == 0) revert InvalidParameters();

        // Check NFT balance
        uint256 contractBalance = iERC1155Asteroid.balanceOf(address(this), id);
        if (contractBalance < quantity) {
            revert InsufficientBalance(quantity, contractBalance);
        }

        // Get funds wallet
        address fundsWallet = iERC1155Asteroid.fundsWallet(id);
        if (fundsWallet == address(0)) revert InvalidConfiguration();

        // Execute transfers
        paymentCoin.safeTransferFrom(userAddress, fundsWallet, realAmount);
        iERC1155Asteroid.safeTransferFrom(
            address(this),
            userAddress,
            id,
            quantity,
            ""
        );

        return true;
    }

    /**
     * @dev Internal function to check purchase limits
     * @param id Token ID to check
     */
    function _checkPurchaseLimit(uint256 id) internal {
        PurchaseLimit storage limit = purchaseLimits[id];
        if (limit.enabled) {
            PurchaseRecord storage record = purchaseRecords[_msgSender()][id];

            // Reset counter if time window has passed
            if (block.timestamp >= record.lastPurchaseTime + limit.timeWindow) {
                record.purchaseCount = 0;
            }

            if (record.purchaseCount >= limit.maxPurchases) {
                revert InvalidAmount(
                    0,
                    limit.maxPurchases,
                    record.purchaseCount + 1
                );
            }

            // Update purchase record
            record.lastPurchaseTime = block.timestamp;
            record.purchaseCount++;
        }
    }

    /**
     * @dev Set purchase limit for specific token ID
     */
    function setPurchaseLimit(
        uint256 id,
        uint256 _timeWindow,
        uint256 _maxPurchases,
        bool _enabled
    ) external onlyOwner {
        require(id > 0, "Invalid token ID");
        require(_timeWindow > 0, "Invalid time window");
        require(_maxPurchases > 0, "Invalid max purchases");

        purchaseLimits[id] = PurchaseLimit({
            timeWindow: _timeWindow,
            maxPurchases: _maxPurchases,
            enabled: _enabled
        });

        emit PurchaseLimitSet(id, _timeWindow, _maxPurchases, _enabled);
    }

    /**
     * @dev Batch set purchase limits
     */
    function batchSetPurchaseLimits(
        uint256[] calldata ids,
        uint256[] calldata timeWindows,
        uint256[] calldata maxPurchases,
        bool[] calldata enableds
    ) external onlyOwner {
        require(
            ids.length == timeWindows.length &&
                ids.length == maxPurchases.length &&
                ids.length == enableds.length,
            "Array lengths mismatch"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] > 0, "Invalid token ID");
            require(timeWindows[i] > 0, "Invalid time window");
            require(maxPurchases[i] > 0, "Invalid max purchases");

            purchaseLimits[ids[i]] = PurchaseLimit({
                timeWindow: timeWindows[i],
                maxPurchases: maxPurchases[i],
                enabled: enableds[i]
            });

            emit PurchaseLimitSet(
                ids[i],
                timeWindows[i],
                maxPurchases[i],
                enableds[i]
            );
        }
    }

    /**
     * @dev Get purchase limit for specific token ID
     */
    function getPurchaseLimit(uint256 id)
        external
        view
        returns (
            uint256 timeWindow,
            uint256 maxPurchases,
            bool enabled
        )
    {
        PurchaseLimit storage limit = purchaseLimits[id];
        return (limit.timeWindow, limit.maxPurchases, limit.enabled);
    }

    /**
     * @dev Set payment token contract
     */
    function setPaymentCoin(IERC20Metadata _iERC20Metadata) external onlyOwner {
        require(
            paymentCoin != _iERC20Metadata,
            "LaunchPadAsteroid#setERC1155AsteroidContract: PaymentCoin has been already configured"
        );
        paymentCoin = _iERC20Metadata;
    }

    /**
     * @dev Set asteroid NFT contract
     */
    function setERC1155AsteroidContract(IERC1155Asteroid _iERC1155Asteroid)
        external
        onlyOwner
    {
        require(
            iERC1155Asteroid != _iERC1155Asteroid,
            "LaunchPadAsteroid#setERC1155AsteroidContract: ERC1155Asteroid has been already configured"
        );
        iERC1155Asteroid = _iERC1155Asteroid;
    }

    /**
     * @dev Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency withdrawal of any ERC20 tokens
     */
    function withdraw(
        address to,
        address erc20Address,
        uint256 amount
    ) external onlyOwner {
        uint256 balance = IERC20Metadata(erc20Address).balanceOf(address(this));
        require(balance >= amount, "Insufficient balance!");
        IERC20Metadata(erc20Address).safeTransfer(to, amount);
    }

    /**
     * @dev Check if token ID has purchase limit configured
     * @param id Token ID to check
     * @return bool Whether the token has purchase limit
     */
    function hasTokenPurchaseLimit(uint256 id) public view returns (bool) {
        PurchaseLimit storage limit = purchaseLimits[id];
        return limit.enabled && limit.timeWindow > 0 && limit.maxPurchases > 0;
    }

    /**
     * @dev Batch transfer tokens from contract to multiple recipients
     * @param ids Array of token IDs
     * @param recipients Array of recipient addresses
     * @param amounts Array of token amounts
     */
    function batchTransferTokens(
        uint256[] calldata ids,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner nonReentrant {
        require(
            ids.length == recipients.length && ids.length == amounts.length,
            "LaunchPadAsteroid: Arrays length mismatch"
        );
        require(ids.length > 0, "LaunchPadAsteroid: Empty arrays");

        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] > 0, "LaunchPadAsteroid: Invalid token ID");
            require(
                recipients[i] != address(0),
                "LaunchPadAsteroid: Invalid recipient"
            );
            require(amounts[i] > 0, "LaunchPadAsteroid: Invalid amount");

            // Check contract balance
            uint256 contractBalance = iERC1155Asteroid.balanceOf(
                address(this),
                ids[i]
            );
            require(
                contractBalance >= amounts[i],
                "LaunchPadAsteroid: Insufficient token balance"
            );

            // Transfer token
            iERC1155Asteroid.safeTransferFrom(
                address(this),
                recipients[i],
                ids[i],
                amounts[i],
                ""
            );
        }
    }

    /**
     * @dev Emergency token recovery
     * @param id Token ID
     * @param recipient Recipient address
     * @param amount Token amount
     */
    function emergencyWithdraw(
        uint256 id,
        address recipient,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(id > 0, "LaunchPadAsteroid: Invalid token ID");
        require(
            recipient != address(0),
            "LaunchPadAsteroid: Invalid recipient"
        );
        require(amount > 0, "LaunchPadAsteroid: Invalid amount");

        // Check contract balance
        uint256 contractBalance = iERC1155Asteroid.balanceOf(address(this), id);
        require(
            contractBalance >= amount,
            "LaunchPadAsteroid: Insufficient token balance"
        );

        // Transfer token
        iERC1155Asteroid.safeTransferFrom(
            address(this),
            recipient,
            id,
            amount,
            ""
        );
    }
}
