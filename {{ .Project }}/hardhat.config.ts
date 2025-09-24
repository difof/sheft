import dotenv from "dotenv"
dotenv.config({ quiet: true })

import type { HardhatUserConfig } from "hardhat/config"
import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers"

const config: HardhatUserConfig = {
    plugins: [hardhatToolboxMochaEthersPlugin],
    networks: {
        hardhat: {
            type: "edr-simulated",
            chainType: "l1",
            chainId: parseInt(process.env.HARDHAT_CHAINID!),
        },
        ...loadExternalNetworks(),
    },
    paths: {
        sources: "src/contracts",
        tests: "test/hardhat",
        cache: "cache/hardhat",
        artifacts: "artifacts/hardhat",
    },
    typechain: {
        outDir: "typechain",
        alwaysGenerateOverloads: true,
        tsNocheck: true,
    },
    solidity: {
        profiles: {
            default: {
                version: "{{.Scaffold.solc_version}}",
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

    const envVars = process.env
    const networkNames = new Set<string>()

    Object.keys(envVars).forEach((key) => {
        if (key.endsWith("_CHAINID")) {
            const networkName = key.replace("_CHAINID", "")

            if (
                networkName.toLowerCase().startsWith("anvil") ||
                networkName.toLowerCase().startsWith("hardhat")
            ) {
                return
            }

            networkNames.add(networkName)
        }
    })

    networkNames.forEach((networkName) => {
        const chainIdKey = `${networkName}_CHAINID`
        const rpcKey = `${networkName}_RPC`

        const chainId = envVars[chainIdKey]
        const url = envVars[rpcKey]

        if (chainId && url && chainId.trim() !== "" && url.trim() !== "") {
            const parsedChainId = parseInt(chainId.trim())
            if (!isNaN(parsedChainId)) {
                const networkKey = networkName.toLowerCase() //.replace(/_/g, '-')
                networks[networkKey] = {
                    chainId: parsedChainId,
                    url: url.trim(),
                    type: "http",
                }
            }
        }
    })

    return networks
}

export default config
