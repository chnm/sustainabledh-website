+++
title = 'Adding a Static Search to Former CMS Sites'
date = '2025-08-20T09:24:34-05:00'
author = 'Savannah Scott'
description = 'Implementing static search on former content management system websites.'
tags = ["omeka","drupal","wordpress","static search"]
categories = []
toc = true
+++

As part of [RRCHNM](http://rrchnm.org)'s sustainability efforts, we are flattening websites built with content management systems (CMS). In this context, "flattening" refers to the conversion of dynamic, database-based websites to static, simplistic versions. A flat website is built only with HTML, CSS, and JavaScript. Flattening websites involves accepting different trade-offs. While the flattened versions save server space and reduce security threats, they lose dynamic features such as queries or user-input. A search function is a key site feature that is lost with flattening. [A static site search remedies this](https://sustainabledh.org/blog/building-static-search/).

This blog post will explain the differences between implementing static site search across different CMSes, namely [Drupal](https://new.drupal.org/drupal-cms), [Omeka](https://omeka.org/), and [WordPress](https://wordpress.com/). First, we will walk through the general process of adding a static site search feature to a flat website. Then, we will discuss the tweaks needed to optimize the search's performance for each CMS file structure. A basic understanding of HTML would be helpful for this blog post but is not required.

## Implementing Static Search

The following was adapted from [development notes](https://github.com/chnm/sustainability/blob/main/DEVNOTES.md) written by Jason Heppler.

1.  Before starting, ensure the following dependencies are installed:

    [Node.js](https://nodejs.org/en) (v12+) and [npx](https://docs.npmjs.com/cli/v8/commands/npx).

2.  File Set Up
    - Create a search directory at the root of the project. This will contain the search page template.
    - Create a static-search directory at the root of the project. This will contain utility files like [stopwords](https://github.com/chnm/sustainability/blob/main/digitalcampus/static-search/stopwords.txt) and an HTML [tidying script](https://github.com/chnm/sustainability/blob/main/digitalcampus/static-search/tidy.sh).
    - Copy over `update_search.sh`, `update_search_index.js`, and the `Makefile`.
        - [update_search.sh](https://github.com/chnm/sustainability/blob/main/digitalcampus/update_search.sh): bash script to orchestrate the search index generator.
        - [update_search_index.js](https://github.com/chnm/sustainability/blob/main/digitalcampus/update_search_index.js): Node.js script that processes HTML files to create the search index.
        - [Makefile](https://github.com/chnm/sustainability/blob/main/digitalcampus/Makefile): contains shortcuts for common operations.
    - Create an `index.html` file in the search directory.
        - You can do this in multiple ways. If your site already has a search page, this can be moved to the search directory (and renamed to `index.html` if needed)
        - This can be copied from another `index.html` file in the root directory.
3.  Configure the search page.
    - Add the [MiniSearch](https://lucaong.github.io/minisearch/index.html) CDN to the `<header>` of the page.
    - Add CSS styling for the search results int the `<header>` of the search page.
    - Create the search area with HTML. This should be the only main content on this page.
    - Add JavaScript that powers the search functionality to the bottom of the page before the closing `</body>` tag.
    - You will need to edit the navigation throughout the site to get to the search page. This can be done by adding a search link to the current navigation. The easiest way to achieve this is through a files-wide search and replace feature found in most IDEs like [Visual Studio Code](https://code.visualstudio.com/).
4.  Search Index Generation
    - `update_search_index.js` is the main script that:
        - Scans for all HTML files in the project
        - Extracts titles, content, and tags from each file
        - Removes stopwords to improve search quality.
        - Deduplicates content when the same page appears with different URLs.
        - Creates a JSON file with all indexed content.
    - This is the file that will need editing depending on the former CMS.
    - Stopwords are defined in static-search/stopwords.txt. Stopwords are common words like "the," "and," "or" that are removed to improve search relevance.
5.  Running the Build Process
    - To generate the search index run: `node update_search_index.js`
        - This generates a `search-documents.json` file inside a `js` folder, which MiniSearch will load for the search function.

Now that the static search function is set-up, we can tweak and optimize it for specific CMS. The main differences between CMSes are their file structure and their HTML page structure. We will now explore these differences and discuss how to integrate them into our static search.

## Working With Former Drupal Sites

Flattened Drupal websites, which can be captured with command line tools like wget, have five distinct directories: content, misc, modules, node, and sites. How do these folders relate to our static search?

- Content
  - This directory is where the majority of the website's pages are
    held. It could be renamed as archive, exhibits, etc.
  - We want our search index generator to look through this directory
    and parse its HTML pages.
- Misc
  - This directory contains miscellaneous files, such as the favicon and
    jQuery files.
  - This directory can be ignored by our search index generator.
- Modules
  - This directory contains CSS files for the node directory.
  - This directory can be ignored by our search index generator.
- Node
  - This directory is essentially a copy of the content directory. For
    every file in content, there is a replicated file in node except the
    filename contains a number (for example, `2.html`).
  - Because we do not want duplicate search results, we can ignore this
    directory when working with our search index generator.
- Sites
  - This directory includes the necessary files for the website to run.
    It includes CSS files, JavaScript files, and icon images.
  - Because this directory is not visible to a website user, it can be
    ignored by our search index generator.

What does it mean for our search index generator to ignore our directory? It means that we can exclude file paths in our script, and those files will not be included in our search index. When building a search index, we only want to include webpages users can access and eliminate duplicate results.

We do this with lists. In `update_search_index.js`, we can edit the excludeDirs and excludePatterns lists to include directories or file patterns, respectively, that we want to ignore.

Now that we know what files and directories we want to include and exclude, we can turn our attention to the content and structure of the webpages themselves. In our script, there are four main types of elements we identify with HTML selectors: the main content of the page, the page's title, an additional heading, and elements to remove.

- Content
  - These selectors are used to extract the main content from a webpage. This is where much of our searchable text will come from.
  - Examples of main content selectors commonly used by Drupal are:
    - `.entry-content`
    - `.post-content`
    - `.view-content`
    - `.l-main`
- Title
  - These selectors extract the titles of webpages typically via the `<title>` markup but can also be modified as we do below. This will also be what users will see in the search results. It is important for the titles to be accurate, and as descriptive and unique as possible.
  - Example of title selectors commonly used by Drupal are:
    - `.post-title`
    - `.entry-title`
- Additional Heading
  - These selectors are prepended on our title if they are found. While not always needed, they can be helpful for creating unique titles if pages have repeated information.
  - Examples of additional heading selectors:
    - `h2.subtitle`
    - `.subtitle`
- Remove
  - These selectors are elements we want to remove from HTML pages before extracting content our search results. These will be elements that are found on every webpage and are not unique to a specific webpage.
  - Examples of elements to remove:
    - `header`
    - `footer`
    - `.sidebar`
    - `.navigation`
    - `.comments`
    
Finding the most accurate and efficient selector can be tricky. If an element does not have a consistent and unique class or id, the selector may be less obvious. If you are unsure of an appropriate selector from simply the HTML, you may need to use your browser's developer tools. This can be done by opening the desired webpage, right clicking, choosing inspect. This pane will show the webpage's HTML code. Find the element you want to identify, right click, hover over copy, and click copy selector. This should be a unique selector or selector path to identify the element, and it can be copied into the script. You may have to enable your developer tools for Chrome, Safari, or Firefox.

Drupal's consistent use of specific classes for certain elements can make selector searching a little easier. By utilizing the structure of both Drupal's file and HTML structure, we can more easily implement static search into a flattened Drupal site.

## Working With Former Omeka Sites

Like former Drupal sites, former Omeka sites have a distinct directory layout. The exact directory structure will vary by website, but most Omeka sites will have an exhibit directory and an items directory. This is where much of the site content will be. An Omeka site will have a number of directories for CSS, JavaScript, and other necessary files (such as admin, shared, or themes folders), which can be ignored for our search function.

Omeka's exhibits and items directories are not as straightforward as Drupal's. The main issue is the duplication of content. For example, a digital exhibit (under the exhibits directory) may contain an introduction, essays, teaching materials, and relevant primary sources. However, because of how `wget` fetches pages, these primary sources can also be found in the broader collection and have a webpage under the items directory. This creates the issue of having the same primary source accessible from two different places, which could create confusion for a user using our search function. To remedy this, we must exclude specific directories. Following our example, we could add "exhibits/example-exhibit/primary-sources/" to our `excludeDirs` list, and the items in that directory will be ignored.

Collection items are also duplicated in the items directory. Omeka's items directory has a browse and show directory. The browse directory includes tags and pages for browsing the content. These pages list and provide a preview of multiple items. While this is a helpful feature for users, it is less helpful for searching. Instead of a keyword matching to a specific webpage, it would also match these browse pages, creating an extra step for the searcher. Ignoring the items/browse directory solves this issue.

Like Drupal, Omeka utilizes certain selectors for its HTML elements. A key difference between Omeka and Drupal is that Omeka uses IDs (denoted with `#`) instead of classes (identified with `.`). When working with Omeka sites, there was more inconsistency in the IDs used to style page titles. This could be due to different HTML structures for different pages, or the use of Omeka themes. Whatever the origin, I was often required to use selector paths and verify these paths through my browser's developer tools. For example, when working with the 1989 site, `#primary-source > h3`, `#exhibit-title`, `#title > a\`, `body > h2`, `#primary > h2` were all used to identify a webpage's title. The most likely selectors are listed first since the script will move on to the next action once title content has been found (even if it is not the right information). Finding the right selectors for Omeka might take some testing, which is why I recommend familiarizing yourself with your browser's developer tools.

A small issue with former Omeka sites is that they can include a short line in the footer that states "Powered by Omeka." Once a website is flattened, this statement is no longer true. There are a few different ways to address this. This statement can be edited to say, "Formerly powered by Omeka," the statement can be deleted from the footer and moved to an About page, or it can be deleted entirely. The website's sustainability team or owner can decide this.

Flattened Omeka sites are also prone to a particular bug. The JavaScript libraries used in Omeka can override MiniSearch. This can be a frustrating error, as MiniSearch (ready to go with a search bar and search index) will not work and console produces no error messages. If this happens, comment out the JavaScript libraries found within the `<head>` tag. I recommend doing this one-by-one to preserve any other functionality, and to target the problem scripts directly. If this does not work, try other debugging methods.

## Working With Former WordPress Sites

Like the other CMSes, former WordPress sites have a unique file structure. In addition to your site-specific content folders, other directories include `category/`, `feed/`, `images/`, `page/`, `ui/j`, `wp-content/`, `wp-includes/`, `wp-json/`. The `feed/`, `wp-json/`, `wp-includes/`, and `category/` directories can be excluded. Depending on the specificity of your directory structure, you can content type map based on your directory patterns. We can content map these directories by creating a dictionary with directory names and content types. For example, the Digital Campus flattened site had a directory for each year of the podcast, containing a different webpage for each episode. Content mapping for this resembles `{ "2007/": "Podcast", "2008/": "Podcast", "category/": "Category"}`. This is useful for creating more detailed search results and organization.

WordPress selectors use a combination of classes and element types to effectively query the HTML document. Here are examples of selectors for a script traversing a former WordPress site:

- Content selectors
  - `#content`
  - `#primary`
  - `main`
  - `.entry-content`
  - `.post-content`
- Title selectors`
  - `title`
  - `h1`
  - `.post-title`
  - `.entry-title`
- Additional heading selectors
  - `#item-text h3`
  - `h2.subtitle`
- Elements to remove
  - `.navigation`
  - `.comments`
  - `.widget-area`
  - `.sidebar`

As with the other CMSes, selectors can vary based on HTML structure, themes, and personal naming conventions. Remember to double check with a live webpage and your browser's developer tools.

Each CMS comes with different conventions to navigate when creating a static search for a flattened site. Once you understand the directory and file structure, you can unlock the nuances to build a robust static site search.
