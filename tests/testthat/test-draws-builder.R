# 014 repair Phase 4 (AP-2): the array builder keeps the scientific
# declarations required and generates the bookkeeping.
pr_builder_args <- function(values, ...) {
  K <- dim(values)[3L]; criteria <- dimnames(values)[[3L]]
  c(list(values = values,
    targets = data.frame(criterion_id = criteria, estimand = "Synthetic latent need", entity_population = "Synthetic sites",
      time_reference = "Test", units = "standardized"),
    context = list(cohort_id = "builder-test", data_version = "1", data_conditioning = "Synthetic test values",
      model_summary = "Independent Normal draws"),
    provenance = list(producer = "postrank tests", artifact_id = "builder-array", construction_note = "test-draws-builder.R",
      created_at = "2026-10-19T00:00:00Z"),
    origin = list(source_id = "test", fit_id = "none", model_id = "normal", source_format = "R array", source_artifact = "tests"),
    identification_note = "Targets are the simulated coordinates.",
    tie_justification = "Continuous Normal draws; exact ties have probability zero.",
    joint_generation = "Each draw holds every site and criterion from one simulated state.",
    sampling_provenance = "Simulated in the test."), list(...))
}

testthat::test_that("IID arrays become validated draws with the same pairwise coefficients", {
  set.seed(101); v <- array(stats::rnorm(40 * 5 * 2), c(40, 5, 2), dimnames = list(NULL, LETTERS[1:5], c("need1", "need2")))
  d <- do.call(postrank_draws_from_array, pr_builder_args(v))
  testthat::expect_s3_class(d, "postrank_draws")
  testthat::expect_identical(d$entity_ids, LETTERS[1:5]); testthat::expect_identical(d$criterion_ids, c("need1", "need2"))
  pw <- postrank_pairwise(d)
  testthat::expect_equal(unname(pw$e), pr_oracle_e_from_draws(unname(v)))
  again <- do.call(postrank_draws_from_array, pr_builder_args(v))
  testthat::expect_identical(again$validation$input_identity, d$validation$input_identity)
})

testthat::test_that("MCMC arrays get chain-major history with warmup and thinning", {
  set.seed(102); v <- array(stats::rnorm(60 * 4 * 2), c(60, 4, 2), dimnames = list(NULL, paste0("s", 1:4), c("a", "b")))
  d <- do.call(postrank_draws_from_array, pr_builder_args(v, regime = "mcmc", chains = 3L, warmup_per_chain = 100L, thin = 2L))
  h <- d$joint_draws$sampling$chain_history
  testthat::expect_identical(vapply(h, `[[`, "", "chain_id"), c("chain1", "chain2", "chain3"))
  testthat::expect_equal(h[[1]]$retained_iterations, 100 + 2 * (1:20))
  testthat::expect_equal(h[[2]]$discarded_sampling_iterations, 100 + 2 * (1:20) - 1)
  testthat::expect_identical(d$joint_draws$draw_index[[21]]$chain_id, "chain2")
  testthat::skip_if_not_installed("posterior")
  fr <- postrank_mc_fragility(d, settings = list(weights = c(a = .5, b = .5), tau = .25, G_max = 2L), screen_margin = 1)
  testthat::expect_identical(fr$mcse_method, "posterior::mcse_mean"); testthat::expect_false(anyNA(fr$pairs$mcse))
})

testthat::test_that("the builder refuses missing declarations, bad layouts and ties", {
  set.seed(103); v <- array(stats::rnorm(20 * 3 * 1), c(20, 3, 1), dimnames = list(NULL, c("x", "y", "z"), "k"))
  args <- pr_builder_args(v); dimnames(args$values) <- NULL
  testthat::expect_error(do.call(postrank_draws_from_array, args), class = "postrank_input_error")
  # 20 draws do not split into 3 equal chains.
  testthat::expect_error(do.call(postrank_draws_from_array, pr_builder_args(v, regime = "mcmc", chains = 3L,
    warmup_per_chain = 0L, thin = 1L)), class = "postrank_input_error")
  # The MCMC chain layout is a declaration: missing parts are refused, not assumed.
  err <- tryCatch(do.call(postrank_draws_from_array, pr_builder_args(v, regime = "mcmc", chains = 2L)), error = identity)
  testthat::expect_s3_class(err, "postrank_input_error"); testthat::expect_match(conditionMessage(err), "warmup_per_chain, thin")
  testthat::expect_error(do.call(postrank_draws_from_array, pr_builder_args(v, regime = "mcmc", warmup_per_chain = 0L, thin = 1L)),
    "explicit chains", class = "postrank_input_error")
  testthat::expect_error(do.call(postrank_draws_from_array, pr_builder_args(v, chains = 1L)), "leave them unset for IID",
    class = "postrank_input_error")
  args <- pr_builder_args(v); args$tie_justification <- ""
  testthat::expect_error(do.call(postrank_draws_from_array, args), class = "postrank_input_error")
  args <- pr_builder_args(v); args$context$model_summary <- NULL
  testthat::expect_error(do.call(postrank_draws_from_array, args), class = "postrank_input_error")
  tied <- v; tied[3, 2, 1] <- tied[3, 1, 1]
  err <- tryCatch(do.call(postrank_draws_from_array, pr_builder_args(tied)), error = identity)
  testthat::expect_s3_class(err, "postrank_input_error"); testthat::expect_identical(err$code, "observed_target_tie")
})
