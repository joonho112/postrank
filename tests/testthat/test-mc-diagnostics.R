# 014 repair Phase 3 (Step 3.2): cross-fitted risk and MC-fragile pairs.
pr_multichain_payload <- function(seed, chains, per_chain, n, K) {
  x <- pr_random_payload(seed, chains * per_chain, n, K)
  S <- chains * per_chain; chain_of <- rep(seq_len(chains), each = per_chain); iter_of <- rep(seq_len(per_chain), times = chains) + 2L
  slots <- x$joint_draws$tensor$dimnames$draw
  x$joint_draws$draw_index <- lapply(seq_len(S), function(s) list(slot_id = slots[s], original_draw_id = paste0("orig", s),
    chain_id = paste0("chain", chain_of[s]), iteration = iter_of[s]))
  x$joint_draws$sampling <- list(regime = "mcmc", target_distribution = "declared_posterior", equal_weight = TRUE,
    warmup_status = "removed", sampling_provenance = "Explicit synthetic testing fixture; not evidence of posterior sampling.",
    chain_history = lapply(seq_len(chains), function(c) list(chain_id = paste0("chain", c),
      retained_iterations = seq_len(per_chain) + 2L, warmup_iterations = 1:2, discarded_sampling_iterations = integer(),
      selection_note = "Synthetic retained indices; no thinning.")))
  x
}

pr_risk_from_values <- function(values, grade, w, tau) {
  e <- pr_oracle_e_from_draws(values); x <- outer(grade, grade, `<`); n <- length(grade); M <- choose(n, 2); N <- sum(x)
  (sum(vapply(seq_along(w), function(k) w[[k]] * sum(e[, , k][x]), numeric(1L))) + tau * (M - N)) / M
}

testthat::test_that("IID cross-fitting evaluates each fold grade on the other half of the draws", {
  testthat::skip_if_not_installed("highs")
  x <- pr_random_payload(81L, 40L, 6L, 2L, conflict = FALSE); w <- c(need1 = .6, need2 = .4)
  cf <- postrank_crossfit(x, settings = list(weights = w, tau = .3, G_max = 3L), backend = "highs", control = list(time_limit = 20))
  testthat::expect_s3_class(cf, "postrank_crossfit")
  testthat::expect_identical(cf$interpretation_support, list(risk_functional = "linear_weighted",
    fold_optimism_unbiasedness = "conditional_on_independent_target_iid_folds"))
  testthat::expect_identical(cf$split$method, "iid_halves"); testthat::expect_identical(unname(cf$split$sizes), c(20L, 20L))
  v <- x$joint_draws$tensor$values; halves <- list(A = v[1:20, , , drop = FALSE], B = v[21:40, , , drop = FALSE])
  for (f in c("A", "B")) {
    r <- cf$folds[[f]]; g <- unname(r$grade); other <- if (f == "A") "B" else "A"
    testthat::expect_identical(r$status, "optimal")
    testthat::expect_equal(r$in_fold_risk, pr_risk_from_values(halves[[f]], g, w, .3), tolerance = 1e-12)
    testthat::expect_equal(r$out_of_fold_risk, pr_risk_from_values(halves[[other]], g, w, .3), tolerance = 1e-12)
    testthat::expect_equal(r$optimism, r$out_of_fold_risk - r$in_fold_risk)
  }
  testthat::expect_true(cf$agreement$between_folds >= 0 && cf$agreement$between_folds <= 1)
})

testthat::test_that("MCMC cross-fitting splits whole chains and compares with the full-data grade", {
  testthat::skip_if_not_installed("highs")
  x <- pr_multichain_payload(82L, 4L, 15L, 5L, 2L); w <- c(need1 = .5, need2 = .5)
  full <- postrank_solve(postrank_problem(postrank_pairwise(x), w, .3, 3L), "highs", list(time_limit = 20))
  cf <- postrank_crossfit(x, fit = full, backend = "highs", control = list(time_limit = 20))
  testthat::expect_identical(cf$split$method, "mcmc_chain_groups")
  testthat::expect_identical(cf$interpretation_support, list(risk_functional = "linear_weighted",
    fold_optimism_unbiasedness = "not_claimed"))
  testthat::expect_identical(cf$split$chains, list(A = c("chain1", "chain2"), B = c("chain3", "chain4")))
  testthat::expect_true(all(c("full_vs_A", "full_vs_B") %in% names(cf$agreement)))
  testthat::expect_true(is.finite(cf$folds$A$full_grade_risk_on_fold))
  single <- postrank_crossfit(pr_test_payload(S = 8L, n = 4L, K = 2L, regime = "mcmc"), settings = list(weights = w, tau = .3, G_max = 2L),
    backend = "highs", control = list(time_limit = 20))
  testthat::expect_identical(single$split$method, "mcmc_single_chain_halves"); testthat::expect_length(single$warnings, 1L)
  testthat::expect_identical(single$interpretation_support$fold_optimism_unbiasedness, "not_claimed")
})

testthat::test_that("fragility flags equal the margin-versus-MCSE definition over all pairs (IID)", {
  x <- pr_random_payload(83L, 60L, 7L, 2L, conflict = TRUE); w <- c(need1 = .5, need2 = .5); tau <- .25
  fr <- postrank_mc_fragility(x, settings = list(weights = w, tau = tau, G_max = 3L), z = 2)
  v <- x$joint_draws$tensor$values; n <- 7L; S <- 60L; brute <- character()
  for (i in 1:(n - 1)) for (j in (i + 1):n) {
    tij <- w[[1]] * (v[, i, 1] <= v[, j, 1]) + w[[2]] * (v[, i, 2] <= v[, j, 2])
    tji <- w[[1]] * (v[, j, 1] <= v[, i, 1]) + w[[2]] * (v[, j, 2] <= v[, i, 2])
    trace <- if (mean(tij) <= mean(tji)) tij else tji
    if (abs(mean(trace) - tau) < 2 * stats::sd(trace) / sqrt(S)) brute <- c(brute, paste(sprintf("%03d", i), sprintf("%03d", j)))
  }
  got <- with(fr$pairs[fr$pairs$fragile, ], paste(entity_i, entity_j))
  testthat::expect_setequal(got, brute)
  testthat::expect_identical(fr$summary$fragile, length(brute))
  testthat::expect_true(fr$screen_margin >= 2 * .5 / sqrt(S - 1) - 1e-15)
})

testthat::test_that("fragility uses posterior::mcse_mean over chains for MCMC and reports grade relations", {
  testthat::skip_if_not_installed("posterior"); testthat::skip_if_not_installed("highs")
  x <- pr_multichain_payload(84L, 3L, 30L, 5L, 2L); w <- c(need1 = .5, need2 = .5); tau <- .25
  fit <- postrank_solve(postrank_problem(postrank_pairwise(x), w, tau, 3L), "highs", list(time_limit = 20))
  fr <- postrank_mc_fragility(x, fit = fit, screen_margin = 1)
  testthat::expect_identical(fr$mcse_method, "posterior::mcse_mean"); testthat::expect_identical(fr$summary$traced, 10L)
  v <- x$joint_draws$tensor$values; row <- fr$pairs[1, ]
  i <- match(row$entity_i, x$entity_ids); j <- match(row$entity_j, x$entity_ids)
  if (row$better_direction == "j_ahead") { k <- i; i <- j; j <- k }
  trace <- w[[1]] * (v[, i, 1] <= v[, j, 1]) + w[[2]] * (v[, i, 2] <= v[, j, 2])
  testthat::expect_equal(row$mcse, posterior::mcse_mean(matrix(trace, ncol = 3L)))
  g <- unname(fit$grade[x$entity_ids])
  rel <- vapply(seq_len(nrow(fr$pairs)), function(r) {
    a <- match(fr$pairs$entity_i[r], x$entity_ids); b <- match(fr$pairs$entity_j[r], x$entity_ids)
    if (g[a] == g[b]) "tied" else if ((g[a] < g[b]) == (fr$pairs$better_direction[r] == "i_ahead")) "disclosed_better_direction" else "disclosed_reverse"
  }, character(1L))
  testthat::expect_identical(fr$pairs$relation_in_grade, rel)
})

testthat::test_that("MC diagnostics refuse criterionwise input and ambiguous settings", {
  testthat::expect_error(postrank_mc_fragility(pr_test_criterionwise(), settings = list(weights = c(need1 = .5, need2 = .5), tau = .25, G_max = 2L)),
    class = "postrank_input_error")
  testthat::expect_error(postrank_mc_fragility(pr_test_payload()), class = "postrank_input_error")
})

pr_layout_payload <- function(seed, lengths, n, K, interleaved = FALSE) {
  S <- sum(lengths); x <- pr_random_payload(seed, S, n, K); C <- length(lengths)
  if (interleaved) { stopifnot(length(unique(lengths)) == 1L); chain_of <- rep(seq_len(C), times = lengths[1L]); iter_of <- rep(seq_len(lengths[1L]), each = C) + 2L }
  else { chain_of <- rep(seq_len(C), times = lengths); iter_of <- unlist(lapply(lengths, seq_len)) + 2L }
  slots <- x$joint_draws$tensor$dimnames$draw
  x$joint_draws$draw_index <- lapply(seq_len(S), function(s) list(slot_id = slots[s], original_draw_id = paste0("orig", s),
    chain_id = paste0("chain", chain_of[s]), iteration = iter_of[s]))
  x$joint_draws$sampling <- list(regime = "mcmc", target_distribution = "declared_posterior", equal_weight = TRUE,
    warmup_status = "removed", sampling_provenance = "Explicit synthetic testing fixture.",
    chain_history = lapply(seq_len(C), function(c) list(chain_id = paste0("chain", c), retained_iterations = seq_len(lengths[c]) + 2L,
      warmup_iterations = 1:2, discarded_sampling_iterations = integer(), selection_note = "Synthetic.")))
  list(payload = x, chain_of = chain_of, iter_of = iter_of)
}

testthat::test_that("interleaved chain storage is arranged by original chain and iteration", {
  testthat::skip_if_not_installed("posterior"); testthat::skip_if_not_installed("highs")
  lay <- pr_layout_payload(85L, c(20, 20, 20), 5L, 2L, interleaved = TRUE); x <- lay$payload; w <- c(need1 = .5, need2 = .5)
  cf <- postrank_crossfit(x, settings = list(weights = w, tau = .25, G_max = 3L), backend = "highs", control = list(time_limit = 10))
  testthat::expect_identical(cf$split$chains$A, c("chain1", "chain2")); testthat::expect_identical(unname(cf$split$sizes), c(40L, 20L))
  fr <- postrank_mc_fragility(x, settings = list(weights = w, tau = .25), screen_margin = 1)
  v <- x$joint_draws$tensor$values; row <- fr$pairs[1, ]
  i <- match(row$entity_i, x$entity_ids); j <- match(row$entity_j, x$entity_ids)
  if (row$better_direction == "j_ahead") { k <- i; i <- j; j <- k }
  trace <- w[[1]] * (v[, i, 1] <= v[, j, 1]) + w[[2]] * (v[, i, 2] <= v[, j, 2])
  arranged <- sapply(1:3, function(c) trace[lay$chain_of == c][order(lay$iter_of[lay$chain_of == c])])
  testthat::expect_equal(row$mcse, suppressWarnings(posterior::mcse_mean(arranged)))
})

testthat::test_that("unequal chains report unavailable fragility instead of zero", {
  lay <- pr_layout_payload(86L, c(20, 20, 15), 4L, 2L)
  fr <- postrank_mc_fragility(lay$payload, settings = list(weights = c(need1 = .5, need2 = .5), tau = .25), screen_margin = 1)
  testthat::expect_true(is.na(fr$summary$fragile)); testthat::expect_match(fr$mcse_method, "not_computed")
})

testthat::test_that("MC diagnostics validate the loss settings", {
  x <- pr_random_payload(87L, 20L, 4L, 2L)
  for (bad in list(list(weights = c(a = .5, b = .5), tau = .25), list(weights = c(need1 = 1, need2 = 1), tau = .25),
                   list(weights = c(need1 = 1.5, need2 = -.5), tau = .25), list(weights = c(need1 = .5, need2 = .5), tau = .9)))
    testthat::expect_error(postrank_mc_fragility(x, settings = bad), class = "postrank_input_error")
})

# AUD-02: exact enumeration, not a Monte Carlo simulation. The target law has
# two equally likely states with opposing criterion errors (0,1) and (1,0).
# With exact_G=2 every selected grade's true risk is 1/2 under either objective.
testthat::test_that("cross-fit unbiasedness is confined to independent IID linear risk, not empirical minimax", {
  testthat::skip_if_not_installed("highs")
  patterns <- as.matrix(expand.grid(rep(list(0:1), 4L)))
  records <- vector("list", 2L * nrow(patterns)); cursor <- 0L
  support <- list()
  for (mode in c("weighted", "minimax")) for (r in seq_len(nrow(patterns))) {
    x <- pr_test_payload(S = 4L, n = 2L, K = 2L)
    for (j in seq_len(4L)) {
      x$joint_draws$tensor$values[j, , 1L] <- if (patterns[r, j]) c(1, 2) else c(2, 1)
      x$joint_draws$tensor$values[j, , 2L] <- if (patterns[r, j]) c(2, 1) else c(1, 2)
    }
    cf <- postrank_crossfit(x, settings = list(weights = c(need1 = .75, need2 = .25),
      tau = .25, G_max = 2L, exact_G = 2L, objective = mode),
      backend = "highs", control = list(time_limit = 5))
    testthat::expect_identical(cf$folds_with_incumbent, 2L)
    testthat::expect_true(all(vapply(cf$folds, function(f) length(unique(f$grade)) == 2L, logical(1L))))
    # The conditional target risk is known from the two-state law, independently
    # of the solver or postrank risk evaluation, even when the selected direction changes.
    cursor <- cursor + 1L
    records[[cursor]] <- data.frame(mode = mode, in_A = cf$folds$A$in_fold_risk,
      out_A = cf$folds$A$out_of_fold_risk, reported_A = cf$folds$A$optimism,
      true_A = .5 - cf$folds$A$in_fold_risk)
    support[[mode]] <- cf$interpretation_support
  }
  result <- do.call(rbind, records)
  weighted <- result[result$mode == "weighted", ]
  minimax <- result[result$mode == "minimax", ]
  # The weighted problem has genuine selection optimism: this is not a vacuous
  # equality from using a fixed grade or identically zero optimism.
  testthat::expect_equal(mean(weighted$out_A), .5, tolerance = 1e-12)
  testthat::expect_equal(mean(weighted$reported_A), .125, tolerance = 1e-12)
  testthat::expect_equal(mean(weighted$reported_A), mean(weighted$true_A), tolerance = 1e-12)
  testthat::expect_identical(support$weighted, list(risk_functional = "linear_weighted",
    fold_optimism_unbiasedness = "conditional_on_independent_target_iid_folds"))
  # An empirical maximum of individually unbiased criterion risks is biased:
  # evaluation-fold risk averages .75 while the true selected-grade risk is .5.
  testthat::expect_equal(mean(minimax$out_A), .75, tolerance = 1e-12)
  testthat::expect_equal(mean(minimax$reported_A), 0, tolerance = 1e-12)
  testthat::expect_equal(mean(minimax$true_A), -.25, tolerance = 1e-12)
  testthat::expect_identical(support$minimax, list(risk_functional = "empirical_maximum",
    fold_optimism_unbiasedness = "not_claimed"))
})
