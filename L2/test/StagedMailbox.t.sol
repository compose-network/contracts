// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {IStagedMailbox} from "@ssv/src/core/interfaces/IStagedMailbox.sol";
import {StagedMailbox} from "@ssv/src/core/StagedMailbox.sol";
import {Setup} from "@ssv/test/Setup.t.sol";

contract StagedMailboxTest is Setup {
    uint256 internal thisChain = block.chainid;
    uint256 internal otherChain = 2;

    address internal messageSender = address(0xabc);
    address internal messageReceiver = address(0x123);

    /// @dev Tests constructor sets coordinator correctly and reverts for zero address
    function testConstructor() public {
        assertEq(
            stagedMailbox.COORDINATOR(),
            COORDINATOR,
            "Coordinator should be set"
        );

        vm.expectRevert(IStagedMailbox.OnlyCoordinatorAllowed.selector);
        new StagedMailbox(address(0));
    }

    /// @dev Tests that non-coordinator cannot write to inbox
    function testShouldRevertNonCoordinatorToWriteToInbox() public {
        vm.prank(messageSender);
        vm.expectRevert(IStagedMailbox.OnlyCoordinatorAllowed.selector);
        stagedMailbox.putInbox(otherChain, messageSender, messageReceiver, 1, "SWAP", "hello");
    }

    /// @dev Tests that non-coordinator cannot write to outbox
    function testShouldRevertNonCoordinatorToWriteToOutbox() public {
        vm.prank(messageSender);
        vm.expectRevert(IStagedMailbox.OnlyCoordinatorAllowed.selector);
        stagedMailbox.putOutbox(otherChain, messageSender, messageReceiver, 1, "SWAP", "hello");
    }

    /// @dev Tests writing a single message to inbox by coordinator
    function testWriteInboxSingle() public returns (bytes32 key) {
        vm.startPrank(COORDINATOR);

        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.InboxMessageAdded(
            stagedMailbox.getKey(otherChain, thisChain, messageSender, messageReceiver, 1, "SWAP")
        );

        stagedMailbox.putInbox(otherChain, messageSender, messageReceiver, 1, "SWAP", "salut");
        vm.stopPrank();

        key = stagedMailbox.getKey(otherChain, thisChain, messageSender, messageReceiver, 1, "SWAP");
        assertEq(stagedMailbox.inbox(key), "salut", "The message should match");
        assertTrue(stagedMailbox.createdKeys(key), "Key should be created");
        assertFalse(stagedMailbox.usedKeys(key), "Key should not be used yet");
    }

    /// @dev Tests writing a single message to outbox by coordinator
    function testWriteOutboxSingle() public returns (bytes32 key) {
        vm.startPrank(COORDINATOR);

        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.OutboxMessageAdded(
            stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 1, "SWAP")
        );

        stagedMailbox.putOutbox(otherChain, messageSender, messageReceiver, 1, "SWAP", "hello");
        vm.stopPrank();

        key = stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 1, "SWAP");
        assertEq(stagedMailbox.outbox(key), "hello", "The message should match");
        assertTrue(stagedMailbox.createdKeys(key), "Key should be created");
        assertFalse(stagedMailbox.usedKeys(key), "Key should not be used yet");
    }

    /// @dev Tests writing multiple messages to inbox
    function testWriteInboxMultiple() public {
        bytes32 key1 = testWriteInboxSingle();

        vm.startPrank(COORDINATOR);

        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.InboxMessageAdded(
            stagedMailbox.getKey(otherChain, thisChain, messageSender, messageReceiver, 2, "SWAP")
        );

        stagedMailbox.putInbox(otherChain, messageSender, messageReceiver, 2, "SWAP", "salut2");
        vm.stopPrank();

        bytes32 key2 = stagedMailbox.getKey(
            otherChain,
            thisChain,
            messageSender,
            messageReceiver,
            2,
            "SWAP"
        );
        assertEq(stagedMailbox.inbox(key1), "salut", "First message should remain");
        assertEq(stagedMailbox.inbox(key2), "salut2", "Second message should match");
    }

    /// @dev Tests writing multiple messages to outbox
    function testWriteOutboxMultiple() public {
        bytes32 key1 = testWriteOutboxSingle();

        vm.startPrank(COORDINATOR);

        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.OutboxMessageAdded(
            stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 2, "SWAP")
        );

        stagedMailbox.putOutbox(otherChain, messageSender, messageReceiver, 2, "SWAP", "hello2");
        vm.stopPrank();

        bytes32 key2 = stagedMailbox.getKey(
            thisChain,
            otherChain,
            messageSender,
            messageReceiver,
            2,
            "SWAP"
        );
        assertEq(stagedMailbox.outbox(key1), "hello", "First message should remain");
        assertEq(stagedMailbox.outbox(key2), "hello2", "Second message should match");
    }

    /// @dev Tests reading a message from inbox
    function testRead() public {
        testWriteInboxSingle();
        bytes32 key = stagedMailbox.getKey(otherChain, thisChain, messageSender, messageReceiver, 1, "SWAP");
        vm.prank(messageReceiver);
        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.MessageRead(key);

        bytes memory data = stagedMailbox.read(
            otherChain,
            messageSender,
            1,
            "SWAP"
        );
        assertEq(data, "salut", "Should match the read message");
        assertTrue(stagedMailbox.usedKeys(key), "Key should be marked as used");
        assertEq(stagedMailbox.inbox(key), "", "Inbox message should be deleted");
        bytes32 expectedRoot = keccak256(abi.encode(bytes32(0), key, "salut"));
        assertEq(stagedMailbox.inboxRootPerChain(otherChain), expectedRoot, "Inbox root should match");
    }

    /// @dev Tests reading an empty but created message returns empty data
    function testReadEmptyCreated() public {
        vm.prank(COORDINATOR);
        stagedMailbox.putInbox(otherChain, messageSender, messageReceiver, 1, "SWAP", "");
        vm.prank(messageReceiver);
        bytes memory data = stagedMailbox.read(
            otherChain,
            messageSender,
            1,
            "SWAP"
        );
        assertEq(data, "", "Should return empty message");
    }

    /// @dev Tests reading non-existent message reverts
    function testReadNotFound() public {
        bytes32 key = stagedMailbox.getKey(otherChain, thisChain, messageSender, messageReceiver, 1, "SWAP");
        vm.prank(messageReceiver);
        vm.expectRevert(abi.encodeWithSelector(IStagedMailbox.MessageNotFound.selector, key));
        stagedMailbox.read(otherChain, messageSender, 1, "SWAP");
    }

    /// @dev Tests reading an already used message reverts
    function testReadAlreadyUsed() public {
        bytes32 key = testWriteInboxSingle();
        vm.prank(messageReceiver);
        stagedMailbox.read(otherChain, messageSender, 1, "SWAP");
        vm.prank(messageReceiver);
        vm.expectRevert(abi.encodeWithSelector(IStagedMailbox.MessageAlreadyUsed.selector, key));
        stagedMailbox.read(otherChain, messageSender, 1, "SWAP");
    }

    /// @dev Tests writing a message to outbox
    function testWrite() public {
        vm.prank(COORDINATOR);
        stagedMailbox.putOutbox(otherChain, messageSender, messageReceiver, 1, "SWAP", "hello");
        bytes32 key = stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 1, "SWAP");

        vm.prank(messageSender);
        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.MessageWritten(key);

        stagedMailbox.write(otherChain, messageReceiver, 1, "SWAP", "hello");
        assertTrue(stagedMailbox.usedKeys(key), "Key should be marked as used");
        assertEq(stagedMailbox.outbox(key), "", "Outbox message should be deleted");
        bytes32 expectedRoot = keccak256(abi.encode(bytes32(0), key, "hello"));
        assertEq(stagedMailbox.outboxRootPerChain(otherChain), expectedRoot, "Outbox root should match");
    }

    /// @dev Tests writing with non-existent key reverts
    function testWriteNonExistentKey() public {
        bytes32 key = stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 1, "SWAP");
        vm.prank(messageSender);
        vm.expectRevert(abi.encodeWithSelector(IStagedMailbox.MessageNotFound.selector, key));
        stagedMailbox.write(otherChain, messageReceiver, 1, "SWAP", "hello");
    }

    /// @dev Tests writing with already used key reverts
    function testWriteAlreadyUsed() public {
        bytes32 key = testWriteOutboxSingle();
        vm.prank(messageSender);
        stagedMailbox.write(otherChain, messageReceiver, 1, "SWAP", "hello");
        vm.prank(messageSender);
        vm.expectRevert(abi.encodeWithSelector(IStagedMailbox.MessageAlreadyUsed.selector, key));
        stagedMailbox.write(otherChain, messageReceiver, 1, "SWAP", "hello");
    }

    /// @dev Tests writing with data mismatch reverts
    function testWriteDataMismatch() public {
        vm.prank(COORDINATOR);
        stagedMailbox.putOutbox(otherChain, messageSender, messageReceiver, 1, "SWAP", "hello");
        bytes32 key = stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 1, "SWAP");
        vm.prank(messageSender);
        vm.expectRevert(abi.encodeWithSelector(IStagedMailbox.MessageDataMismatch.selector, key));
        stagedMailbox.write(otherChain, messageReceiver, 1, "SWAP", "different");
    }

    /// @dev Tests safeExecute with inbox and outbox messages
    function testSafeExecute() public {
        address target = address(new MockTarget());

        IStagedMailbox.StagedInboxMsg[] memory inboxMsgs = new IStagedMailbox.StagedInboxMsg[](1);
        inboxMsgs[0] = IStagedMailbox.StagedInboxMsg({
            srcChainID: otherChain,
            sender: messageSender,
            receiver: messageReceiver,
            sessionId: 1,
            label: "SWAP",
            data: "salut"
        });

        IStagedMailbox.StagedOutboxMsg[] memory outboxMsgs = new IStagedMailbox.StagedOutboxMsg[](1);
        outboxMsgs[0] = IStagedMailbox.StagedOutboxMsg({
            destChainID: otherChain,
            sender: messageSender,
            receiver: messageReceiver,
            sessionId: 1,
            label: "SWAP",
            data: "hello"
        });

        bytes memory mainTxData = abi.encodeWithSignature("doSomething()");

        vm.startPrank(COORDINATOR);
        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.InboxMessageAdded(
            stagedMailbox.getKey(otherChain, thisChain, messageSender, messageReceiver, 1, "SWAP")
        );
        vm.expectEmit(true, false, false, true);
        emit IStagedMailbox.OutboxMessageAdded(
            stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 1, "SWAP")
        );

        stagedMailbox.safeExecute(inboxMsgs, outboxMsgs, target, mainTxData);

        bytes32 inboxKey = stagedMailbox.getKey(otherChain, thisChain, messageSender, messageReceiver, 1, "SWAP");
        bytes32 outboxKey = stagedMailbox.getKey(thisChain, otherChain, messageSender, messageReceiver, 1, "SWAP");

        assertEq(stagedMailbox.inbox(inboxKey), "salut", "Inbox message should be set");
        assertEq(stagedMailbox.outbox(outboxKey), "hello", "Outbox message should be set");
        assertTrue(stagedMailbox.createdKeys(inboxKey), "Inbox key should be created");
        assertTrue(stagedMailbox.createdKeys(outboxKey), "Outbox key should be created");
        vm.stopPrank();
    }

    /// @dev Tests safeExecute reverts on failed target call
    function testSafeExecuteFailedCall() public {
        address target = address(new MockTarget());
        IStagedMailbox.StagedInboxMsg[] memory inboxMsgs = new IStagedMailbox.StagedInboxMsg[](0);
        IStagedMailbox.StagedOutboxMsg[] memory outboxMsgs = new IStagedMailbox.StagedOutboxMsg[](0);
        bytes memory mainTxData = abi.encodeWithSignature("fail()");

        vm.prank(COORDINATOR);
        vm.expectRevert();
        stagedMailbox.safeExecute(inboxMsgs, outboxMsgs, target, mainTxData);
    }

    /// @dev Tests getKey is consistent
    function testGetKeyPure() public view {
        bytes32 key1 = stagedMailbox.getKey(
            1,
            2,
            address(0xA),
            address(0xB),
            1,
            "LABEL"
        );
        bytes32 key2 = stagedMailbox.getKey(
            1,
            2,
            address(0xA),
            address(0xB),
            1,
            "LABEL"
        );
        assertEq(key1, key2, "Keys should be the same");
        bytes32 keyDiff = stagedMailbox.getKey(
            1,
            2,
            address(0xA),
            address(0xB),
            1,
            "DIFF"
        );
        assertNotEq(
            key1,
            keyDiff,
            "Different labels should give different keys"
        );
    }
}

contract MockTarget {
    function doSomething() external pure returns (bool) {
        return true;
    }

    function fail() external pure {
        revert("Failed");
    }
}