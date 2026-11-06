# T-ref-02: every active export resolves to a topic whose title is Title Case and at most 60
# characters; the three grade scales share one topic, the 24 formatters another, and the
# generated re-exports topic keeps its own title.
test_that("export topics have Title Case titles of at most 60 characters", {
  db <- pr_rd_db()
  field <- function(rd, tag) pr_rd_field(rd, tag)
  aliases <- lapply(db, field, tag = "\\alias")
  small <- c("a", "an", "the", "and", "or", "nor", "of", "for", "from", "to", "in", "on", "by", "with", "as", "per", "at", "via")
  for (e in setdiff(getNamespaceExports("postrank"), "autoplot")) {
    topic <- names(aliases)[vapply(aliases, function(a) e %in% a, TRUE)]
    expect_length(topic, 1L)
    title <- trimws(gsub("\\s+", " ", field(db[[topic]], "\\title")))
    expect_true(nzchar(title), info = e)
    expect_lte(nchar(title), 60L)
    words <- strsplit(title, " ", fixed = TRUE)[[1]][-1L]
    lower <- words[!words %in% small & !words %in% c("postrank", "ggplot2") & grepl("^[a-z]", words)]   # package names keep their case
    expect_identical(lower, character(), info = paste(e, title))
    expect_match(title, "^[A-Z]", info = e)
  }
  scale_topics <- unique(vapply(c("scale_colour_grade", "scale_color_grade", "scale_fill_grade"), function(e)
    names(aliases)[vapply(aliases, function(a) e %in% a, TRUE)], ""))
  expect_length(scale_topics, 1L)
  fmt_topics <- unique(vapply(grep("^format_postrank_.*_cli$", getNamespaceExports("postrank"), value = TRUE), function(e)
    names(aliases)[vapply(aliases, function(a) e %in% a, TRUE)], ""))
  expect_identical(fmt_topics, "format_postrank_cli.Rd")
})
