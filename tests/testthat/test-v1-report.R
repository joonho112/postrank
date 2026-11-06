# Independent behavioral checks for the v1 HTML report on supplied probabilities.
vr_input <- function(summaries = TRUE, escaped = FALSE) {
  ids <- if (escaped) c('A <script>alert("entity")</script>', "B & partners", 'C "quoted"') else c("A", "B", "C")
  # Independent p_i ~ Uniform(0, u_i), u = (.2, .4, .8), theta_i = -p_i.
  e <- rbind(c(NA, .25, .125), c(.75, NA, .25), c(.875, .75, NA))
  dimnames(e) <- list(ids, ids)
  target <- "Negative event probability theta = -p; larger target means lower event probability"
  if (escaped) target <- paste(target, '<script>alert("target")</script> & units')
  s <- if (summaries) list(
    means = matrix(c(-.1, -.2, -.4), 3L, 1L, dimnames = list(ids, "risk")),
    lower = matrix(c(-.19, -.38, -.76), 3L, 1L, dimnames = list(ids, "risk")),
    upper = matrix(c(-.01, -.02, -.04), 3L, 1L, dimnames = list(ids, "risk")),
    level = .9, same_targets = TRUE, description = "Analytic same-target uniform marginal summaries") else NULL
  postrank_probabilities(1 - e, "higher_priority", TRUE, 0,
    list(kind = "analytic_reference", description = "Independent uniform comparison probabilities",
      conditioning = if (escaped) 'Fixed source <b>not markup</b> & "quoted"' else "Fixed independent uniform marginal laws"),
    stats::setNames(target, "risk"), criterion = "risk", summaries = s)
}
vr_native <- local({
  cache <- list()
  function(summaries = TRUE) {
    skip_if_not_installed("highs")
    key <- as.character(summaries)
    if (is.null(cache[[key]])) cache[[key]] <<- postrank(vr_input(summaries), tau = .2,
      G_max = 3L, backend = "highs", control = postrank_control(time_limit = 10, threads = 1),
      diagnostics = TRUE, crossfit = TRUE)
    cache[[key]]
  }
})
vr_html <- function(path) paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
vr_section <- function(html, id) {
  hit <- regmatches(html, regexpr(paste0('(?s)<(section|header) id="', id, '">.*?</(section|header)>'), html, perl = TRUE))
  if (length(hit)) hit else ""
}
vr_no_compute <- function(...) stop("report attempted a fresh calculation")

test_that("tier 2: supplied K=1 intervals survive a native fit and offline report", {
  a <- vr_native(TRUE)
  expect_true(a$fit$incumbent_validated)
  expect_equal(a$evaluation$weighted_risk, 23 / 120, tolerance = 1e-9)
  local_mocked_bindings(.pr_solve_core = vr_no_compute, postrank_pairwise = vr_no_compute,
    postrank_evaluate = vr_no_compute, postrank_report_card = vr_no_compute,
    .pr_posterior_summaries = vr_no_compute)
  before <- serialize(a, NULL)
  path <- withr::local_tempfile(fileext = ".html")
  r <- postrank_report(a$fit, analysis = a, output_file = path, figures = FALSE)
  expect_identical(r$dimensions, list(entities = 3L, criteria = 1L))
  expect_identical(r$grade, a$fit$grade)
  expect_identical(r$objective, a$fit$objective)
  expect_identical(r$status, a$fit$status)
  expect_identical(r$report_card, a$report_card)
  expect_identical(r$targets, a$input$targets)
  expect_identical(r$declarations$event, "higher_priority")
  expect_identical(r$declarations$probability_source, a$input$source)
  expect_equal(c(r$disclosure$G, r$disclosure$N, r$disclosure$M), c(2, 2, 3))
  expect_equal(r$disclosure$disclosure_rate, 2 / 3)
  expect_equal(r$criterion_profile$expected_errors, unname(a$evaluation$E))
  expect_identical(r$report_card$interval_source, "supplied_marginal_summaries")
  expect_equal(r$report_card$level, .9)
  expect_false(r$source_validation$convergence_verified)
  expect_false(r$source_validation$numerical_certification)
  expect_null(r$diagnostics); expect_null(r$diagnostic_table)
  expect_null(r$fragility_summary); expect_null(r$crossfit)
  expect_identical(vapply(r$figures, `[[`, "", "reason"), rep("figures_disabled", 2L))
  html <- vr_html(path)
  expect_match(vr_section(html, "header"), "3 entities.*1 criterion", perl = TRUE)
  expect_match(vr_section(html, "frame"), a$input$targets[[1]], fixed = TRUE)
  expect_match(vr_section(html, "grades"), "-0.19", fixed = TRUE)
  expect_match(vr_section(html, "grades"), "-0.01", fixed = TRUE)
  expect_match(vr_section(html, "decision"), "<td>Disclosed comparisons</td><td>2</td>", fixed = TRUE)
  expect_match(vr_section(html, "decision"), "<td>All entity pairs</td><td>3</td>", fixed = TRUE)
  expect_false(grepl("data:image/png;base64,", html, fixed = TRUE))
  expect_false(grepl("<(script|iframe)|(?:src|href)=\"(?:https?:)?//", html, perl = TRUE))
  ids <- regmatches(html, gregexpr('<(?:section|header) id="[a-z]+"', html, perl = TRUE))[[1]]
  expect_identical(sub('.*id="([a-z]+)"', "\\1", ids),
    c("header", "frame", "declarations", "grades", "decision", "profiles", "protection",
      "posterior", "mc", "stability", "provenance"))
  expect_identical(serialize(a, NULL), before)
})

test_that("tier 2: absent marginal summaries stay absent in the report", {
  a <- vr_native(FALSE)
  local_mocked_bindings(.pr_solve_core = vr_no_compute, postrank_pairwise = vr_no_compute,
    postrank_evaluate = vr_no_compute, postrank_report_card = vr_no_compute,
    .pr_posterior_summaries = vr_no_compute)
  path <- withr::local_tempfile(fileext = ".html")
  expect_no_warning(r <- postrank_report(a$fit, analysis = a, output_file = path, figures = FALSE))
  expect_true(r$incumbent_validated)
  expect_identical(r$grade, a$fit$grade)
  expect_null(r$report_card); expect_null(r$posterior_profiles)
  expect_identical(r$extras$report_card$reason, "supplied_marginal_intervals_unavailable")
  expect_false(r$capabilities$can_report_card)
  for (extra in c("diagnostics", "fragility", "crossfit")) {
    expect_false(r$extras[[extra]]$supported)
    expect_identical(r$extras[[extra]]$reason, "supplied_probabilities_have_no_target_draws")
  }
  html <- vr_html(path)
  grade_html <- vr_section(html, "grades")
  expect_length(regmatches(grade_html, gregexpr("<th ", grade_html, fixed = TRUE))[[1]], 2L)
  expect_match(grade_html, "<td>A</td>", fixed = TRUE)
  expect_false(grepl("lower_risk|upper_risk|mean_risk", vr_section(html, "grades")))
  expect_match(vr_section(html, "posterior"), 'class="missing"', fixed = TRUE)
  expect_match(vr_section(html, "mc"), "supplied_probabilities_have_no_target_draws", fixed = TRUE)
  expect_match(vr_section(html, "frame"), a$input$targets[[1]], fixed = TRUE)
})

test_that("a no-incumbent K=1 report keeps dimensions, status, and lower bound", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(grade = NULL, status = "time_limit", lower = -.1))
  a <- postrank(vr_input(), tau = .2, G_max = 3L, backend = "highs")
  local_mocked_bindings(.pr_solve_core = vr_no_compute, postrank_pairwise = vr_no_compute,
    postrank_evaluate = vr_no_compute, postrank_report_card = vr_no_compute,
    .pr_posterior_summaries = vr_no_compute)
  path <- withr::local_tempfile(fileext = ".html")
  r <- postrank_report(a$fit, analysis = a, output_file = path, figures = FALSE)
  expect_identical(r$dimensions, list(entities = 3L, criteria = 1L))
  expect_false(r$incumbent_validated)
  expect_null(r$grade); expect_null(r$disclosure); expect_null(r$criterion_profile)
  expect_null(r$report_card)
  expect_identical(r$status, a$fit$status)
  expect_identical(r$status$normalized, "time_limit")
  expect_identical(r$objective, a$fit$objective)
  expect_true(is.finite(r$objective$risk_lower_bound))
  expect_true(is.na(r$objective$primary_action_risk))
  expect_true(is.na(r$objective$risk_absolute_gap))
  html <- vr_html(path)
  expect_match(vr_section(html, "header"), "3 entities.*1 criterion", perl = TRUE)
  expect_match(vr_section(html, "header"), "time limit", ignore.case = TRUE)
  expect_false(grepl("<table>", vr_section(html, "grades"), fixed = TRUE))
  expect_match(vr_section(html, "decision"), "time_limit", fixed = TRUE)
  expect_false(grepl("One validated incumbent is shown", html, fixed = TRUE))
})

test_that("validated limited and all-withheld results preserve distinct stored status", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(
    c(A = 1L, B = 2L, C = 2L), status = "time_limit", lower = NA_real_))
  a <- postrank(vr_input(), tau = .2, G_max = 3L, backend = "highs")
  path <- withr::local_tempfile(fileext = ".html")
  r <- postrank_report(a$fit, analysis = a, output_file = path, figures = FALSE)
  expect_true(r$incumbent_validated)
  expect_identical(r$status, a$fit$status)
  expect_true(is.na(r$objective$risk_lower_bound))
  expect_true(is.na(r$objective$risk_absolute_gap))
  expect_equal(r$objective$primary_action_risk, 23 / 120)
  expect_match(vr_section(vr_html(path), "header"), "time limit", ignore.case = TRUE)
  expect_false(grepl("status: optimal", vr_section(vr_html(path), "header"), fixed = TRUE))

  local_mocked_bindings(.pr_solve_core = pr_mock_solver(c(A = 1L, B = 1L, C = 1L)))
  a <- postrank(vr_input(), tau = .2, G_max = 3L, backend = "highs")
  r <- postrank_report(a$fit, analysis = a, figures = FALSE)
  expect_identical(r$disclosure$N, 0L)
  expect_equal(r$objective$primary_action_risk, .2)
  expect_true(all(is.na(r$criterion_profile$error_per_disclosed_pair)))
  expect_identical(r$grade, c(A = 1L, B = 1L, C = 1L))
})

test_that("supplied targets, entities, and source descriptions are escaped as text", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  a <- postrank(vr_input(escaped = TRUE), tau = .2, G_max = 3L, backend = "highs")
  local_mocked_bindings(.pr_solve_core = vr_no_compute, postrank_pairwise = vr_no_compute,
    postrank_evaluate = vr_no_compute, postrank_report_card = vr_no_compute,
    .pr_posterior_summaries = vr_no_compute)
  path <- withr::local_tempfile(fileext = ".html")
  r <- postrank_report(a$fit, analysis = a, output_file = path, figures = FALSE)
  html <- vr_html(path)
  expect_identical(r$targets, a$input$targets)
  expect_false(grepl("<script>|<b>not markup</b>", html))
  expect_match(vr_section(html, "frame"), '&lt;script&gt;alert(&quot;target&quot;)&lt;/script&gt; &amp; units', fixed = TRUE)
  expect_match(vr_section(html, "grades"), '&lt;script&gt;alert(&quot;entity&quot;)&lt;/script&gt;', fixed = TRUE)
  expect_match(vr_section(html, "grades"), "B &amp; partners", fixed = TRUE)
  expect_match(vr_section(html, "declarations"), "&lt;b&gt;not markup", fixed = TRUE)
})

test_that("tier 2: a supplied-summary K=1 card figure uses prepared values", {
  skip_if_not(isTRUE(capabilities("png")), "no PNG device")
  a <- vr_native(TRUE)
  local_mocked_bindings(.pr_solve_core = vr_no_compute, postrank_pairwise = vr_no_compute,
    postrank_evaluate = vr_no_compute, postrank_report_card = vr_no_compute,
    .pr_posterior_summaries = vr_no_compute)
  path <- withr::local_tempfile(fileext = ".html")
  r <- postrank_report(a$fit, analysis = a, output_file = path, figures = TRUE)
  expect_true(r$figures[[1]]$available)
  expect_identical(r$figures[[1]]$id, "fig-report-card")
  expect_identical(r$report_card, a$report_card)
  expect_match(vr_section(vr_html(path), "grades"), 'src="data:image/png;base64,', fixed = TRUE)
})
