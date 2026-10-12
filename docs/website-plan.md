# Documentation website plan

## Intent

Build a public user manual for Linux Recovery Toolkit that combines an Astro Distro-inspired terminal landing page with conventional, navigable technical documentation.

The website is not a prerequisite for using the Bash scripts, and it must never execute recovery scripts in the visitor's browser or on the documentation build runner.

## Planned repository layout

```text
.
|-- scripts/              # Linux recovery scripts
|-- docs/                 # Existing Markdown recovery guides
|-- website/
|   |-- src/
|   |-- public/
|   |-- package.json
|   |-- astro.config.mjs
|   `-- LICENSES/        # Retained upstream theme attribution
|-- .github/workflows/
|   |-- shellcheck.yml
|   `-- pages.yml
`-- ROADMAP.md
```

Avoid duplicate, diverging copies of reference pages. Choose and document one primary location for authored Markdown as part of the implementation.

## Theme

- Theme: https://astro.build/themes/details/astro-distro/
- Upstream: https://github.com/ansango/astro-distro
- Upstream MIT license; retain its copyright and license notice in substantial adaptations.
- Adopt its terminal-styled visual components, navigation and responsive behavior where appropriate.
- Remove any fake machine status data or personal portfolio links and replace with real project navigation.
- Its Bun-based GitHub project synchronization is not required for stable static docs.
- Evaluate Astro Starlight compatibility before choosing it; do not assume it can be dropped into an existing customized theme unchanged.

## Navigation

- Home: project identity, principle, release status and Getting Started.
- Getting Started: requirements, installation, safe first audit.
- Tools: one page per Bash script, with privileges, options, examples, outputs, exit codes and limitations.
- Recovery Guides: audit, classification, backup, verify, encrypted HOME, preflight, reinstall and restore.
- Development: architecture, roadmap, changelog and contribution/testing instructions.

## GitHub Pages

Expected project URL: https://tidus747.github.io/linux-recovery-toolkit/

Astro must set `site` to `https://tidus747.github.io` and `base` to `/linux-recovery-toolkit` (for a repository project page). Ensure every asset and internal link respects the base.

Use GitHub Actions to validate the site in pull requests and deploy the generated static `dist/` after merging to `main`. GitHub repository Pages must be configured with GitHub Actions as the publishing source.

## Editorial and security rules

- Every command example is reviewed against the current corresponding script.
- Do not conflate file-content checksum comparisons with Linux metadata restore guarantees.
- Distinguish tested distributions/filesystems from plausible but untested ones.
- Use fictional and non-identifying sample paths and hostnames.
- Publish no generated `reports/`, SSH/GPG keys, private mounts, disk IDs or backups.
- Describe diagnostics before prescribing changes, and include verification and rollback for significant changes.

Tracking: https://github.com/tidus747/linux-recovery-toolkit/issues/5 and https://github.com/tidus747/linux-recovery-toolkit/issues/6
