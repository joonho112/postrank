# Finish native MathML and example-image alternatives for pkgdown2.2 reference HTML.
# This maintainer step changes generated HTML only. It never solves, evaluates
# a grading, modifies R sources/Rd or downloads resources. Run after build_site.
finish_local_site <- function(site = 'docs', alt_file = 'pkgdown/reference-image-alt.json') {
  stopifnot(requireNamespace('xml2', quietly = TRUE), requireNamespace('rmarkdown', quietly = TRUE))
  site <- normalizePath(site); alts <- jsonlite::read_json(alt_file, simplifyVector = TRUE)
  escaped <- function(s) {
    s <- gsub('&', '&amp;', s, fixed = TRUE)
    s <- gsub('<', '&lt;', s, fixed = TRUE)
    gsub('>', '&gt;', s, fixed = TRUE)
  }
  cache <- new.env(parent = emptyenv())
  convert <- function(tex) {
    if (exists(tex, cache, inherits = FALSE)) return(get(tex, cache, inherits = FALSE))
    inp <- tempfile(fileext = '.md'); out <- tempfile(fileext = '.html')
    on.exit(unlink(c(inp, out)), add = TRUE)
    # Pandoc's math reader needs the modern equivalent of legacy TeX's
    # grouped Roman-font declaration; this changes typography syntax only.
    canonical <- gsub(r"(\{\\rm\s+([^{}]+)\})", "{\\\\mathrm{\\1}}", tex, perl = TRUE)
    writeLines(enc2utf8(canonical), inp, useBytes = TRUE)
    rmarkdown::pandoc_convert(inp, from = 'markdown+tex_math_single_backslash', to = 'html',
      output = out, options = '--mathml')
    h <- xml2::read_html(out, encoding = 'UTF-8')
    math <- xml2::xml_find_all(h, './/math')
    if (length(math) != 1L) stop('Native MathML conversion failed for: ', tex)
    value <- as.character(math[[1L]])
    assign(tex, value, cache); value
  }
  pattern <- r"(\\\([\s\S]*?\\\)|\\\[[\s\S]*?\\\]|\$\$[\s\S]*?\$\$)"
  receipts <- list(); used <- character()
  for (file in sort(list.files(file.path(site, 'reference'), '\\.html$', full.names = TRUE))) {
    doc <- xml2::read_html(file, encoding = 'UTF-8')
    added_alt <- 0L; converted <- 0L
    for (img in xml2::xml_find_all(doc, './/img')) {
      src <- xml2::xml_attr(img, 'src'); key <- basename(src)
      if (!is.null(alts[[key]])) {
        xml2::xml_set_attr(img, 'alt', alts[[key]]); used <- c(used, key); added_alt <- added_alt + 1L
      }
    }
    nodes <- xml2::xml_find_all(doc, './/text()[not(ancestor::code or ancestor::pre or ancestor::script or ancestor::style or ancestor::math)]')
    for (node in nodes) {
      text <- xml2::xml_text(node)
      matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
      if (matches[1L] < 0L) next
      lens <- attr(matches, 'match.length'); pieces <- character(); cursor <- 1L
      for (i in seq_along(matches)) {
        start <- matches[[i]]; finish <- start + lens[[i]] - 1L
        if (start > cursor) pieces <- c(pieces, escaped(substr(text, cursor, start - 1L)))
        pieces <- c(pieces, convert(substr(text, start, finish)))
        cursor <- finish + 1L; converted <- converted + 1L
      }
      if (cursor <= nchar(text)) pieces <- c(pieces, escaped(substr(text, cursor, nchar(text))))
      fragment <- xml2::read_html(paste0('<span>', paste0(pieces, collapse = ''), '</span>'), encoding = 'UTF-8')
      replacement <- xml2::xml_find_first(fragment, './/body/span')
      xml2::xml_replace(node, replacement)
    }
    if (added_alt || converted) xml2::write_html(doc, file, encoding = 'UTF-8')
    if (added_alt || converted) receipts[[basename(file)]] <- list(example_alternatives = added_alt, native_mathml_added = converted)
  }
  stopifnot(setequal(unique(used), names(alts)))
  total_math <- 0L; remaining <- 0L
  for (file in list.files(file.path(site, 'reference'), '\\.html$', full.names = TRUE)) {
    doc <- xml2::read_html(file, encoding = 'UTF-8')
    total_math <- total_math + length(xml2::xml_find_all(doc, './/math'))
    text <- xml2::xml_text(xml2::xml_find_all(doc, './/text()[not(ancestor::code or ancestor::pre or ancestor::script or ancestor::style or ancestor::math)]'))
    remaining <- remaining + sum(grepl(pattern, text, perl = TRUE))
  }
  stopifnot(remaining == 0L)
  list(reference_pages_changed = length(receipts), reference_example_alternatives = length(used),
    unique_formulas_converted_this_run = length(ls(cache, all.names = TRUE)),
    native_reference_mathml_total = total_math, unconverted_reference_math_nodes = remaining, pages = receipts,
    method = 'Rendered reference HTML only; UTF-8 Pandoc native MathML; explicit source-controlled image descriptions.')
}

link_local_figures <- function(site = 'docs') {
  site <- normalizePath(site); linked <- list()
  for (file in sort(list.files(site, '\\.html$', recursive = TRUE, full.names = TRUE))) {
    doc <- xml2::read_html(file, encoding = 'UTF-8'); count <- 0L
    for (img in xml2::xml_find_all(doc, './/img')) {
      src <- xml2::xml_attr(img, 'src'); alt <- xml2::xml_attr(img, 'alt')
      classes <- xml2::xml_attr(img, 'class')
      if (is.na(alt) || !nzchar(alt) || (!is.na(classes) && 'logo' %in% strsplit(classes, ' ')[[1L]]) ||
          grepl('^[a-zA-Z]+:|^//', src) || length(xml2::xml_find_all(img, 'ancestor::a'))) next
      stopifnot(file.exists(file.path(dirname(file), src)))
      xml2::xml_add_parent(img, 'a', href = src, class = 'figure-full-size',
        title = 'Open full-size figure', `aria-label` = paste('Open full-size figure:', alt),
        target = '_blank', rel = 'noopener')
      anchor <- xml2::xml_parent(img)
      caption <- xml2::xml_add_sibling(anchor, 'span', class = 'figure-full-size-link d-block small')
      link <- xml2::xml_add_child(caption, 'a', href = src, target = '_blank', rel = 'noopener',
        `aria-label` = paste('Open full-size figure:', alt))
      xml2::xml_set_text(link, 'Open full-size figure'); count <- count + 1L
    }
    if (count) {
      xml2::write_html(doc, file, encoding = 'UTF-8')
      linked[[substring(file, nchar(site) + 2L)]] <- count
    }
  }
  list(figures_linked_this_run = sum(unlist(linked)), pages = linked,
    purpose = 'Open the local PNG at original resolution for mobile inspection; no JS or remote resources.')
}

apply_local_site_css <- function(site = 'docs', css = 'pkgdown/extra.css') {
  site <- normalizePath(site); stopifnot(file.copy(css, file.path(site, 'extra.css'), overwrite = TRUE))
  linked <- character()
  for (file in list.files(site, '\\.html$', recursive = TRUE, full.names = TRUE)) {
    if (basename(file) == '404.html') next
    doc <- xml2::read_html(file, encoding = 'UTF-8')
    hrefs <- xml2::xml_attr(xml2::xml_find_all(doc, './/head/link'), 'href')
    if (any(grepl('(^|/)extra\\.css$', hrefs))) next
    relative <- substring(file, nchar(site) + 2L); dir <- dirname(relative)
    depth <- if (dir == '.') 0L else length(strsplit(dir, '/', fixed = TRUE)[[1L]])
    xml2::xml_add_child(xml2::xml_find_first(doc, './/head'), 'link', rel = 'stylesheet',
      href = paste0(strrep('../', depth), 'extra.css'))
    xml2::write_html(doc, file, encoding = 'UTF-8'); linked <- c(linked, relative)
  }
  list(stylesheet = 'extra.css', sha256 = digest::digest(file = css, algo = 'sha256'),
    pages_linked_this_run = linked, purpose = 'Apply the site stylesheet and preserve readable formulas on narrow screens.')
}

localize_alias_redirects <- function(site = 'docs', canonical_url = yaml::read_yaml('_pkgdown.yml')$url) {
  site <- normalizePath(site); stopifnot(is.character(canonical_url), length(canonical_url) == 1L)
  if (!endsWith(canonical_url, '/')) canonical_url <- paste0(canonical_url, '/')
  changed <- list()
  for (file in list.files(site, '\\.html$', recursive = TRUE, full.names = TRUE)) {
    doc <- xml2::read_html(file, encoding = 'UTF-8')
    metas <- xml2::xml_find_all(doc, './/meta')
    eq <- xml2::xml_attr(metas, 'http-equiv'); refresh <- metas[!is.na(eq) & tolower(eq) == 'refresh']
    for (node in refresh) {
      content <- xml2::xml_attr(node, 'content')
      target <- sub('^[^;]*;[[:space:]]*URL=', '', content, ignore.case = TRUE)
      if (!startsWith(target, canonical_url)) next
      dest <- substring(target, nchar(canonical_url) + 1L)
      path <- strsplit(dest, '[?#]', perl = TRUE)[[1L]][1L]
      suffix <- substring(dest, nchar(path) + 1L)
      actual <- normalizePath(file.path(site, utils::URLdecode(path)), mustWork = TRUE)
      stopifnot(startsWith(actual, paste0(site, '/')))
      relative <- paste0(as.character(fs::path_rel(actual, start = dirname(file))), suffix)
      xml2::xml_set_attr(node, 'content', paste0('0;URL=', relative))
      for (a in xml2::xml_find_all(doc, './/a')) if (identical(xml2::xml_attr(a, 'href'), target)) xml2::xml_set_attr(a, 'href', relative)
      body <- xml2::xml_find_first(doc, './/body')
      if (inherits(body, 'xml_missing')) body <- xml2::xml_add_child(xml2::xml_find_first(doc, './/html'), 'body')
      if (!length(xml2::xml_find_all(body, './/a'))) {
        p <- xml2::xml_add_child(body, 'p')
        a <- xml2::xml_add_child(p, 'a', href = relative)
        xml2::xml_set_text(a, 'Continue to the reference topic.')
      }
      xml2::write_html(doc, file, encoding = 'UTF-8')
      changed[[substring(file, nchar(site) + 2L)]] <- relative
    }
  }
  list(aliases_localized_this_run = length(changed), targets = changed,
    purpose = 'Known topic aliases stay inside the current local site; canonical SEO URLs and default404 are preserved.')
}

# Remove only pkgdown's own generator comment from rendered pages.
clean_site_headers <- function(site = 'docs') {
  files <- list.files(site, '\\.html$', recursive = TRUE, full.names = TRUE)
  changed <- character()
  for (file in files) {
    text <- paste(readLines(file, warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
    pattern <- '<!--[^>]*pkgdown:[^>]*-->'
    clean <- gsub(pattern, '', text, perl = TRUE)
    if (!identical(clean, text)) {
      writeLines(enc2utf8(clean), file, useBytes = TRUE)
      changed <- c(changed, file)
    }
  }
  invisible(changed)
}


# pkgdown may discover root Markdown files independently of Rbuildignore.
# Private maintenance notes are excluded from public documentation.
exclude_local_maintenance_pages <- function(site = "docs") {
  pages <- c("AGENTS.html", "AGENTS.md")
  files <- file.path(site, pages)
  removed <- basename(files[file.exists(files)])
  unlink(files[file.exists(files)])
  search <- file.path(site, "search.json")
  n_search <- 0L
  if (file.exists(search)) {
    entries <- jsonlite::read_json(search)
    keep <- vapply(entries, function(x) {
      path <- x$path
      valid <- is.character(path) && length(path) == 1L && !is.na(path) && nzchar(path)
      valid && !basename(sub("[?#].*$", "", path)) %in% pages
    }, logical(1))
    n_search <- sum(!keep)
    jsonlite::write_json(entries[keep], search, auto_unbox = TRUE,
      null = "null", digits = NA)
  }
  sitemap <- file.path(site, "sitemap.xml")
  n_sitemap <- 0L
  if (file.exists(sitemap)) {
    doc <- xml2::read_xml(sitemap)
    nodes <- xml2::xml_find_all(doc, "//*[local-name()='url']")
    remove <- vapply(nodes, function(x) {
      path <- xml2::xml_text(xml2::xml_find_first(x, "./*[local-name()='loc']"))
      basename(sub("[?#].*$", "", path)) %in% pages
    }, logical(1))
    n_sitemap <- sum(remove)
    xml2::xml_remove(nodes[remove])
    xml2::write_xml(doc, sitemap)
  }
  invisible(list(removed_local_pages = removed, removed_search_entries = n_search,
    removed_sitemap_entries = n_sitemap))
}


# Proposal for the source-controlled tools/finish-site.R maintainer finalizer.
# This edits generated pkgdown.js only. Canonical SEO markup is unchanged.
localize_search_navigation <- function(site = 'docs', canonical_url = yaml::read_yaml('_pkgdown.yml')$url) {
  stopifnot(is.character(canonical_url), length(canonical_url)==1L, !is.na(canonical_url))
  if (!endsWith(canonical_url,'/')) canonical_url <- paste0(canonical_url,'/')
  file <- file.path(site,'pkgdown.js')
  text <- paste(readLines(file,warn=FALSE,encoding='UTF-8'),collapse='\n')
  marker <- '// Resolve local search targets from the current page search-index URL.'
  if (grepl(marker,text,fixed=TRUE)) return(invisible(list(status='already localized',sha256=digest::digest(file=file,algo='sha256'))))
  anchor <- 'window.location.href = s.path + "?q=" + q + "#" + s.id;'
  stopifnot(length(regmatches(text,gregexpr(anchor,text,fixed=TRUE))[[1L]])==1L)
  replacement <- paste0(marker,'\n',
    '      var searchIndexURL = new URL($("#search-input").data("search-index"), window.location.href);\n',
    '      var canonicalSiteBase = ',jsonlite::toJSON(canonical_url,auto_unbox=TRUE),';\n',
    '      var localPath = s.path.indexOf(canonicalSiteBase) === 0 ? s.path.slice(canonicalSiteBase.length) : s.path;\n',
    '      var destination = new URL(localPath, searchIndexURL);\n',
    '      destination.searchParams.set("q", q);\n',
    '      destination.hash = s.id || "";\n',
    '      window.location.href = destination.href;')
  before <- digest::digest(file=file,algo='sha256')
  text <- sub(anchor,replacement,text,fixed=TRUE)
  writeLines(enc2utf8(text),file,useBytes=TRUE)
  invisible(list(status='localized',source_anchor=anchor,before_sha256=before,
    sha256=digest::digest(file=file,algo='sha256'),canonical_base=canonical_url,
    method='Resolve canonical search paths relative to the page-specific search-index URL; preserve canonical link and Open Graph metadata.'))
}

# Build a reader-facing catalogue from the same article groups used by pkgdown.
# This changes only the generated index; vignette sources and URLs stay fixed.
finish_vignette_guide <- function(site = "docs", config = "_pkgdown.yml",
  guide_file = "pkgdown/vignette-guide.yml") {
  groups <- yaml::read_yaml(config)$articles
  guide <- yaml::read_yaml(guide_file)
  ids <- unlist(lapply(groups, function(g) unlist(g$contents)), use.names = FALSE)
  stopifnot(length(ids) == 20L, !anyDuplicated(ids),
    setequal(ids, names(guide$descriptions)))
  file <- file.path(site, "articles", "index.html")
  doc <- xml2::read_html(file, encoding = "UTF-8")
  main <- xml2::xml_find_first(doc, ".//main[@id='main']")
  # On a repeated finish pass, the same title links remain in the catalogue.
  links <- xml2::xml_find_all(main, ".//dt/a")
  names <- sub("\\.html$", "", xml2::xml_attr(links, "href"))
  titles <- stats::setNames(xml2::xml_text(links), names)
  stopifnot(length(links) == 20L, setequal(names, ids))
  xml2::xml_remove(xml2::xml_children(main))
  add <- function(parent, tag, text = NULL, ...) {
    node <- xml2::xml_add_child(parent, tag, ...)
    if (!is.null(text)) xml2::xml_set_text(node, text)
    node
  }
  header <- add(main, "div", class = "page-header")
  add(header, "h1", "Vignettes")
  add(main, "p", guide$intro, class = "vignette-intro")
  start <- add(main, "div", class = "vignette-start")
  add(start, "p", "First visit?", class = "vignette-start-label")
  add(start, "a", titles[["a1-getting-started"]],
    href = "a1-getting-started.html", class = "vignette-start-link")
  add(start, "p", guide$start, class = "mb-0")
  category_nav <- add(main, "nav", class = "vignette-categories",
    `aria-label` = "Vignette categories")
  slug <- function(x) gsub("[^a-z0-9]+", "-", tolower(x))
  for (g in groups) add(category_nav, "a", g$title, href = paste0("#", slug(g$title)))
  for (g in groups) {
    section <- add(main, "section", class = "vignette-section", id = slug(g$title))
    add(section, "h2", g$title, id = paste0(slug(g$title), "-heading"))
    add(section, "p", g$desc, class = "vignette-section-description")
    list <- add(section, "dl", class = "vignette-list")
    for (id in unlist(g$contents)) {
      stopifnot(file.exists(file.path(site, "articles", paste0(id, ".html"))))
      term <- add(list, "dt")
      add(term, "a", titles[[id]], href = paste0(id, ".html"))
      add(list, "dd", guide$descriptions[[id]])
    }
  }
  xml2::xml_set_text(xml2::xml_find_first(doc, ".//head/title"), "Vignettes • postrank")
  og <- xml2::xml_find_first(doc, ".//meta[@property='og:title']")
  if (!inherits(og, "xml_missing")) xml2::xml_set_attr(og, "content", "Vignettes")
  xml2::write_html(doc, file, encoding = "UTF-8")
  search <- file.path(site, "search.json")
  if (file.exists(search)) {
    entries <- jsonlite::read_json(search)
    canonical <- paste0(sub("/$", "", yaml::read_yaml(config)$url), "/articles/index.html")
    entries <- Filter(function(x) !identical(x$path, canonical), entries)
    entries[[length(entries) + 1L]] <- list(path = canonical, id = NULL, dir = "articles",
      previous_headings = "", what = "Vignettes", title = "Vignettes",
      text = paste(c(guide$intro, vapply(groups, `[[`, "", "title"),
        unname(titles[ids]), unlist(guide$descriptions)), collapse = " "))
    jsonlite::write_json(entries, search, auto_unbox = TRUE, null = "null", digits = NA)
  }
  invisible(list(title = "Vignettes", categories = length(groups), vignettes = length(ids)))
}
