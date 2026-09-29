# Sustainable DH

Source for [sustainabledh.org](https://sustainabledh.org), documentation and resources for sustaining digital humanities projects from the [Roy Rosenzweig Center for History and New Media](https://rrchnm.org) (RRCHNM).

The site is built with [Hugo](https://gohugo.io) and uses [Pagefind](https://pagefind.app) for search.

## Requirements

- Hugo **extended**, 0.158.0 or newer (production builds use 0.161.1)
- Node.js, only to run Pagefind through `npx`. The site has no npm dependencies.

## Local development

```sh
make preview
```

This builds the Pagefind search index into `static/pagefind/` and then starts `hugo serve` with drafts and future-dated posts included, at <http://localhost:1313>. Search works once the index is built; run `make preview` again to pick up new pages in search results.

If you don't need search, `hugo serve --buildDrafts --buildFuture` is enough.

To make a production build in `public/`:

```sh
make build
```

## Writing content

Content lives in `content/`:

| Path | Page |
| --- | --- |
| `content/_index.md` | Homepage |
| `content/blog/` | True Stories posts (published at `/blog/`) |
| `content/protocols.md` | Reusable Protocols |
| `content/resources.md` | Resources |
| `content/about.md` | About |

### New True Stories posts

```sh
hugo new content blog/2026-10-01-short-slug/index.md
```

This uses `archetypes/blog.md`, which starts the post as a draft. Fill in the front matter:

```toml
title = 'Post Title'
date = '2026-10-01T10:00:00-05:00'
draft = true          # remove or set to false to publish
authors = ['First Last', 'Second Author']
description = 'One sentence used for search engines and link previews.'
tags = ['omeka', 'engineering']
categories = ['true stories']
toc = true            # table of contents; appears when a post has 2+ headings
```

Put images for a post in the same folder as its `index.md`.

### Downloadable files

Protocol documents and other downloads go in `static/files/` and are served from `/files/...`.

## Theme and customization

The theme, `themes/rrchnm-hugo`, carries the RRCHNM brand and is shared with other RRCHNM sites. Its [README](themes/rrchnm-hugo/README.md) documents its configuration and features.

Prefer customizing this site without editing the theme:

- **Styles:** add rules to `assets/css/custom.css`. They're appended to the theme stylesheet and can use its variables (`--red-brand`, `--stone-*`, `--font-serif`, …).
- **Templates:** copy a theme template to the same path under `layouts/` and edit the copy. Hugo uses the site's version instead of the theme's.
- **Shortcodes:** site-specific shortcodes live in `layouts/shortcodes/`.
- **Navigation, footer links, and taxonomies** are configured in `hugo.toml`.
