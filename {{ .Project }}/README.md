# {{ .Project }}

{{ .Scaffold.description }}

{{ if (.Scaffold.readme_sections | has "SHEFT general") }}
## What is SHEFT stack?
Quick rundown: this repo is a comfy starter for shipping smart contracts with a modern toolbelt.

- Foundry for blazing-fast Solidity dev and tests
- Hardhat + Ethers for TypeScript scripts, tooling and ABI/types
- Bun for fast JS/TS tooling
- Taskfile as your humane command palette

{{ end }}
