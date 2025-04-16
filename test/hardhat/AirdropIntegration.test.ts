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
