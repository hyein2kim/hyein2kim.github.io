# Project Notes

## Overview
- Repo: `hyein2kim.github.io`
- Workflow: Obsidian Vault (same repo) -> GitHub -> GitHub Actions (Jekyll 4) -> GitHub Pages
- Main sections:
  - `index.html` (About)
  - `publications.html`
  - `projects.html` (Projects listing, Jekyll collection-backed)
  - `abcd.html` (Field notes landing + tag filter, Jekyll collection-backed)

## Jekyll Setup
- Config file: `_config.yml`
- Collections:
  - `_abcd/` -> permalink `/abcd/:name/`
  - `_projects/` -> permalink `/projects/:name/`
- Layouts (assigned automatically by folder):
  - `_layouts/abcd_layout.html` (blog post detail)
  - `_layouts/project_layout.html` (project detail)
- Obsidian conversion and draft protection: `_plugins/obsidian.rb`
- Deployment: `.github/workflows/pages.yml` (Pages source must be set to GitHub Actions)

## Writing and Publishing (Obsidian)
- Open `/Users/hyeinkim/Documents/GitHub/hyein2kim.github.io` as the Obsidian vault.
- The repo is public, so anything committed can be read on GitHub even if it is not on the site.

1. Create a note. It starts in `_drafts/`, which is never committed.
2. Run the Obsidian command "Templates: Insert template" and choose `post`.
3. When it is ready, move the note to `_abcd/` or `_projects/` and turn on the `published` property.
4. Commit and push `main` with GitHub Desktop, then wait for the "Deploy site" action to finish.

To take down a published note, turn `published` off and push. The note stays readable in the repo.

### Front matter
```yaml
---
date: 2026-02-14
tags: [obsidian, jekyll]
published: true
# optional:
# title: "Shown instead of the file name"
# cover: /assets/project-cover.jpg   (projects only)
---
```
- `published` defaults to false: a note without `published: true` is not on the site.
- A note with no front matter is never published. The build log shows a warning.
- The title defaults to the file name. A note with no `date` uses the build time, so always set it.
- Future dates are published as usual.

### Supported Obsidian syntax
- `[[note]]`, `[[note|label]]`: matched by file name across `_abcd/` and `_projects/`.
  - `[[note#heading]]` links to the note, not the heading.
  - A link to an unpublished or missing note becomes plain text and logs a build warning.
- `![[image.png]]`, `![[image.png|caption]]`, `![[image.png|300]]`: pasted images are saved in `assets/images/`.
- `![[file.pdf]]` and `![[note]]`: become links, not embeds.
- `==highlight==`, `> [!type] title` callouts, footnotes.
  - Foldable callouts (`[!note]-`) always display open.
- `%%comment%%`: removed from the site, but still readable in the repo.
- A single line break stays a line break. `{{ }}` and `{% %}` display as written.
- Code blocks and inline code are never converted.

Not supported: Dataview, Canvas, and other features that only run inside Obsidian.

### Embedding a marimo notebook
```bash
marimo export html-wasm notebook.py -o assets/notebooks/<name> --mode run
```
```html
<iframe src="/assets/notebooks/<name>/" width="100%" height="600" loading="lazy"></iframe>
```
- An export is about 1,000 files and 33 MB, and all of it is committed. Add notebooks sparingly.
- `_config.yml` includes `_*.js` and `_*.css`, because Jekyll otherwise skips the `_` files in an export.
- It only loads from a server: use local preview or the live site.

## Key UI Decisions
- `abcd.html`
  - Hero section with sentence + custom `abcd` logo row
  - Tag filters for blog list (client-side JS)
  - Mobile spacing tuned in `style.css`
- Blog post detail
  - Centered rounded card
  - Order: title -> date -> tags -> content
  - Tags reuse `.abcd-tag` style
- Projects listing (`projects.html`)
  - 4-column tile grid on desktop (3-column under 1200px, 1-column mobile)
  - Tile shows title; optional cover image if `cover` exists
- Project detail
  - No rounded outer card
  - Order: title -> date -> topic(tags) -> content

## Important CSS Notes
- Main stylesheet: `style.css`
- There are multiple mobile media-query blocks; later rules can override earlier ones.
- For `abcd` spacing, effective mobile spacing is controlled by rules around:
  - `.abcd-page .abcd-hero`
  - `.abcd-list { margin-top: ... }`
- Note content styles (lists, tables, callouts, highlights) are at the end of the file.

## Local Preview
```bash
bundle exec jekyll serve --host 0.0.0.0 --port 4001
```
- Local URL: `http://127.0.0.1:4001`
- Local preview and the deployed site both use the Jekyll version in `Gemfile.lock`.

## Deployment Notes
- If live changes seem missing:
  1. confirm commit pushed to `main`
  2. check the "Deploy site" run in the Actions tab, and its log for `Obsidian:` warnings
  3. confirm the note has `published: true`
  4. hard refresh browser cache
