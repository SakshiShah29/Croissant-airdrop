//SPDX-License-Identifier: MIT
// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.24;
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    // ERRORS
    error MerkleAirdrop__InvalidMerkleProof();
    //some list of addresses
    //allow someone in the list to claim tokens
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    //Events
    event Claim(address indexed account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }
    /*
     *@notice: Allows an account to claim a specified amount of tokens if they are included in the Merkle tree.
     *@param account: The address of the account claiming the tokens.
     *@param amount: The amount of tokens to claim.
     *@param merkleProof: An array of bytes32 hashes. It represents the merkle proof required to demonstrate
     * that the combination of account and amount is part of the allowlist encoded in the i_merkleRoot.
     */

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        // here all the address and amount pairs lie on the leaf node of the markle tree as
        // hashed value which are all hashed again to form the intermediate nodes
        // and finally the root node
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        ); //standard to hash it twice to basically eradicate the second preimage attack
        //verify the proof
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidMerkleProof();
        }
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }
}
