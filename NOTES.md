# Project Notes

## Overview
- Repo: `hyein2kim.github.io`
- Workflow: Obsidian Vault (same repo) -> GitHub -> GitHub Pages (Jekyll)
- Main sections:
  - `index.html` (About)
  - `publications.html`
  - `projects.html` (Projects listing, Jekyll collection-backed)
  - `abcd.html` (Field notes landing + tag filter)

## Jekyll Setup
- Config file: `_config.yml`
- Collections:
  - `abcd` -> permalink `/abcd/:name/`
  - `projects` -> permalink `/projects/:name/`
- Layouts:
  - `_layouts/abcd_layout.html` (blog post detail)
  - `_layouts/project_layout.html` (project detail)

## Content Locations (Obsidian)
- Blog notes: `abcd/*.md`
- Projects notes: `_projects/*.md`

### Required front matter (abcd)
```yaml
---
title: "My First Post"
date: 2026-02-14
layout: abcd_layout
tags: [obsidian, jekyll]
---
```

### Required front matter (projects)
```yaml
---
title: "First Project"
date: 2026-02-14
layout: project_layout
tags: [urban, data]
# optional:
# cover: /assets/project-cover.jpg
---
```

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

## Local Preview
```bash
bundle exec jekyll serve --host 0.0.0.0 --port 4001
```
- Local URL: `http://127.0.0.1:4001`

## Deployment Notes
- GitHub Pages build can exclude future-dated content.
- Keep note/project `date` as today or past for immediate visibility.
- If live changes seem missing:
  1. confirm commit pushed
  2. check Actions/Pages deployment status
  3. hard refresh browser cache

## Recent Commits (high-level)
- `cf5408e`: mobile spacing tune for `abcd`
- `ba5f3d1`: projects grid layout + heading alignment
- `179e60f`: projects collection and layouts
- `148084d`: post layout + mobile typography consistency
- `1863269`: `abcd` hero/hover refinements
