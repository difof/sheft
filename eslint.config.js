import { defineConfig } from "eslint/config"
import typescriptEslint from "@typescript-eslint/eslint-plugin"
import prettier from "eslint-plugin-prettier"
import jslint from "@eslint/js"
import { FlatCompat } from "@eslint/eslintrc"
import path from "path"
import { fileURLToPath } from "url"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const { configs } = jslint
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: configs.recommended,
    allConfig: configs.all,
})

export default defineConfig([
    {
        ignores: [
            "**/node_modules/**",
            "**/coverage/**",
            "**/cache/**",
            "**/artifacts/**",
            "**/lib/**",
            "**/typechain/**",
            "**/docs/**",
            "**/package/**",
            "**/typechain/**",
        ],
    },
    // TypeScript files
    {
        plugins: {
            "@typescript-eslint": typescriptEslint,
            prettier,
        },
        extends: compat.extends(
            "eslint:recommended",
            "plugin:@typescript-eslint/recommended",
            "plugin:prettier/recommended"
        ),
        rules: {
            "prettier/prettier": "error",
        },
    },
])
