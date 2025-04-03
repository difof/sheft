import { MerkleTree } from "merkletreejs"

export type DataItem = object
export type HexString = string

export type MapperFunction<T extends DataItem> = (item: T) => string
export type HashFunction = (input: string) => HexString

class MerkleWrapper<T extends DataItem> {
    readonly #mapperFunction: MapperFunction<T>
    readonly #hashFunction: HashFunction
    readonly #tree: MerkleTree
    readonly #hashedData: HexString[]

}

export default MerkleWrapper
