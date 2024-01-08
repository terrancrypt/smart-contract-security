// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice contract này sửa lổ hổng Reentrancy trong contract ReentrancyEther.sol
contract ReentrancyEtherFixed is ReentrancyGuard {
    error ReentrancyEther_InsufficientBalance();
    error ReentrancyEther_SendingEtherError();
    error ReentrancyEther_NonReentrant();

    mapping(address user => uint amount) private s_balances;

    event Deposited(address, uint);
    event Withdrawed(address, uint);

    function deposit() public payable {
        s_balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() public payable nonReentrant {
        uint balance = s_balances[msg.sender];

        // Checks
        if (balance <= 0) {
            revert ReentrancyEther_InsufficientBalance();
        }

        // Effects
        s_balances[msg.sender] = 0;

        // Interactions
        (bool sent, ) = address(msg.sender).call{value: balance}("");

        if (!sent) {
            revert ReentrancyEther_SendingEtherError();
        }

        emit Withdrawed(msg.sender, balance);
    }

    function getBalanceOf(address _of) external view returns (uint) {
        return s_balances[_of];
    }
}
