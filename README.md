# Run OrchStep

Run an [OrchStep](https://orchstep.dev) workflow, lint, or list-tasks on a
GitHub Actions runner in a single step. The action installs the OrchStep CLI
for you, so you do not need a separate setup step.

## Quick Start

```yaml
- uses: actions/checkout@v4
- uses: orchstep/run-orchstep@v1
  with:
    workflow: orchstep.yml
```

This installs the latest OrchStep release, verifies it, and runs the `main`
task of your `orchstep.yml` workflow.

## Inputs

| Input               | Description                                                          | Default                  |
| ------------------- | -------------------------------------------------------------------- | ------------------------ |
| `workflow`          | Path to the workflow file (relative to `working-directory`)          | _required_               |
| `task`              | Named task to run (run command only; default: the main task)         | `''`                     |
| `command`           | Subcommand: `run`, `lint`, or `list-tasks`                           | `run`                    |
| `vars`              | Multi-line `KEY=VALUE` pairs passed as `--var`                       | `''`                     |
| `vars-file`         | Path to a YAML vars file passed as `--vars-file`                     | `''`                     |
| `env`               | Environment name passed as `--env` (`dev`, `staging`, `production`)  | `''`                     |
| `output`            | Output format for `run`: `plain` (CI-friendly), `pretty`, or `json`  | `plain`                  |
| `json-file`         | Also write the structured run result (JSON) to this path             | `''`                     |
| `working-directory` | Directory to run from                                                | `${{ github.workspace }}`|
| `version`           | OrchStep CLI version to install: `latest` or a semver                | `latest`                 |
| `extra-args`        | Additional CLI arguments passed verbatim                             | `''`                     |
| `fail-on-error`     | Fail the action when the CLI exits nonzero                           | `true`                   |

When a run fails, the action's underlying CLI emits a GitHub `::error`
annotation (with file + line when available), so the failure shows up inline in
the checks UI. It also follows a documented [exit-code contract](https://orchstep.dev/spec/output/)
(`3` = bad workflow, `4` = assertion failed, `1` = step failed).

## Outputs

| Output      | Description                                  |
| ----------- | -------------------------------------------- |
| `exit-code` | The exit code returned by the OrchStep CLI   |
| `summary`   | The first 50 lines of CLI output             |

## Examples

### Run a workflow with vars and secrets

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: orchstep/run-orchstep@v1
        with:
          workflow: orchstep.yml
          task: deploy
          vars: |
            region=us-east-1
            api_token=${{ secrets.API_TOKEN }}
```

### Lint workflows on a pull request

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: orchstep/run-orchstep@v1
        with:
          command: lint
          workflow: orchstep.yml
```

### Matrix deploy across environments

```yaml
jobs:
  deploy:
    strategy:
      matrix:
        env: [dev, staging, production]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: orchstep/run-orchstep@v1
        with:
          workflow: orchstep.yml
          task: deploy
          env: ${{ matrix.env }}
```

### Replay a captured session as a PR regression gate

A workflow captured with `/orchstep-capture` can be replayed on every pull
request to catch regressions before they merge.

```yaml
jobs:
  regression:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: orchstep/run-orchstep@v1
        with:
          command: run
          workflow: .orchstep/captured-session.yml
```

### Scheduled run

```yaml
on:
  schedule:
    - cron: '0 6 * * *'

jobs:
  nightly:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: orchstep/run-orchstep@v1
        with:
          workflow: orchstep.yml
          task: nightly
```

## Security

The OrchStep CLI binary is verified against the SHA256 sums published in the
release's `checksums.txt` before it is installed; a missing or mismatched
checksum fails the action. Note that GitHub Actions step summaries are **not**
secret-masked, so any workflow or CLI output that echoes a secret value would
be visible on the run page. Ensure your workflows and the OrchStep CLI do not
print secret variable values.

## License

See [LICENSE](LICENSE).
