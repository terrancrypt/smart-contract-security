// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ReentrancyEther} from "src/ReentrancyEther.sol";
import {DeployReentrancyEther} from "script/DeployReentrancyEther.s.sol";

contract ReentrancyEtherTest is Test {
    ReentrancyEther reentrancyEther;
    DeployReentrancyEther deployer;

    address owner = makeAddr("owner");
    address user = makeAddr("user");

    uint256 constant AMOUNT_OF_OWNER = 10 ether;
    uint256 constant AMOUNT_OF_USER = 2 ether;
    uint256 constant AMOUNT_TO_DEPOSIT = 1 ether;

    function setUp() external {
        deployer = new DeployReentrancyEther();
        reentrancyEther = deployer.run();

        deal(owner, AMOUNT_OF_OWNER);
        deal(user, AMOUNT_OF_USER);

        vm.prank(owner);
        reentrancyEther.deposit{value: AMOUNT_OF_OWNER}();
    }

    function test_canDeposit() public {
        vm.prank(user);
        reentrancyEther.deposit{value: AMOUNT_TO_DEPOSIT}();

        uint balanceOfUserAfterDeposit = reentrancyEther.getBalance(user);
        uint balanceOfContractAfterDeposit = address(reentrancyEther).balance;

        assertEq(AMOUNT_OF_USER - AMOUNT_TO_DEPOSIT, balanceOfUserAfterDeposit);
        assertEq(
            AMOUNT_OF_OWNER + AMOUNT_TO_DEPOSIT,
            balanceOfContractAfterDeposit
        );
    }
}
