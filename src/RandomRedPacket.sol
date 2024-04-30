// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "solmate/utils/SafeTransferLib.sol";

contract RandomRedPacket is ReentrancyGuard {
    struct RedPacket {
        address owner;
        bytes32 merkleRoot;
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 startTime;
        uint256 endTime;
        bool isEnd;
    }

    uint256 public redPacketCount;
    mapping(uint256 => RedPacket) public redPackets;
    mapping(uint256 => mapping(address => bool)) public claimed;

    event RedPacketCreated(
        uint256 indexed redPacketId,
        address indexed owner,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    );
    event RedPacketClaimed(
        uint256 indexed redPacketId,
        address indexed claimer,
        uint256 amount,
        uint claimTime
    );
    event RedPacketRefunded(
        uint256 indexed redPacketId,
        uint256 refundedAmount,
        uint256 refundedTime
    );
    event RedPacketEnded(uint indexed redPacketId, uint endedTime);

    function createRedPacket(
        bytes32 _merkleRoot,
        uint256 _totalAmount,
        uint256 _startTime,
        uint256 _duration
    ) public payable nonReentrant {
        require(msg.value == _totalAmount, "msgvalue error");
        require(_startTime >= block.timestamp, "startTime error");
        require(_duration > 0, "duration error");

        redPacketCount++;
        redPackets[redPacketCount] = RedPacket({
            owner: msg.sender,
            merkleRoot: _merkleRoot,
            totalAmount: _totalAmount,
            amountClaimed: 0,
            startTime: _startTime,
            endTime: _startTime + _duration,
            isEnd: false
        });

        emit RedPacketCreated(
            redPacketCount,
            msg.sender,
            _totalAmount,
            _startTime,
            _startTime + _duration
        );
    }

    function claimRedPacket(
        uint256 redPacketId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public nonReentrant {
        // check
        RedPacket storage packet = redPackets[redPacketId];
        require(!packet.isEnd, "ended");
        require(
            block.timestamp >= packet.startTime &&
                block.timestamp <= packet.endTime,
            "time error"
        );
        require(!claimed[redPacketId][msg.sender], "claimed");

        // verify
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, packet.merkleRoot, leaf),
            "merkle proof error"
        );

        // change state
        uint256 newAmountClaimed = packet.amountClaimed + amount;
        require(newAmountClaimed <= packet.totalAmount, "amountClaimed error");

        claimed[redPacketId][msg.sender] = true;
        packet.amountClaimed = newAmountClaimed;
        SafeTransferLib.safeTransferETH(msg.sender, amount);
        emit RedPacketClaimed(redPacketId, msg.sender, amount, block.timestamp);

        if (newAmountClaimed == packet.totalAmount) {
            packet.isEnd = true;
            emit RedPacketEnded(redPacketId, block.timestamp);
        }
    }

    function refundRedPacket(uint256 redPacketId) public nonReentrant {
        RedPacket storage packet = redPackets[redPacketId];
        uint256 remainingAmount = packet.totalAmount - packet.amountClaimed;
        require(remainingAmount > 0, "no fund");
        require(msg.sender == packet.owner, "owner error");
        require(block.timestamp > packet.endTime, "endTime error");
        require(!packet.isEnd, "ended");

        packet.isEnd = true;
        SafeTransferLib.safeTransferETH(msg.sender, remainingAmount);

        emit RedPacketEnded(redPacketId, block.timestamp);
        emit RedPacketRefunded(redPacketId, remainingAmount, block.timestamp);
    }

    receive() external payable {}
}
