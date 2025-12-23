import type { NodePlopAPI, ActionType } from "plop"
import type { Answers } from "inquirer"
import { parse, stringify } from "yaml"
import { pascalCase } from "change-case"
import { existsSync, statSync, mkdirSync, readFileSync } from "fs"
import { resolve, join } from "path"
import keccak from "./src/ts/keccak.ts"

function contractNamePrompt() {
    return {
        type: "input",
        name: "contractName",
        message: "Smart contract name:",
        validate: (value: string) => {
            if (!value || value.trim().length === 0) {
                return "Contract name is required"
            }
            if (!/^[a-zA-Z][a-zA-Z0-9\s\-_]*$/.test(value)) {
                return "Contract name must start with a letter and contain only alphanumeric characters, spaces, hyphens, and underscores"
            }
            return true
        },
        filter: pascalCase,
    }
}

function interfaceNamePrompt() {
    return {
        type: "input",
        name: "interfaceName",
        message:
            "Interface name (Preferred with 'I' prefix):",
        validate: (value: string) => {
            if (!value || value.trim().length === 0) {
                return "Interface name is required"
            }
            const trimmed = value.trim()
            if (!/^[a-zA-Z][a-zA-Z0-9\s\-_]*$/.test(trimmed)) {
                return "Interface name must start with a letter and contain only alphanumeric characters, spaces, hyphens, and underscores"
            }
            return true
        },
        filter: pascalCase,
    }
}

function solcVersionPrompt() {
    return {
        type: "input",
        name: "solcVersion",
        message: "Solidity version:",
        default: "0.8.24",
        validate: (value: string) => {
            if (!/^\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(value)) {
                return "Invalid Solidity version format. Expected format: x.y.z (e.g., 0.8.24)"
            }
            return true
        },
    }
}

function licensePrompt() {
    const licenseChoices = [
        "MIT",
        "Apache-2.0",
        "BSD-3-Clause",
        "BSD-2-Clause",
        "ISC",
        "Unlicense",
        "CC0-1.0",
    ]

    let defaultLicense = "MIT"
    try {
        const packageJsonPath = join(process.cwd(), "package.json")
        if (existsSync(packageJsonPath)) {
            const packageJson = JSON.parse(
                readFileSync(packageJsonPath, "utf-8")
            )
            if (
                packageJson.license &&
                licenseChoices.includes(packageJson.license)
            ) {
                defaultLicense = packageJson.license
            }
        }
    } catch (err) {
        defaultLicense = "MIT"
    }

    return {
        type: "list",
        name: "license",
        message: "License of the project:",
        choices: licenseChoices,
        default: defaultLicense,
    }
}

function tokenNamePrompt() {
    return {
        type: "input",
        name: "tokenName",
        message: "Token name (e.g., My Token):",
        validate: (value: string) => {
            if (!value || value.trim().length === 0) {
                return "Token name is required"
            }
            return true
        },
    }
}

function tokenSymbolPrompt() {
    return {
        type: "input",
        name: "tokenSymbol",
        message: "Token symbol (e.g., MTK):",
        validate: (value: string) => {
            if (!value || value.trim().length === 0) {
                return "Token symbol is required"
            }
            if (!/^[A-Z0-9]+$/.test(value.toUpperCase())) {
                return "Token symbol should contain only alphanumeric characters"
            }
            return true
        },
        filter: (value: string) => value.toUpperCase(),
    }
}

function storageDomainPrompt() {
    return {
        type: "input",
        name: "storageDomain",
        message: "Storage domain (e.g., com.example.MyContract):",
        validate: (value: string) => {
            if (!value || value.trim().length === 0) {
                return "Storage domain is required"
            }
            if (!/^[a-zA-Z0-9._-]+$/.test(value)) {
                return "Storage domain must contain only alphanumeric characters, dots, hyphens, and underscores"
            }
            return true
        },
    }
}

function outputDirPrompt(defaultDir: string) {
    return {
        type: "input",
        name: "outputDir",
        message: "Output directory:",
        default: defaultDir,
        validate: (value: string) => {
            if (!value || value.trim().length === 0) {
                return "Output directory is required"
            }
            const dirPath = resolve(value.trim())
            if (!existsSync(dirPath)) {
                try {
                    mkdirSync(dirPath, { recursive: true })
                    return true
                } catch (err) {
                    return `Error creating directory: ${err instanceof Error ? err.message : String(err)}`
                }
            }
            const stats = statSync(dirPath)
            if (!stats.isDirectory()) {
                return `Path exists but is not a directory: ${dirPath}`
            }
            return true
        },
    }
}

function addToContractsPrompt(options?: {
    message?: string
    defaultValue?: boolean
}) {
    const { message, defaultValue } = options ?? {}
    return {
        type: "confirm",
        name: "addToContractsYaml",
        message: message ?? "Add contract name to tasks/contracts.yaml?",
        default: defaultValue ?? true,
    }
}

function addAction(from: string, to: string): ActionType {
    return {
        type: "add",
        path: to,
        templateFile: `.templates/${from}`,
    }
}

function modifyContractsYamlAction(contractName: string): ActionType {
    return {
        type: "modify",
        path: "tasks/contracts.yaml",
        transform: (fileContents: string) => {
            const yaml = parse(fileContents)
            yaml.vars.CONTRACTS.push(contractName)
            return stringify(yaml, { indent: 4 })
        },
    }
}

function addWithUpdateContracts(
    from: string,
    to: string
): (data?: Answers) => ActionType[] {
    return (data?: Answers): ActionType[] => {
        const actions = [addAction(from, to)]

        if (data!.addToContractsYaml) {
            actions.push(
                modifyContractsYamlAction(data!.contractName as string)
            )
        }

        return actions
    }
}

export default function (plop: NodePlopAPI) {
    plop.setGenerator("contract", {
        description: "Generate a new smart contract",
        prompts: [
            contractNamePrompt(),
            outputDirPrompt("src/contracts"),
            solcVersionPrompt(),
            licensePrompt(),
            addToContractsPrompt(),
        ],
        actions: addWithUpdateContracts(
            "contract.hbs",
            "{{outputDir}}/{{contractName}}.sol"
        ),
    })

    plop.setGenerator("erc20", {
        description: "Generate a new ERC20 token contract",
        prompts: [
            contractNamePrompt(),
            outputDirPrompt("src/contracts"),
            tokenNamePrompt(),
            tokenSymbolPrompt(),
            solcVersionPrompt(),
            licensePrompt(),
            addToContractsPrompt({
                message: "Add contract name to contracts.yaml?",
                defaultValue: false,
            }),
        ],
        actions: addWithUpdateContracts(
            "erc20.hbs",
            "{{outputDir}}/{{contractName}}.sol"
        ),
    })

    plop.setGenerator("erc721", {
        description: "Generate a new ERC721 NFT contract",
        prompts: [
            contractNamePrompt(),
            outputDirPrompt("src/contracts"),
            tokenNamePrompt(),
            tokenSymbolPrompt(),
            solcVersionPrompt(),
            licensePrompt(),
            addToContractsPrompt({
                message: "Add contract name to contracts.yaml?",
                defaultValue: false,
            }),
        ],
        actions: addWithUpdateContracts(
            "erc721.hbs",
            "{{outputDir}}/{{contractName}}.sol"
        ),
    })

    plop.setGenerator("erc1155", {
        description: "Generate a new ERC1155 multi-token contract",
        prompts: [
            contractNamePrompt(),
            outputDirPrompt("src/contracts"),
            {
                type: "input",
                name: "baseURI",
                message:
                    "Base URI for metadata (e.g., https://example.com/api/item/):",
                validate: (value: string) => {
                    if (!value || value.trim().length === 0) {
                        return "Base URI is required"
                    }
                    return true
                },
            },
            solcVersionPrompt(),
            licensePrompt(),
            addToContractsPrompt({
                message: "Add contract name to contracts.yaml?",
                defaultValue: false,
            }),
        ],
        actions: addWithUpdateContracts(
            "erc1155.hbs",
            "{{outputDir}}/{{contractName}}.sol"
        ),
    })

    plop.setGenerator("test", {
        description: "Generate a new Solidity test contract",
        prompts: [
            contractNamePrompt(),
            outputDirPrompt("test/foundry"),
            solcVersionPrompt(),
            licensePrompt(),
        ],
        actions: [
            addAction("soltest.hbs", "{{outputDir}}/{{contractName}}.test.sol"),
        ],
    })

    plop.setGenerator("deploy", {
        description: "Generate a new Solidity deploy script",
        prompts: [
            contractNamePrompt(),
            outputDirPrompt("script/foundry/deploy"),
            solcVersionPrompt(),
            {
                type: "confirm",
                name: "generateForkTest",
                message: "Generate fork test?",
                default: false,
            },
            licensePrompt(),
        ],
        actions: (data?: Answers): ActionType[] => {
            const actions = [
                addAction(
                    "soldeploy.hbs",
                    "{{outputDir}}/{{contractName}}.s.sol"
                ),
            ]

            if (data!.generateForkTest) {
                actions.push(
                    addAction(
                        "soldeployforktest.hbs",
                        "test/foundry/fork/Fork_Deploy{{contractName}}.test.sol"
                    )
                )
            }

            return actions
        },
    })

    plop.setGenerator("appstorage", {
        description: "Generate a new App Storage library",
        prompts: [
            contractNamePrompt(),
            storageDomainPrompt(),
            outputDirPrompt("src/contracts"),
            solcVersionPrompt(),
            licensePrompt(),
        ],
        actions: (data?: Answers): ActionType[] => {
            const storageDomain = data!.storageDomain as string
            const storageHash = keccak(storageDomain)

            return [
                {
                    type: "add",
                    path: "{{outputDir}}/{{contractName}}Storage.sol",
                    templateFile: ".templates/appstorage.hbs",
                    data: {
                        storageHash,
                        storageDomain,
                    },
                },
            ]
        },
    })

    plop.setGenerator("uups", {
        description: "Generate a new UUPS upgradeable contract",
        prompts: [
            contractNamePrompt(),
            outputDirPrompt("src/contracts"),
            solcVersionPrompt(),
            licensePrompt(),
            addToContractsPrompt(),
        ],
        actions: addWithUpdateContracts(
            "uups.hbs",
            "{{outputDir}}/{{contractName}}.sol"
        ),
    })

    plop.setGenerator("interface", {
        description:
            "Generate a new interface (automatically prepends 'I' to the name)",
        prompts: [
            interfaceNamePrompt(),
            outputDirPrompt("src/contracts"),
            solcVersionPrompt(),
            licensePrompt()
        ],
        actions: (data?: Answers): ActionType[] => {
            const actions = [
                addAction(
                    "interface.hbs",
                    "{{outputDir}}/{{interfaceName}}.sol"
                ),
            ]

            if (data!.addToContractsYaml) {
                actions.push(
                    modifyContractsYamlAction(data!.interfaceName as string)
                )
            }

            return actions
        },
    })

    plop.setHelper("loud", (v) => {
        return v.toUpperCase()
    })
}
