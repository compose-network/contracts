// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.30;

interface IComposeMailbox {
    error InvalidCoordinator();
    error InvalidBridge();
    error MessageNotFound();
    error MessageAlreadyConsumed();
    error InvalidId();
    error MessageAlreadyExists();

    event OutboxMessageWritten(bytes32 key, uint256 destChain, address receiver, string label);
    event InboxMessageDelivered(bytes32 key, uint256 sourceChain, address sender, string label);
    event InboxMessageConsumed(bytes32 key, address receiver);

    struct MessageHeader {
        uint256 sessionId;
        uint256 chainSrc;
        uint256 chainDest;
        address sender;
        address receiver;
        string label;
    }

    struct Message {
        MessageHeader header;
        bytes payload;
    }

    function write(
        Message calldata message
    ) external;

    function read(
        MessageHeader calldata header
    ) external returns (bytes memory);

    function putInbox(
        Message calldata message
    ) external;
}