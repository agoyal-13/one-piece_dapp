// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OnePieceMint is VRFConsumerBaseV2, ERC721, Ownable, ERC721URIStorage {
    event NftRequested(uint256 requestId, address requester);
    event CharacterTraitDetermined(uint256 characterId);
    event NftMinted(uint256 characterId, address minter);

    uint256 private s_tokenCounter;
    VRFCoordinatorV2Interface private i_vrfCoordinator;
    uint256 private i_subscriptionId;
    bytes32 private i_keyHash;
    uint256 private i_callbackGasLimit;

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

    function mintNFT(address _recipient, uint256 _characterId) internal {
        require(hasMinted[_recipient], "Already minted the character");
        uint256 tokenId = s_tokenCounter;
        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, characterTokenURIs[_characterId]);
        s_addressToCharacter[_recipient] = _characterId;

        s_tokenCounter++;
        hasMinted[_recipient] = true;

        emit NftMinted(_characterId, _recipient);
    }
}
