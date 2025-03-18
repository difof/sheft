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
}

export default config
