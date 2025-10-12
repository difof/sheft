import { password, number } from "@inquirer/prompts"
import { writeFileSync } from "fs"

interface KeystoreData {
    mnemonic: string
    accountIndex: number
}

async function promptForKeystoreDataAsync(): Promise<KeystoreData> {
    const promptConfig = {
        required: true,
        theme: {
            prefix: "",
        },
    }

    const mnemonic = await password({
        message: "Enter 12 word mnemonic:",
        ...promptConfig,
    })

    const accountIndex = await number({
        message: "Account index:",
        default: 0,
        ...promptConfig,
    })

    if (accountIndex === undefined) {
        throw new Error("Account index is required")
    }

    return {
        mnemonic,
        accountIndex,
    }
}

function saveKeystoreData(data: KeystoreData) {
    const basePath = ".keystore/.tmp"

    writeFileSync(`${basePath}.mn`, data.mnemonic, "utf8")

    writeFileSync(`${basePath}.mni`, data.accountIndex.toString(), "utf8")
}

async function main(): Promise<void> {
    try {
        const keystoreData = await promptForKeystoreDataAsync()
        saveKeystoreData(keystoreData)
    } catch (error) {
        if (error instanceof Error && error.name === "ExitPromptError") {
            process.exit(1)
        }
        throw error
    }
}

main()
