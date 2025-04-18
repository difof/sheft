import { build } from "esbuild"
build({
    bundle: true,
    outdir: "./dist",
    format: "esm",
    platform: "browser",
    entryPoints: ["./index.ts"],
})
