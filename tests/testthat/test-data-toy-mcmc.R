# T-doc-11: the fixed MCMC toy with complete declarations reproduces the methods book's
# recorded diagnostics (pooled pair mean exactly; posterior diagnostics at 1e-6).
tm_wrap <- function() postrank_draws(pr_toy_mcmc, regime = "mcmc", chains = 4L, warmup_per_chain = 0L, thin = 1L,
  declarations = attr(pr_toy_mcmc, "law")$declarations)

test_that("the wrapped toy is a valid four-chain MCMC input with declared layout", {
  x <- tm_wrap()
  expect_s3_class(x, "postrank_draws")
  expect_identical(x$joint_draws$sampling$regime, "mcmc")
  expect_length(x$joint_draws$sampling$chain_history, 4L)
  expect_identical(names(attributes(x$joint_draws$tensor$values)), c("dim", "dimnames"))
  expect_identical(dim(pr_toy_mcmc), c(2048L, 3L, 2L))
})

test_that("pooled pair mean is exactly 353/2048 and the known identities hold", {
  x <- tm_wrap()
  pw <- postrank_pairwise(x)
  expect_identical(pw$e["A", "B", "k1"], 353 / 2048)
  law <- attr(pr_toy_mcmc, "law")
  expect_identical(law$known_identities$pooled_pair_mean, 353 / 2048)
  # Known-law optimum checked without a solver: risk of (1,2,2) under the stationary law is 13/60.
  state_e <- function(st) { e <- array(NA_real_, c(3, 3, 2)); for (k in 1:2) for (i in 1:3) for (j in 1:3) if (i != j) e[i, j, k] <- as.numeric(st[i, k] <= st[j, k]); e }
  e_law <- .8 * state_e(law$states$state0) + .2 * state_e(law$states$state1)
  dimnames(e_law) <- list(entity_i = c("A", "B", "C"), entity_j = c("A", "B", "C"), criterion = c("k1", "k2"))
  risk <- function(g) { x <- outer(g, g, `<`); M <- 3; N <- sum(x)
    (sum(c(.6, .4) * vapply(1:2, function(k) sum(e_law[, , k][x]), 1)) + .25 * (M - N)) / M }
  expect_equal(risk(c(1, 2, 2)), 13 / 60, tolerance = 1e-15)
  expect_equal(risk(c(1, 2, 3)), 4 / 15, tolerance = 1e-15)
  # (1, 2, 2) is the known-law optimum over every grade with at most three levels.
  all_risks <- vapply(pr_oracle_ordered_partitions(3L, 3L), risk, 1)
  expect_equal(min(all_risks), 13 / 60, tolerance = 1e-15)
  best <- pr_oracle_ordered_partitions(3L, 3L)[abs(all_risks - 13 / 60) < 1e-12]
  expect_true(any(vapply(best, function(g) identical(as.integer(g), c(1L, 2L, 2L)), TRUE)))
})

test_that("recorded MCMC diagnostics are reproduced where posterior is available", {
  skip_if_not_installed("posterior")
  d <- postrank_diagnose(tm_wrap(), grade = c(A = 1L, B = 2L, C = 3L),
    settings = list(weights = c(k1 = .6, k2 = .4), tau = .25, G_max = 3L))
  s <- d$summaries$weighted_total_loss; m <- s$diagnostics
  expect_true(d$total_loss$available)
  expect_lte(abs(s$mean - .248242), 1e-6)
  expect_false(m$ess_tail$available)
  expect_lte(abs(m$rhat$value - 1.090465), 1e-6)
  expect_lte(abs(m$ess_bulk$value - 42.954836), 1e-6)
  expect_lte(abs(m$mcse_mean$value - .038428), 1e-6)
  expect_false(d$convergence_verified)
  expect_true(any(grepl("not a convergence verdict", d$warnings)))
})
