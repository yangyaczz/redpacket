// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/RandomRedPacket.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RandomRedPacketTest is Test {
    RandomRedPacket redPacket;
    address owner;

    function setUp() public {
        owner = 0x21C8e614CD5c37765411066D2ec09912020c846F;
        redPacket = new RandomRedPacket();
        vm.deal(owner, 10 ether);
    }

    function testClaimRedPacket() public {
        address user1 = 0x6A6AF8c1157b179e5cdeB0dF54e96200516Fe195;
        uint amount1 = 1 ether;
        bytes32 leaf1 = keccak256(abi.encodePacked(user1, amount1));

        address user2 = 0x48402530d59B99966f6e277854856f166cb92018;
        uint amount2 = 3 ether;
        bytes32 leaf2 = keccak256(abi.encodePacked(user2, amount2));

        address user3 = 0x75915368b2e48Ad464c7b22afAFeF517dEcF29B2;
        uint amount3 = 2 ether;
        bytes32 leaf3 = keccak256(abi.encodePacked(user3, amount3));

        bytes32[] memory merkleProof = new bytes32[](2);
        merkleProof[0] = leaf2;
        merkleProof[1] = leaf3;

        bytes32 merkleRoot = MerkleProof.processProof(merkleProof, leaf1);

        {
            uint256 startTime = block.timestamp;
            uint256 duration = 3 days;
            uint256 totalAmount = 6 ether;

            redPacket.createRedPacket{value: totalAmount}(
                merkleRoot,
                totalAmount,
                startTime,
                duration
            );
        }

        vm.startPrank(user1);
        bytes32[] memory merkleProof1 = new bytes32[](2);
        merkleProof1[0] = leaf2;
        merkleProof1[1] = leaf3;
        redPacket.claimRedPacket(1, amount1, merkleProof1);

        vm.startPrank(user2);
        bytes32[] memory merkleProof2 = new bytes32[](2);
        merkleProof2[0] = leaf1;
        merkleProof2[1] = leaf3;
        redPacket.claimRedPacket(1, amount2, merkleProof2);

        vm.startPrank(user3);
        bytes32[] memory merkleProof3 = new bytes32[](1);
        merkleProof3[0] = keccak256(abi.encodePacked(leaf1, leaf2));
        redPacket.claimRedPacket(1, amount3, merkleProof3);
    }

    function testRefund() public {
        vm.startPrank(owner);
        redPacket.createRedPacket{value: 3 ether}(
            bytes32("111"),
            3 ether,
            block.timestamp,
            1 days
        );
        vm.warp(block.timestamp + 3 days);
        redPacket.refundRedPacket(1);
    }
}
