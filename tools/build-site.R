# Run from the repository root after installing this package.
# Optional argument: --library PATH selects an existing R package library.
args <- commandArgs(TRUE)
if (length(args)) {
  if (length(args) != 2L || args[[1L]] != '--library')
    stop('Usage: Rscript tools/build-site.R [--library PATH]')
  .libPaths(c(normalizePath(args[[2L]], mustWork = TRUE), .libPaths()))
}
stopifnot(file.exists('DESCRIPTION'), file.exists('_pkgdown.yml'))
library(postrank)
stopifnot(as.character(packageVersion('postrank')) == unname(read.dcf('DESCRIPTION')[1L, 'Version']))
current <- jsonlite::read_json('inst/extdata/manifests/cache-manifest.json')
installed <- jsonlite::read_json(system.file('extdata', 'manifests', 'cache-manifest.json',
  package = 'postrank', mustWork = TRUE))
stopifnot(identical(current$source_id, installed$source_id))
# Rebuild the output directory because exported HTML has no build-marker comments.
pkgdown::clean_site('.')
pkgdown::build_site('.', new_process = FALSE, install = FALSE, preview = FALSE,
  examples = TRUE, run_dont_run = FALSE)
source('tools/finish-site.R')
finish_vignette_guide()
exclude_local_maintenance_pages()
localize_search_navigation()
finish_local_site()
link_local_figures()
apply_local_site_css()
localize_alias_redirects()
clean_site_headers()
unlink(file.path("docs", "llms.txt"))
invisible(file.create(file.path('docs', '.nojekyll')))
