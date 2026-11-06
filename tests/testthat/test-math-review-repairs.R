# External review PKG-01/02/03/04/08/09/17: scientific-input and row-linkage
# invariants, with independent arithmetic/CDF checks rather than snapshots.
math_review_weights <- c(need_A = .6, need_B = .4)
math_review_fit <- function(settings) {
  postrank_solve(postrank_problem(postrank_pairwise(postrank_toy), settings = settings), backend = "highs")
}
math_review_mixture <- function(locations, deviations, weights, shift = 0, unit = 1) {
  ids <- c("A", "B"); ks <- "k1"
  components <- lapply(seq_along(locations), function(j) list(mu = c(k1 = shift + unit * locations[j]),
    Sigma = matrix(unit^2, 1L, 1L, dimnames = list(criterion_i = ks, criterion_j = ks)),
    means = matrix(shift + unit * c(locations[j], locations[j] + 1), 2L, 1L,
      dimnames = list(entity = ids, criterion = ks)),
    covariance = array((unit * deviations[j])^2, c(1L, 1L, 2L),
      dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids))))
  names(components) <- names(weights) <- paste0("s", seq_along(components))
  postrank_mixture_coefficients(components, weights, data.frame(state_id = names(components)),
    "fixed_finite_mixture", "entities_given_shared_h",
    list(producer_id = "external-review-regression", producer_version = "1", posterior_id = "fixed-law",
      input_payload_sha256 = strrep("a", 64), source_sha256 = strrep("b", 64), config_sha256 = strrep("c", 64)))
}

test_that("PKG-02: named composite declarations and column permutations preserve scores", {
  m <- matrix(c(0, 5, 100, 0), 2L, 2L, dimnames = list(c("A", "B"), c("x", "y")))
  w <- c(x = .5, y = .5); sc <- c(x = 1, y = 100); ce <- c(x = 0, y = 0)
  expected <- c(A = .5, B = 2.5)
  for (ord in list(c("x", "y"), c("y", "x"))) {
    result <- postrank_composite(m[, ord], w[rev(ord)], sc[rev(ord)], ce[rev(ord)])
    expect_equal(as.numeric(result), unname(expected), tolerance = 1e-14)
    expect_identical(attr(result, "scales"), sc[ord])
  }
  expect_equal(as.numeric(postrank_composite(m, w, 2, 0)), c(25, 1.25))
  expect_equal(as.numeric(postrank_composite(m, w, c(1, 100))), unname(expected))
  shifted <- postrank_composite(m, w, sc, c(y = 100, x = 1))
  expect_equal(as.numeric(shifted), unname(expected) - 1)
})

test_that("PKG-02: ambiguous or incomplete named scale declarations are refused", {
  m <- matrix(1:4, 2L, 2L, dimnames = list(c("A", "B"), c("x", "y")))
  for (bad in list(c(x = 1), c(x = 1, z = 2), c(x = 1, x = 2), setNames(c(1, 2), c("x", NA_character_)))) {
    expect_error(postrank_composite(m, c(x = .5, y = .5), scales = bad), class = "postrank_input_error")
    expect_error(postrank_composite(m, c(x = .5, y = .5), centers = bad), class = "postrank_input_error")
  }
  expect_equal(as.numeric(postrank_composite(m[, "x", drop = FALSE], c(x = 1), scales = c(x = 2))), c(.5, 1))
  rownames(m) <- c("A", "A")
  expect_error(postrank_composite(m, c(x = .5, y = .5)), class = "postrank_input_error")
})

test_that("PKG-01: quantile cuts honor the realized grade cap and exact grade count", {
  pw <- postrank_pairwise(postrank_toy); ids <- pw$entity_ids
  s <- postrank_settings(math_review_weights, G_max = 1L)
  bad <- tryCatch(postrank_cuts(setNames(1:3, ids), pw, s, rule = "quantile", G_b = 2L), error = identity)
  expect_identical(bad$code, "baseline_grade_limit_violation")
  exact <- postrank_settings(math_review_weights, G_max = 3L, exact_G = 3L)
  bad <- tryCatch(postrank_cuts(setNames(c(1, 1, 2), ids), pw, exact, rule = "quantile"), error = identity)
  expect_identical(bad$code, "exact_G_exceeds_blocks")
  # Requested resolution may exceed the cap when exact-score merging produces
  # an admissible realized action; all scores equal realizes one grade.
  merged <- postrank_cuts(setNames(rep(1, 3), ids), pw, s, rule = "quantile", G_b = 3L)
  expect_identical(merged$evaluation$G, 1L)
  expect_equal(merged$risk, s$tau)
  expect_identical(merged$provenance$requested_G_b, 3L)
  altered <- merged; altered$grade <- setNames(c(1L, 1L, 2L), ids)
  expect_error(.pr_validate_baseline(altered), class = "postrank_input_error")
})

test_that("PKG-01: enough score blocks do not excuse an exact-G quantile merge", {
  pw <- postrank_pairwise(as_postrank_draws(pr_random_payload(750L, 16L, 4L, 2L)))
  s <- postrank_settings(setNames(c(.5, .5), pw$criterion_ids), G_max = 3L, exact_G = 3L)
  # B=3, but positional labels 1,1,2,3 merge through the middle equal-score block.
  scores <- setNames(c(1, 2, 2, 3), pw$entity_ids)
  bad <- tryCatch(postrank_cuts(scores, pw, s, rule = "quantile"), error = identity)
  expect_identical(bad$code, "baseline_exact_grade_violation")
  s$exact_G <- NULL; s <- .pr_settings_complete(s); class(s) <- c("postrank_settings", "list")
  good <- postrank_cuts(scores, pw, s, rule = "quantile", G_b = 3L)
  expect_identical(good$evaluation$G, 2L)
})

test_that("PKG-01: arbitrary action risk survives with explicit family membership", {
  ids <- postrank_toy$entity_ids; tied <- setNames(rep(1L, 3), ids)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(tied))
  s <- postrank_settings(math_review_weights, tau = .25, G_max = 3L, q = c(need_B = 0))
  fit <- math_review_fit(s)
  g <- setNames(c(1L, 1L, 2L), ids)
  cmp <- postrank_compare(fit, supplied = g, baselines = character())
  expect_identical(cmp$table$family_feasible, c(TRUE, FALSE))
  expect_identical(cmp$table$feasibility_reason, c(NA_character_, "protection_violation:need_B"))
  expect_equal(cmp$table$risk, c(.25, .2125), tolerance = 1e-14)
  expect_equal(cmp$table$E_over_N_need_B[2], .4375)
  expect_identical(cmp$table$status[2], "evaluated")
  expect_identical(cmp$provenance$family_feasibility_tolerance, fit$solution_validation$tolerances$feasibility)
  expect_true(is.na(cmp$table$E_over_N_need_B[1]))
  cap <- math_review_fit(postrank_settings(math_review_weights, G_max = 1L))
  cc <- postrank_compare(cap, supplied = g, baselines = character())
  expect_identical(cc$table$feasibility_reason[2], "grade_limit_violation")
})

test_that("PKG-01: one recorded tolerance governs raw q residuals and no-action rows", {
  ids <- postrank_toy$entity_ids; tied <- setNames(rep(1L, 3), ids); g <- setNames(c(1L, 1L, 2L), ids)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(tied))
  pw <- postrank_pairwise(postrank_toy)
  s <- postrank_settings(math_review_weights, q = c(need_B = .4375 - 5e-6 / 2), G_max = 3L)
  problem <- postrank_problem(pw, settings = s)
  loose <- postrank_solve(problem, backend = "highs", control = list(tolerances = list(feasibility = 1e-5)))
  strict <- postrank_solve(problem, backend = "highs", control = list(tolerances = list(feasibility = 1e-7)))
  lc <- postrank_compare(loose, supplied = g, baselines = character())
  sc <- postrank_compare(strict, supplied = g, baselines = character())
  expect_true(lc$table$family_feasible[2]); expect_false(sc$table$family_feasible[2])
  expect_identical(lc$provenance$family_feasibility_tolerance, 1e-5)
  expect_identical(sc$provenance$family_feasibility_tolerance, 1e-7)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(NULL, status = "time_limit", lower = -1))
  absent <- postrank_solve(problem, backend = "highs")
  cc <- postrank_compare(strict, timed_out = absent, baselines = character())
  expect_true(is.na(cc$table$family_feasible[2])); expect_true(is.na(cc$table$feasibility_reason[2]))
  expect_identical(cc$table$reason[2], "no_validated_incumbent")
})

test_that("PKG-01: comparison print and both views mark outside-family actions", {
  ids <- postrank_toy$entity_ids
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(setNames(rep(1L, 3), ids)))
  fit <- math_review_fit(postrank_settings(math_review_weights, q = c(need_B = 0), G_max = 3L))
  cmp <- postrank_compare(fit, supplied = setNames(c(1L, 1L, 2L), ids), baselines = character())
  txt <- paste(format_postrank_comparison_cli(cmp, width = 120), collapse = "\n")
  expect_match(txt, "Outside declared family", fixed = TRUE)
  expect_match(txt, "protection_violation:need_B", fixed = TRUE)
  for (view in c("summary", "relations")) {
    p <- postrank_plot_compare(cmp, view = view)
    expect_match(gsub("[[:space:]]+", " ", p$labels$subtitle), "Outside declared family", fixed = TRUE)
    expect_match(unname(p$scales$get_scales("y")$labels["supplied"]), "outside family", fixed = TRUE)
    expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  }
  legacy <- cmp; legacy$table$family_feasible <- legacy$table$feasibility_reason <- NULL
  expect_match(paste(format_postrank_comparison_cli(legacy), collapse = "\n"), "was not recorded", fixed = TRUE)
  expect_match(postrank_plot_compare(legacy)$labels$subtitle, "not recorded", fixed = TRUE)
})

test_that("PKG-03: method-name suffix collisions never cross-wire relations", {
  ids <- postrank_toy$entity_ids
  reference <- setNames(c(1L, 1L, 2L), ids)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(reference))
  fit <- math_review_fit(postrank_settings(math_review_weights, G_max = 3L))
  actions <- list(setNames(rep(1L, 3), ids), setNames(1:3, ids), setNames(3:1, ids))
  names(actions) <- c("other", "other_2", "other")
  cmp <- do.call(postrank_compare, c(list(x = fit, baselines = character()), actions))
  expect_identical(cmp$table$method, c("joint", "other", "other_2", "other_3"))
  # Independently compare unordered pairs of integer labels, without the package relation helper.
  pair <- combn(3L, 2L); r0 <- sign(reference[pair[2, ]] - reference[pair[1, ]])
  for (i in seq_along(actions)) {
    g <- actions[[i]]; r <- sign(g[pair[2, ]] - g[pair[1, ]])
    expected <- c(sum(r0 == r), sum(r0 == 0 & r != 0), sum(r0 != 0 & r == 0), sum(r0 * r == -1))
    expect_equal(unname(unlist(cmp$relations[i, c("n_same", "n_new_disclosed", "n_new_withheld", "n_reversed")])), expected)
  }
  expect_equal(cmp$relations$n_reversed[3], 2)
  expect_identical(.pr_unique_comparison_methods(c("joint", "joint", "joint_2", "joint_3", "joint")),
    c("joint", "joint_4", "joint_2", "joint_3", "joint_5"))
  corrupt <- cmp; colnames(corrupt$grades)[4] <- "other_2"
  expect_error(.pr_validate_comparison(corrupt), class = "postrank_input_error")
  for (view in c("summary", "relations")) expect_s3_class(ggplot2::ggplot_build(postrank_plot_compare(cmp, view)), "ggplot_built")
})

test_that("PKG-04: full and OAT grids contain the same requested weight-only policies", {
  base <- postrank_settings(math_review_weights, G_max = 3L)
  profiles <- list(base = c(need_A = .2, need_B = .8), reference = c(need_A = .8, need_B = .2))
  full <- postrank_settings_grid(base, weights = profiles, design = "full")
  oat <- postrank_settings_grid(base, weights = profiles)
  expect_identical(nrow(full), 3L); expect_identical(nrow(oat), 3L)
  expect_setequal(vapply(full$settings, function(s) paste(s$weights, collapse = ":"), ""),
    vapply(oat$settings, function(s) paste(s$weights, collapse = ":"), ""))
  expect_false(anyDuplicated(full$label) > 0L); expect_false(anyDuplicated(oat$label) > 0L)
  with_q <- postrank_settings_grid(base, weights = profiles[1], q = list(need_A = c(.2, .4)), design = "full")
  expect_identical(nrow(with_q), 6L)
  expect_identical(sum(with_q$is_reference), 1L)
})

test_that("PKG-04: duplicated or missing profile and budget names are refused", {
  base <- postrank_settings(math_review_weights, G_max = 3L)
  for (bad_names in list(c("x", "x"), c("x", NA_character_), c("x", " "))) {
    profiles <- setNames(list(math_review_weights, rev(math_review_weights)), bad_names)
    budgets <- setNames(list(.2, .4), bad_names)
    for (design in c("full", "one_at_a_time")) {
      expect_error(postrank_settings_grid(base, weights = profiles, design = design), class = "postrank_input_error")
      expect_error(postrank_settings_grid(base, q = budgets, design = design), class = "postrank_input_error")
    }
  }
})

test_that("PKG-04: NA budget values cannot masquerade as the full-grid base sentinel", {
  base <- postrank_settings(math_review_weights, G_max = 3L)
  for (design in c("full", "one_at_a_time")) {
    for (bad in list(NA_real_, c(.2, NA_real_), numeric(), Inf, -.1, 1.1, "0.2", TRUE))
      expect_error(postrank_settings_grid(base, q = list(need_A = bad), design = design), class = "postrank_input_error")
    expect_error(postrank_settings_grid(base, q = list(unknown = .2), design = design), class = "postrank_input_error")
  }
})

test_that("PKG-08: grade caps are validated before integer conversion in both designs", {
  base <- postrank_settings(math_review_weights, G_max = 3L)
  for (design in c("full", "one_at_a_time")) {
    for (bad in list(2.9, c(2, 2.9), 0, -1, NA_real_, Inf, "2", TRUE, .Machine$integer.max + 1)) {
      err <- tryCatch(postrank_settings_grid(base, G_max = bad, design = design), error = identity)
      expect_s3_class(err, "postrank_input_error")
      expect_identical(err$code, "invalid_grade_limit")
    }
    a <- postrank_settings_grid(base, G_max = 2, design = design)
    b <- postrank_settings_grid(base, G_max = 2L, design = design)
    expect_identical(a$G_max, b$G_max)
  }
})

test_that("PKG-17: numeric labels round-trip and user labels cannot collide", {
  base <- postrank_settings(math_review_weights, G_max = 3L)
  values <- c(.1, .4, .25000000001, .25000000002, 1e-30, .Machine$double.xmin)
  labels <- vapply(values, .pr_grid_num, "")
  expect_identical(as.numeric(labels), values)
  expect_identical(labels[1:2], c("0.10", "0.40"))
  for (design in c("full", "one_at_a_time")) {
    g <- postrank_settings_grid(base, tau = values[1:5], q = list(need_A = c(.25000000001, .25000000002)), design = design)
    expect_identical(anyDuplicated(g$label), 0L)
    expect_identical(anyDuplicated(g$setting_id), 0L)
  }
  g <- postrank_settings_grid(base, tau = .1, weights = list(`tau=0.10` = c(need_A = .2, need_B = .8)))
  expect_identical(anyDuplicated(g$label), 0L)
  expect_match(g$label[3], "S03", fixed = TRUE)
})

test_that("PKG-09: one-component mixture intervals equal analytic Gaussian intervals at tiny units", {
  for (unit in c(1, 1e-8, 1e-12, 1e-16)) {
    mx <- math_review_mixture(0, 1, 1, unit = unit)
    before <- mx$coefficient_identity
    s <- postrank_posterior_means(mx, level = .9)
    got <- c(attr(s, "lower")["A", "k1"], attr(s, "upper")["A", "k1"]) / unit
    expect_equal(got, stats::qnorm(c(.05, .95)), tolerance = 1e-12)
    expect_equal(diff(stats::pnorm(got)), .9, tolerance = 1e-12)
    expect_identical(mx$coefficient_identity, before)
    expect_true(validate_postrank_coefficients(mx, recompute = TRUE))
  }
})

test_that("PKG-09: mixture quantiles are affine-equivariant and have small CDF residuals", {
  for (spec in list(list(m = c(-1, 1), s = c(.4, 1.2), w = c(.3, .7)),
    list(m = c(-10, 10), s = c(.01, 3), w = c(.5, .5)))) {
    m <- spec$m; sd <- spec$s; w <- spec$w
    F <- function(z) sum(w * stats::pnorm(z, mean = m, sd = sd))
    for (level in c(.5, .9, .99)) {
      p <- c((1 - level) / 2, 1 - (1 - level) / 2)
      q <- .pr_mixture_quantile(m, sd, w, p)
      expect_lte(max(abs(vapply(q, F, 1) - p)), 1e-10)
      for (unit in c(1e-16, 1e-8, 1, 1e8)) {
        shift <- 3 * unit
        transformed <- .pr_mixture_quantile(shift + unit * m, unit * sd, w, p)
        expect_equal((transformed - shift) / unit, q, tolerance = 1e-10)
      }
      expect_equal(.pr_mixture_quantile(rev(m), rev(sd), rev(w), p), q, tolerance = 1e-10)
      expect_equal(.pr_mixture_quantile(c(m, 1e100), c(sd, 1), c(w, 0), p), q, tolerance = 1e-10)
    }
  }
})

test_that("PKG-09: impossible target-unit rounding is an explicit numerical failure", {
  e <- tryCatch(.pr_mixture_quantile(1e20, 1, 1, c(.05, .95)), error = identity)
  expect_s3_class(e, "postrank_input_error")
  expect_identical(e$code, "posterior_quantile_failure")
})
