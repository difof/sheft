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
