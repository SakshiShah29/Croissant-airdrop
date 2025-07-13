//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Croissant} from "../src/Croissant.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public merkleAirdrop;
    Croissant public croissant;
    DeployMerkleAirdrop public deployer;
    HelperConfig public helperConfig;
    bytes32 public rootHash;
    uint256 public deployerKey;

    address user;
    uint256 userPrivateKey;

    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_SEND;
    //need to pass it as intermediatory bytes32
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    function setUp() public {
        deployer = new DeployMerkleAirdrop();
        (croissant, merkleAirdrop, helperConfig) = deployer.run();
        (rootHash, deployerKey) = helperConfig.activeNetworkConfig();
        (user, userPrivateKey) = makeAddrAndKey("user");

        // assuming the test airdrop is for 4 users thus we need to send 4times the amount of tokens to claim to the
        // croissant contract
        AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
        vm.startPrank(vm.addr(deployerKey));
        croissant.mint(vm.addr(deployerKey), AMOUNT_TO_SEND);
        croissant.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        vm.stopPrank();
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = croissant.balanceOf(user);
        vm.prank(user);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF);
        uint256 endingBalance = croissant.balanceOf(user);
        console.log("Ending Balance: ", endingBalance);
        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}
