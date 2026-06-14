# Changelog

## [1.0.0] - Unreleased

### Added

- Initial release: composite action that runs an OrchStep workflow,
  lint, or list-tasks in a single step.
- Inputs: `workflow`, `task`, `command`, `vars`, `vars-file`, `env`,
  `output`, `json-file`, `working-directory`, `version`, `extra-args`,
  `fail-on-error`.
- Outputs: `exit-code`, `summary`.
- `run` defaults to `--output plain` (CI-friendly logs); `output: json` and
  `json-file` expose the structured run result.
- Surfaces OrchStep's documented exit-code contract (3 = bad workflow,
  4 = assertion failed, 1 = step failed) and its GitHub `::error` annotations.
- Installs the OrchStep CLI automatically (bundled installer with SHA256
  checksum verification and binary caching).
