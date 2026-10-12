# Linux Recovery Toolkit website

Astro 7 + Tailwind 4 website inspired by [Astro Distro](https://github.com/ansango/astro-distro) (MIT). It is independent of the toolkit's Bash scripts.

## Develop

Requires Bun and Node.js >=22.12 (as required by upstream Astro Distro). Run inside `website/`:

```bash
bun install --frozen-lockfile
bun run dev
bun run build
```

Astro uses `site: https://tidus747.github.io` and `base: /linux-recovery-toolkit` for project Pages. Verify local links at `http://localhost:4321/linux-recovery-toolkit/`.

## Publish

The repo's `.github/workflows/pages.yml` builds on PRs and deploys on pushes to `main`. Enable GitHub Pages with **Settings > Pages > Build and deployment > Source: GitHub Actions**. After the successful deployment, visit https://tidus747.github.io/linux-recovery-toolkit/ .

The website is static, has no live system integrations, and must not publish generated `reports/` or any private backup or system inventory.

## Attribution

Styling and TUI components are adapted from Astro Distro by ansango under the MIT license. Required notice in `LICENSES/ASTRO-DISTRO-MIT.txt`. The toolkit is GPL-3.0. The site content is independent of runtime Linux scripts.

## Content structure

- `src/data/tool-reference.ts`: one structured reference entry for each v0.3 script.
- `src/pages/tools/[slug].astro`: static generated manual for each script.
- `src/data/recovery-guides.ts`: editorial recovery and privacy guidance.
- `src/pages/guides/[slug].astro`: static generated guide pages.

After a script changes, review its manual and safety caveats in the same PR. The documentation does not guarantee safe behavior for untested distributions or filesystems.
