import createHash from "keccak"

function withHash(): createHash.Keccak {
    return createHash("keccak256")
}
