// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ComposeCommonTest } from "test/setup/ComposeCommonTest.sol";
import { GameType, GameStatus, Claim } from "@optimism/src/dispute/lib/Types.sol";

/// @title ComposeDisputeGameTest
/// @notice Tests for the ComposeDisputeGame contract
contract ComposeDisputeGameTest is ComposeCommonTest {
    
    // ============ Initialization Tests ============

    function test_implementation_deployed() public view {
        assertTrue(address(composeDisputeGameImpl) != address(0), "Game impl not deployed");
    }

    function test_implementation_hasCorrectVerifier() public view {
        assertEq(
            address(composeDisputeGameImpl.PROOF_VERIFIER()),
            address(mockSP1Verifier),
            "Verifier mismatch"
        );
    }

    function test_implementation_hasCorrectASR() public view {
        assertEq(
            address(composeDisputeGameImpl.ANCHOR_STATE_REGISTRY()),
            address(composeAnchorStateRegistry),
            "ASR mismatch"
        );
    }

    function test_implementation_hasCorrectAuthorizedProposer() public view {
        assertEq(
            composeDisputeGameImpl.AUTHORIZED_PROPOSER(),
            authorizedProposer,
            "Authorized proposer mismatch"
        );
    }

    // ============ Factory Registration Tests ============

    function test_factory_hasGameRegistered() public view {
        address gameImpl = address(
            composeDisputeGameFactory.gameImpls(GameType.wrap(5555))
        );
        
        assertEq(gameImpl, address(composeDisputeGameImpl), "Game not registered in factory");
    }

    // TODO: Fix game creation test - requires proper initialization setup
    // function test_factory_canCreateGame() public {
    //     // Create mock game data
    //     bytes32 rootClaim = bytes32(uint256(1));
    //     bytes memory extraData = "";
    //     
    //     // Get bond amount
    //     uint256 bond = composeDisputeGameFactory.initBonds(GameType.wrap(5555));
    //     
    //     // Create game as authorized proposer
    //     vm.deal(authorizedProposer, bond);
    //     vm.prank(authorizedProposer);
    //     
    //     address game = address(composeDisputeGameFactory.create{value: bond}(
    //         GameType.wrap(5555),
    //         Claim.wrap(rootClaim),
    //         extraData
    //     ));
    //     
    //     assertTrue(game != address(0), "Game not created");
    // }

    // ============ Game Type Tests ============

    function test_gameType_isCorrect() public view {
        assertEq(composeDisputeGameImpl.COMPOSE_GAME_TYPE(), 5555, "Game type mismatch");
    }

    // ============ Version Tests ============

    function test_version_isSet() public view {
        string memory ver = composeDisputeGameImpl.version();
        assertTrue(bytes(ver).length > 0, "Version not set");
    }

    // ============ Integration Tests ============

    function test_asr_respectsGameType() public view {
        GameType respectedType = composeAnchorStateRegistry.respectedGameType();
        assertEq(respectedType.raw(), 5555, "ASR doesn't respect COMPOSE game type");
    }
}
