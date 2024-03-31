// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {console} from "hardhat/console.sol";

contract OnePieceMint is VRFConsumerBaseV2, ERC721, Ownable, ERC721URIStorage {
    event NftRequested(uint256 requestId, address requester);
    event CharacterTraitDetermined(uint256 characterId);
    event NftMinted(uint256 characterId, address minter);

    uint256 private s_tokenCounter;
    VRFCoordinatorV2Interface private i_vrfCoordinator;
    uint64 private i_subscriptionId;
    bytes32 private i_keyHash;
    uint32 private i_callbackGasLimit;

    string[] internal characterTokenURIs = [
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmNp4sHf4ccqPpqMBUCSG1CpFwFR4D6kgHesxc1mLs75am",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmPHaFt55PeidgCuXe2kaeRYmLaBUPE1Y7Kg4tDyzapZHy",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmP9pC9JuUpKcnjUk8GBXEWVTGvK3FTjXL91Q3MJ2rhA16",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmSnNXo5hxrFnpbyBeb7jY7jhkm5eyknaCXtr8muk31AHK",
        "https://scarlet-live-iguana-759.mypinata.cloud/ipfs/QmarkkgDuBUcnqksatPzU8uNS4o6LTbEtuK43P7Jyth9NH"
    ];

    constructor(address _vrfCoordinatorV2Address, uint64 _subId, bytes32 _keyHash, uint32 _callbackGasLimit)
        VRFConsumerBaseV2(_vrfCoordinatorV2Address)
        ERC721("OnePiece NFT", "OPN")
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2Address);
        i_subscriptionId = _subId;
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
    }

    mapping(uint256 => address) private requestIdToSender; // allows the contract to keep track of which address made a request
    mapping(address => uint256) private userCharacter; // enables the contract to associate each user with their selected character
    mapping(address => bool) public hasMinted; // prevents users from minting multiple NFTs with the same address
    mapping(address => uint256) public s_addressToCharacter; // allows users to query which character they received based on their address

    function mintNFT(address _recipient, uint256 _characterId) public {
        require(!hasMinted[_recipient], "User already minted the character");
        uint256 tokenId = s_tokenCounter;
        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, characterTokenURIs[_characterId]);

        s_addressToCharacter[_recipient] = _characterId;

        s_tokenCounter++;
        hasMinted[_recipient] = true;
        console.log("hasMinted[_recipient]:--", hasMinted[_recipient]);
        emit NftMinted(_characterId, _recipient);
    }

    function requestNFT(uint256[5] memory answers) public {
        // Determine the character based on the provided answers and store it for the user
        userCharacter[msg.sender] = determineCharacter(answers);

        uint256 requestId = i_vrfCoordinator.requestRandomWords(i_keyHash, i_subscriptionId, 3, i_callbackGasLimit, 1);

        // Map the request ID to the sender's address for later reference
        requestIdToSender[requestId] = msg.sender;

        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Get the address of the NFT owner associated with the request ID
        address nftOwner = requestIdToSender[requestId];

        // Get the character ID determined based on the user's traits
        uint256 traitBasedCharacterId = userCharacter[nftOwner];

        // Retrieve the first random word from the provided array
        uint256 randomValue = randomWords[0];

        // Calculate the random character ID based on the random value
        uint256 randomCharacterId = (randomValue % 5);

        // Calculate the final character ID by combining the trait-based and random character IDs
        uint256 finalCharacterId = (traitBasedCharacterId + randomCharacterId) % 5;

        // Mint the NFT for the owner with the final character ID
        mintNFT(nftOwner, finalCharacterId);
    }

    function determineCharacter(uint256[5] memory answers) private returns (uint256) {
        // Initialize characterId variable to store the calculated character ID
        uint256 characterId = 0;

        // Loop through each answer provided in the answers array
        for (uint256 i = 0; i < 5; i++) {
            // Add each answer to the characterId variable
            characterId += answers[i];
        }

        // Calculate the final character ID by taking the remainder when divided by 5 and adding 1
        characterId = (characterId % 5) + 1;

        // Emit an event to log the determination of the character traits
        emit CharacterTraitDetermined(characterId);

        // Return the final character ID
        return characterId;
    }

    // Override the transfer functionality of ERC721 to make it soulbound
    // This function is called before every token transfer to enforce soulbinding
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        // Ensure that tokens are only transferred to or from the zero address
        require(from == address(0) || to == address(0), "Err! This is not allowed");
    }

    // Override the tokenURI function to ensure compatibility with ERC721URIStorage
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        // Call the parent contract's implementation of tokenURI
        return super.tokenURI(tokenId);
    }

    // Override the supportsInterface function to ensure compatibility with ERC721URIStorage
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        // Call the parent contract's implementation of supportsInterface
        return super.supportsInterface(interfaceId);
    }

    // Override the _burn function to ensure compatibility with ERC721URIStorage
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        // Call the parent contract's implementation of _burn
        super._burn(tokenId);
    }
}
