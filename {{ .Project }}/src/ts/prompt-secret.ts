import { password, number } from "@inquirer/prompts"
import { writeFileSync } from "fs"

interface PromptConfig {
    required: boolean
    theme: {
        prefix: string
    }
}

interface KeystoreData {
    mnemonic: string
    accountIndex: number
}

async function promptForKeystoreData(): Promise<KeystoreData> {
    const promptConfig: PromptConfig = {
        required: true,
        theme: {
            prefix: ""
        }
    }

    const mnemonic = await password({
        message: "Enter 12 word mnemonic:",
        ...promptConfig
    })

    const accountIndex = await number({
        message: "Account index:",
        default: 0,
        ...promptConfig
    })

    return {
        mnemonic,
        accountIndex
    }
}

async function saveKeystoreData(data: KeystoreData): Promise<void> {
    const basePath = ".keystore/.tmp"

    writeFileSync(
        `${basePath}.mn`,
        data.mnemonic,
        "utf8"
    )

    writeFileSync(
        `${basePath}.mni`,
        data.accountIndex.toString(),
        "utf8"
    )
}

async function main(): Promise<void> {
    try {
        const keystoreData = await promptForKeystoreData()
        await saveKeystoreData(keystoreData)
    } catch (error) {
        if (error instanceof Error && error.name === "ExitPromptError") {
            process.exit(1)
        }
        throw error
    }
}

main()