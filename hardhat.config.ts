import dotenv from "dotenv"
dotenv.config({ quiet: true })

import type { HardhatUserConfig } from "hardhat/config"
import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers"

const config: HardhatUserConfig = {
    plugins: [hardhatToolboxMochaEthersPlugin],
    paths: {
        sources: "src/contracts",
        tests: "test/hardhat",
        cache: "cache/hardhat",
        artifacts: "artifacts/hardhat",
    },
    typechain: {
        outDir: "typechain",
        alwaysGenerateOverloads: true,
    },
    solidity: {
        profiles: {
            default: {
                version: "0.8.23",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        },
    },
}

function loadExternalNetworks() {
    const networks: {
        [key: string]: { chainId: number; url: string; type: string }
    } = {}


    return networks
}

export default config
