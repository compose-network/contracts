// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.30;

interface IComposeBridge {
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
    event CETBurned(address indexed sender, uint256 amount);
    event TokensReceived(address indexed token, uint256 amount);
    event MailboxWrite(uint256 indexed chainId, address indexed account, uint256 indexed sessionId, string label);
    event MailboxAckWrite(uint256 indexed chainId, address indexed account, uint256 indexed sessionId, string label);
    event TokensBridged(
        uint256 indexed chainDest,
        address indexed sender,
        address indexed receiver,
        address tokenSrc,
        uint256 amount,
        uint256 sessionId,
        bytes32 messageId
    );
    event ETHBridged(
        uint256 chainID,
        address sender,
        address to,
        uint256 value,
        uint256 sessionId,
        bytes label
    );
    event ETHLocked(address indexed sender, uint256 indexed value);
    event ETHReceived(address indexed receiver, uint256 indexed value);
    event WrappedCETRedeemed(address wrappedCET, address coreCET, address receiver, uint256 amount);

    error Unauthorized();
    error WrongDestinationChain();
    error InvalidMessage();
    error NoSendMessage();
    error CETAddressMismatch();
    error TransferFailed();
    error NoAckMessage();
    error InvalidCetAddress();
    error NotReceiver();
    error InvalidAckPayload();
    error AckSourceTokenMismatch();
    error AckAmountMismatch();
    error ZeroEthSent();
    error EthReceiveFailed(bytes data);
    error ZeroAddress();
    error InvalidAssetAddress();
}