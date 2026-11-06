cd_fixture <- function(kind = "gaussian", iterations = rep(c(10, 20, 30, 40), 2)) {
  ids <- c("A", "B"); ks <- "k1"
  m <- matrix(c(-.2, .4), 2, 1, dimnames = list(entity = ids, criterion = ks))
  C <- array(.5, c(1, 1, 2), dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids))
  p <- list(producer_id = "synthetic-diagnostic-fixture-no-sampler", producer_version = "1",
    posterior_id = "fixed-law-not-actual-MCMC", input_payload_sha256 = strrep("a", 64),
    source_sha256 = strrep("b", 64), config_sha256 = strrep("c", 64))
  if (kind == "gaussian") return(postrank_gaussian_coefficients(m, C, "entities_given_shared_h", p))
  delta <- c(-1, .2, .5, -.3, .8, -.6, .4, -.2)
  components <- lapply(delta, function(d) {
    z <- m; z[1, 1] <- d
    list(mu = c(k1 = d), Sigma = matrix(1, 1, 1, dimnames = list(criterion_i = ks, criterion_j = ks)),
      means = z, covariance = C)
  })
  names(components) <- paste0("s", 1:8)
  index <- data.frame(state_id = names(components))
  if (kind == "mcmc") { index$chain_id <- rep(1:2, each = 4); index$iteration <- iterations }
  postrank_mixture_coefficients(components, stats::setNames(rep(1/8, 8), names(components)), index,
    if (kind == "mcmc") "hyperparameter_mcmc" else "fixed_finite_mixture", "entities_given_shared_h", p)
}
cd_history <- function(iterations = rep(c(10, 20, 30, 40), 2)) list(
  list(chain_id = 1L, retained_iterations = iterations[1:4]),
  list(chain_id = 2L, retained_iterations = iterations[5:8]))
cd_settings <- list(weights = c(k1 = 1), tau = .25, G_max = 2L)
cd_grade <- c(A = 1L, B = 2L)
cd_diagnose <- function(x, ...) postrank_coefficient_diagnose(x, grade = cd_grade, settings = cd_settings, ...)

test_that("Gaussian reports analytic risk without invented target traces or zero MCSE", {
  x <- cd_fixture(); d <- postrank_diagnose(x, grade = cd_grade, settings = cd_settings)
  expect_s3_class(d, "postrank_coefficient_diagnostics")
  expect_equal(d$evaluation$weighted_risk, postrank_evaluate(cd_grade, x, c(k1 = 1), .25)$weighted_risk)
  expect_null(d$conditional_risk_trace)
  expect_false(d$target_loss_trace$available); expect_false(d$target_quantiles$available)
  expect_false(d$diagnostics$mcse_mean$available)
  expect_identical(d$diagnostics$mcse_mean$unavailable_reason, "analytic_Gaussian_no_hyperstate_MC_trace")
  expect_true(is.na(d$diagnostics$mcse_mean$value))
  expect_false(d$convergence_verified); expect_false(d$finite_sample_certificate)
})

test_that("fixed finite mixture exposes conditional expected risk with weighted summary not MC draws", {
  x <- cd_fixture("fixed"); d <- cd_diagnose(x)
  expect_equal(d$conditional_risk_trace$weighted_mean, d$evaluation$weighted_risk, tolerance = 1e-12)
  expect_identical(d$conditional_risk_trace$quantity, "RB_conditional_expected_weighted_risk")
  expect_equal(nrow(d$conditional_risk_trace$criterion_values), 8L)
  expect_identical(d$conditional_risk_trace$state_index, x$source$state_index)
  expect_identical(d$unavailable_reason, "fixed_finite_mixture_MC_not_used")
  expect_false(d$diagnostics$mcse_mean$available)
  args <- x$source; args$weights <- stats::setNames(c(.3, rep(.1, 7)), names(args$components))
  y <- postrank_mixture_coefficients(args$components, args$weights, args$state_index,
    args$source_regime, args$conditional_independence, x$provenance)
  z <- cd_diagnose(y)
  expect_equal(z$conditional_risk_trace$weighted_mean,
    sum(args$weights * z$conditional_risk_trace$values), tolerance = 0)
  expect_error(cd_diagnose(x, chain_history = cd_history()), "only applies")
})

test_that("MCMC diagnostics need original matching regular history and preserve coordinates", {
  x <- cd_fixture("mcmc"); d <- cd_diagnose(x)
  expect_identical(d$unavailable_reason, "missing_original_chain_history")
  expect_false(d$diagnostics$mcse_mean$available)
  h <- cd_history(); d <- cd_diagnose(x, chain_history = h)
  expect_identical(d$layout$original_history, h)
  expect_true(d$layout$history_structure_checked); expect_false(d$layout$history_truth_verified)
  expected <- matrix(d$conditional_risk_trace$values[d$layout$rows], nrow = 4, ncol = 2)
  reference <- .pr_mcmc_trace_metrics(expected)
  expect_identical(d$diagnostics, reference)
  order <- c(8, 1, 6, 3, 4, 7, 2, 5)
  source <- x$source
  permuted <- postrank_mixture_coefficients(source$components[order], source$weights[order],
    source$state_index[order, ], source$source_regime, source$conditional_independence, x$provenance)
  expect_identical(cd_diagnose(permuted, chain_history = h)$diagnostics, reference)
  expect_false(d$convergence_verified); expect_false(d$numerical_certification)
  bad <- h; bad[[1]]$retained_iterations[1] <- 5
  expect_error(cd_diagnose(x, chain_history = bad), "coordinates and retained history")
  bad <- h; bad[[2]]$chain_id <- 1L
  expect_error(cd_diagnose(x, chain_history = bad), "cover exactly")
  irregular <- c(10, 20, 35, 40, 10, 20, 30, 40)
  d <- cd_diagnose(cd_fixture("mcmc", irregular), chain_history = cd_history(irregular))
  expect_identical(d$unavailable_reason, "irregular_or_different_retained_spacing")
})

test_that("unequal short or single chains are not truncated padded or promoted", {
  x <- cd_fixture("mcmc")
  index <- x$source$state_index
  single <- list(list(chain_id = 1L, retained_iterations = 10 * 1:8))
  i <- index; i$chain_id[] <- 1L; i$iteration <- 10 * 1:8
  expect_identical(.pr_cf_history_layout(i, single)$reason, "insufficient_original_chains")
  i <- index; i$chain_id <- c(rep(1L, 3), rep(2L, 5)); i$iteration <- c(10 * 1:3, 10 * 1:5)
  h <- list(list(chain_id = 1L, retained_iterations = 10 * 1:3), list(chain_id = 2L, retained_iterations = 10 * 1:5))
  expect_identical(.pr_cf_history_layout(i, h)$reason, "unequal_chain_lengths")
  i <- index[1:2, ]; i$chain_id <- c(1L, 2L)
  h <- list(list(chain_id = 1L, retained_iterations = 10), list(chain_id = 2L, retained_iterations = 20))
  expect_identical(.pr_cf_history_layout(i, h)$reason, "insufficient_retained_iterations")
})

test_that("optional posterior absence preserves reasoned unavailability", {
  (function() {
    # 0.9.0: the package namespace is locked under test, so the optional-posterior
    # probe is replaced through testthat rather than assign() into the namespace.
    local_mocked_bindings(.pr_posterior_diagnostic_functions = function() NULL)
    d <- cd_diagnose(cd_fixture("mcmc"), chain_history = cd_history())
    expect_false(d$diagnostics$mcse_mean$available)
    expect_identical(d$diagnostics$mcse_mean$unavailable_reason, "posterior_package_unavailable")
    expect_true(is.na(d$diagnostics$mcse_mean$value))
    expect_false(d$conditional_risk_mcse_available)
    expect_identical(d$unavailable_reason, "posterior_package_unavailable")
  })()
})

test_that("target-draw diagnostics and invalid typed requests reject before native work", {
  x <- cd_fixture()
  expect_error(postrank_crossfit(x, settings = cd_settings), "no latent target draws")
  expect_error(postrank_mc_fragility(x, settings = cd_settings), "no latent target draws")
  expect_error(postrank_iid_bounds(x), "not fixed-S IID")
  expect_error(postrank_diagnose(x, grade = cd_grade, settings = cd_settings, pairs = list()), "pair-indicator")
  expect_error(postrank_diagnose(x, grade = cd_grade, settings = cd_settings, stability = list()), "stability")
  expect_error(cd_diagnose(cd_fixture("fixed"), max_trace_bytes = 1), "memory guard")
  expect_error(postrank_coefficient_diagnose(x, settings = cd_settings), "without a fixed grade")
  expect_error(postrank_coefficient_diagnose(x, grade = cd_grade), "requires loss settings")
  expect_error(cd_diagnose(x, max_trace_bytes = NA_real_), "finite nonnegative")
  d <- postrank_coefficient_diagnose(x)
  expect_identical(d$unavailable_reason, "no_fixed_grade")
})

test_that("fit identity settings and validated grade stay tied to the same input", {
  x <- cd_fixture(); p <- postrank_problem(x, c(k1 = 1), .25, 2L)
  primal <- .pr_engine_primal(p, cd_grade)
  raw <- list(primal = primal, raw_status = "FIXED_MOCK_NO_SOLVER", raw_message = "fixed mathematical validation",
    status_normalized = "feasible_not_certified", termination_reason = "mock", has_incumbent = TRUE,
    raw_objective = sum(p$model$objective * primal), raw_lower_bound = NA_real_, relative_gap = NA_real_,
    runtime = 0, backend = list(name = "mock", wrapper_version = "fixture", solver_version = NA_character_, options = list()),
    raw = list(execution_scope = "mock", native_solver_called = FALSE), warnings = character(),
    bound_source = "backend_reported_dual_bound")
  fit <- .pr_normalize_solver_result(p, raw, .pr_control(list()))
  d <- postrank_coefficient_diagnose(x, fit = fit)
  expect_true(d$post_selection_descriptive)
  expect_equal(d$evaluation$weighted_risk, fit$objective$primary_action_risk, tolerance = 0)
  bad <- fit; bad$input_identity <- strrep("0", 64)
  expect_error(postrank_coefficient_diagnose(x, fit = bad), "identity differ")
  bad <- fit; bad$settings$tau <- .3
  expect_error(postrank_coefficient_diagnose(x, fit = bad), "settings changed")
  bad <- fit; bad$grade <- bad$solution_validation$grade <- c(A = 2L, B = 1L)
  expect_error(postrank_coefficient_diagnose(x, fit = bad), "primal changed")
  expect_error(postrank_coefficient_diagnose(x, fit = fit, grade = c(A = 2L, B = 1L)), "grade disagrees")
  expect_error(postrank_coefficient_diagnose(x, fit = fit, settings = list(weights = c(k1 = 1), tau = .3)), "settings disagree")
})

test_that("all-withheld constant risk is action structure not target certainty", {
  d <- postrank_coefficient_diagnose(cd_fixture("fixed"), grade = c(A = 1L, B = 1L), settings = cd_settings)
  expect_true(d$conditional_risk_trace$structural_constant_from_action)
  expect_true(all(d$conditional_risk_trace$values == .25))
  expect_false(d$target_loss_trace$available)
  expect_false(d$convergence_verified)
  mcmc <- postrank_coefficient_diagnose(cd_fixture("mcmc"), grade = c(A = 1L, B = 1L),
    settings = cd_settings, chain_history = cd_history())
  expect_true(mcmc$conditional_risk_trace$structural_constant_from_action)
  expect_false(mcmc$convergence_verified)
  expect_identical(mcmc$diagnostics, .pr_mcmc_trace_metrics(matrix(.25, 4, 2)))
  before <- if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) get(".Random.seed", .GlobalEnv) else NULL
  invisible(cd_diagnose(cd_fixture("mcmc"), chain_history = cd_history()))
  after <- if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) get(".Random.seed", .GlobalEnv) else NULL
  expect_identical(after, before)
})
