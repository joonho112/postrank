pr_adapter_fixture <- function(I = 2L, C = 2L, n = 3L, K = 2L, regime = "mcmc") {
  metadata <- pr_test_payload(S = I * C, n = n, K = K, regime = regime)
  expected <- metadata$joint_draws$tensor$values
  map <- metadata$joint_draws$variable_map
  for (m in seq_along(map)) map[[m]]$source_target_variable_id <- paste0("opaque_target_", m)
  metadata$joint_draws$variable_map <- map
  variables <- c(rev(vapply(map, `[[`, character(1L), "source_target_variable_id")), "lp__")
  source <- array(NA_real_, c(I, C, length(variables)),
    dimnames = list(iteration = as.character(seq_len(I)), chain = as.character(seq_len(C)), variable = variables))
  source[, , "lp__"] <- -Inf # A diagnostic variable is not a target.
  coordinates <- vector("list", I * C)
  for (chain in seq_len(C)) for (iteration in seq_len(I)) {
    s <- iteration + I * (chain - 1L)
    coordinates[[s]] <- list(slot_id = dimnames(expected)$draw[[s]],
      iteration_index = iteration, chain_index = chain)
    for (m in seq_along(map)) {
      i <- match(map[[m]]$entity_id, metadata$entity_ids)
      k <- match(map[[m]]$criterion_id, metadata$criterion_ids)
      source[iteration, chain, map[[m]]$source_target_variable_id] <- expected[s, i, k]
    }
    if (regime == "mcmc") {
      metadata$joint_draws$draw_index[[s]]$chain_id <- paste0("original-chain-", LETTERS[[chain]])
      metadata$joint_draws$draw_index[[s]]$iteration <- 1000L + 2L * iteration
    }
  }
  if (regime == "mcmc") metadata$joint_draws$sampling$chain_history <- lapply(seq_len(C), function(chain)
    list(chain_id = paste0("original-chain-", LETTERS[[chain]]),
      retained_iterations = 1000L + 2L * seq_len(I), warmup_iterations = 1:1000,
      discarded_sampling_iterations = seq.int(1001L, 1000L + 2L * I, by = 2L),
      selection_note = "Explicit synthetic original iteration identities, distinct from source array positions."))
  metadata$joint_draws$origin$source_format <- "Declared external CSV"
  metadata$joint_draws$origin$source_hash <- strrep("a", 64L)
  metadata$joint_draws$tensor$values <- NULL
  list(source = posterior::as_draws_array(source), map = map, metadata = metadata,
    coordinates = coordinates, expected = expected)
}
pr_run_adapter <- function(z) as_postrank_posterior(z$source, z$map, z$metadata, z$coordinates)

testthat::test_that("posterior conversion checks every target cell and preserves supplied identities", {
  testthat::skip_if_not_installed("posterior")
  z <- pr_adapter_fixture()
  d <- pr_run_adapter(z)
  testthat::expect_identical(d$joint_draws$tensor$values, z$expected)
  testthat::expect_identical(d$joint_draws$origin, z$metadata$joint_draws$origin)
  testthat::expect_identical(d$joint_draws$draw_index, z$metadata$joint_draws$draw_index)
  testthat::expect_identical(d$joint_draws$sampling, z$metadata$joint_draws$sampling)
  testthat::expect_identical(d$targets, z$metadata$targets)
  testthat::expect_true(d$validation$source_values_checked)
  testthat::expect_identical(d$validation$check_results$source_values, "passed")
  testthat::expect_false(d$validation$schema_checked)
  testthat::expect_false(d$validation$jointness_verified)
  testthat::expect_false(d$validation$convergence_verified)
  a <- d$validation$source_audit
  testthat::expect_identical(a$source_object_sha256, digest::digest(unclass(z$source), algo = "sha256"))
  testthat::expect_false(identical(a$source_object_sha256, z$metadata$joint_draws$origin$source_hash))
  testthat::expect_false(a$external_source_hash_verified)
  testthat::expect_identical(a$unused_variable_ids, "lp__")
  testthat::expect_equal(a$source_cells_checked, 24)
  testthat::expect_equal(a$complete_source_draws_checked, 4)
  testthat::expect_identical(a$source_chain_mapping[[1L]]$declared_chain_id, "original-chain-A")
  testthat::expect_equal(a$source_chain_mapping[[1L]]$original_iterations_in_source_order, c(1002, 1004))
  testthat::expect_true(validate_postrank_draws(d)$source_values_checked)
  d$joint_draws$tensor$values[1, 1, 1] <- d$joint_draws$tensor$values[1, 1, 1] + 0.01
  testthat::expect_false(validate_postrank_draws(d)$source_values_checked)
})

testthat::test_that("mapping order and singleton source axes do not change targets", {
  testthat::skip_if_not_installed("posterior")
  z <- pr_adapter_fixture()
  z$map <- rev(z$map)
  z$coordinates <- rev(z$coordinates)
  testthat::expect_identical(pr_run_adapter(z)$joint_draws$tensor$values, z$expected)
  z$metadata$joint_draws$tensor$shape <- rev(z$metadata$joint_draws$tensor$shape)
  z$metadata$joint_draws$tensor$dimnames <- rev(z$metadata$joint_draws$tensor$dimnames)
  z$metadata$joint_draws$variable_map <- lapply(z$metadata$joint_draws$variable_map, rev)
  testthat::expect_identical(pr_run_adapter(z)$joint_draws$tensor$values, z$expected)
  z <- pr_adapter_fixture(I = 1L, C = 1L, n = 2L, K = 1L)
  testthat::expect_identical(dim(pr_run_adapter(z)$joint_draws$tensor$values), c(1L, 2L, 1L))
  z <- pr_adapter_fixture(regime = "iid")
  d <- pr_run_adapter(z)
  testthat::expect_true(d$validation$source_values_checked)
  testthat::expect_length(d$validation$source_audit$source_chain_mapping, 0L)
  testthat::expect_identical(d$joint_draws$draw_index, z$metadata$joint_draws$draw_index)
})

testthat::test_that("adapter rejects guessed, duplicate, missing and contradictory maps", {
  testthat::skip_if_not_installed("posterior")
  z <- pr_adapter_fixture()
  y <- z; y$source <- unclass(y$source)
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$map <- y$map[-1L]
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$map[[1L]]$source_target_variable_id <- "not_in_source"
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$map[[1L]]$source_target_variable_id <- y$map[[2L]]$source_target_variable_id
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$map[[1L]]$entity_id <- y$map[[2L]]$entity_id
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$metadata$joint_draws$variable_map[[1L]]$derivation_note <- "Contradictory map declaration"
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
})

testthat::test_that("source coordinates form a full bijection with source draws", {
  testthat::skip_if_not_installed("posterior")
  z <- pr_adapter_fixture()
  y <- z; y$coordinates <- y$coordinates[-1L]
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$coordinates[[2L]] <- y$coordinates[[1L]]
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$coordinates[[2L]]$iteration_index <- y$coordinates[[1L]]$iteration_index
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$coordinates[[1L]]$iteration_index <- 3L
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$coordinates[[1L]]$chain_index <- 1.5
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$coordinates[[1L]]$chain_index <- matrix(1L, 1L, 1L)
  testthat::expect_error(pr_run_adapter(y), "scalars", class = "postrank_input_error")
  y <- z; y$metadata$joint_draws$tensor$shape$S <- 3L
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
  y <- z; y$metadata$joint_draws$tensor$values <- y$expected
  y$metadata$joint_draws$tensor$values[1, 1, 1] <- 99
  testthat::expect_error(pr_run_adapter(y), "disagree", class = "postrank_input_error")
  y <- z; y$source[1, 1, "opaque_target_1"] <- Inf
  testthat::expect_error(pr_run_adapter(y), class = "postrank_input_error")
})

testthat::test_that("MCMC source chain and temporal identities cannot be reassigned silently", {
  testthat::skip_if_not_installed("posterior")
  z <- pr_adapter_fixture()
  y <- z
  y$coordinates[[1L]]$iteration_index <- 2L
  y$coordinates[[2L]]$iteration_index <- 1L
  testthat::expect_error(pr_run_adapter(y), "increasing", class = "postrank_input_error")
  y <- z
  y$coordinates[[1L]]$chain_index <- 2L
  y$coordinates[[3L]]$chain_index <- 1L
  testthat::expect_error(pr_run_adapter(y), "one declared chain", class = "postrank_input_error")
  y <- z
  for (s in seq_along(y$metadata$joint_draws$draw_index)) {
    y$metadata$joint_draws$draw_index[[s]]$chain_id <- "merged-chain"
    y$metadata$joint_draws$draw_index[[s]]$iteration <- s + 1000L
  }
  y$metadata$joint_draws$sampling$chain_history <- list(list(chain_id = "merged-chain",
    retained_iterations = 1001:1004, warmup_iterations = 1:1000,
    discarded_sampling_iterations = integer(), selection_note = "Synthetic merged-chain counterexample."))
  testthat::expect_error(pr_run_adapter(y), "distinct declared chains", class = "postrank_input_error")
})
