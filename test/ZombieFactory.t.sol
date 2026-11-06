// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, stdError} from "forge-std/Test.sol";
import {ZombieFactory} from "../src/ZombieFactory.sol";

contract ZombieFactoryTest is Test {
    event ZombieCreated(uint256 indexed id, address indexed owner, string name, uint256 dna);

    ZombieFactory factory;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        factory = new ZombieFactory();
    }

    function expectedDna(address owner, string memory name) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(owner, name))) % factory.DNA_MODULUS();
    }

    function testCreateZombie() public {
        vm.warp(1_700_000_000);
        vm.prank(alice);
        uint256 id = factory.createZombie("Alice");

        assertEq(id, 0);
        assertEq(factory.zombieToOwner(id), alice);
        assertEq(factory.ownerZombieCount(alice), 1);
        assertEq(factory.totalZombies(), 1);

        (string memory name, uint256 dna, uint256 createdAt) = factory.getZombie(id);
        assertEq(name, "Alice");
        assertEq(dna, expectedDna(alice, "Alice"));
        assertEq(createdAt, 1_700_000_000);
    }

    function testTwoOwnersGetDifferentIds() public {
        vm.prank(alice);
        uint256 aliceId = factory.createZombie("Alice");
        vm.prank(bob);
        uint256 bobId = factory.createZombie("Bob");

        assertEq(aliceId, 0);
        assertEq(bobId, 1);
        assertEq(factory.zombieToOwner(aliceId), alice);
        assertEq(factory.zombieToOwner(bobId), bob);
        assertEq(factory.totalZombies(), 2);
    }

    function testEmptyNameReverts() public {
        vm.prank(alice);
        vm.expectRevert("Empty name");
        factory.createZombie("");
        assertEq(factory.totalZombies(), 0);
    }

    function testSecondZombieSameOwnerReverts() public {
        vm.startPrank(alice);
        factory.createZombie("First");
        vm.expectRevert("Already has zombie");
        factory.createZombie("Second");
        vm.stopPrank();

        assertEq(factory.ownerZombieCount(alice), 1);
        assertEq(factory.totalZombies(), 1);
    }

    function testDnaWithinModulus() public {
        vm.prank(alice);
        uint256 id = factory.createZombie("Alice");
        (, uint256 dna,) = factory.getZombie(id);
        assertLt(dna, factory.DNA_MODULUS());
    }

    function testEventEmitted() public {
        uint256 dna = expectedDna(alice, "Alice");
        vm.expectEmit(true, true, false, true, address(factory));
        emit ZombieCreated(0, alice, "Alice", dna);
        vm.prank(alice);
        factory.createZombie("Alice");
    }

    function testGetZombieUnknownIdReverts() public {
        vm.expectRevert(stdError.indexOOBError);
        factory.getZombie(0);
    }

    function testDnaDependsOnSender() public {
        vm.prank(alice);
        factory.createZombie("Same");
        vm.prank(bob);
        factory.createZombie("Same");

        (, uint256 dnaA,) = factory.getZombie(0);
        (, uint256 dnaB,) = factory.getZombie(1);
        assertTrue(dnaA != dnaB);
    }

    function testFuzzDnaWithinModulus(address owner, string calldata name) public {
        vm.assume(bytes(name).length > 0);
        vm.prank(owner);
        uint256 id = factory.createZombie(name);
        (, uint256 dna,) = factory.getZombie(id);
        assertLt(dna, factory.DNA_MODULUS());
    }
}
