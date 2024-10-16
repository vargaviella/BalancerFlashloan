// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "IFlashLoanRecipient.sol";
import "IBalancerVault.sol";
import "hardhat/console.sol";

contract BalancerFlashLoan is IFlashLoanRecipient {
    using SafeMath for uint256;

    address public immutable vault;
    address private owner;

    constructor(address _vault) {
        vault = _vault;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory
    ) external override {
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];
            console.log("borrowed amount:", amount);
            uint256 feeAmount = feeAmounts[i];
            console.log("flashloan fee: ", feeAmount);
            
            //add logic

            // Return loan
            token.transfer(vault, amount);
        }
    }

    function flashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external {
        IBalancerVault(vault).flashLoan(
            IFlashLoanRecipient(address(this)),
            tokens,
            amounts,
            userData
        );
    }

    function withdrawTokens(IERC20[] memory tokens, uint256[] memory amounts) external onlyOwner {
        require(tokens.length == amounts.length, "Token and amount arrays must have the same length");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(address(this));
            require(balance >= amounts[i], "Insufficient token balance");

            tokens[i].transfer(msg.sender, amounts[i]);
        }
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient Ether balance");
        payable(msg.sender).transfer(amount);
    }

    function transferTokens(IERC20 token, address to, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");

        token.transfer(to, amount);
    }

    function transferEther(address payable to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient Ether balance");
        to.transfer(amount);
    }

    receive() external payable {
        // Esta función permite que el contrato reciba Ether cuando se le envía directamente.
    }
}
