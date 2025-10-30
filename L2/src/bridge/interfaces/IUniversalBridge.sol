// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

interface IUniversalBridge {
    event TokensSendQueued(
        uint256 indexed chainDest,
        address indexed sender,
        address indexed receiver,
        address remoteAsset,
        uint256 amount,
        uint256 sessionId,
        bytes32 messageId
    );
    event TokensLocked(address indexed token, address indexed sender, uint256 amount);
    event CETBurned(address indexed token, address indexed sender, uint256 amount);
    event TokensReceived(address indexed token, uint256 amount);
    event MailboxWrite(uint256 indexed chainId, address indexed account, uint256 indexed sessionId, string label);
    event MailboxAckWrite(uint256 indexed chainId, address indexed account, uint256 indexed sessionId, string label);

    error Unauthorized();
    error WrongDestinationChain();
    error InvalidMessage();
    error NoSendMessage();
    error CETAddressMismatch();
    error TransferFailed();
    error NoAckMessage();
    error InvalidCetAddress();
    error NotReceiver();
}