// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DeployReentrancyEther} from "script/DeployReentrancyEther.s.sol";
import {ReentrancyEther, AttackReentrancyEther} from "src/ReentrancyEther.sol";

contract ReentrancyEtherTest is Test {
    ReentrancyEther reentrancyEther;
    DeployReentrancyEther deployer;

    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    uint constant AMOUNT_OF_OWNER = 10 ether;
    uint constant AMOUNT_OF_USER = 2 ether;
    uint constant AMOUNT_OF_ATTACKER = 1 ether;
    uint constant AMOUNT_DEPOSIT = 1 ether;

    function setUp() external {
        deployer = new DeployReentrancyEther();
        reentrancyEther = deployer.run();

        deal(owner, AMOUNT_OF_OWNER);
        deal(user, AMOUNT_OF_OWNER);
        deal(attacker, AMOUNT_OF_ATTACKER);

        vm.prank(owner);
        reentrancyEther.deposit{value: AMOUNT_OF_OWNER}();
    }

    modifier userDeposited() {
        vm.prank(user);
        reentrancyEther.deposit{value: AMOUNT_DEPOSIT}();
        _;
    }

    function test_canDeposit() public {
        vm.prank(user);
        reentrancyEther.deposit{value: AMOUNT_DEPOSIT}();

        uint balanceOfUserAfterDeposit = reentrancyEther.getBalanceOf(user);
        uint balanceOfContractAfterDeposit = address(reentrancyEther).balance;
        console.log(
            "Balance Of Contract After Deposit",
            balanceOfContractAfterDeposit
        );

        assertEq(AMOUNT_OF_USER - AMOUNT_DEPOSIT, balanceOfUserAfterDeposit);
        assertEq(
            AMOUNT_OF_OWNER + AMOUNT_DEPOSIT,
            balanceOfContractAfterDeposit
        );
    }

    function test_canWithdraw() public userDeposited {
        uint balanceOfContractBeforeWithdraw = address(reentrancyEther).balance;

        vm.prank(user);
        reentrancyEther.withdraw();

        uint balanceOfUserAfterWithdraw = reentrancyEther.getBalanceOf(user);
        uint balanceOfContractAfterWithdraw = address(reentrancyEther).balance;

        assertEq(0, balanceOfUserAfterWithdraw);
        assertEq(
            balanceOfContractBeforeWithdraw - AMOUNT_DEPOSIT,
            balanceOfContractAfterWithdraw
        );
    }

    function test_revertWithdrawIfUserInsufficientBalance() public {
        vm.prank(user);
        vm.expectRevert(
            ReentrancyEther.ReentrancyEther_InsufficientBalance.selector
        );
        reentrancyEther.withdraw();
    }

    function test_canReentrancyAttack() public userDeposited {
        vm.startBroadcast();
        AttackReentrancyEther attackContract = new AttackReentrancyEther(
            address(reentrancyEther)
        );
        vm.stopBroadcast();

        vm.prank(attacker);
        attackContract.deposit{value: AMOUNT_OF_ATTACKER}();

        uint amountOfAttackContractBeforeAttack = address(attackContract)
            .balance;
        console.log(
            "Amount Of Attack Contract Before Attack",
            amountOfAttackContractBeforeAttack
        );

        uint amountOfTargetContractBeforeAttack = address(reentrancyEther)
            .balance;

        console.log(
            "Amount Of Target Contract Before Attack",
            amountOfTargetContractBeforeAttack
        );

        attackContract.attack(AMOUNT_OF_ATTACKER);

        uint amountOfAttackContractAfterAttack = address(attackContract)
            .balance;
        console.log(
            "Amount Of Attack Contract After Attack",
            amountOfAttackContractAfterAttack
        );

        uint amountOfTargetContractAfterAttack = address(reentrancyEther)
            .balance;

        console.log(
            "Amount Of Target Contract After Attack",
            amountOfTargetContractAfterAttack
        );
    }
}
