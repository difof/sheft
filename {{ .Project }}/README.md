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

{{ if (.Scaffold.readme_sections | has "Stack stats") }}
## Project stats
- Solidity compiler: `{{ .Scaffold.solc_version }}`
- Target EVM: `{{ .Scaffold.evm_version }}`
- Has package subfolder (SDK exports): `{{ .Scaffold.should_package }}`

Key files and tools you’ll touch:
- `remappings.txt`, `lib/README.md` (Solidity libs)
- `hardhat.config.ts` (Hardhat configuration)
- `Taskfile.yaml` (your shortcuts)
{{ end }}
