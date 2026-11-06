# Direct beta-tail arithmetic, independent of the archived integration helpers.
cde_log_difference <- function(large, small) {
  ans <- large + log(-expm1(pmin(0, small - large)))
  ans[is.infinite(large) & large < 0] <- -Inf
  ans
}
cde_log_beta_mass <- function(lo, hi, a, b) {
  lhi <- pbeta(hi, a, b, log.p = TRUE)
  left <- cde_log_difference(lhi, pbeta(lo, a, b, log.p = TRUE))
  right <- cde_log_difference(pbeta(lo, a, b, lower.tail = FALSE, log.p = TRUE),
    pbeta(hi, a, b, lower.tail = FALSE, log.p = TRUE))
  ifelse(lhi < log(.5), left, right)
}
cde_cdf <- function(q, i, x = pr_case_cde) {
  law <- x$reference$frozen_posterior
  lo <- head(law$edges, -1L); hi <- tail(law$edges, -1L)
  a <- x$units$chronic_absent_count[i] + 1
  b <- x$units$eligible_count[i] - a + 2
  w <- law$posterior_bin_masses[i, ]
  vapply(q, function(z) {
    if (z <= 0) return(0)
    if (z >= 1) return(1)
    bin <- findInterval(z, law$edges, all.inside = TRUE)
    part <- exp(cde_log_beta_mass(lo[bin], z, a, b) - cde_log_beta_mass(lo[bin], hi[bin], a, b))
    sum(w[hi <= z]) + w[bin] * part
  }, 0)
}
cde_direct_loss <- function(grade, e, tau) {
  total <- 0; N <- 0L
  for (i in seq_len(length(grade) - 1L)) for (j in seq.int(i + 1L, length(grade))) {
    if (grade[i] == grade[j]) total <- total + tau
    else {
      N <- N + 1L
      total <- total + if (grade[i] < grade[j]) e[i, j] else e[j, i]
    }
  }
  list(risk = total / choose(length(grade), 2L), N = N)
}

test_that("CDE preserves the twelve-school selection and oriented K1 summaries", {
  x <- pr_case_cde
  expect_identical(names(x), c("input", "units", "alternatives", "reference", "provenance"))
  expect_identical(class(x), "list")
  expect_identical(nrow(x$units), 12L)
  expect_identical(x$units$entity_id, x$input$entity_ids)
  expect_true(all(grepl("^[0-9]{14}$", x$units$entity_id)))
  expect_true(any(substr(x$units$entity_id, 1, 1) == "0"))
  expect_equal(unname(table(x$units$observed_rate_group, x$units$denominator_group)),
    matrix(1L, 4L, 3L), ignore_attr = TRUE)
  expect_equal(x$units$observed_rate, x$units$chronic_absent_count / x$units$eligible_count)
  expect_equal(sum(x$provenance$full_frame_stratum_counts), 5834)
  expect_match(x$provenance$selection_rule, "not a representative")
  for (input in c(list(x$input), x$alternatives)) {
    expect_true(validate_postrank_probabilities(input))
    expect_identical(input$event, "higher_priority")
    expect_identical(input$criterion_ids, "negative_chronic_absence")
    expect_identical(input$source$kind, "numerical_integration")
    expect_true(all(is.na(input$sample_sizes)))
    expect_false(input$capabilities$target_draws)
    expect_false(input$validation$numerical_certification)
    means <- postrank_posterior_means(input, level = .9)
    law <- x$reference$frozen_posterior
    expect_equal(as.numeric(means), -law$original_p_mean)
    expect_equal(as.numeric(attr(means, "lower")), -law$original_p_q95)
    expect_equal(as.numeric(attr(means, "upper")), -law$original_p_q05)
    expect_error(postrank_posterior_means(input, level = .95), "level")
  }
})

test_that("CDE continuous posterior weights and quantiles agree with the frozen G", {
  x <- pr_case_cde; law <- x$reference$frozen_posterior
  lo <- head(law$edges, -1L); hi <- tail(law$edges, -1L)
  expect_length(law$prior_bin_masses, 161L)
  expect_equal(sum(law$prior_bin_masses), 1, tolerance = 1e-14)
  expect_identical(rownames(law$posterior_bin_masses), x$units$entity_id)
  for (i in seq_len(nrow(x$units))) {
    a <- x$units$chronic_absent_count[i] + 1
    b <- x$units$eligible_count[i] - a + 2
    # G is uniform within a prior bin; likelihood multiplication yields a
    # truncated Beta posterior. Bin midpoint atoms would fail these checks.
    logmass <- cde_log_beta_mass(lo, hi, a, b)
    z <- log(law$prior_bin_masses) - log(hi - lo) + logmass
    w <- exp(z - max(z)); w <- w / sum(w)
    expect_equal(w, unname(law$posterior_bin_masses[i, ]), tolerance = 1e-12)
    moment <- a / (a + b) * exp(cde_log_beta_mass(lo, hi, a + 1, b) - logmass)
    keep <- w > 1e-14
    expect_equal(sum(w[keep] * moment[keep]), law$original_p_mean[i], tolerance = 1e-11)
    expect_equal(cde_cdf(c(law$original_p_q05[i], law$original_p_q95[i]), i), c(.05, .95), tolerance = 1e-9)
  }
})

test_that("CDE raw integration and its two separate corrections remain inspectable", {
  x <- pr_case_cde; q <- x$reference$quadrature
  inputs <- c(list(order_16 = x$input), x$alternatives)
  expect_identical(q$checks$order, c(16L, 32L, 64L))
  expect_true(all(q$checks$mass_error <= 1e-7))
  expect_true(all(q$checks$complement_error <= 1e-6))
  expect_true(all(q$checks$next_order_maximum_difference[1:2] <= 1e-4))
  expect_false(q$mass_renormalized)
  expect_false(q$probability_floor)
  expect_false(q$numerical_certification)
  for (name in names(inputs)) {
    raw <- q$raw_integrals[[name]]; receipt <- q$upstream_bound_receipts[[name]]
    bounded <- raw; bounded[] <- pmin(1, pmax(0, raw))
    changed <- which(bounded != raw)
    expect_identical(receipt$changed_indices, changed)
    expect_identical(receipt$raw_values, raw[changed])
    expect_lte(receipt$maximum_correction, 64 * .Machine$double.eps)
    diag(bounded) <- NA_real_
    expect_equal(inputs[[name]]$raw_probabilities[, , 1L], bounded, ignore_attr = TRUE)
    expect_identical(inputs[[name]]$correction$method, "symmetric")
    expect_identical(inputs[[name]]$correction$tolerance, 1e-6)
    expect_equal(inputs[[name]]$e, 1 - inputs[[name]]$corrected_probabilities)
  }
  # Independent adaptive integration for a close pair uses the retained
  # truncated-Beta law, rather than the source's fixed Legendre-node code.
  law <- x$reference$frozen_posterior
  lo <- head(law$edges, -1L); hi <- tail(law$edges, -1L)
  i <- 1L; j <- 2L; a <- x$units$chronic_absent_count[i] + 1
  b <- x$units$eligible_count[i] - a + 2
  w <- law$posterior_bin_masses[i, ]; keep <- which(w > 1e-12)
  values <- vapply(keep, function(k) {
    normalizer <- cde_log_beta_mass(lo[k], hi[k], a, b)
    integrate(function(p) exp(dbeta(p, a, b, log = TRUE) - normalizer) *
      w[k] * (1 - cde_cdf(p, j)), lo[k], hi[k], abs.tol = 1e-11, rel.tol = 1e-9)$value
  }, 0)
  expect_equal(sum(values), x$input$raw_probabilities[i, j, 1L], tolerance = 1e-9)
})

test_that("CDE fixed actions and archived statewide metrics retain their distinct scope", {
  x <- pr_case_cde
  for (method in names(x$reference$actions)) {
    grades <- x$reference$actions[[method]]
    direct <- cde_direct_loss(grades, x$input$e[, , 1L], .2)
    actual <- postrank_evaluate(grades, x$input, weights = x$reference$settings$weights, tau = .2)
    stored <- x$reference$metrics[x$reference$metrics$method == method, ]
    expect_equal(actual$primary_risk, direct$risk, tolerance = 1e-12)
    expect_equal(stored$risk, direct$risk, tolerance = 1e-12)
    expect_equal(actual$N, direct$N)
  }
  s <- x$reference$statewide$metrics
  expect_true(all(s$M == choose(x$reference$statewide$schools, 2L)))
  expect_equal(s$risk, (s$E + .2 * (s$M - s$N)) / s$M, tolerance = 1e-12)
  expect_equal(s$E_over_N[s$N > 0], s$E[s$N > 0] / s$N[s$N > 0], tolerance = 1e-12)
  expect_true(all(is.na(s$E_over_N[s$N == 0])))
  expect_false(any(s$unrestricted_optimum_claim))
  expect_false(any(s$numerical_certification))
  primary <- s[s$action_id == "posterior_mean-g3-tau0.2", ]
  expect_equal(primary$N, 11343829)
  expect_equal(primary$risk, .0754867753352028, tolerance = 1e-14)
  expect_equal(primary$risk - primary$risk_lower_bound, primary$absolute_relaxation_gap, tolerance = 1e-14)
  expect_match(x$reference$statewide$interpretation, "not the unrestricted")
})

test_that("CDE local inclusion conditions are explicit and the object is portable", {
  x <- pr_case_cde
  expect_identical(x$provenance$rights$status, "local_preparation_only; redistribution_not_established")
  expect_false(x$provenance$rights$public_distribution_cleared)
  expect_true(is.na(x$provenance$rights$license))
  expect_identical(x$provenance$rights$notice_excerpt_sha256,
    digest::digest(enc2utf8(x$provenance$rights$notice_excerpt), algo = "sha256", serialize = FALSE))
  expect_true(all(grepl("^[0-9a-f]{64}$", x$provenance$source_files$sha256)))
  expect_false(any(grepl("^/|^[A-Za-z]:", x$provenance$source_files$path)))
  inspect <- function(z) {
    issues <- if (is.environment(z) || is.function(z) || is.language(z)) "active object" else character()
    if (is.character(z) && any(grepl("/Users/|/home/|/Library/Frameworks/|POSTRANK_CDE_ROOT", z)))
      issues <- c(issues, "machine path or environment setting")
    if (is.list(z)) issues <- c(issues, unlist(lapply(z, inspect), use.names = FALSE))
    issues
  }
  expect_length(inspect(x), 0L)
})

test_that("CDE small K1 native solution agrees with all thirteen ordered partitions", {
  skip_if_not_installed("highs")
  x <- pr_case_cde; ids <- x$input$entity_ids[1:3]; s <- x$input$summaries
  small <- postrank_probabilities(x$input$corrected_probabilities[ids, ids, 1L],
    event = "higher_priority", zero_ties = TRUE, margin = 0, criterion = x$input$criterion_ids,
    source = x$input$source, targets = x$input$targets,
    summaries = list(means = s$means[ids, , drop = FALSE], lower = s$lower[ids, , drop = FALSE],
      upper = s$upper[ids, , drop = FALSE], level = .9, same_targets = TRUE, description = s$description))
  grades <- as.matrix(expand.grid(rep(list(1:3), 3)))
  grades <- grades[apply(grades, 1L, function(g) identical(sort(unique(as.integer(g))), seq_len(max(g)))), , drop = FALSE]
  colnames(grades) <- ids
  expect_identical(nrow(grades), 13L)
  risk <- apply(grades, 1L, function(g) cde_direct_loss(g, small$e[, , 1L], .2)$risk)
  for (r in seq_len(nrow(grades))) {
    ev <- postrank_evaluate(grades[r, ], small, weights = x$reference$settings$weights, tau = .2)
    expect_equal(ev$primary_risk, risk[r], tolerance = 1e-12)
  }
  a <- postrank(small, tau = .2, G_max = 3L, level = .9, backend = "highs",
    control = list(time_limit = 10, threads = 1), fragility = FALSE)
  expect_true(a$fit$incumbent_validated)
  expect_equal(a$evaluation$primary_risk, min(risk), tolerance = 1e-10)
  expect_lte(a$fit$objective$risk_lower_bound, min(risk) + 1e-10)
  expect_identical(a$report_card$interval_source, "supplied_marginal_summaries")
  expect_identical(a$report_card$level, .9)
})
