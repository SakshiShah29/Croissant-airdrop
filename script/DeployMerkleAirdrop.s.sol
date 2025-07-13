//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Croissant} from "../src/Croissant.sol";

contract DeployMerkleAirdrop is Script {
    function run() external returns (Croissant, MerkleAirdrop, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (bytes32 rootHash, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        vm.startBroadcast(deployerKey);
        Croissant croissantToken = new Croissant();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(rootHash, IERC20(croissantToken));
        vm.stopBroadcast();
        return (croissantToken, merkleAirdrop, helperConfig);
    }
}
