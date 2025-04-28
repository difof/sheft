import { expect } from "chai"
import { describe, it, beforeEach } from "mocha"
import { network } from "hardhat"
import { type HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types"

import Merkle from "../../src/ts/merkle.ts"

import {
    type FooToken,
    FooToken__factory,
    type Airdrop,
    Airdrop__factory,
} from "../../typechain/index.ts"
import { type AirdropMembershipStruct } from "../../typechain/Airdrop.sol/Airdrop.ts"

const { ethers } = await network.connect()

describe("Airdrop contract", () => {
    let token: FooToken
    let airdrop: Airdrop
    let owner: HardhatEthersSigner
    let whitelist: AirdropMembershipStruct[]
    let merkle: Merkle<AirdropMembershipStruct>

    beforeEach(async () => {
        owner = await getSigner()

        const contracts = await loadContracts(owner)
        airdrop = contracts.airdrop
        token = contracts.token

        whitelist = generateTestWhitelist()
        merkle = await makeMerkleTree(token, whitelist)

        await fundAirdropWithTotalAllocation(whitelist, airdrop, token)
    })

    it("Should update merkle root", async () => {
        const root = merkle.getRoot()
        const updatedRoot = await updateMerkleRoot(airdrop, root)
        expect(updatedRoot).to.eq(root)
    })

    it("Merkle leaf at index 0 should equal to mapped allocation", async () => {
        const mapper = await buildMapperFunction(token)

        const index = 0
        const allocation = whitelist[index]!
        const hashedAllocation = ethers.keccak256(mapper(allocation))
        const leaf = "0x" + merkle.getTree().getLeaf(index).toString("hex")
        expect(leaf).to.eq(hashedAllocation)
    })

    it("Should locally verify whitelist", () => {
        const index = 0
        const leaf = merkle.getItem(index)
        const proof = merkle.getProof(index)
        const root = merkle.getRoot().substring(2)
        const result = merkle.getTree().verify(proof, leaf, root)
        expect(result).to.be.true
    })

    it("Should airdrop", async () => {
        await updateMerkleRoot(airdrop, merkle.getRoot())

        const index = 0
        const proof = merkle.getProof(index)
        const userWallet = whitelist[index]!.userWallet
        const expectedAmount = BigInt(whitelist[index]!.claimAmount)

        const balanceBefore = await token.balanceOf(userWallet)

        // shortcut for block confirmation
        await (
            await airdrop.claim(
                proof,
                whitelist[index]!,
                await token.getAddress()
            )
        ).wait()

        const balanceAfter = await token.balanceOf(userWallet)
        expect(balanceAfter - balanceBefore).to.eq(expectedAmount)
    })

    it("Should fail airdrop", async () => {
        await updateMerkleRoot(airdrop, merkle.getRoot())

        const index = 0
        whitelist[index]!.claimAmount += "1"
        merkle = await makeMerkleTree(token, whitelist)
        const proof = merkle.getProof(index)

        let failed = false
        try {
            await (
                await airdrop.claim(
                    proof,
                    whitelist[index]!,
                    await token.getAddress()
                )
            ).wait()
        } catch {
            failed = true
        }

        expect(failed).to.be.true
    })
})

async function makeMerkleTree(
    token: FooToken,
    whitelist: AirdropMembershipStruct[]
): Promise<Merkle<AirdropMembershipStruct>> {
    return new Merkle(
        whitelist,
        await buildMapperFunction(token),
        ethers.keccak256
    )
}

async function buildMapperFunction(
    token: FooToken
): Promise<(item: AirdropMembershipStruct) => string> {
    const chainId = (await ethers.provider.getNetwork()).chainId
    const tokenAddress = await token.getAddress()

    return (item: AirdropMembershipStruct): string => {
        return ethers.solidityPacked(
            ["address", "uint256", "address", "uint256"],
            [item.userWallet, item.claimAmount, tokenAddress, chainId]
        )
    }
}

async function getSigner(): Promise<HardhatEthersSigner> {
    const [owner] = await ethers.getSigners()
    if (!owner) throw new Error("No signers available")

    return owner
}

async function loadContracts(
    owner: HardhatEthersSigner
): Promise<{ airdrop: Airdrop; token: FooToken }> {
    const airdrop = new Airdrop__factory(owner).deploy(owner)
    const token = new FooToken__factory(owner).deploy(
        ethers.parseEther("1000"),
        owner
    )
    return { airdrop: await airdrop, token: await token }
}

function generateTestWhitelist(): AirdropMembershipStruct[] {
    return Array.from({ length: 10 }, () => {
        // generate random amount between 0.1 and 10 ETH
        const randomEth = Math.random() * 9.9 + 0.1
        const claimAmount = ethers.parseEther(randomEth.toString()).toString()

        return {
            userWallet: ethers.Wallet.createRandom().address,
            claimAmount: claimAmount,
        }
    })
}

async function fundAirdropWithTotalAllocation(
    whitelist: AirdropMembershipStruct[],
    airdrop: Airdrop,
    token: FooToken
) {
    const totalClaimAmount = whitelist.reduce((sum, user) => {
        return sum + BigInt(user.claimAmount)
    }, 0n)

    const tx = await token.transfer(
        await airdrop.getAddress(),
        totalClaimAmount
    )
    await tx.wait()
}

async function updateMerkleRoot(
    airdrop: Airdrop,
    root: string
): Promise<string> {
    const tx = await airdrop.updateMerkleRoot(root)
    await tx.wait()

    return await airdrop.merkleRoot()
}
