# PKG-14: preserve legacy structural contracts while documenting the extra friendly lint.
test_that("declaration token lint is specific to the friendly array bundle", {
  d <- attr(pr_toy_mcmc, "law")$declarations
  args <- unclass(d)
  args$identification_note <- "TBD"
  err <- tryCatch(do.call(postrank_declarations, args), error = identity)
  expect_identical(err$code, "placeholder_declaration")
  err <- tryCatch(postrank_draws(pr_toy_mcmc, regime = "mcmc", chains = 4L,
    warmup_per_chain = 0L, thin = 1L, declarations = args), error = identity)
  expect_identical(err$code, "placeholder_declaration")
  legacy <- do.call(postrank_draws_from_array, c(list(values = pr_toy_mcmc,
    regime = "mcmc", chains = 4L, warmup_per_chain = 0L, thin = 1L), args))
  expect_identical(legacy$identification$note, "TBD")
  expect_true(legacy$validation$valid)
})

test_that("canonical objects and JSON retain the legacy declaration presence contract", {
  payload <- pr_test_payload()
  payload$identification$note <- "TBD"
  payload$tie_policy$justification <- "unknown"
  payload$targets[[1L]]$estimand <- "TBD"
  x <- as_postrank_draws(payload)
  expect_identical(postrank_draws(x), x)
  path <- withr::local_tempfile(fileext = ".json")
  write_postrank_draws(x, path)
  y <- read_postrank_draws(path)
  expect_identical(y$validation$input_identity, x$validation$input_identity)
  expect_identical(y$identification$note, "TBD")
  expect_identical(y$tie_policy$justification, "unknown")
  expect_identical(y$targets[[1L]]$estimand, "TBD")
})

test_that("matrix metadata and posterior metadata do not add bundle token lint", {
  full <- pr_test_criterionwise(); full$identification$note <- "TBD"
  mats <- lapply(full$criterion_blocks, function(b) b$matrix$values)
  names(mats) <- vapply(full$criterion_blocks, `[[`, "", "criterion_id")
  meta <- full
  for (i in seq_along(meta$criterion_blocks)) meta$criterion_blocks[[i]]$matrix <- NULL
  expect_identical(postrank_draws(mats, metadata = meta), as_postrank_draws(full))
})

test_that("posterior metadata preserves explicit legacy text", {
  skip_if_not_installed("posterior")
  meta <- pr_test_payload(); meta$identification$note <- "TBD"
  values <- meta$joint_draws$tensor$values; map <- meta$joint_draws$variable_map
  vars <- vapply(map, `[[`, "", "source_target_variable_id")
  src <- array(NA_real_, c(dim(values)[1L], 1L, length(vars)),
    dimnames = list(iteration = NULL, chain = "1", variable = vars))
  for (i in seq_along(map)) src[, 1L, vars[i]] <- values[, map[[i]]$entity_id, map[[i]]$criterion_id]
  coords <- lapply(seq_len(dim(values)[1L]), function(i)
    list(slot_id = dimnames(values)$draw[i], iteration_index = i, chain_index = 1L))
  meta$joint_draws$tensor$values <- NULL
  da <- posterior::as_draws_array(src)
  direct <- as_postrank_posterior(da, map, meta, coords)
  friendly <- postrank_draws(da, variables = map, metadata = meta, source_coordinates = coords)
  expect_identical(friendly, direct)
  expect_identical(friendly$identification$note, "TBD")
})

# PKG-16: every named formatter remains a compatibility entry point for format().
test_that("all 24 named formatter wrappers equal their generic capture", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  w <- c(need_A = .6, need_B = .4)
  a <- postrank(postrank_toy, weights = w, tau = .25, G_max = 3L,
    backend = "highs", diagnostics = TRUE)
  pw <- a$pairwise; s <- a$settings; fit <- a$fit
  design <- list(sample_sizes_fixed_before_sampling = TRUE, alpha_fixed_before_sampling = TRUE,
    adaptive_stopping = FALSE, planned_sample_sizes = c(need_A = 32L, need_B = 32L),
    declaration_note = "The shipped toy generator fixed its sample size in advance.")
  objects <- list(
    analysis = a, backend_availability = postrank_backend_available("highs"),
    baseline = postrank_cuts(postrank_expected_rank(pw, w), pw, s),
    coefficient_diagnostics = postrank_coefficient_diagnose(pr_example_gaussian),
    coefficients = pr_example_gaussian,
    commonality_cost = postrank_commonality_cost(a, backend = "highs"),
    comparison = postrank_compare(a), control = a$control,
    crossfit = postrank_crossfit(postrank_toy, fit = fit, backend = "highs"),
    declarations = attr(pr_toy_mcmc, "law")$declarations,
    diagnostics = a$diagnostics, draws = postrank_toy, fit = fit,
    frontier = postrank_frontier(pw, w, tau = c(.25, .3), G_max = 3L, backend = "highs"),
    guarantee = postrank_iid_bounds(postrank_toy, alpha = .05,
      alpha_by_criterion = c(need_A = .025, need_B = .025), design = design),
    mc_fragility = a$fragility, pairwise = pw, problem = a$problem,
    report = postrank_report(fit, analysis = a, figures = FALSE), report_card = a$report_card,
    sensitivity = postrank_sensitivity(pw, postrank_settings_grid(s, tau = .3), backend = "highs"),
    settings = s, summary = summary(a), validation = validate_postrank_draws(postrank_toy))
  exported <- grep("^format_postrank_.*_cli$", getNamespaceExports("postrank"), value = TRUE)
  expect_length(objects, 24L)
  expect_setequal(paste0("format_postrank_", names(objects), "_cli"), exported)
  for (name in names(objects)) {
    wrapper <- getExportedValue("postrank", paste0("format_postrank_", name, "_cli"))
    expect_identical(format(objects[[name]], width = 72L, tier = 2L, n_head = 3L),
      wrapper(objects[[name]], width = 72L, tier = 2L, n_head = 3L), info = name)
  }
})
