# Self-contained since 0.9.0: the independent main-study Gaussian math is the
# packaged oracle copy in pr_cf_oracle (helper-coefficient-oracles.R); the API
# under test is the package namespace itself.
cg_main <- pr_cf_fixture_root()
cg_math <- pr_cf_oracle
cg_provenance <- function() list(producer_id = "fixed-gaussian-adapter-fixture", producer_version = "1",
  posterior_id = "fixed-mathematical-law-not-sampled", input_payload_sha256 = strrep("a", 64),
  source_sha256 = strrep("b", 64), config_sha256 = strrep("c", 64))
cg_fixture <- function(id = "heterogeneous-three") {
  f <- cg_math$read_fixed_gaussian_fixture(id, cg_main)
  conditional <- cg_math$main_gaussian_conditional(f$Y, f$V, f$mu, f$Sigma)
  m <- conditional$means; C <- conditional$covariance
  names(dimnames(m)) <- c("entity", "criterion")
  names(dimnames(C)) <- c("criterion_i", "criterion_j", "entity")
  list(means = m, covariance = C, reference = conditional, literal = f)
}
cg_make <- function(f = cg_fixture()) postrank_gaussian_coefficients(
  f$means, f$covariance, "entities_given_shared_h", cg_provenance())

testthat::test_that("three fixed Gaussian cases agree with Phase2 mean/e references and density integration", {
  for (id in c("unit-three", "tail-three", "heterogeneous-three")) {
    f <- cg_fixture(id); x <- cg_make(f)
    reference <- cg_math$main_gaussian_coefficients(f$reference)
    testthat::expect_identical(unname(x$means), unname(reference$means))
    testthat::expect_equal(unname(x$e), unname(reference$e), tolerance = 0)
    testthat::expect_silent(validate_postrank_coefficients(x, recompute = TRUE))
    for (k in seq_len(ncol(f$means))) for (i in seq_len(nrow(f$means))) for (j in seq_len(nrow(f$means))) {
      if (i == j) next
      # Independent density integral of the scalar difference, no production CDF.
      mean_difference <- f$means[i, k] - f$means[j, k]
      sd_difference <- sqrt(f$covariance[k, k, i] + f$covariance[k, k, j])
      density <- function(d) stats::dnorm(d, mean_difference, sd_difference)
      probability <- stats::integrate(density, -Inf, 0, rel.tol = 1e-11, abs.tol = 1e-28)$value
      tolerance <- if (probability < 1e-12) 1e-25 else 1e-11
      testthat::expect_lt(abs(x$e[i, j, k] - probability), tolerance)
    }
  }
})

testthat::test_that("direct CDF preserves tiny tails and positive means imply correct direction", {
  f <- cg_fixture("unit-three")
  f$means[,] <- 0; f$means[1, 1] <- 8
  x <- cg_make(f)
  tail <- stats::integrate(function(z) stats::dnorm(z), 8, Inf,
                           rel.tol = 1e-11, abs.tol = 1e-30)$value
  testthat::expect_gt(x$e[1, 2, 1], 0)
  testthat::expect_lt(abs(x$e[1, 2, 1] - tail), 1e-25)
  testthat::expect_gt(x$e[2, 1, 1], 0.99)
  testthat::expect_identical(unname(diag(x$e[, , 1])), rep(NA_real_, 3))
})

testthat::test_that("entity and criterion permutations retain literal axis roles and values", {
  f <- cg_fixture(); x <- cg_make(f)
  ei <- c(3, 1, 2); ki <- c(2, 1)
  f$means <- f$means[ei, ki, drop = FALSE]
  f$covariance <- f$covariance[ki, ki, ei, drop = FALSE]
  y <- cg_make(f)
  testthat::expect_identical(y$means, x$means[ei, ki, drop = FALSE])
  testthat::expect_equal(y$e, x$e[ei, ei, ki, drop = FALSE], tolerance = 0)
  testthat::expect_identical(names(dimnames(y$means)), c("entity", "criterion"))
  testthat::expect_identical(names(dimnames(y$e)), c("entity_i", "entity_j", "criterion"))
  testthat::expect_false(identical(x$coefficient_identity, y$coefficient_identity))
})

testthat::test_that("extreme finite variances avoid variance-sum overflow without repairing inputs", {
  f <- cg_fixture("unit-three")
  f$means[,] <- 0
  for (i in 1:3) f$covariance[, , i] <- diag(1e308, 2)
  x <- cg_make(f)
  testthat::expect_identical(unname(x$e[1, 2, 1]), 0.5)
  testthat::expect_silent(validate_postrank_coefficients(x, recompute = TRUE))
  for (i in 1:3) f$covariance[, , i] <- diag(1e-300, 2)
  f$means[1, 1] <- sqrt(2e-300)
  y <- cg_make(f)
  testthat::expect_equal(unname(y$e[1, 2, 1]), stats::pnorm(-1), tolerance = 1e-15)
  testthat::expect_identical(y$source$covariance, f$covariance)
})

testthat::test_that("strict roles, axes, independence and covariance/provenance boundaries reject", {
  f <- cg_fixture()
  testthat::expect_error(postrank_gaussian_coefficients(f$means, f$covariance,
    provenance = cg_provenance()), "conditional_independence")
  testthat::expect_error(postrank_gaussian_coefficients(f$means, f$covariance,
    "marginal_independence", cg_provenance()), "independence declaration")
  for (change in list(function(f) {names(dimnames(f$means)) <- NULL; f},
                      function(f) {names(dimnames(f$covariance)) <- NULL; f},
                      function(f) {dimnames(f$covariance)[[3]] <- rev(rownames(f$means)); f},
                      function(f) {rownames(f$means) <- c("a", "a", "b"); f},
                      function(f) {attr(f$means,"hidden") <- TRUE; f},
                      function(f) {f$means[1,1] <- Inf; f},
                      function(f) {f$covariance[1,1,1] <- 0; f},
                      function(f) {f$covariance[1,2,1] <- f$covariance[1,2,1] + 1e-15; f},
                      function(f) {f$covariance[1,2,1] <- 100; f})) {
    testthat::expect_error(cg_make(change(f)))
  }
  p <- cg_provenance(); p$source_sha256 <- "not-a-hash"
  testthat::expect_error(postrank_gaussian_coefficients(f$means, f$covariance,
    "entities_given_shared_h", p), "SHA256")
  p <- cg_provenance(); p$unknown <- TRUE
  testthat::expect_error(postrank_gaussian_coefficients(f$means, f$covariance,
    "entities_given_shared_h", p), "unknown fields")
  m <- f$means[1, , drop = FALSE]; C <- f$covariance[, , 1, drop = FALSE]
  testthat::expect_error(postrank_gaussian_coefficients(m, C,
    "entities_given_shared_h", cg_provenance()), "IDs")
})

testthat::test_that("new source seal has no fabricated draw count, certificate or legacy identity", {
  x <- cg_make()
  testthat::expect_identical(class(x), c("postrank_coefficients", "list"))
  testthat::expect_false(inherits(x, "postrank_pairwise"))
  testthat::expect_false(inherits(x, "postrank_draws"))
  testthat::expect_null(x$sample_sizes)
  testthat::expect_null(x$draw_index)
  testthat::expect_false(x$validation$source_values_checked)
  testthat::expect_false(x$validation$convergence_verified)
  testthat::expect_false(x$capabilities$exact_rational)
  testthat::expect_false(x$capabilities$formal_numerical_certification)
  bad <- x; bad$source$covariance[1,1,1] <- bad$source$covariance[1,1,1] + 0.1
  testthat::expect_error(validate_postrank_coefficients(bad), "changed after construction")
})

testthat::test_that("Gaussian public constructor leaves RNG and backend loading untouched", {
  before_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) get(".Random.seed", envir = .GlobalEnv) else NULL
  before_ns <- vapply(c("highs", "gurobi", "cmdstanr"), isNamespaceLoaded, logical(1))
  x <- cg_make(); invisible(validate_postrank_coefficients(x, recompute = TRUE))
  after_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) get(".Random.seed", envir = .GlobalEnv) else NULL
  after_ns <- vapply(c("highs", "gurobi", "cmdstanr"), isNamespaceLoaded, logical(1))
  testthat::expect_identical(before_seed, after_seed)
  testthat::expect_identical(before_ns, after_ns)
})
