prob_source <- function(kind = "analytic_reference") list(kind = kind,
  description = "Independent continuous uniform targets",
  conditioning = "Fixed illustrative laws; no parameter estimation")

prob_uniform <- function(u = c(A = .2, B = .4, C = .8), summaries = NULL) {
  e <- matrix(NA_real_, length(u), length(u), dimnames = list(names(u), names(u)))
  for (i in seq_along(u)) for (j in seq_along(u)) if (i != j)
    e[i, j] <- if (u[i] <= u[j]) u[i] / (2 * u[j]) else 1 - u[j] / (2 * u[i])
  postrank_probabilities(e, "directional_error", TRUE, 0, prob_source(),
    c(risk = "Negative probability; theta=-p, where p is Uniform(0,u)"),
    criterion = "risk", summaries = summaries)
}

prob_summaries <- function(u = c(A = .2, B = .4, C = .8), level = .9) {
  mat <- function(z) matrix(z, length(u), 1L, dimnames = list(names(u), "risk"))
  list(means = mat(-u / 2), same_targets = TRUE,
    description = "Means and equal-tail intervals of theta=-p, with p Uniform(0,u)",
    lower = mat(-u * (1 + level) / 2), upper = mat(-u * (1 - level) / 2), level = level)
}

test_that("precomputed probabilities preserve K=1 and explicit event meaning", {
  x <- prob_uniform()
  expect_s3_class(x, "postrank_probabilities")
  expect_true(validate_postrank_probabilities(x))
  expect_identical(dim(x$e), c(3L, 3L, 1L))
  expect_identical(postrank_pairwise(x), x)
  p <- 1 - x$raw_probabilities
  y <- postrank_probabilities(p, "higher_priority", TRUE, 0, prob_source(), x$targets)
  expect_equal(y$e, x$e, tolerance = 1e-15)
  z <- postrank_probabilities(x$raw_probabilities, "directional_error", TRUE, 0,
    prob_source(), x$targets)
  expect_identical(x, z)
  expect_true(all(is.na(x$sample_sizes)))
  expect_null(x$exact)
  expect_false(x$capabilities$target_draws)
  expect_false(x$capabilities$iid_bound)
  expect_false(x$validation$jointness_verified)
  expect_error(postrank_pairwise(x, method = "reference"), "omit draw aggregation")
})

test_that("input checks reject ambiguous directions, IDs, atoms and margins", {
  x <- prob_uniform(); p <- x$raw_probabilities
  construct <- function(a = p, ...) postrank_probabilities(a, source = prob_source(),
    targets = x$targets, ...)
  expect_error(construct(), "must be supplied explicitly")
  expect_error(construct(event = "superior", zero_ties = TRUE, margin = 0), "event must")
  expect_error(construct(event = "directional_error", zero_ties = FALSE, margin = 0), "equality")
  expect_error(construct(event = "directional_error", zero_ties = NA, margin = 0), "equality")
  expect_error(construct(event = "directional_error", zero_ties = TRUE, margin = .01), "zero comparison")
  bad <- p; dimnames(bad)[[2L]] <- rev(dimnames(bad)[[2L]])
  expect_error(construct(bad, event = "directional_error", zero_ties = TRUE, margin = 0), "same order")
  bad <- p; bad[1, 1, 1] <- .5
  expect_error(construct(bad, event = "directional_error", zero_ties = TRUE, margin = 0), "NA diagonals")
  for (value in c(NA_real_, NaN, Inf, -.01, 1.01)) {
    bad <- p; bad[1, 2, 1] <- value
    expect_error(construct(bad, event = "directional_error", zero_ties = TRUE, margin = 0), "off-diagonal")
  }
  bad <- p; bad[1, 2, 1] <- bad[1, 2, 1] + .1
  expect_error(construct(bad, event = "directional_error", zero_ties = TRUE, margin = 0), "reverse probabilities")
})

test_that("symmetric correction is explicit and distinct from integration error", {
  x <- prob_uniform(); p <- x$raw_probabilities; p[1, 2, 1] <- p[1, 2, 1] + 2e-7
  call <- function(...) postrank_probabilities(p, "directional_error", TRUE, 0,
    prob_source("numerical_integration"), x$targets, ...)
  expect_error(call(correction = "symmetric"), "explicit tolerance")
  expect_error(call(correction = "none", tolerance = 1e-6), "only used")
  expect_error(call(correction = "symmetric", tolerance = 1e-8), "reverse probabilities")
  y <- call(correction = "symmetric", tolerance = 1e-6)
  expect_identical(y$raw_probabilities, p)
  expect_equal(y$e[1, 2, 1], x$e[1, 2, 1] + 1e-7, tolerance = 1e-15)
  expect_lt(abs(y$correction$maximum_absolute_change[["risk"]] - 1e-7), 1e-15)
  expect_equal(y$e[, , 1] + t(y$e[, , 1]),
    matrix(c(NA, 1, 1, 1, NA, 1, 1, 1, NA), 3, 3,
      dimnames = list(entity_i = x$entity_ids, entity_j = x$entity_ids)))
  expect_match(y$correction$risk_change_scope, "not an integration error bound")
  expect_false(y$validation$numerical_certification)
})

test_that("all small ordered partitions agree with a separate loss calculation", {
  x <- prob_uniform(); u <- c(.2, .4, .8); n <- length(u); tau <- .2
  assignments <- as.matrix(expand.grid(rep(list(seq_len(n)), n)))
  valid <- apply(assignments, 1, function(g) identical(sort(unique(g)), seq_len(max(g))))
  grades <- assignments[valid, , drop = FALSE]
  expect_equal(nrow(grades), 13)
  reference <- numeric(nrow(grades))
  for (r in seq_len(nrow(grades))) {
    g <- grades[r, ]; loss <- 0
    for (i in seq_len(n - 1L)) for (j in (i + 1L):n) {
      if (g[i] == g[j]) loss <- loss + tau else {
        first <- if (g[i] < g[j]) i else j
        second <- if (g[i] < g[j]) j else i
        loss <- loss + if (u[first] <= u[second])
          u[first] / (2 * u[second]) else 1 - u[second] / (2 * u[first])
      }
    }
    reference[r] <- loss / choose(n, 2)
    ev <- postrank_evaluate(stats::setNames(g, x$entity_ids), x, c(risk = 1), tau)
    expect_equal(ev$weighted_risk, reference[r], tolerance = 1e-14)
  }
  expect_equal(min(reference), 23 / 120, tolerance = 1e-14)
  all_tie <- postrank_evaluate(c(A = 1L, B = 1L, C = 1L), x, c(risk = 1), tau)
  expect_equal(all_tie$weighted_risk, tau)
  expect_equal(all_tie$N, 0)
  expect_true(is.na(all_tie$E_over_N))
  expect_equal(unname(postrank_expected_rank(x)), 1 + rowSums(x$e[, , 1], na.rm = TRUE),
    ignore_attr = TRUE)
  cuts <- postrank_cuts(postrank_expected_rank(x), x,
    postrank_settings(c(risk = 1), tau = tau, G_max = 3L))
  expect_equal(cuts$risk, min(reference), tolerance = 1e-14)
})

test_that("K=2 keeps criterion errors separate and only accepts the supported problem", {
  one <- prob_uniform(); a <- array(c(one$e, 1 - one$e), c(3L, 3L, 2L),
    dimnames = list(entity_i = one$entity_ids, entity_j = one$entity_ids,
      criterion = c("first", "second")))
  x <- postrank_probabilities(a, "directional_error", TRUE, 0, prob_source(),
    c(first = "First oriented target", second = "Second oriented target"))
  ev <- postrank_evaluate(c(A = 1L, B = 2L, C = 3L), x, c(first = .75, second = .25), .2)
  expect_equal(ev$weighted_risk, .75 * mean(a[, , 1][upper.tri(a[, , 1])]) +
    .25 * mean(a[, , 2][upper.tri(a[, , 2])]))
  expect_error(postrank_problem(x, c(first = .5, second = .5), .2, 3L,
    objective = "minimax"), "at-most-G")
  expect_error(postrank_problem(x, c(first = .5, second = .5), .2, 3L,
    exact_G = 2L), "at-most-G")
  expect_error(postrank_problem(x, c(first = .5, second = .5), .2, 3L,
    q = c(first = .1)), "at-most-G")
  expect_error(postrank_evaluate(c(A = 1L, B = 2L, C = 3L), x,
    c(first = .5, second = .5), .2, objective = "minimax"), "at-most-G")
  expect_error(postrank_cuts(postrank_expected_rank(x), x,
    postrank_settings(c(first = .5, second = .5), .2, 3L, exact_G = 2L)), "at-most-G")
  expect_false(x$capabilities$joint_functionals)
})

test_that("public low-level reuse checks the full new domain and content", {
  x <- prob_uniform(summaries = prob_summaries())
  altered <- list(
    function(z) { z$source$conditioning <- "Changed prior"; z },
    function(z) { z$raw_probabilities[1, 2, 1] <- .2; z },
    function(z) { z$e[1, 2, 1] <- .2; z },
    function(z) { z$summaries$means[1, 1] <- 0; z },
    function(z) { z$capabilities$iid_bound <- TRUE; z },
    function(z) { z$sample_sizes[] <- 100; z },
    function(z) { z$validation$convergence_verified <- TRUE; z },
    function(z) { class(z) <- c("postrank_pairwise", "list"); z })
  for (change in altered) {
    bad <- change(x)
    expect_error(validate_postrank_probabilities(bad), class = "postrank_input_error")
    expect_error(postrank_evaluate(c(A = 1L, B = 2L, C = 3L), bad, c(risk = 1), .2),
      class = "postrank_input_error")
  }
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  saveRDS(x, path)
  expect_identical(readRDS(path), x)
  expect_true(validate_postrank_probabilities(readRDS(path)))
})

test_that("supplied summaries are explicit, aligned and fixed at their interval level", {
  s <- prob_summaries(); x <- prob_uniform(summaries = s)
  m <- postrank_posterior_means(x, .9)
  expect_equal(unname(m[, 1]), c(-.1, -.2, -.4))
  expect_identical(attr(m, "interval_source"), "supplied_marginal_summaries")
  expect_equal(unname(attr(m, "lower")[, 1]), c(-.19, -.38, -.76))
  expect_error(postrank_posterior_means(x, .95), "level 0.9")
  expect_error(postrank_posterior_means(prob_uniform()), "do not determine")
  s$same_targets <- FALSE
  expect_error(prob_uniform(summaries = s), "same oriented targets")
  s <- prob_summaries(); rownames(s$means) <- rev(rownames(s$means))
  expect_error(prob_uniform(summaries = s), "matching IDs")
  s <- prob_summaries(); s$lower <- NULL
  expect_error(prob_uniform(summaries = s), "together")
  s <- prob_summaries(); s$lower[1, 1] <- 2
  expect_error(prob_uniform(summaries = s), "exceed")
  s <- prob_summaries(); s[c("lower", "upper", "level")] <- NULL
  means_only <- prob_uniform(summaries = s)
  expect_true(means_only$capabilities$posterior_means)
  expect_false(means_only$capabilities$posterior_intervals)
  expect_error(postrank_posterior_means(means_only, .9), "no marginal intervals")
})

test_that("one-call probability analysis uses K=1 weight one and honest unavailable extras", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  a <- postrank(prob_uniform(), G_max = 3L, backend = "highs", diagnostics = TRUE, crossfit = TRUE)
  expect_identical(a$settings$weights, c(risk = 1))
  expect_true(a$fit$incumbent_validated)
  expect_null(a$report_card); expect_null(a$diagnostics)
  expect_identical(a$extras$report_card$reason, "supplied_marginal_intervals_unavailable")
  for (extra in c("fragility", "crossfit", "diagnostics")) {
    expect_false(a$extras[[extra]]$supported)
    expect_identical(a$extras[[extra]]$reason, "supplied_probabilities_have_no_target_draws")
  }
  expect_error(postrank_report_card(a), "do not determine")
  only_means <- prob_summaries(); only_means[c("lower", "upper", "level")] <- NULL
  expect_warning(m <- postrank(prob_uniform(summaries = only_means),
    G_max = 3L, backend = "highs"), NA)
  expect_null(m$report_card)
  expect_identical(m$extras$report_card$reason, "supplied_marginal_intervals_unavailable")
  expect_null(m$extras$report_card$condition)
  expect_equal(unname(postrank_posterior_means(m$input)[, 1]), c(-.1, -.2, -.4))
  b <- postrank(prob_uniform(summaries = prob_summaries()), G_max = 3L, backend = "highs")
  expect_true(b$extras$report_card$available)
  expect_identical(b$report_card$interval_source, "supplied_marginal_summaries")
  expect_identical(postrank_report_card(b$fit)$data, b$report_card$data)
  expect_identical(postrank_report_card(b, level = .9)$data, b$report_card$data)
  expect_error(postrank_report_card(b, level = .95), "level 0.9")
  expect_error(postrank_report_card(b, level = .900000001),
    class = "postrank_input_error", regexp = "level 0.9")
  expect_error(postrank_report_card(b$fit, level = .900000001),
    class = "postrank_input_error", regexp = "level 0.9")
  expect_error(postrank(b$input, level = .95, backend = "highs"), "level 0.9")
  stale <- b; stale$input$summaries$means[1, 1] <- 10
  expect_error(postrank_report_card(stale), "changed")
})

test_that("K=1 default weight also works for existing draw input", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  draws <- as_postrank_draws(pr_test_payload(K = 1L))
  a <- postrank(draws, G_max = 3L, backend = "highs", fragility = FALSE)
  expect_identical(a$settings$weights, c(need1 = 1))
})

test_that("entity permutation preserves the analytic loss after matching IDs", {
  x <- prob_uniform(); order <- c(3L, 1L, 2L)
  y <- postrank_probabilities(x$raw_probabilities[order, order, , drop = FALSE],
    "directional_error", TRUE, 0, prob_source(), x$targets)
  g <- c(A = 1L, B = 2L, C = 2L)
  expect_equal(postrank_evaluate(g, x, c(risk = 1), .2)$weighted_risk,
    postrank_evaluate(g[y$entity_ids], y, c(risk = 1), .2)$weighted_risk)
})

test_that("tier 2: HiGHS agrees with the independent continuous oracle", {
  skip_if_not_installed("highs")
  a <- postrank(prob_uniform(), tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10, threads = 1), fragility = FALSE)
  expect_true(a$fit$incumbent_validated)
  expect_equal(a$evaluation$weighted_risk, 23 / 120, tolerance = 1e-9)
  expect_equal(a$fit$objective$risk_absolute_gap, 0, tolerance = 1e-9)
})
