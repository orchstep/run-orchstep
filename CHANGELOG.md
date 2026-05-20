# Changelog

## [Unreleased]

### Added

- Initial release: composite action that runs an OrchStep workflow,
  lint, or list-tasks in a single step.
- Inputs: `workflow`, `task`, `command`, `vars`, `vars-file`, `env`,
  `working-directory`, `version`, `extra-args`, `fail-on-error`.
- Outputs: `exit-code`, `summary`.
- Installs the OrchStep CLI automatically (bundled installer with SHA256
  checksum verification and binary caching).
