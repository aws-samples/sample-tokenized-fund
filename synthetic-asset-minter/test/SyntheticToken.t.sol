// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SyntheticToken.sol";

contract SyntheticTokenTest is Test {
    SyntheticToken public token;
    
    address public owner = address(1);
    address public minter = address(2);
    address public user = address(3);
    address public nonOwner = address(4);
    
    event MinterUpdated(address indexed oldMinter, address indexed newMinter);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        vm.prank(owner);
        token = new SyntheticToken("Synthetic S&P 500", "sSPY", owner);
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsNameAndSymbol() public view {
        assertEq(token.name(), "Synthetic S&P 500");
        assertEq(token.symbol(), "sSPY");
    }

    function test_Constructor_SetsOwner() public view {
        assertEq(token.owner(), owner);
    }

    function test_Constructor_MinterIsZeroInitially() public view {
        assertEq(token.minter(), address(0));
    }

    // ============ setMinter Tests ============

    function test_SetMinter_OwnerCanSetMinter() public {
        vm.prank(owner);
        token.setMinter(minter);
        assertEq(token.minter(), minter);
    }

    function test_SetMinter_EmitsMinterUpdatedEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit MinterUpdated(address(0), minter);
        token.setMinter(minter);
    }

    function test_SetMinter_CanUpdateMinter() public {
        vm.startPrank(owner);
        token.setMinter(minter);
        
        address newMinter = address(5);
        vm.expectEmit(true, true, false, false);
        emit MinterUpdated(minter, newMinter);
        token.setMinter(newMinter);
        
        assertEq(token.minter(), newMinter);
        vm.stopPrank();
    }

    function test_SetMinter_RevertsForNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        token.setMinter(minter);
    }

    // ============ mint Tests ============

    function test_Mint_MinterCanMint() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        assertEq(token.balanceOf(user), 1000 ether);
        assertEq(token.totalSupply(), 1000 ether);
    }

    function test_Mint_EmitsTransferEvent() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user, 1000 ether);
        token.mint(user, 1000 ether);
    }

    function test_Mint_RevertsForNonMinter() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(user);
        vm.expectRevert("Only minter");
        token.mint(user, 1000 ether);
    }

    function test_Mint_RevertsWhenMinterNotSet() public {
        vm.prank(user);
        vm.expectRevert("Only minter");
        token.mint(user, 1000 ether);
    }

    function test_Mint_OwnerCannotMintUnlessMinter() public {
        vm.prank(owner);
        vm.expectRevert("Only minter");
        token.mint(user, 1000 ether);
    }

    // ============ burn Tests ============

    function test_Burn_MinterCanBurn() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        vm.prank(minter);
        token.burn(user, 400 ether);

        assertEq(token.balanceOf(user), 600 ether);
        assertEq(token.totalSupply(), 600 ether);
    }

    function test_Burn_EmitsTransferEvent() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        vm.prank(minter);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user, address(0), 400 ether);
        token.burn(user, 400 ether);
    }

    function test_Burn_RevertsForNonMinter() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        vm.prank(user);
        vm.expectRevert("Only minter");
        token.burn(user, 400 ether);
    }

    function test_Burn_RevertsWhenBurningMoreThanBalance() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        vm.prank(minter);
        vm.expectRevert(abi.encodeWithSignature("ERC20InsufficientBalance(address,uint256,uint256)", user, 1000 ether, 2000 ether));
        token.burn(user, 2000 ether);
    }

    // ============ Standard ERC20 Tests ============

    function test_Transfer_UserCanTransfer() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        vm.prank(user);
        token.transfer(nonOwner, 300 ether);

        assertEq(token.balanceOf(user), 700 ether);
        assertEq(token.balanceOf(nonOwner), 300 ether);
    }

    function test_Approve_UserCanApprove() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        vm.prank(user);
        token.approve(nonOwner, 500 ether);

        assertEq(token.allowance(user, nonOwner), 500 ether);
    }

    function test_TransferFrom_SpenderCanTransferWithAllowance() public {
        vm.prank(owner);
        token.setMinter(minter);

        vm.prank(minter);
        token.mint(user, 1000 ether);

        vm.prank(user);
        token.approve(nonOwner, 500 ether);

        vm.prank(nonOwner);
        token.transferFrom(user, nonOwner, 300 ether);

        assertEq(token.balanceOf(user), 700 ether);
        assertEq(token.balanceOf(nonOwner), 300 ether);
        assertEq(token.allowance(user, nonOwner), 200 ether);
    }

    function test_Decimals_Returns18() public view {
        assertEq(token.decimals(), 18);
    }
}
