import { nodeModulesPolyfillPlugin } from "esbuild-plugins-node-modules-polyfill"
import { build } from "esbuild"
build({
    bundle: true,
    outdir: "./dist",
    format: "esm",
    platform: "browser",
    entryPoints: ["./index.ts"],
    plugins: [
        nodeModulesPolyfillPlugin({
            modules: {
                buffer: true,
                events: true,
            },
        }),
    ],
})
