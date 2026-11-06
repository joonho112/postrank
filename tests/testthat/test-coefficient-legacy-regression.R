# Fixed legacy laws, distinct from the new continuous coefficient constructors.
cl_actions <- function() {
  grid <- as.matrix(expand.grid(rep(list(1:3), 3)))
  canonical <- t(apply(grid, 1, function(g) match(g, sort(unique(g)))))
  canonical[!duplicated(apply(canonical, 1, paste, collapse = ":")), , drop = FALSE]
}
cl_states <- function(x, k) {
  if (x$input_kind == "exact_finite_posterior") {
    return(list(values = do.call(rbind, lapply(x$finite_law$states, function(s) s$theta[, k])),
      mass = vapply(x$finite_law$states, function(s) s$mass_numerator, numeric(1)) / x$finite_law$denominator))
  }
  values <- if (x$dependence_mode == "joint_model")
    x$joint_draws$tensor$values[, , k] else
    x$criterion_blocks[[match(x$criterion_ids[k], vapply(x$criterion_blocks, function(b) b$criterion_id, character(1)))]]$matrix$values
  list(values = values, mass = rep(1 / nrow(values), nrow(values)))
}
cl_literal_risk <- function(x, grade, weights, tau) {
  # State-level unordered-pair loss, independent of pairwise/model helpers.
  criterion <- numeric(length(weights))
  for (k in seq_along(weights)) {
    z <- cl_states(x, k)
    losses <- vapply(seq_len(nrow(z$values)), function(s) {
      total <- 0
      for (i in 1:2) for (j in seq.int(i + 1L, 3L)) {
        if (grade[i] == grade[j]) total <- total + tau else {
          ahead <- if (grade[i] < grade[j]) i else j
          behind <- if (ahead == i) j else i
          total <- total + as.numeric(z$values[s, ahead] < z$values[s, behind])
        }
      }
      total / 3
    }, numeric(1))
    criterion[k] <- sum(z$mass * losses)
  }
  list(weighted = sum(weights * criterion), criterion = criterion)
}
cl_inputs <- function() list(joint = pr_test_payload(),
  criterionwise = pr_test_criterionwise(), exact_finite = pr_test_exact())

testthat::test_that("all legacy input kinds retain public modes without optimization", {
  for (x in cl_inputs()) {
    p <- postrank_pairwise(as_postrank_draws(x), method = "reference")
    testthat::expect_s3_class(p, "postrank_pairwise")
    testthat::expect_false(inherits(p, "postrank_coefficients"))
    testthat::expect_equal(postrank_pairwise(x, method = "blocks", block_size = 1L)$e, p$e)
    w <- c(need1 = .25, need2 = .75)
    modes <- list(
      list(), list(objective = "minimax"), list(q = c(need1 = .8)),
      list(exact_G = 2L),
      list(objective = "minimax", q = c(need1 = .8), exact_G = 2L, minimax_criteria = "need2"))
    for (mode in modes) {
      problem <- do.call(postrank_problem, c(list(pairwise = p, weights = w, tau = .25, G_max = 3L), mode))
      testthat::expect_s3_class(problem, "postrank_problem")
      testthat::expect_identical(problem$input_identity, p$input_identity)
    }
  }
})

testthat::test_that("all13 n3 weak orders match direct legacy state-law losses", {
  actions <- cl_actions()
  testthat::expect_identical(nrow(actions), 13L)
  for (x in cl_inputs()) {
    p <- postrank_pairwise(x); w <- c(need1 = .25, need2 = .75)
    for (r in seq_len(nrow(actions))) {
      g <- stats::setNames(actions[r, ], x$entity_ids)
      truth <- cl_literal_risk(x, g, w, .25)
      weighted <- postrank_evaluate(g, p, w, .25)
      minimax <- postrank_evaluate(g, p, w, .25, objective = "minimax")
      testthat::expect_equal(weighted$weighted_risk, truth$weighted, tolerance = 1e-14)
      testthat::expect_equal(minimax$primary_risk, max(truth$criterion), tolerance = 1e-14)
      testthat::expect_identical(weighted$G, length(unique(g)))
    }
    all_tie <- postrank_evaluate(stats::setNames(rep(1L, 3), x$entity_ids), p, w, .25)
    testthat::expect_identical(all_tie$N, 0L)
    testthat::expect_true(all(is.na(all_tie$E_over_N)))
  }
})

testthat::test_that("legacy stale pairwise and problem mutations fail closed", {
  for (x in cl_inputs()) {
    p <- postrank_pairwise(x); w <- c(need1 = .5, need2 = .5)
    bad <- p; bad$e[1, 2, 1] <- .2; bad$e[2, 1, 1] <- .8
    testthat::expect_error(postrank_evaluate(stats::setNames(1:3, x$entity_ids), bad, w, .25), "changed after aggregation")
    problem <- postrank_problem(p, w, .25, 3L)
    problem$settings$tau <- .3
    testthat::expect_error(validate_postrank_solution(problem, rep(0, length(problem$model$objective))), "changed after construction")
  }
})
