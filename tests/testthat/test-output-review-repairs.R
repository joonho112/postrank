# External review PKG-05/06: prepared coefficient diagnostics and complete frontier views.
pr_output_coefficients <- function(K = 2L, mixture = FALSE, reserved = FALSE) {
  ids <- c("A", "B", "C")
  ks <- if (reserved) c("risk", "N/M", paste0("k", seq_len(K - 2L))) else paste0("k", seq_len(K))
  means <- outer(c(1, .2, -1), seq(.6, 1.8, length.out = K))
  dimnames(means) <- list(entity = ids, criterion = ks)
  covariance <- array(0, c(K, K, 3), dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids))
  for (i in seq_len(3L)) covariance[, , i] <- diag(K)
  provenance <- list(producer_id = "output-regression", producer_version = "1", posterior_id = "fixed-law",
    input_payload_sha256 = strrep("a", 64), source_sha256 = strrep("b", 64), config_sha256 = strrep("c", 64))
  if (!mixture) return(postrank_gaussian_coefficients(means, covariance, "entities_given_shared_h", provenance))
  state <- function(shift) list(mu = setNames(rep(shift, K), ks),
    Sigma = matrix(diag(K), K, K, dimnames = list(criterion_i = ks, criterion_j = ks)),
    means = means + shift, covariance = covariance)
  postrank_mixture_coefficients(list(s1 = state(-.4), s2 = state(.7)), c(s1 = .3, s2 = .7),
    data.frame(state_id = c("s1", "s2")), "fixed_finite_mixture", "entities_given_shared_h", provenance)
}

test_that("coefficient diagnostics reports preserve class-specific metrics and NA reasons", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  for (mixture in c(FALSE, TRUE)) for (diagnostics in c(FALSE, TRUE)) {
    x <- pr_output_coefficients(mixture = mixture)
    a <- postrank(x, weights = c(k1 = .5, k2 = .5), tau = .35, G_max = 3L,
      backend = "highs", diagnostics = diagnostics)
    rep <- postrank_report(a$fit, analysis = a, figures = FALSE)
    path <- withr::local_tempfile(fileext = ".html")
    written <- postrank_report(a$fit, analysis = a, figures = FALSE, output_file = path)
    expect_true(file.exists(written$output_file))
    html <- paste(readLines(path, warn = FALSE), collapse = "\n")
    if (diagnostics) {
      expect_s3_class(rep$diagnostics, "postrank_coefficient_diagnostics")
      expect_setequal(rep$diagnostic_table$metric, c("mcse_mean", "rhat", "ess_mean", "ess_bulk", "ess_tail"))
      expect_true(all(is.na(rep$diagnostic_table$value)))
      reason <- if (mixture) "fixed_finite_mixture_MC_not_used" else "analytic_Gaussian_no_hyperstate_MC_trace"
      expect_true(all(rep$diagnostic_table$NA_reason == reason))
      expect_match(html, reason, fixed = TRUE)
      expect_match(html, "Typed coefficient diagnostics", fixed = TRUE)
      expect_match(html, "Target-loss draws and target-loss MCSE are unavailable", fixed = TRUE)
      expect_match(html, "ESS is not an IID sample size", fixed = TRUE)   # honesty register (013 V-07)
      expect_false(grepl("Total loss:", html, fixed = TRUE))
    } else expect_null(rep$diagnostic_table)
    expect_error(postrank_report(a$fit, analysis = a, output_file = path, figures = FALSE), "already exists")
  }
})

test_that("coefficient report validates association and schema without recomputation", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  x <- pr_output_coefficients(mixture = TRUE)
  a <- postrank(x, weights = c(k1 = .5, k2 = .5), tau = .35, G_max = 3L, backend = "highs", diagnostics = TRUE)
  d <- a$diagnostics
  boom <- function(...) stop("report recomputation attempted")
  local_mocked_bindings(.pr_solve_core = boom, postrank_pairwise = boom, postrank_evaluate = boom,
    .pr_cf_risk_trace = boom, .pr_posterior_summaries = boom, postrank_report_card = boom)
  expect_no_error(postrank_report(a$fit, diagnostics = d, figures = FALSE))
  bad <- d; bad$diagnostics$mcse_mean$value <- 0
  expect_error(postrank_report(a$fit, diagnostics = bad, figures = FALSE), "value/availability")
  bad <- d; bad$schema_version <- "wrong"
  expect_error(postrank_report(a$fit, diagnostics = bad, figures = FALSE), "schema/input kind")
  bad <- d; bad$input_identity <- "different"
  expect_error(postrank_report(a$fit, diagnostics = bad, figures = FALSE), "input identity")
  bad <- d; bad$settings$tau <- .2
  expect_error(postrank_report(a$fit, diagnostics = bad, figures = FALSE), "grade/settings")
  bad <- d; bad$conditional_risk_trace$weighted_mean <- .9
  expect_error(postrank_report(a$fit, diagnostics = bad, figures = FALSE), "trace summary")
})

test_that("draw report diagnostics and crossfit remain available", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  a <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L,
    backend = "highs", diagnostics = TRUE, crossfit = TRUE)
  path <- withr::local_tempfile(fileext = ".html")
  rep <- postrank_report(a$fit, analysis = a, figures = FALSE, output_file = path)
  expect_s3_class(rep$diagnostics, "postrank_diagnostics")
  expect_true(nrow(rep$diagnostic_table) > 0)
  expect_s3_class(rep$crossfit, "postrank_crossfit")
  expect_match(paste(readLines(path), collapse = ""), "Total loss:", fixed = TRUE)
})

test_that("frontier retains every finite criterion at K eight and twelve including reserved names", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  for (K in c(8L, 12L)) {
    x <- pr_output_coefficients(K, reserved = TRUE)
    fr <- postrank_frontier(x, weights = setNames(rep(1/K, K), x$criterion_ids), tau = c(.25, .35),
      G_max = 3L, backend = "highs")
    p <- postrank_plot_frontier(fr)
    built <- ggplot2::ggplot_build(p)
    er <- p$data[as.character(p$data$panel) == "error E_k/N", ]
    expect_equal(nrow(er), 2L * K)
    expect_setequal(er$series, x$criterion_ids)
    expect_equal(length(unique(er$series_id)), K)
    expect_false(any(er$series_id %in% p$data$series_id[as.character(p$data$panel) != "error E_k/N"]))
    for (k in x$criterion_ids) expect_equal(er$value[er$series == k], fr$table[[paste0("E_over_N_", k)]])
    for (layer in built$data[1:2]) {
      expect_equal(nrow(layer), nrow(p$data))
      expect_false(anyNA(layer$colour))
      expect_true(all(is.finite(layer$y)))
    }
    expect_false(anyNA(built$data[[1]]$linetype))
    expect_equal(length(built$plot$scales$get_scales("colour")$get_breaks()), K)
    if (isTRUE(capabilities("png"))) {
      path <- withr::local_tempfile(fileext = ".png")
      expect_warning(ggplot2::ggsave(path, p, width = 8, height = 8, dpi = 72), NA)
      expect_gt(file.info(path)$size, 0)
    }
    # Absence is retained as absence: no invented error rates for all-withheld rows.
    fr$table[, grep("^E_over_N_", names(fr$table))] <- NA_real_
    empty <- postrank_plot_frontier(fr, panels = "error")
    expect_match(pr_unwrap(empty$labels$subtitle), "nothing disclosed")
  }
})

test_that("MCMC coefficient reports retain history, unavailable reasons and metric warnings", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  source <- pr_output_coefficients(mixture = TRUE)$source
  components <- rep(source$components, 4L); names(components) <- paste0("s", seq_len(8L))
  for (i in seq_along(components)) components[[i]]$means[1, 1] <- c(-1, .2, .5, -.3, .8, -.6, .4, -.2)[i]
  idx <- data.frame(state_id = names(components), chain_id = rep(1:2, each = 4L), iteration = rep(c(10L,20L,30L,40L), 2L))
  x <- postrank_mixture_coefficients(components, setNames(rep(1/8, 8), names(components)), idx,
    "hyperparameter_mcmc", "entities_given_shared_h", pr_output_coefficients()$provenance)
  a <- postrank(x, weights = c(k1=.5,k2=.5), tau=.35, G_max=3L, backend="highs", diagnostics=TRUE)
  absent <- postrank_report(a$fit, analysis=a, figures=FALSE)
  expect_true(all(absent$diagnostic_table$NA_reason == "missing_original_chain_history"))
  h <- list(list(chain_id=1L,retained_iterations=c(10L,20L,30L,40L)),
    list(chain_id=2L,retained_iterations=c(10L,20L,30L,40L)))
  d <- postrank_coefficient_diagnose(x, fit=a$fit, chain_history=h)
  expect_identical(any(vapply(d$diagnostics, function(m) m$available, TRUE)), requireNamespace("posterior", quietly=TRUE))
  d$diagnostics$mcse_mean$warnings <- "Synthetic diagnostic warning for report preservation"
  path <- withr::local_tempfile(fileext=".html")
  rep <- postrank_report(a$fit, diagnostics=d, figures=FALSE, output_file=path)
  expect_identical(rep$diagnostic_table$raw_value[1], d$diagnostics$mcse_mean$raw_value)
  html <- paste(readLines(path),collapse="")
  expect_match(html,"Synthetic diagnostic warning for report preservation",fixed=TRUE)
  expect_match(html,"retained_iterations",fixed=TRUE)
  bad <- absent$diagnostics
  bad$diagnostics$rhat$available <- TRUE; bad$diagnostics$rhat$value <- 1
  bad$diagnostics$rhat$unavailable_reason <- NULL
  expect_error(postrank_report(a$fit, diagnostics=bad, figures=FALSE),"checked history layout")
})

test_that("coefficient report without an incumbent does not invent a Gaussian source", {
  local_mocked_bindings(.pr_solve_core=pr_mock_solver(grade=NULL,status="time_limit"))
  x <- pr_output_coefficients(mixture=TRUE)
  a <- postrank(x,weights=c(k1=.5,k2=.5),tau=.35,G_max=3L,backend="highs")
  d <- postrank_coefficient_diagnose(x,fit=a$fit)
  path <- withr::local_tempfile(fileext=".html")
  rep <- postrank_report(a$fit,diagnostics=d,figures=FALSE,output_file=path)
  expect_null(rep$diagnostics$evaluation)
  html <- paste(readLines(path),collapse="")
  expect_match(html,"Hyperstate trace: unavailable: no_fixed_grade",fixed=TRUE)
  expect_false(grepl("analytic Gaussian input",html,fixed=TRUE))
})

test_that("q frontier describes a change in feasible set", {
  local_mocked_bindings(.pr_solve_core=pr_mock_solver())
  fr <- postrank_frontier(postrank_pairwise(postrank_toy),weights=c(need_A=.6,need_B=.4),tau=.35,G_max=3L,
    q_grid=c(.8,1),q_criterion="need_A",backend="highs")
  expect_match(pr_unwrap(postrank_plot_frontier(fr)$labels$caption),"Changing q changes the feasible set",fixed=TRUE)
})
