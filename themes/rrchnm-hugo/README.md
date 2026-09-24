# rrchnm-hugo

A plain-CSS Hugo theme carrying the RRCHNM brand (as on rrchnm.org and CRDH):
IBM Plex type, brand red `#C32A26`, stone grays, the RRCHNM affiliation line in
the header, and the dark RRCHNM/GMU footer. No Tailwind, no Node build step.

Requires Hugo 0.158.0 or newer.

## Site configuration

```toml
theme = 'rrchnm-hugo'

[params]
description = 'Used for the meta description when a page has none.'
affiliation = 'A publication of the'   # header text before the RRCHNM name (this is the default)
footer = 'Markdown shown in the footer, e.g. the license statement.'
copyright_start = 2018             # optional; renders "© 2018–<this year>"
matomo_site_id = 70                # optional; Matomo loads in production builds only

[[menus.main]]    # header navigation
name = 'About'
pageRef = '/about'

[[menus.footer]]  # footer links
name = 'Accessibility'
url = 'https://rrchnm.org/accessibility/'
```

Add site-specific styles in `assets/css/custom.css`. They're appended to the
theme stylesheet, so the variables in `assets/css/main.css` (`--red-brand`,
`--stone-*`, `--font-serif`, ...) are available.

## Pages

- **Single pages** show breadcrumbs, the title, and a byline when `author` is
  set. `author` can be one name or a list (`author = ['A', 'B']`). A table of contents appears when a page has two or more headings; set
  `toc = false` in front matter to turn it off.
- **Section and term lists** group pages by year and show a taxonomy sidebar.
- **Shortcodes:** `{{< recent-posts sortby="publishDate|lastMod" limit=5 section="blog" >}}`
  and `{{< terms-cloud terms="tags" sortby="count|alphabetical" >}}`.

## Search (Pagefind)

Create `content/search.md` with `layout = 'search'`. A Search link then shows
up in the header automatically. Build the index after Hugo runs:

```sh
hugo && npx -y pagefind --site public
```

Only page bodies (`data-pagefind-body`) are indexed. List pages, navigation,
and breadcrumbs are not. For `hugo serve`, write the index into `static/`
first: `npx -y pagefind --site public --output-path static/pagefind`.
