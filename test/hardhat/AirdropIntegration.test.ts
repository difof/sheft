import { expect } from "chai"
import { describe, it, beforeEach } from "mocha"
import { network } from "hardhat"
import Merkle from "../../src/ts/merkle.ts"
import {
    type FooToken,
    FooToken__factory,
    type Airdrop,
    Airdrop__factory,
} from "../../typechain/index.ts"
import { type AirdropMembershipStruct } from "../../typechain/Airdrop.sol/Airdrop.ts"

const { ethers } = await network.connect()

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
