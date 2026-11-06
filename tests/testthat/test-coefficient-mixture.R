# Self-contained since 0.9.0: fixture JSON and the independent mixture oracle
# are packaged test copies (tests/fixtures/), loaded via helper-coefficient-oracles.R.
.cm_root <- pr_cf_fixture_root()
read_fixed_gaussian_fixture <- pr_cf_oracle$read_fixed_gaussian_fixture
oracle_mixture_conditional <- pr_cf_oracle$oracle_mixture_conditional
oracle_rb_mixture <- pr_cf_oracle$oracle_rb_mixture
oracle_independent_h_probability <- pr_cf_oracle$oracle_independent_h_probability
.cm_fixture <- function() {
  f <- read_fixed_gaussian_fixture("heterogeneous-three", .cm_root)
  hs <- f$catalog$mixture_fixture
  ids <- rownames(f$Y); ks <- colnames(f$Y)
  state_ids <- vapply(hs$states, function(h) h$state_id, character(1))
  states <- lapply(hs$states, function(h) {
    S <- do.call(rbind, lapply(h$Sigma_rows, function(row) as.numeric(unlist(row))))
    dimnames(S) <- list(criterion_i = ks, criterion_j = ks)
    mu <- stats::setNames(as.numeric(unlist(h$mu)), ks)
    moments <- oracle_mixture_conditional(f$Y, f$V, mu, S)
    dimnames(moments$means) <- list(entity = ids, criterion = ks)
    dimnames(moments$covariance) <- list(criterion_i = ks, criterion_j = ks, entity = ids)
    list(mu = mu, Sigma = S, means = moments$means, covariance = moments$covariance)
  })
  names(states) <- state_ids
  fixture_sha <- digest::digest(file = file.path(.cm_root, "tests/fixtures/gaussian-fixed.json"), algo = "sha256")
  args <- list(components = states,
    weights = stats::setNames(as.numeric(unlist(hs$weights)), state_ids),
    state_index = data.frame(state_id = state_ids), source_regime = "fixed_finite_mixture",
    conditional_independence = "entities_given_shared_h",
    provenance = list(producer_id = "literal-fixture-no-sampler", producer_version = "fixture-v1",
      posterior_id = "declared-fixed-conditional-law", input_payload_sha256 = fixture_sha,
      source_sha256 = fixture_sha, config_sha256 = fixture_sha))
  list(f = f, args = args)
}
.cm_make <- function(args = .cm_fixture()$args) do.call(postrank_mixture_coefficients, args)

test_that("fixed shared mixture agrees with independent precision/density oracle", {
  fixture <- .cm_fixture(); args <- fixture$args
  reference <- oracle_rb_mixture(fixture$f$Y, fixture$f$V, args$components, args$weights)
  x <- .cm_make(args)
  expect_true(validate_postrank_coefficients(x, recompute = TRUE))
  expect_equal(unname(x$means), unname(reference$means), tolerance = 1e-11)
  expect_equal(unname(x$e), unname(reference$e), tolerance = 1e-12)
  expect_identical(dimnames(x$e), list(entity_i = rownames(fixture$f$Y),
    entity_j = rownames(fixture$f$Y), criterion = colnames(fixture$f$Y)))
  expect_identical(x$source$components, args$components)
  expect_identical(x$source$weights, args$weights)
  expect_identical(names(x$source$state_index), "state_id")
  expect_false(inherits(x, "postrank_draws"))
  expect_null(x$sample_sizes); expect_null(x$exact)
  expect_true(x$capabilities$rb_conditional_risk_trace)
  expect_false(x$capabilities$hyperparameter_mcse_eligible)
  expect_true(all(!unlist(x$validation[setdiff(names(x$validation), "structure_checked")])))
})

test_that("shared state differs from independently chosen entity states", {
  f <- .cm_fixture(); x <- .cm_make(f$args)
  reference <- oracle_rb_mixture(f$f$Y, f$f$V, f$args$components, f$args$weights)
  wrong <- oracle_independent_h_probability(reference$conditional_moments, f$args$weights, 1, 2, 1)
  expect_gt(abs(x$e[1, 2, 1] - wrong), 1e-4)
  expect_identical(x$source$components[[1]]$mu, f$args$components[[1]]$mu)
  expect_identical(x$source$components[[2]]$Sigma, f$args$components[[2]]$Sigma)
})

test_that("structural MCMC coordinates do not establish sampler or convergence truth", {
  args <- .cm_fixture()$args
  args$source_regime <- "hyperparameter_mcmc"
  args$weights[] <- .5
  args$state_index$chain_id <- c(1L, 2L); args$state_index$iteration <- c(1L, 1L)
  args$provenance$producer_id <- "synthetic-coordinate-contract-test-no-sampler"
  x <- .cm_make(args)
  expect_true(validate_postrank_coefficients(x, recompute = TRUE))
  expect_true(x$capabilities$hyperparameter_mcse_eligible)
  expect_false(x$validation$source_values_checked)
  expect_false(x$validation$convergence_verified)
  expect_false(x$validation$finite_sample_certificate)
  expect_identical(x$source$state_index, args$state_index)
  bad <- args; bad$weights <- c("fixed-h1" = .25, "fixed-h2" = .75)
  expect_error(.cm_make(bad), "uniform")
  bad <- args; bad$weights[] <- c(.5 + 5e-13, .5 - 5e-13)
  expect_error(.cm_make(bad), "uniform")
  bad <- args; bad$state_index$chain_id[] <- 1L
  expect_error(.cm_make(bad), "duplicate")
  bad <- args; bad$state_index$iteration[1] <- 0L
  expect_error(.cm_make(bad), "safe integers")
})

test_that("fixed source rejects invented coordinates and invalid weights or declarations", {
  args <- .cm_fixture()$args
  bad <- args; bad$state_index$chain_id <- c(1L, 2L)
  expect_error(.cm_make(bad), "columns")
  for (weights in list(c(.25, .75), rev(args$weights),
    stats::setNames(c(-.25, 1.25), names(args$weights)),
    stats::setNames(c(.3, .3), names(args$weights)))) {
    bad <- args; bad$weights <- weights
    expect_error(.cm_make(bad), "weights")
  }
  bad <- args; bad$conditional_independence <- "inferred_from_marginals"
  expect_error(.cm_make(bad), "conditional independence")
  bad <- args; bad$conditional_independence <- NULL
  expect_error(.cm_make(bad), "missing")
  bad <- args; bad$source_regime <- "target_iid_draws"
  expect_error(.cm_make(bad), "unsupported")
})

test_that("component values source axes and hidden attributes are checked", {
  args <- .cm_fixture()$args
  bad <- args; bad$components[[1]]$mu <- NULL
  expect_error(.cm_make(bad), "missing fields")
  bad <- args; bad$components[[1]]$Sigma[1, 1] <- 0
  expect_error(.cm_make(bad), "positive definite")
  bad <- args; dimnames(bad$components[[1]]$means)[[1]] <- rev(rownames(bad$components[[1]]$means))
  expect_error(.cm_make(bad), "axes")
  bad <- args; bad$components[[2]]$covariance[1, 1, 1] <- NA_real_
  expect_error(.cm_make(bad), "finite")
  bad <- args; attr(bad$components, "true_theta") <- "hidden"
  expect_error(.cm_make(bad), "hidden")
  bad <- args; bad$provenance$source_sha256 <- "not-a-digest"
  expect_error(.cm_make(bad), "SHA256")
})

test_that("one component and many repeated mathematical states keep masks and stable sums", {
  args <- .cm_fixture()$args
  single <- args; single$components <- single$components[1]
  single$weights <- stats::setNames(1, names(single$components))
  single$state_index <- data.frame(state_id = names(single$components))
  x <- .cm_make(single)
  reference <- .pr_cf_project_gaussian(list(kind = "gaussian_conditional",
    means = single$components[[1]]$means, covariance = single$components[[1]]$covariance,
    conditional_independence = "entities_given_shared_h"))
  expect_identical(x$means, reference$means)
  expect_identical(x$e, reference$e)
  component <- single$components[[1]]
  component$means[, 1] <- c(-80, 0, 80)
  S <- 1000L; ids <- paste0("literal-state-", seq_len(S))
  many <- single; many$components <- stats::setNames(rep(list(component), S), ids)
  many$weights <- stats::setNames(rep(1 / S, S), ids)
  many$state_index <- data.frame(state_id = ids)
  y <- .cm_make(many)
  expect_true(validate_postrank_coefficients(y))
  expect_equal(y$e[1, 3, 1], 1, tolerance = 0)
  expect_equal(y$e[3, 1, 1], 0, tolerance = 0)
  expect_true(all(is.na(diag(y$e[, , 1]))))
  expect_identical(y$source$weights, many$weights)
})

test_that("identity binds source states and means/e without authorizing false source claims", {
  x <- .cm_make()
  bad <- x; bad$source$components[[1]]$mu[1] <- bad$source$components[[1]]$mu[1] + .1
  expect_error(validate_postrank_coefficients(bad), "changed after construction")
  bad <- x; bad$means[1, 1] <- bad$means[1, 1] + .1
  expect_error(validate_postrank_coefficients(bad), "changed after construction")
  bad <- x; bad$e[1, 2, 1] <- .6; bad$e[2, 1, 1] <- .4
  expect_error(validate_postrank_coefficients(bad), "changed after construction")
  expect_identical(x$coefficient_identity, x$input_identity)
  expect_identical(x$coefficient_identity, x$pairwise_identity)
})

test_that("mathematical mixture constructor leaves RNG unchanged", {
  before <- if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) get(".Random.seed", .GlobalEnv) else NULL
  x <- .cm_make(); expect_true(validate_postrank_coefficients(x))
  after <- if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) get(".Random.seed", .GlobalEnv) else NULL
  expect_identical(after, before)
})
