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
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MerkleAirdrop is ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;
    // ERRORS

    error MerkleAirdrop__InvalidMerkleProof();
    error MerkleAirdrop__AccountHasClaimedTokensAlready();
    error MerkleAirdrop__InvalidSignature();
    //some list of addresses
    //allow someone in the list to claim tokens

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    mapping(address => bool) private s_hasClaimed;
    //Events

    event Claim(address indexed account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
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

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
        nonReentrant
    {
        // Check if the account has already claimed tokens
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AccountHasClaimedTokensAlready();
        }
        // Check if the signature is valid
        bytes32 digest = getMessage(account, amount);
        if (!isValidSignature(account, digest, v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        // here all the address and amount pairs lie on the leaf node of the markle tree as
        // hashed value which are all hashed again to form the intermediate nodes
        // and finally the root node
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount)))); //standard to hash it twice to basically eradicate the second preimage attack
        //verify the proof
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidMerkleProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    // Public function to get the EIP-712 message digest for the frontend to sign
    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        //calculate the structhash
        bytes32 structHash = keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount})));

        //_hashTypedDatav4 constructs the EIP-712 message digest
        // keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash))
        return _hashTypedDataV4(structHash);
    }

    //Internal function to verify the signature
    function isValidSignature(address expectedSigner, bytes32 digest, uint8 _v, bytes32 _r, bytes32 _s)
        internal
        pure
        returns (bool)
    {
        //using the ECDSA.tryRecover(hash, signature); for safer signature recovery
        (address recovered,,) = ECDSA.tryRecover(digest, _v, _r, _s);
        // Check if the recovered address matches the expected signer
        return (recovered == expectedSigner && recovered != address(0));
    }

    //getter functions
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
