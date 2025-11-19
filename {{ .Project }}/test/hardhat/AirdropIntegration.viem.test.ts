import { expect } from "chai"
import { describe, it } from "mocha"
import { network } from "hardhat"
import { parseEther, keccak256, encodePacked } from "viem"
import { generatePrivateKey, privateKeyToAccount } from "viem/accounts"

import Merkle from "../../src/ts/merkle.ts"

const { viem, networkHelpers } = await network.connect()

type AirdropMembershipStruct = { userWallet: string, claimAmount: bigint }
type Contract = Awaited<ReturnType<typeof viem.deployContract>>
type Signer = Awaited<ReturnType<typeof viem.getWalletClients>>[0]

async function setupFixture() {
    const [owner] = await viem.getWalletClients()
    if (!owner) throw new Error("No signers available")

    const contracts = await deployContracts(owner)
    const whitelist = generateTestWhitelist()
    const merkleTree = await makeMerkleTree(contracts.token, whitelist)
    await fundAirdropWithTotalAllocation(whitelist, contracts.airdrop, contracts.token)

    return {
        airdrop: contracts.airdrop,
        token: contracts.token,
        owner,
        whitelist,
        merkleTree
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
        const mapped = mapper(allocation)
        const hashedAllocation = keccak256(mapped as `0x${string}`)
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

        const balanceBefore = await token.read.balanceOf([userWallet])

        await airdrop.write.claim([
            proof,
            whitelist[index]!,
            token.address
        ])

        const balanceAfter = await token.read.balanceOf([userWallet])
        expect(balanceAfter - balanceBefore).to.eq(expectedAmount)
    })

    it("Should fail airdrop", async () => {
        const { merkleTree, airdrop, whitelist, token } = await networkHelpers.loadFixture(setupFixture)
        await updateMerkleRoot(airdrop, merkleTree.getRoot())

        const index = 0
        whitelist[index]!.claimAmount = BigInt(whitelist[index]!.claimAmount) + 1n
        const newTree = await makeMerkleTree(token, whitelist)
        const proof = newTree.getProof(index)

        await viem.assertions.revertWithCustomError(
            airdrop.write.claim([
                proof,
                whitelist[index]!,
                token.address
            ]),
            airdrop,
            "NotEligible"
        )
    })
})

async function deployContracts(
    owner: Signer
): Promise<{ airdrop: Contract; token: Contract }> {
    const ownerAddress = owner.account.address

    const airdrop = await viem.deployContract("Airdrop", [ownerAddress])
    const token = await viem.deployContract("{{.ProjectPascal}}Token", [
        parseEther("1000"),
        ownerAddress
    ])

    return { airdrop, token }
}

async function makeMerkleTree(
    token: Contract,
    whitelist: AirdropMembershipStruct[]
): Promise<Merkle<AirdropMembershipStruct>> {
    const hashFunction = (input: string): string => {
        return keccak256(input as `0x${string}`)
    }
    return new Merkle(
        whitelist,
        await buildMapperFunction(token),
        hashFunction
    )
}

async function buildMapperFunction(
    token: Contract
): Promise<(item: AirdropMembershipStruct) => string> {
    const publicClient = await viem.getPublicClient()
    const chainId = await publicClient.getChainId()
    const tokenAddress = token.address as `0x${string}`

    return (item: AirdropMembershipStruct): string => {
        return encodePacked(
            ["address", "uint256", "address", "uint256"],
            [
                item.userWallet as `0x${string}`,
                BigInt(item.claimAmount),
                tokenAddress,
                BigInt(chainId)
            ]
        )
    }
}

function generateTestWhitelist(): AirdropMembershipStruct[] {
    return Array.from({ length: 10 }, () => {
        // generate random amount between 0.1 and 10 ETH
        const randomEth = Math.random() * 9.9 + 0.1
        const claimAmount = parseEther(randomEth.toString())

        const privateKey = generatePrivateKey()
        const account = privateKeyToAccount(privateKey)

        return {
            userWallet: account.address,
            claimAmount: claimAmount,
        }
    })
}

async function fundAirdropWithTotalAllocation(
    whitelist: AirdropMembershipStruct[],
    airdrop: Contract,
    token: Contract
) {
    const totalClaimAmount = whitelist.reduce((sum, user) => {
        return sum + BigInt(user.claimAmount)
    }, 0n)

    await token.write.transfer([
        airdrop.address,
        totalClaimAmount
    ])
}

async function updateMerkleRoot(
    airdrop: Contract,
    root: string
): Promise<string> {
    await airdrop.write.updateMerkleRoot([root as `0x${string}`])
    return await airdrop.read.merkleRoot()
}
