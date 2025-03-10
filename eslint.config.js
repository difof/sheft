import { defineConfig } from "eslint/config"
import typescriptEslint from "@typescript-eslint/eslint-plugin"
import prettier from "eslint-plugin-prettier"
import { FlatCompat } from "@eslint/eslintrc"
import path from "path"
import { fileURLToPath } from "url"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const compat = new FlatCompat({
    baseDirectory: __dirname,
export default defineConfig([
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
