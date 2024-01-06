// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {ReentrancyEther, Attack} from "src/ReentrancyEther.sol";
import {DeployReentrancyEther} from "script/DeployReentrancyEther.s.sol";

contract ReentrancyEtherTest is Test {
    ReentrancyEther reentrancyEther;
    DeployReentrancyEther deployer;

    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    uint256 constant AMOUNT_OF_OWNER = 10 ether;
    uint256 constant AMOUNT_OF_USER = 2 ether;
    uint256 constant AMOUNT_OF_ATTACKER = 1 ether;
    uint256 constant AMOUNT_TO_DEPOSIT = 1 ether;

    function setUp() external {
        deployer = new DeployReentrancyEther();
        reentrancyEther = deployer.run();

        deal(owner, AMOUNT_OF_OWNER);
        deal(user, AMOUNT_OF_USER);
        deal(attacker, AMOUNT_OF_ATTACKER);

        vm.prank(owner);
        reentrancyEther.deposit{value: AMOUNT_OF_OWNER}();
    }

    modifier userDeposited() {
        vm.prank(user);
        reentrancyEther.deposit{value: AMOUNT_TO_DEPOSIT}();
        _;
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

    function test_canWithdraw() public userDeposited {
        uint balanceOfContractBeforeWithdraw = address(reentrancyEther).balance;

        vm.prank(user);
        reentrancyEther.withdraw();

        uint balanceOfUserAfterWithdraw = reentrancyEther.getBalance(user);
        uint balanceOfContractAfterWithdraw = address(reentrancyEther).balance;

        assertEq(balanceOfUserAfterWithdraw, 0);
        assertEq(
            balanceOfContractBeforeWithdraw - AMOUNT_TO_DEPOSIT,
            balanceOfContractAfterWithdraw
        );
    }

    function test_revertWithdrawIfInsufficientBalance() public {
        vm.prank(user);
        vm.expectRevert(
            ReentrancyEther.ReentrancyEther_InsufficientBalance.selector
        );
        reentrancyEther.withdraw();
    }

    function test_canAttack() public userDeposited {
        vm.startBroadcast();
        Attack attackContract = new Attack(address(reentrancyEther));
        vm.stopBroadcast();

        vm.prank(attacker);
        attackContract.deposit{value: AMOUNT_OF_ATTACKER}();

        uint amoutOfAttackContractBeforeAttack = address(attackContract)
            .balance;
        console.log(
            "Amount Of Attack Contract Before Attack",
            amoutOfAttackContractBeforeAttack
        );

        attackContract.attack(AMOUNT_OF_ATTACKER);

        uint amoutOfAttackContractAfterAttack = address(attackContract).balance;
        console.log(
            "Amount Of Attack Contract Before Attack",
            amoutOfAttackContractAfterAttack
        );
    }
}
