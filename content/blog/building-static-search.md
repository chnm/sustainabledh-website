+++
title = 'Building Static Search'
date = '2025-08-20T10:29:07-05:00'
author = 'Jason Heppler'
description = ''
tags = ['omeka', 'wordpress', 'drupal', 'static search']
categories = ['true stories']
toc = true
+++

One of the nice features of a [dynamic website](https://en.wikipedia.org/wiki/Dynamic_web_page)---the kind of thing that's often driven by databases---is the ability to run a search feature. Search is a feature across the various content management systems we use (or once used) at RRCHNM -- Omeka, Drupal, and Wordpress. But once a site is flattened and no longer reliant on a database for serving content, the built-in ability of search goes away. For many of our sites, the loss of this feature can be dismaying to users. So, a goal this summer was to figure out a way to implement search on a static site. 

We first started experimenting with the Project Endings [staticSearch](https://github.com/projectEndings/staticSearch) generator, but were immediately beset with a problem: their static search generator expected website DOM or XML to be valid and verified. As their [documentation explained](https://endings.uvic.ca/staticSearch/docs/howDoIUseIt.html), "The generator is expecting to parse _well-formed XHTML5 web pages_" (emphasis theirs). In many of the sites we fetched via `wget` this simply wasn't the case. I attempted to resolve this using a library called HTML Tidy resulting in this bash script that attempted to clean up the HTML before I sent the static search generator on an indexing path. Tidy HTML helped, but it didn't catch everything---and the manual process of cleaning up the problems would've taken an entire summer all on their own. So we had to pursue another approach.

Instead, I turned to a Javascript library called [MiniSearch](https://github.com/lucaong/minisearch). MiniSearch aims to handle both the indexing of content as well as providing the scaffolding for building a search page. In our case, we built this using its ability to do field extraction: within our HTML, we could look for typical HTML meta tags (like `<title>`) to capture page titles or use CSS selectors to grab elements on an HTML page where titles were otherwise held (for example, a CSS class like `.page-title`). Combined with MiniSearch's other features like fuzzy matching, tokenization, index boosting, and ability to add filters for different categories or tags, we had the ability to start building towards a new search. 

The workflow typically works in two phases. First, to keep it simple, we add MiniSearch's CDN to a new `search.html` page. This page is typically built off the index page simply by copying and pasting all of the content over and removing the content we don't want present on the search page. There's a bit of [custom CSS I developed](https://github.com/chnm/sustainability/blob/main/DEVNOTES.md#search-page-configuration) to build out a decent-looking search page, and in the new `search.html` page we add in the snippet of HTML that MiniSearch will look for to build the rest of the page when it loads. Finally, with a few lines of Javascript, we initialize MiniSearch and watch for input by the user. Any input that's provided triggers the search index we used MiniSearch to build. 

That is phase two: building the search index. This process takes the most amount of time, as well as some potential trial and error. To build an index, for each site we create a file called `update_search_index.js`, a simple node application designed to scan local directories for HTML files, parse them for titles, content, keywords, and tags, remove stopwords, and finally build a `search_index.json` file with the parameters we want to search by (typically, `title`, `content`, `keywords`, and `tags`.) This resulting `search_index.json` is the file MiniSearch uses to power its static search, so getting the content right in this file is our priority. 

We can take a closer look at one of the more complicated implementations that we did for [Children and Youth in History](https://cyh.rrchnm.org/index.html). CYH had three things we need to capture: the content, the type of content (case studies, teaching modules, primary sources, and website reviews), and categories. The content was simple enough: we had to look for anything that might refer to the main content area through a search that looked like this 

```js {linenos=inline}
const mainContent = $('#content, #primary, main, article').text() || $('body').text();
```

Content types were a little more complicated; thankfully, however, `wget` captured these content types as directories. With that in mind, we used this structure to [assign categories](https://github.com/chnm/sustainability/blob/9a8f4bc377f9fb5849c7d3c215f5cd1f2177b0f7/cyh/update_search_index.js#L123) like so 

```js
let contentType = 'Other';
// Is the directory "case-studies"? Then assign it Case Study, etc.
if (relativePath.startsWith('case-studies/')) {
  contentType = 'Case Study';
} else if (relativePath.startsWith('teaching-modules/')) {
  contentType = 'Teaching Module';
} else if (relativePath.startsWith('items/')) {
  contentType = 'Primary Source';
} else if (relativePath.startsWith('primary-sources/')) {
  contentType = 'Primary Source';
} else if (relativePath.startsWith('website-reviews/')) {
  contentType = 'Website Review';
}
```

Tags were also a bit complicated, but usually contained in a list element on the page that we could identify through a selector that looked for `#item-tags ul li` or `meta[name="keywords"]`. 

Once these content areas were identified, we could return the results that would compile the `search_results.json` file: 

```js
return {
  title,
  content,
  url: encodedRelativePath,
  tags: tags,
  contentType: contentType
};
```

The structure of this return is fairly straightforward: `title` refers to the `<title>` or a page's title that we captured through CSS selectors; content is, as noted above, anything that might've been a `<main>` or `<article>` or some CSS class or ID that we could use to capture the content; the URL is the path to the item (we had to encode this to get it to work correctly; these paths followed the `wget` capture and were easy to build); and, finally, the `tags` or `contentType` if any were provided. 

This portion of the project didn't necessarily rely on MiniSearch: we're able to generate the `search_results.json` into the kind of structure that MiniSearch expects to [build its search page](https://github.com/chnm/sustainability/blob/main/cyh/js/search.js), but building the index itself didn't require the use of MiniSearch. Ideally, we hope this means there's a kind of build-in longevity to this: if MiniSearch were to become unmaintained tomorrow, we'd still have the search index in a standard web data structure that would likely be readable by some other library (or, could easily be made into one). Even so, if we had to regenerate the structure our `update_search_index.js` application has already done the heavy lifting of finding content---we'd only have to update its output.

The one additional bit of customization we had to add to CYH is the search page itself. Most of the search pages we've implemented this summer across [Digital Campus](https://digitalcampus.tv), [Amboyna Conspiracy Trial](https://amboyna.org), [Maritime Asia](https://maritime-asia.org), [DoHistory](https://dohistory.org), [Object of History](https://objectofhistory.org), [Pilbara Strike](https://www.pilbarastrike.org), and [1989](https://1989.rrchnm.org) all follow the same minimal design: a search bar that fuzzy loads results as you type. CYH was slightly different: since it had categories, we wanted to provide a way for users to filter by those categories. That included some [custom CSS styling](https://github.com/chnm/sustainability/blob/9a8f4bc377f9fb5849c7d3c215f5cd1f2177b0f7/cyh/search.html#L105) to visually distinguish by content type, as well as provide [checkboxes to filter by content types and tags](https://github.com/chnm/sustainability/blob/9a8f4bc377f9fb5849c7d3c215f5cd1f2177b0f7/cyh/js/search.js#L203) (thus mimicking the kind of search feature that already existed in CYH).

To get this to all work together, the following components are required: 

- the MiniSearch library
- a `search.html` [page](https://github.com/chnm/sustainability/blob/main/cyh/search.html) that provides structure and waits for input by the user
- a `search.js` that [builds the search page and reads the search index](https://github.com/chnm/sustainability/blob/main/cyh/js/search.js#L203)
- a `update_search_index.js` that [generates the search index](https://github.com/chnm/sustainability/blob/main/cyh/update_search_index.js)
- two helpers: a `stopwords.txt` that we use for removing stopwords ([here](https://github.com/chnm/sustainability/blob/main/cyh/search/stopwords.txt)), and [a bash script](https://github.com/chnm/sustainability/blob/main/cyh/search/tidy.sh) that calls on [HTML Tidy](https://www.html-tidy.org) to systematically process all HTML files (this was no longer necessary using MiniSearch)
- as a quality of life improvement, a small [Makefile](https://github.com/chnm/sustainability/blob/main/cyh/Makefile) handled common tasks
- some clever find-and-replace across files. Adding a link to a search page in the navigation, for example, often meant firing up VSCode to use its search across files feature, searching the *exact* navigation as it existed and replacing it with the same content plus the link to the search page. As you might expect, this was not always a consistent experiment and took some trial and error to catch everything.

So, what's next? Now that we've deployed static search across several sites already this summer, we have plenty more to get to. We're trying next on our biggest site: the 9/11 Digital Archive. If we can get it working there, we won't have to worry about any other site.
