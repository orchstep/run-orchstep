# Changelog

## [1.1.0] - Unreleased

### Added

- `output` input (default `plain`, CI-friendly) and `json-file` input to expose
  the structured run result.
- Surfaces OrchStep's documented exit-code contract (3 = bad workflow,
  4 = assertion failed, 1 = step failed) and its GitHub `::error` annotations
  (provided by orchstep CLI v0.9.0+).

### Changed

- `run` now defaults to `--output plain` for CI-friendly logs (overridable via
  the `output` input or `extra-args`).

## [1.0.0] - 2026-05-20

### Added

- Initial release: composite action that runs an OrchStep workflow,
  lint, or list-tasks in a single step.
- Inputs: `workflow`, `task`, `command`, `vars`, `vars-file`, `env`,
  `working-directory`, `version`, `extra-args`, `fail-on-error`.
- Outputs: `exit-code`, `summary`.
- Installs the OrchStep CLI automatically (bundled installer with SHA256
  checksum verification and binary caching).
