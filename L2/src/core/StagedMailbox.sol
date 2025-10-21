// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

import { IStagedMailbox } from "./interfaces/IStagedMailbox.sol";

contract StagedMailbox is IStagedMailbox {
    address public immutable COORDINATOR;

    mapping(bytes32 => bytes) public inbox;
    mapping(bytes32 => bytes) public outbox;
    mapping(bytes32 => bool) public createdKeys;
    mapping(bytes32 => bool) public usedKeys;

    mapping(uint256 => bytes32) public inboxRootPerChain;
    mapping(uint256 => bytes32) public outboxRootPerChain;

    uint256[] public chainIDsInbox;
    uint256[] public chainIDsOutbox;

    modifier onlyCoordinator() {
        if (msg.sender != COORDINATOR) {
            revert OnlyCoordinatorAllowed();
        }
        _;
    }

    constructor(address _coordinator) {
        if (_coordinator == address(0)) {
            revert ZeroAddress();
        }
        COORDINATOR = _coordinator;
    }

    function getKey(
        uint256 srcChainID,
        uint256 destChainID,
        address sender,
        address receiver,
        uint256 sessionId,
        bytes calldata label
    ) public pure returns (bytes32 key) {
        key = keccak256(
            abi.encodePacked(srcChainID, destChainID, sender, receiver, sessionId, label)
        );
    }

    function putInbox(
        uint256 srcChainID,
        address sender,
        address receiver,
        uint256 sessionId,
        bytes calldata label,
        bytes calldata data
    ) public onlyCoordinator {
        bytes32 key = getKey(srcChainID, block.chainid, sender, receiver, sessionId, label);
        if (createdKeys[key]) {
            revert KeyAlreadyExists(key);
        }

        createdKeys[key] = true;
        inbox[key] = data;

        emit InboxMessageAdded(key);
    }

    function putOutbox(
        uint256 destChainID,
        address sender,
        address receiver,
        uint256 sessionId,
        bytes calldata label,
        bytes calldata data
    ) public onlyCoordinator {
        bytes32 key = getKey(block.chainid, destChainID, sender, receiver, sessionId, label);
        if (createdKeys[key]) {
            revert KeyAlreadyExists(key);
        }

        createdKeys[key] = true;
        outbox[key] = data;

        emit OutboxMessageAdded(key);
    }

    function read(
        uint256 srcChainID,
        address sender,
        uint256 sessionId,
        bytes calldata label
    ) external returns (bytes memory) {
        bytes32 key = getKey(srcChainID, block.chainid, sender, msg.sender, sessionId, label);
        if (!createdKeys[key]) {
            revert MessageNotFound(key);
        }
        if (usedKeys[key]) {
            revert MessageAlreadyUsed(key);
        }

        usedKeys[key] = true;

        bytes memory data = inbox[key];
        delete inbox[key];

        if (inboxRootPerChain[srcChainID] == bytes32(0)) {
            chainIDsInbox.push(srcChainID);
        }
        inboxRootPerChain[srcChainID] =
                        keccak256(abi.encode(inboxRootPerChain[srcChainID], key, data));

        emit MessageRead(key);
        return data;
    }

    function write(
        uint256 destChainID,
        address receiver,
        uint256 sessionId,
        bytes calldata label,
        bytes calldata data
    ) external {
        bytes32 key = getKey(block.chainid, destChainID, msg.sender, receiver, sessionId, label);
        if (!createdKeys[key]) {
            revert MessageNotFound(key);
        }
        if (usedKeys[key]) {
            revert MessageAlreadyUsed(key);
        }

        bytes memory stored = outbox[key];

        if (keccak256(stored) != keccak256(data)) {
            revert MessageDataMismatch(key);
        }

        usedKeys[key] = true;
        delete outbox[key];

        if (outboxRootPerChain[destChainID] == bytes32(0)) {
            chainIDsOutbox.push(destChainID);
        }
        outboxRootPerChain[destChainID] =
                        keccak256(abi.encode(outboxRootPerChain[destChainID], key, stored));

        emit MessageWritten(key);
    }

    function safeExecute(
        StagedInboxMsg[] calldata stagedInboxMsgs,
        StagedOutboxMsg[] calldata stagedOutboxMsgs,
        address target,
        bytes calldata mainTxData
    ) external onlyCoordinator {
        uint256 inLen = stagedInboxMsgs.length;
        uint256 outLen = stagedOutboxMsgs.length;

        for (uint256 i = 0; i < inLen; i++) {
            StagedInboxMsg calldata m = stagedInboxMsgs[i];
            putInbox(m.srcChainID, m.sender, m.receiver, m.sessionId, m.label, m.data);
        }

        for (uint256 i = 0; i < outLen; i++) {
            StagedOutboxMsg calldata m = stagedOutboxMsgs[i];
            putOutbox(m.destChainID, m.sender, m.receiver, m.sessionId, m.label, m.data);
        }

        (bool success, bytes memory data) = target.call(mainTxData);
        if (!success) {
            revert MainCallFailed(data);
        }
    }
}