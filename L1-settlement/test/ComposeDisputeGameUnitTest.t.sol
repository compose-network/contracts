// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {DisputeGameFactory} from "../lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol";
import {IDisputeGame} from "interfaces/dispute/IDisputeGame.sol";
import {Claim, GameStatus, GameType, Hash, Timestamp} from "@optimism/src/dispute/lib/Types.sol";
import {ComposeDisputeGame} from "../src/ComposeDisputeGame.sol";
import {AlreadyInitialized, GameNotInProgress} from "../src/ComposeDisputeGame.sol";

import {MockComposeL2OutputOracle} from "./mock/MockComposeL2OutputOracle.sol";
import {Test} from "forge-std/Test.sol";
import {Utils} from "./Utils.sol";

contract ComposeDisputeGameUnitTest is Test, Utils {
    ComposeDisputeGame private game;
    ComposeDisputeGame private impl;
    MockComposeL2OutputOracle private mockOracle;
    DisputeGameFactory private factory;

    address private constant CREATOR = address(0x1234);
    Claim private constant ROOT_CLAIM = Claim.wrap(0x66cec985afe7e41f97a2f77c876fe9015be47f18baa0bd87c59795c52887df19);
    Hash private constant L1_HEAD = Hash.wrap(bytes32(uint256(2)));
    bytes private constant EXTRA_DATA = hex"000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000025866cec985afe7e41f97a2f77c876fe9015be47f18baa0bd87c59795c52887df19000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000104a4594c59162bdead7c5ac7b05e2b0576eddf5cac6ad631b71129796bfb5db2da2d14189822763aff12bbf03cad631c20a6d4c3c1eaaf9808216d174a2be0af8a996c00e5084af057ddac9445681ec7844e1b52e33a1ed84b5e8106599554107f50e3954518586d4071b44f7c22f0d954bf259a8bf0610ebb4debd43e8eb1dfb29960c9aa0d935506c2b1d79d007a576dc095325189300c0ea459a4d994854cbe82829bac16fda18d408ad0aa80ed7d0e9ccc5af167b4310b4c1430da73640e8e81daeabe0c7a4e8c3ca2b20393882c62c5815a5703f990b7166809942de5d7dfabbc4fed013ad62d57aaefbf0a600025cc420b9195936eb202a9da25acdf27f94884091300000000000000000000000000000000000000000000000000000000";
    GameType private constant GAME_TYPE = GameType.wrap(5555);

    function setUp() public {
        mockOracle = new MockComposeL2OutputOracle();

        impl = new ComposeDisputeGame(address(mockOracle));

        factory = deployDisputeGameFactory();

        bytes memory oracleArgs = abi.encode(address(mockOracle));
        factory.setImplementation(GAME_TYPE, IDisputeGame(address(impl)));
        factory.setInitBond(GAME_TYPE, 0);
    }

    function test_CreateGame() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(address(game), address(proxy));
    }

    function test_CreateGameSetsPublicState() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(Timestamp.unwrap(game.createdAt()), uint64(block.timestamp));
        assertEq(uint8(game.status()), uint8(GameStatus.DEFENDER_WINS));
        assertEq(Timestamp.unwrap(game.resolvedAt()), uint64(block.timestamp));
        assertTrue(game.wasRespectedGameTypeWhenCreated());
    }

    function test_CreateGameReturnsCorrectGameType() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(GameType.unwrap(game.gameType()), GameType.unwrap(GAME_TYPE));
    }

    function test_CreateGameReturnsCorrectCreator() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(game.gameCreator(), CREATOR);
    }

    function test_CreateGameReturnsCorrectRootClaim() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(Claim.unwrap(game.rootClaim()), Claim.unwrap(ROOT_CLAIM));
    }

    function test_CreateGameReturnsCorrectL1Head() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(Hash.unwrap(game.l1Head()), blockhash(block.number - 1));
    }

    function test_CreateGameReturnsCorrectL2SequenceNumber() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(game.l2SequenceNumber(), 0);
    }

    function test_CreateGameReturnsCorrectVersion() public {
        vm.prank(CREATOR);
        IDisputeGame proxy = factory.create(GAME_TYPE, ROOT_CLAIM, EXTRA_DATA);
        game = ComposeDisputeGame(address(proxy));

        assertEq(game.version(), "v0.0.1");
    }
}