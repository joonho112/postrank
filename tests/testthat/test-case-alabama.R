alabama_small_input <- function(input, ids = input$entity_ids[1:3]) {
  s <- input$summaries
  postrank_probabilities(input$e[ids, ids, , drop = FALSE], event = "directional_error",
    zero_ties = TRUE, margin = 0, source = input$source, targets = input$targets,
    summaries = list(means = s$means[ids, , drop = FALSE],
      lower = s$lower[ids, , drop = FALSE], upper = s$upper[ids, , drop = FALSE],
      same_targets = TRUE, description = s$description, level = s$level))
}

# Direct unordered-pair definition, independent of package evaluation helpers.
alabama_loss <- function(grade, probabilities, weights, tau) {
  loss <- 0; disclosed <- 0L; n <- length(grade)
  for (i in seq_len(n - 1L)) for (j in seq.int(i + 1L, n)) {
    if (grade[i] == grade[j]) loss <- loss + tau
    else {
      disclosed <- disclosed + 1L
      above <- if (grade[i] < grade[j]) i else j
      below <- if (grade[i] < grade[j]) j else i
      loss <- loss + sum(weights * probabilities[above, below, ])
    }
  }
  list(risk = loss / choose(n, 2L), N = disclosed)
}

test_that("Alabama inputs retain county identity, historical direction and genuine fixed summaries", {
  x <- pr_case_alabama
  expect_identical(names(x), c("input", "units", "alternatives", "reference", "provenance"))
  expect_identical(class(x), "list")
  expect_identical(x$units$entity_id, x$input$entity_ids)
  expect_identical(nrow(x$units), 67L)
  expect_true(all(grepl("^01[0-9]{3}$", x$units$entity_id)))
  expect_identical(x$input$criterion_ids, c("income", "incarceration"))
  expect_equal(x$units$income_oriented_estimate_points, 100 * x$units$income_source_estimate)
  expect_equal(x$units$incarceration_oriented_estimate_points, -100 * x$units$incarceration_source_estimate)
  expect_match(x$provenance$cohort, "1978-1983")
  expect_match(x$provenance$outcome_dates[["income"]], "2014-2015")
  expect_match(x$provenance$outcome_dates[["incarceration"]], "2010-04-01")
  for (input in c(list(x$input), x$alternatives)) {
    expect_true(validate_postrank_probabilities(input))
    expect_identical(input$dependence_mode, "criterionwise_expected_only")
    expect_identical(input$event, "directional_error")
    expect_identical(input$source$kind, "mcmc_summary")
    expect_true(all(is.na(input$sample_sizes)))
    expect_false(input$capabilities$target_draws)
    expect_identical(input$summaries$level, .95)
    means <- postrank_posterior_means(input, level = .95)
    expect_equal(as.numeric(means), as.numeric(input$summaries$means))
    expect_identical(attr(means, "lower"), input$summaries$lower)
    expect_identical(attr(means, "upper"), input$summaries$upper)
    expect_identical(attr(means, "interval_source"), "supplied_marginal_summaries")
    expect_error(postrank_posterior_means(input, level = .9), "level")
  }
  expect_equal(x$alternatives$income$e[, , 1], x$input$e[, , "income"])
  expect_equal(x$alternatives$incarceration$e[, , 1], x$input$e[, , "incarceration"])
  expect_equal(x$alternatives$income$summaries$means[, 1], x$input$summaries$means[, "income"])
})

test_that("all Alabama archived actions agree with independent A and B loss sums", {
  x <- pr_case_alabama; settings <- x$reference$settings
  for (pool in c("A", "B")) {
    input <- if (pool == "A") x$input else x$alternatives$pool_B
    for (method in names(x$reference$actions)) {
      grades <- x$reference$actions[[method]]
      direct <- alabama_loss(grades, input$e, settings$weights, settings$tau)
      actual <- postrank_evaluate(grades, input, weights = settings$weights, tau = settings$tau)
      stored <- x$reference$metrics[x$reference$metrics$method == method, ]
      expect_equal(direct$risk, stored[[paste0(pool, "_Rtau")]], tolerance = 1e-12)
      expect_equal(actual$primary_risk, direct$risk, tolerance = 1e-12)
      expect_equal(direct$N, stored$N)
      expect_equal(actual$N, direct$N)
    }
  }
  expect_identical(x$reference$actions$P, x$reference$actions$B3)
  expect_identical(x$reference$relation_stability$changed_pairs[
    x$reference$relation_stability$comparison == "B3"], 0L)
  for (k in c("income", "incarceration")) {
    ref <- x$reference$single_criterion[x$reference$single_criterion$criterion == k, ]
    direct <- alabama_loss(x$reference$actions[[ref$method]], x$alternatives[[k]]$e, 1, settings$tau)
    expect_equal(direct$risk, ref$risk, tolerance = 1e-12)
    expect_lte(ref$lower_bound, ref$risk + 1e-12)
    expect_match(x$reference$method_scope[[ref$method]], "different objective")
  }
  all_withheld <- postrank_evaluate(x$reference$actions$B0, x$input,
    weights = settings$weights, tau = settings$tau)
  expect_identical(all_withheld$N, 0L)
  expect_true(all(is.na(all_withheld$E_over_N)))
})

test_that("Alabama stored precision and source terms remain qualified and portable", {
  x <- pr_case_alabama
  p <- x$reference$numerical_pools
  expect_true(p$nonconstant_sensitive_precision_pass[p$pool == "A"])
  expect_false(p$nonconstant_sensitive_precision_pass[p$pool == "B"])
  expect_equal(p$nonconstant_sensitive_failed_rows[p$pool == "B"], 486)
  expect_gt(p$maximum_nonconstant_sensitive_mcse[p$pool == "B"], .005)
  expect_match(paste(x$reference$interpretation, collapse = " "), "not independent observational")
  expect_match(paste(x$reference$interpretation, collapse = " "), "archived chain-based")
  expect_match(paste(x$reference$interpretation, collapse = " "), "unavailable, not zero")
  expect_identical(x$provenance$rights$license, "CC BY 4.0")
  expect_match(x$provenance$attribution, "U.S. Census Bureau", fixed = TRUE)
  expect_match(x$provenance$source_urls[["dataset"]], "10.7910/DVN/NKCQM1", fixed = TRUE)
  expect_true(all(grepl("^[0-9a-f]{64}$", x$provenance$source_files$sha256)))
  expect_false(any(grepl("^/|^[A-Za-z]:", x$provenance$source_files$path)))
  inspect <- function(z) {
    issues <- if (is.environment(z) || is.function(z) || is.language(z)) "active object" else character()
    if (is.character(z) && any(grepl("/Users/|/home/|/Library/Frameworks/|POSTRANK_ALABAMA_ROOT", z)))
      issues <- c(issues, "machine path or environment setting")
    if (is.list(z)) issues <- c(issues, unlist(lapply(z, inspect), use.names = FALSE))
    issues
  }
  expect_length(inspect(x), 0L)
})

test_that("Alabama small common and K1 solves match every ordered partition", {
  skip_if_not_installed("highs")
  x <- pr_case_alabama
  configurations <- list(common = x$input, income = x$alternatives$income,
    incarceration = x$alternatives$incarceration)
  grid <- as.matrix(expand.grid(rep(list(1:3), 3)))
  grid <- grid[apply(grid, 1, function(g) identical(sort(unique(as.integer(g))), seq_len(max(g)))), , drop = FALSE]
  expect_identical(nrow(grid), 13L)
  for (name in names(configurations)) {
    input <- alabama_small_input(configurations[[name]])
    w <- setNames(rep(1 / length(input$criterion_ids), length(input$criterion_ids)), input$criterion_ids)
    risks <- apply(grid, 1, function(g) alabama_loss(g, input$e, w, .2)$risk)
    a <- postrank(input, weights = w, tau = .2, G_max = 3L, level = .95,
      backend = "highs", control = list(time_limit = 10, threads = 1), fragility = FALSE)
    expect_true(a$fit$incumbent_validated)
    expect_equal(a$evaluation$primary_risk, min(risks), tolerance = 1e-10)
    expect_lte(a$fit$objective$risk_lower_bound, min(risks) + 1e-10)
    expect_identical(a$report_card$interval_source, "supplied_marginal_summaries")
    expect_identical(a$report_card$level, .95)
    expect_identical(nrow(a$report_card$data), 3L)
    for (k in input$criterion_ids) {
      pos <- match(a$report_card$data$entity_id, input$entity_ids)
      expect_equal(a$report_card$data[[paste0("mean_", k)]], unname(input$summaries$means[pos, k]))
      expect_equal(a$report_card$data[[paste0("lower_", k)]], unname(input$summaries$lower[pos, k]))
      expect_equal(a$report_card$data[[paste0("upper_", k)]], unname(input$summaries$upper[pos, k]))
    }
  }
})
