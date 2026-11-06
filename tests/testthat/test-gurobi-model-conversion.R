# 014 repair (CP-1): the vectorized Gurobi row conversion must reproduce the
# original per-row implementation exactly. The original body is kept here as the
# reference implementation.
pr_reference_gurobi_model <- function(model) {
  lower <- model$row_lower; upper <- model$row_upper
  source_rows <- integer(); sides <- senses <- names <- character(); rhs <- numeric()
  for (r in seq_len(nrow(model$A))) {
    if (is.finite(lower[r]) && is.finite(upper[r]) && lower[r] == upper[r]) {
      source_rows <- c(source_rows, r); sides <- c(sides, "equal"); senses <- c(senses, "=")
      rhs <- c(rhs, lower[r]); names <- c(names, paste0(model$row_names[r], "_equal"))
    } else {
      if (is.finite(lower[r])) {
        source_rows <- c(source_rows, r); sides <- c(sides, "lower"); senses <- c(senses, ">")
        rhs <- c(rhs, lower[r]); names <- c(names, paste0(model$row_names[r], "_lower"))
      }
      if (is.finite(upper[r])) {
        source_rows <- c(source_rows, r); sides <- c(sides, "upper"); senses <- c(senses, "<")
        rhs <- c(rhs, upper[r]); names <- c(names, paste0(model$row_names[r], "_upper"))
      }
    }
  }
  list(model = list(A = model$A[source_rows, , drop = FALSE], obj = model$objective,
    lb = model$var_lower, ub = model$var_upper, vtype = model$types, varnames = model$var_names,
    rhs = rhs, sense = senses, constrnames = names, modelsense = model$sense),
    row_map = data.frame(source_row = source_rows, side = sides, constraint_name = names, stringsAsFactors = FALSE),
    free_source_rows = which(!is.finite(lower) & !is.finite(upper)))
}

testthat::test_that("vectorized Gurobi conversion equals the original per-row conversion for every mode", {
  pw <- postrank_pairwise(pr_test_payload(S = 6L, n = 5L, K = 2L))
  w <- c(need1 = .5, need2 = .5)
  problems <- list(
    postrank_problem(pw, w, .25, 3L),
    postrank_problem(pw, w, .25, 5L, q = c(need2 = .3)),
    postrank_problem(pw, w, .25, 4L, exact_G = 3L, q = c(need1 = .4)),
    postrank_problem(pw, w, .4, 3L, objective = "minimax"))
  for (p in problems) testthat::expect_identical(.pr_gurobi_model(p$model), pr_reference_gurobi_model(p$model))
  free <- list(A = Matrix::Diagonal(3L), objective = rep(0, 3), var_lower = rep(0, 3), var_upper = rep(1, 3),
    row_lower = rep(-Inf, 3), row_upper = rep(Inf, 3), types = rep("C", 3), var_names = paste0("v", 1:3),
    row_names = paste0("r", 1:3), sense = "min")
  testthat::expect_identical(.pr_gurobi_model(free), pr_reference_gurobi_model(free))
})

testthat::test_that("vectorized Gurobi conversion is linear-time at moderate size", {
  set.seed(7L); n <- 60L; S <- 40L
  x <- pr_test_payload(S = S, n = n, K = 2L)
  x$joint_draws$tensor$values[] <- stats::rnorm(S * n * 2L)
  p <- postrank_problem(postrank_pairwise(x), c(need1 = .5, need2 = .5), .25, 4L)
  elapsed <- system.time(converted <- .pr_gurobi_model(p$model))[["elapsed"]]
  testthat::expect_identical(nrow(converted$row_map), 2L * n * (n - 1L))
  testthat::expect_lt(elapsed, 5)
})
