// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReentrancyEther {
    error ReentrancyEther_InsufficientBalance();
    error ReentrancyEther_SendingError();

    mapping(address user => uint amount) public s_balances;

    event Deposited(address user, uint amount);
    event Withdrawed(address user, uint amount);

    function deposit() public payable {
        s_balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() public payable {
        if (s_balances[msg.sender] < msg.value) {
            revert ReentrancyEther_InsufficientBalance();
        }

        (bool sent, ) = address(msg.sender).call{value: msg.value}("");

        if (!sent) {
            revert ReentrancyEther_SendingError();
        }

        s_balances[msg.sender] -= msg.value;
    }

    function getBalance(address _of) public view returns (uint) {
        return s_balances[_of];
    }
}

contract Attack {}
