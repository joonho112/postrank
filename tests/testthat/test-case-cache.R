test_that("prepared case results read without a solver or fresh posterior computation", {
  reader <- new.env()
  sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), reader)
  guard <- function(...) stop("a stored case view attempted fresh computation")
  local_mocked_bindings(.pr_solve_core = guard, postrank_pairwise = guard,
    postrank_evaluate = guard, postrank_report_card = guard)
  cases <- list(case_cde_12 = pr_case_cde, case_krw_signed97 = pr_case_krw,
    case_alabama67 = pr_case_alabama)
  distribution <- c(case_cde_12 = "public-source-maintainer-confirmed",
    case_krw_signed97 = "CC-BY-NC", case_alabama67 = "CC-BY-4.0")
  for (key in names(cases)) {
    x <- reader$load_or_compute(key)
    expect_s3_class(x, "postrank_analysis")
    expect_identical(x$input, cases[[key]]$input)
    expect_true(.pr_validate_analysis(x))
    expect_true(x$fit$incumbent_validated)
    expect_identical(nrow(as.data.frame(x)), length(x$input$entity_ids))
    expect_identical(names(as.data.frame(x)), c("entity_id", "grade"))
    expect_true(length(format(x)) > 0L)
    expect_true(length(format(summary(x))) > 0L)
    expect_identical(x$report_card$level, cases[[key]]$input$summaries$level)
    expect_match(reader$cache_note(key), unname(distribution[[key]]), fixed = TRUE)
  }
})

test_that("case caches carry source conditions alongside their numerical provenance", {
  man <- jsonlite::read_json(system.file("extdata", "manifests", "cache-manifest.json",
    package = "postrank", mustWork = TRUE))
  keys <- c(case_cde_12 = "pr_case_cde", case_krw_signed97 = "pr_case_krw",
    case_alabama67 = "pr_case_alabama")
  distribution <- c(case_cde_12 = "public-source-maintainer-confirmed",
    case_krw_signed97 = "CC-BY-NC", case_alabama67 = "CC-BY-4.0")
  for (key in names(keys)) {
    rec <- man$assets[[key]]
    expect_identical(rec$case_data, unname(keys[[key]]))
    expect_identical(rec$data_distribution, unname(distribution[[key]]))
    expect_identical(rec$data_notice, "extdata/case-studies/DATA-NOTICE.md")
    expect_identical(rec$backend, "highs")
    expect_identical(rec$solves, 1L)
    expect_equal(rec$control$time_limit, 30)
  }
  src <- jsonlite::read_json(system.file("extdata", "manifests", "source-manifest.json",
    package = "postrank", mustWork = TRUE))
  paths <- vapply(src$entries, `[[`, "", "path")
  expect_true(all(c("DESCRIPTION", "LICENSE", "inst/extdata/case-studies/DATA-NOTICE.md") %in% paths))
  notice <- system.file("extdata", "case-studies", "DATA-NOTICE.md", package = "postrank", mustWork = TRUE)
  rec <- src$entries[[match("inst/extdata/case-studies/DATA-NOTICE.md", paths)]]
  if (identical(src$package_version, as.character(utils::packageVersion("postrank")))) {
    expect_identical(digest::digest(file = notice, algo = "sha256"), rec$sha256)
  } else {
    compatibility <- jsonlite::read_json(system.file("extdata", "manifests",
      "cache-reader-compatibility.json", package="postrank", mustWork=TRUE))
    expect_identical(rec$sha256,
      "e5ead62086a11f0f26010bfa9be0dd0ffb3e3d27adc70d60d9d468421c8e04a2")
    current <- Filter(function(e) identical(e$path,
      "inst/extdata/case-studies/DATA-NOTICE.md"), compatibility$compatible_source_entries)
    expect_length(current, 1L)
    expect_identical(digest::digest(file=notice, algo="sha256"), current[[1L]]$sha256)
  }
  text <- paste(readLines(notice), collapse = "\n")
  expect_match(text, "CC-BY-NC", fixed = TRUE)
  expect_match(text, "CC BY 4.0", fixed = TRUE)
  data <- jsonlite::read_json(system.file("extdata", "manifests", "data-manifest.json",
    package = "postrank", mustWork = TRUE))
  cases <- list(pr_case_cde = pr_case_cde, pr_case_krw = pr_case_krw,
    pr_case_alabama = pr_case_alabama)
  distribution <- c(pr_case_cde = "public-source-maintainer-confirmed",
    pr_case_krw = "CC-BY-NC", pr_case_alabama = "CC-BY-4.0")
  for (nm in names(cases)) {
    rec <- data$objects[[nm]]
    expect_identical(rec$case_id, cases[[nm]]$provenance$case_id)
    expect_identical(rec$input_identity, cases[[nm]]$input$input_identity)
    expect_identical(rec$data_distribution, unname(distribution[[nm]]))
    expect_identical(rec$data_notice, "extdata/case-studies/DATA-NOTICE.md")
    expect_true(nzchar(rec$source_conditions))
  }
})
