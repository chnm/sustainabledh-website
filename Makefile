PAGEFIND = npx -y pagefind@1.5.2

preview :
	@echo "Building the Pagefind search index ..."
	hugo --cleanDestinationDir --buildDrafts --buildFuture --quiet
	$(PAGEFIND) --site public --output-path static/pagefind
	@echo "Serving the preview site with Hugo ..."
	hugo serve --buildDrafts --buildFuture --disableFastRender

build :
	@echo "\nBuilding the site with Hugo ..."
	hugo --cleanDestinationDir --minify
	$(PAGEFIND) --site public
	@echo "Website finished building."

.PHONY : preview build
