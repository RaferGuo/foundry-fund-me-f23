//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DelpoyFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        //assertEq(fundMe.i_owner(), address(this));//funder是owner了，所以这要报错
        assertEq(fundMe.i_owner(), msg.sender);//
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWiithoutEnoughETH() public {
        vm.expectRevert();//hey, the next line,should revert
        //assert(this tx fails/reverts)
        fundMe.fund();//send 0 value,fail so revert
    }
    
    //fund function test
    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);//the next TX will be sent by user;
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }
    
    //test funder.push
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);//the next TX will be sent by user;
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function OnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();//ignore vm line, check next's next
        vm.prank(USER);//USER is not owner;
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
       //arrange
       uint256 startingOwnerBalance = fundMe.getOwner().balance;
       uint256 startingFundMeBalance = address(fundMe).balance;//total banlance;
       
       //ACT
       vm.prank(fundMe.getOwner());//only owner can withdraw; cost:200
       fundMe.withdraw();//only work with fundMe contract itself

       //assert
       uint256 endingOwnerBalance = fundMe.getOwner().balance;
       uint256 endingFundMeBalance = address(fundMe).balance;
       assertEq(endingFundMeBalance, 0);
       //withdraw all the money out of fund to owner;
       assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithDrawWithMultipleFunder() public funded {//funded once;
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;//0/1 sometimes reverts and never let you stuff with
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deak new address
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundME
        }

       uint256 startingOwnerBalance = fundMe.getOwner().balance;
       uint256 startingFundMeBalance = address(fundMe).balance;
        //ACT
       vm.startPrank(fundMe.getOwner());//only owner can withdraw;
       fundMe.withdraw();//only work with fundMe contract itself,fundMe => owner
       vm.stopPrank();

       //assert
       assert(address(fundMe).balance == 0);//we should move all the funds out of the fundMe
       assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}