// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Asteroid.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract LaunchPadAsteroid is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20Metadata;
    // Stablecoin payment
    IERC20Metadata public paymentCoin;
    // Interface for IERC1155Asteroid
    IERC1155Asteroid public iERC1155Asteroid;

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

    constructor(address _initialPayment) Ownable(_msgSender()) {
        require(
            _initialPayment != address(0),
            "Invalid initialPayment address"
        );
        paymentCoin = IERC20Metadata(_initialPayment);
    }

    /**
     * @dev user purchases mine
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
            "LaunchPadAsteroid#purchased: The ERC1155Asteroid contract is not initalized"
        );
        require(
            id > 0 && amount > 0,
            "LaunchPadAsteroid#purchased: Invalid parameter"
        );
        address userAddress = _msgSender();
        uint256 decimal = paymentCoin.decimals();
        require(
            decimal > 0,
            "LaunchPadAsteroid#purchased: Invalid stablecoins"
        );
        uint256 balance = paymentCoin.balanceOf(userAddress);
        uint256 realAmount = amount * 10**decimal;
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
     * @dev set to paymentCoin contract
     */
    function setPaymentCoin(IERC20Metadata _iERC20Metadata) external onlyOwner {
        require(
            paymentCoin != _iERC20Metadata,
            "LaunchPadAsteroid#setERC1155AsteroidContract: PaymentCoin has been already configured"
        );
        paymentCoin = _iERC20Metadata;
    }

    /**
     * @dev set to asteroid contract
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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev If this contract has other funds, emergency withdrawal
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
}