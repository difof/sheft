import { network } from "hardhat"
import { expect } from "chai"
import keccak from "../../src/ts/keccak.ts"

const { ethers } = await network.connect()

describe("Diff keccak lib and ethers", () => {
    it("Should result in same hash from keccak and ethers.keccak256", () => {
        const valueToHash = "Hello, World!"
        const encoded = ethers.solidityPacked(["string"], [valueToHash])
        const ethersKeccakHash = ethers.keccak256(encoded)
        const keccakHash = "0x" + keccak(encoded)
        expect(keccakHash).to.eq(ethersKeccakHash)
    })
})
