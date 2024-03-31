const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers');
const { expect, assert } = require("chai");
// const { hardhat } = "hardhat";
const { ethers } = require("hardhat");
// import { OnePieceMint } from "../contracts/OnePieceMint.sol";
// import { VRFCoordinatorV2Mock } from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { any } = require('hardhat/internal/core/params/argumentTypes');

describe("OnePieceMint", function () {
    let contract;

    beforeEach(async () => {
        const [owner] = await ethers.getSigners();
        const onePieceMint = await ethers.getContractFactory("OnePieceMint");
        const vrfCoordinator = '0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625';
        const keyHash = '0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c';
        const subscriptionId = 0;
        const callbackGasLimit = 500000;

        contract = await onePieceMint.deploy(vrfCoordinator, subscriptionId, keyHash, callbackGasLimit);
    });

    it('emits a NftMinted event on successful minting', async function () {
        const characterId = 0
        const [owner, addr1, receiver] = await ethers.getSigners();
        console.log('owner:', owner.address);
        console.log('addr1:', addr1.address);
        console.log('receiver:', receiver.address);
        const receipt = await contract.mintNFT(receiver, characterId);

        console.log('receipt:', receipt);
        expect(receipt)
            .to.emit(contract, "NftMinted")
            .withArgs({
                characterId: characterId,
                minter: receiver.address
            });
    });

    it('Rejected with custom error in re-minting by the same user', async function () {
        const characterId = 0
        const [receiver] = await ethers.getSigners();
        await contract.mintNFT(receiver, characterId);

        await expect(contract.mintNFT(receiver, characterId))
            .to.be.rejectedWith("User already minted the character");
    });

});
