// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { Mailbox } from "@ssv/src/core/Mailbox.sol";
import { PingPong } from "@ssv/src/core/PingPong.sol";
import { BridgeableToken } from "@ssv/src/core/BridgeableToken.sol";
import { Bridge } from "@ssv/src/core/Bridge.sol";
import { StagedMailbox } from "@ssv/src/core/StagedMailbox.sol";
import { ComposableERC20 } from "@ssv/src/bridge/ComposableErc20.sol";
import { CetFactory } from "@ssv/src/bridge/CetFactory.sol";

contract Setup is Test {
    Mailbox public mailbox;
    PingPong public pingPong;
    BridgeableToken public myToken;
    Bridge public bridge;
    StagedMailbox public stagedMailbox;

    address public immutable DEPLOYER = makeAddr("Deployer");
    address public immutable COORDINATOR = makeAddr("Coordinator");

    uint256 public constant INITIAL_ETH_BALANCE = 10 ether;

    function setUp() public virtual {
        vm.label(DEPLOYER, "Deployer");
        vm.label(COORDINATOR, "Coordinator");

        vm.deal(DEPLOYER, INITIAL_ETH_BALANCE);
        vm.deal(COORDINATOR, INITIAL_ETH_BALANCE);

        vm.prank(DEPLOYER);
        mailbox = new Mailbox(address(COORDINATOR));
        pingPong = new PingPong(address(mailbox));
        bridge = new Bridge(address(mailbox));
        myToken = new BridgeableToken(address(bridge));
        stagedMailbox = new StagedMailbox(address(COORDINATOR));

        vm.label(address(mailbox), "Mailbox");
        vm.label(address(pingPong), "PingPong");
        vm.label(address(myToken), "MyToken");
        vm.label(address(bridge), "Bridge");
        vm.label(address(stagedMailbox), "StagedMailbox");
    }

    function _deployComposableErc20(
        address _remoteAsset,
        uint256 _remoteChainID,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address bridgeAddress
    ) internal returns (ComposableERC20) {
        ComposableERC20 createdToken = new ComposableERC20(
            _remoteAsset,
            _remoteChainID,
            _name,
            _symbol,
            _decimals,
            bridgeAddress
        );

        vm.label(address(createdToken), "CetToken");
        return createdToken;
    }

    function _deployCetFactory() internal returns (CetFactory){
        CetFactory factory = new CetFactory();
        vm.label(address(factory), "CetFactory");
        return factory;
    }
}
