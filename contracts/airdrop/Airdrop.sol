// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../token/interfaces/IERC20Custom.sol";

contract Airdrop is Ownable, ReentrancyGuard {
    IERC20Custom public token;
    bytes32 private merkleRoot;
    mapping(address => bool) public airdropClaimed;

    /**
     * @notice Emitted after a successful token claim
     * @param to recipient of claim
     * @param amount of tokens claimed
     */
    event Claim(address indexed to, uint256 amount);

    constructor(address _tokenAddress, bytes32 _merkleRoot) {
        token = IERC20Custom(_tokenAddress);
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) onlyOwner external {
        require(
            _newMerkleRoot != 0x00 || _newMerkleRoot != merkleRoot,
            "Airdrop: Invalid new merkle root value!"
        );
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @notice Allows claiming tokens if address is part of merkle tree
     * @param amount of tokens owed to claimee
     * @param proof merkle proof to prove address and amount are in tree
     */
    function claim(
      uint256 amount,
      bytes32[] calldata proof
    ) nonReentrant external {
        require(amount > 0, "Airdrop: Amount cannot be 0!");
        // Throw if address has already claimed tokens
        require(!airdropClaimed[msg.sender], "Airdrop: Airdrop has been claimed!");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, "Airdrop: Address has no Airdrop claim!");

        // Set address to claimed
        airdropClaimed[msg.sender] = true;

        // Mint tokens to address
        token.mint(msg.sender, amount);

        // Emit claim event
        emit Claim(msg.sender, amount);
    }
}