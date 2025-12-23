<div align="center">
  <img src="./assets/header.svg" alt="SHEFT - Solidity + Hardhat + Ethers + Foundry + Taskfile" />
</div>

## Solidity Scaffold Template (SHEFT)

This is a [scaffold](https://hay-kot.github.io/scaffold/introduction/quick-start.html) template for initializing a **SHEFT** ([Solidity](https://docs.soliditylang.org/en/v0.8.30/) + [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started) + [Ethers v6](https://docs.ethers.org/v6/) + [Foundry](https://getfoundry.sh/introduction/installation) + [Taskfile](https://taskfile.dev/)) stack.

There is an article on [SHEFT stack here](https://medium.com/@difof/introducing-sheft-stack-405f863071c9) which explains the why's and what's.

## Quickstart

Make sure you have the following installed:

- Git
- [Scaffold](https://hay-kot.github.io/scaffold/introduction/quick-start.html)
- [Foundry](https://getfoundry.sh/introduction/installation) (forge, cast)
- [Bun](https://bun.com/docs/installation) or [npm](https://nodejs.org/en/download)
- [Taskfile](https://taskfile.dev/installation/)

Scaffold a new project (you will be prompted):

```sh
# fetch SHEFT updates into cache
scaffold update
# without `run-hooks` the project will not be properly setup
scaffold new --run-hooks always https://github.com/difof/sheft
```

And you will have your new project ready to work with.

Add a new ERC20 token:

```sh
task new:erc20 # will prompt for necessary info
```

## What You Get

- Foundry and Hardhat configured to the same `src/contracts` and `test` layout
- OpenZeppelin and Solady pre-installed
- Ethers v6 with TypeChain output in `typechain/`
- Viem support
- Bun for TypeScript runner and package manager
- npm support if you choose it in the prompts
- ESLint + Prettier (TS), Forge lint/fmt (Solidity)
- Conventional Commits via commitlint (optional)
- Taskfile-powered workflows for build/test/deploy/verify/docs
- Optional `package/` sub-package exporting TypeChain + TS utils
- Example ERC20 and Merkle airdrop contracts with full coverage

## Project Structure

```text
<project>/
  foundry.toml
  hardhat.config.ts
  remappings.txt
  Taskfile.yaml
  src/
    contracts/
    ts/
  script/
    foundry/
      deploy/
  test/
    foundry/
    hardhat/
    ts/
  package/
  lib/
```

If enabled, `package/` re-exports `typechain` and utilities from `src/ts` and builds an ESM bundle via esbuild.

## Contributing

We follow Conventional Commits style. Note that commitlint is NOT used in this template repository; it is only included in projects generated from this template (when selected during scaffolding). Please format commits accordingly.

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- Examples:
  - `feat(token): add permit support`
  - `fix(airdrop): prevent double-claim`

### Template development workflow

Since this is a template project, apply changes directly to the templates under `{{ .Project }}` and validate them by generating a sandbox project.

1) Edit templates in `{{ .Project }}/...`.
2) From repo root, generate the default sandbox project under `sandbox/`:

```sh
task clean:sandbox
task sandbox         # generates sandbox/
cd sandbox
```

3) Run checks inside the sandbox (the generated project):

```sh
task fmt && task lint && task test:all
```

Iterate: adjust files in `{{ .Project }}`, re-run `task sandbox`, and repeat checks in `sandbox/`.

Tips:
- Use `task sandbox:prompt` to run the scaffold with prompts when you need non-default answers.
- Use `task clean:sandbox` to remove the `sandbox/` directory.

### Template best practices

- Keep templates DRY: avoid duplicating large snippets across files; prefer central helpers where possible.
- Validate output early and often: regenerate the sandbox frequently after small edits.
- Rely on the sandbox for IDE support: use IntelliSense, lint, and format in `sandbox/`, not in the template files.
- Prefer simple, explicit placeholders over clever generation logic; favor readability of the produced code.
- Make changes composable and incremental; avoid sweeping refactors without a sandbox build in between.
- Add and run tests in the generated project (`test/`) to guard template changes.
- Keep formatting consistent by letting the generated project’s linters/formatters rewrite files.

## TODO

- [x] `src/ts` docs
- [x] move inline JS from taskfile:wallet:import:mnemonic to dedicated file in `src/ts`
- [x] FIX: .env with RPC_URL, passed to commands
- [x] add `0x` prefix to keccak hash of `src/ts/keccak.ts`
- [x] Allow usage of either node/npm or bun, instead of just bun
- [x] Use proper `internal` tasks and `sh` execution for `{{.Project}}/Taskfile.yaml`
- [x] Add ABI JSON export to package, using yaml list in taskfile
- [x] Start empty without airdrop and token
- [x] Add viem
- [x] Smart contract and test templates
- [x] Fixes and improvements
  - [x] Check post hook script for some TODOs on more scaffold questions
  - [x] FIX task for ts and sol dependency installation
  - [x] Add docs for `{{ .Project }}/.templates/soldeploy.hbs`
  - [x] This readme's header need to specify npm and viem support (list just like the prompts)
  - [x] Different hardhat and anvil node RPC's and chainIds (hardhat.config.ts, Taskfile.yaml)
  - [x] fmt the files because in crosschain escrow the sol's fmt is not fmted
  - [x] copy plopfile and interface.hbs from crosschain escrow to here
- [ ] Add curl | sh installer script for dependencies
- [ ] Custom cursor rules and commands
  - taskfile usage
  - solidity files
  - solidity test
  - hardhat test
  - typescript test
  - plop and templates
  - foundry and hardhat configs
  - deploy scripts
  - audit
- [ ] Dedicated project contribution guideline file
  - issue template
  - discussion template
  - pr template
- [ ] Github actions
  - sheft docs builder and deployer
  - sandbox gen and test
- [ ] Dedicated merkle and keccak npm package
- [ ] Support Optimism (In Hardhat) and other EVM variants
  - mention somewhere in docs that zk based chains need a different set of foundry and hardhat stuff. I may need to setup hardhat configs for zk's but foundry is up to user to install.

## License

MIT