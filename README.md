## Solidity Scaffold Template (SHEFT)

This is a [scaffold](https://hay-kot.github.io/scaffold/introduction/quick-start.html) template for initializing a **SHEFT** ([Solidity](https://docs.soliditylang.org/en/v0.8.30/) + [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started) + [Ethers v6](https://docs.ethers.org/v6/) + [Foundry](https://getfoundry.sh/introduction/installation) + [Taskfile](https://taskfile.dev/)) stack.

There is an article on [SHEFT stack here](https://difof.medium.com/) which explains the why's and what's.

## Quickstart

Make sure you have the following installed:

- Git
- [Scaffold](https://hay-kot.github.io/scaffold/introduction/quick-start.html)
- [Foundry](https://getfoundry.sh/introduction/installation) (forge, cast)
- [Bun](https://bun.com/docs/installation)
- [Taskfile](https://taskfile.dev/installation/)

Scaffold a new project (you will be prompted):

```sh
scaffold new --run-hooks always https://github.com/difof/sheft
```

And you will have your new project ready to work with.

## What You Get

- Foundry and Hardhat configured to the same `src/contracts` and `test` layout
- OpenZeppelin and Solady pre-installed
- Ethers v6 with TypeChain output in `typechain/`
- Bun for TypeScript runner and package manager
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

- [ ] Allow usage of either node/npm or bun, instead of just bun
- [ ] Add viem
- [ ] Start empty without airdrop and token
- [ ] Smart contract and test templates
- [ ] Custom cursor rules and commands
- [ ] Support Optimism (In Hardhat) and other EVM variants

## License 

MIT