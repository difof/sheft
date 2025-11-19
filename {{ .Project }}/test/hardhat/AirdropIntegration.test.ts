
import { expect } from "chai"
import { describe, it } from "mocha"
import { network } from "hardhat"
import { type HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/types"

import Merkle from "../../src/ts/merkle.ts"

import {
    type {{.ProjectPascal}}Token,
    {{.ProjectPascal}}Token__factory,
    type Airdrop,
    Airdrop__factory,
} from "../../typechain/index.ts"
import { type AirdropMembershipStruct } from "../../typechain/Airdrop.sol/Airdrop.ts"

const { ethers, networkHelpers } = await network.connect()

async function setupFixture() {
    const owner = await getSigner()
    const contracts = await deployContracts(owner)
    const whitelist = generateTestWhitelist()
    const merkleTree = await makeMerkleTree(contracts.token, whitelist)
    await fundAirdropWithTotalAllocation(whitelist, contracts.airdrop, contracts.token)

    return {
        airdrop: contracts.airdrop,
        token: contracts.token,
        owner, whitelist, merkleTree
    }
}

describe("Airdrop contract", () => {
    it("Should update merkle root", async () => {
        const { merkleTree, airdrop } = await networkHelpers.loadFixture(setupFixture)
        const root = merkleTree.getRoot()
        const updatedRoot = await updateMerkleRoot(airdrop, root)
        expect(updatedRoot).to.eq(root)
    })

    it("Merkle leaf at index 0 should equal to mapped allocation", async () => {
        const { token, whitelist, merkleTree } = await networkHelpers.loadFixture(setupFixture)
        const mapper = await buildMapperFunction(token)

        const index = 0
        const allocation = whitelist[index]!
        const hashedAllocation = ethers.keccak256(mapper(allocation))
        const leaf = "0x" + merkleTree.getTree().getLeaf(index).toString("hex")
        expect(leaf).to.eq(hashedAllocation)
    })

    it("Should locally verify whitelist", async () => {
        const { merkleTree } = await networkHelpers.loadFixture(setupFixture)
        const index = 0
        const leaf = merkleTree.getItem(index)
        const proof = merkleTree.getProof(index)
        const root = merkleTree.getRoot().substring(2)
        const result = merkleTree.getTree().verify(proof, leaf, root)
        expect(result).to.be.true
    })

    it("Should airdrop", async () => {
        const { merkleTree, airdrop, whitelist, token } = await networkHelpers.loadFixture(setupFixture)
        await updateMerkleRoot(airdrop, merkleTree.getRoot())

        const index = 0
        const proof = merkleTree.getProof(index)
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
        const { merkleTree, airdrop, whitelist, token } = await networkHelpers.loadFixture(setupFixture)
        await updateMerkleRoot(airdrop, merkleTree.getRoot())

        const index = 0
        whitelist[index]!.claimAmount += "1"
        const newTree = await makeMerkleTree(token, whitelist)
        const proof = newTree.getProof(index)

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

async function getSigner(): Promise<HardhatEthersSigner> {
    const [owner] = await ethers.getSigners()
    if (!owner) throw new Error("No signers available")

    return owner
}

async function deployContracts(
    owner: HardhatEthersSigner
): Promise<{ airdrop: Airdrop; token: {{.ProjectPascal}}Token }> {
    const airdrop = new Airdrop__factory(owner).deploy(owner)
    const token = new {{.ProjectPascal}}Token__factory(owner).deploy(
        ethers.parseEther("1000"),
        owner
    )
    return { airdrop: await airdrop, token: await token }
}

async function makeMerkleTree(
    token: {{.ProjectPascal}}Token,
    whitelist: AirdropMembershipStruct[]
): Promise<Merkle<AirdropMembershipStruct>> {
    return new Merkle(
        whitelist,
        await buildMapperFunction(token),
        ethers.keccak256
    )
}

async function buildMapperFunction(
    token: {{.ProjectPascal}}Token
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
    token: {{.ProjectPascal}}Token
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
