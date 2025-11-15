// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.30;

import { IComposeMailbox } from "@ssv/src/bridge/interfaces/IComposeMailbox.sol";

/**
 * @title Mailbox
 * @notice The Mailbox Contract to manage chain interaction via CIRC/Espresso.
 * @dev It stores messages in inboxes and outboxes using unique keys. Roots are updated for each chain to track changes. Only the coordinator can add to the inbox for security.
 *
 * @author
 * SSV Labs
 */
contract ComposeMailbox is IComposeMailbox {

    /// @notice List of chain IDs that have messages in the inbox.
    uint256[] public chainIDsInbox;

    /// @notice List of chain IDs that have messages in the outbox.
    uint256[] public chainIDsOutbox;

    /// @notice Mapping from chain ID to the root hash of its inbox.
    /// @dev The root is updated each time a new message is added to the inbox for that chain.
    mapping(uint256 chainId => bytes32 inboxRoot) public inboxRootPerChain;

    /// @notice Mapping from chain ID to the root hash of its outbox.
    /// @dev The root is updated each time a new message is added to the outbox for that chain.
    mapping(uint256 chainId => bytes32 outboxRoot) public outboxRootPerChain;

    /// @notice Mapping from message key to the message data in the inbox.
    mapping(bytes32 key => bytes message) public inbox;

    /// @notice Mapping from message key to the message data in the outbox.
    mapping(bytes32 key => bytes message) public outbox;

    /// @notice Mapping to track if a key has been used (read by a bridge)
    mapping(bytes32 key => bool) public consumed;

    /// @notice Mapping to track if a key has been created (used in inbox or outbox).
    mapping(bytes32 key => bool used) public createdKeys;

    /// @notice List of headers for messages in the inbox.
    MessageHeader[] public messageHeaderListInbox;

    /// @notice List of headers for messages in the outbox.
    MessageHeader[] public messageHeaderListOutbox;

    /// @notice The address of the coordinator that can add messages to the inbox.
    address public coordinator;

    /// @notice The address of the bridge that can write to the outbox
    address public bridge;

    /// @notice Modifier to restrict access to only the coordinator.
    /// @dev Reverts if the caller is not the coordinator.
    modifier onlyCoordinator() {
        if (msg.sender != coordinator) revert InvalidCoordinator();
        _;
    }

    /// @notice Modifier to restrict access to only the bridge.
    /// @dev Reverts if the caller is not the bridge.
    modifier onlyBridge() {
        if (msg.sender != bridge) revert InvalidBridge();
        _;
    }

    /// @notice Sets up the mailbox with the coordinator's address.
    /// @dev The coordinator is the only one who can add incoming messages.
    /// @param _coordinator The address of the trusted coordinator.
    constructor(address _coordinator) {
        coordinator = _coordinator;
    }

    function getKey(MessageHeader memory header) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                header.sessionId,
                header.chainSrc,
                header.chainDest,
                header.sender,
                header.receiver,
                header.label
            )
        );
    }

    function write(Message calldata message) external onlyBridge {
        bytes32 key = getKey(message.header);

        if (createdKeys[key]) {
            revert MessageAlreadyExists();
        }

        outbox[key] = message.payload;
        createdKeys[key] = true;

        messageHeaderListOutbox.push(message.header);

        if (outboxRootPerChain[message.header.chainDest] == bytes32(0)) {
            chainIDsOutbox.push(message.header.chainDest);
        }
        outboxRootPerChain[message.header.chainDest] = keccak256(
            abi.encode(outboxRootPerChain[message.header.chainDest], key, message.payload)
        );

        emit OutboxMessageWritten(key, message.header.chainDest, message.header.receiver, message.header.label);
    }

    function putInbox(Message calldata message) external onlyCoordinator {
        bytes32 key = getKey(message.header);

        if (createdKeys[key]) {
            revert MessageAlreadyExists();
        }

        inbox[key] = message.payload;
        createdKeys[key] = true;

        messageHeaderListInbox.push(message.header);

        emit InboxMessageDelivered(key, message.header.chainSrc, message.header.sender, message.header.label);
    }

    function read(MessageHeader calldata header) external onlyBridge returns (bytes memory message) {
        bytes32 key = getKey(header);

        if (consumed[key]) {
            revert MessageAlreadyConsumed();
        }
        if (inbox[key].length == 0 && !createdKeys[key]) {
            revert MessageNotFound();
        }

        message = inbox[key];
        consumed[key] = true;

        if (inboxRootPerChain[header.chainSrc] == bytes32(0)) {
            chainIDsInbox.push(header.chainSrc);
        }
        inboxRootPerChain[header.chainSrc] = keccak256(
            abi.encode(inboxRootPerChain[header.chainSrc], key, message)
        );

        emit InboxMessageConsumed(key, header.receiver);
    }

    // todo just for dev, remove in prod
    function setBridge(address _bridge) external onlyCoordinator {
        bridge = _bridge;
    }

    function setCoordinator(address _coordinator) external onlyCoordinator {
        coordinator = _coordinator;
    }
}