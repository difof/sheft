import type { NodePlopAPI, ActionType } from "plop"
import type { Answers } from "inquirer"
import { parse, stringify } from "yaml"
import { pascalCase } from "change-case"
import {
    existsSync,
    statSync,
    mkdirSync,
    readFileSync,
} from "fs"
import { resolve, join } from "path"

function contractNamePrompt(): ActionType {
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

function solcVersionPrompt(): ActionType {
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

function licensePrompt(): ActionType {
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


function outputDirPrompt(defaultDir: string): ActionType {
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
            {
                type: "confirm",
                name: "addToContractsYaml",
                message: "Add contract name to tasks/contracts.yaml?",
                default: true,
            },
        ],
        actions: addWithUpdateContracts(
            "contract.hbs",
            "{{outputDir}}/{{contractName}}.sol"
        ),
    })
}
