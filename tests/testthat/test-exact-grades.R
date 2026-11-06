pr_exact_grade_base <- function(n, G) {
  p <- postrank_pairwise(pr_test_payload(n = n, K = 1L))
  public <- list(weights = stats::setNames(1, p$criterion_ids), tau = .4, G_max = n, exact_G = G)
  effective <- public; effective$G_max <- G
  ordinary <- .pr_weighted_model(p, effective)
  list(base = .pr_add_exact_grades(ordinary, p, public), ordinary = ordinary, pairwise = p, settings = public)
}

testthat::test_that("exact-G assignments bijectively encode every surjective small label vector", {
  known_surjections <- list(`2` = c(1L, 2L), `3` = c(1L, 6L, 6L))
  for (n in 2:3) for (G in seq_len(n)) {
    obj <- pr_exact_grade_base(n, G); b <- obj$base; m <- b$model
    label_grid <- as.matrix(expand.grid(rep(list(seq_len(G)), n)))
    assignment_grid <- as.matrix(expand.grid(rep(list(0:1), n * G)))
    total_feasible <- 0L
    for (row in seq_len(nrow(label_grid))) {
      labels <- as.numeric(label_grid[row, ])
      z <- matrix(0, nrow = length(m$objective), ncol = nrow(assignment_grid))
      z[b$index$labels, ] <- labels
      pairs <- as.numeric(labels[b$index$pair_i] < labels[b$index$pair_j])
      z[b$index$pairs, ] <- pairs
      z[as.vector(b$index$assignment), ] <- t(assignment_grid)
      activity <- as.matrix(m$A %*% z)
      feasible <- colSums(z < m$var_lower | z > m$var_upper) == 0L &
        colSums(activity < m$row_lower | activity > m$row_upper) == 0L
      # Independent combinatorial criterion: each entity's unique selected
      # category is its label and every category occurs at least once.
      expected_assignment <- outer(labels, seq_len(G), `==`)
      expected <- rowSums(sweep(assignment_grid, 2L, as.numeric(expected_assignment), `!=`)) == 0L &
        setequal(labels, seq_len(G))
      testthat::expect_identical(feasible, expected,
        info = paste("n", n, "exact_G", G, "labels", paste(labels, collapse = ",")))
      total_feasible <- total_feasible + sum(feasible)
    }
    testthat::expect_equal(total_feasible, known_surjections[[as.character(n)]][[G]])
    testthat::expect_identical(dim(b$index$assignment), c(n, G))
    testthat::expect_true(all(m$objective[as.vector(b$index$assignment)] == 0))
    testthat::expect_true(all(m$types[as.vector(b$index$assignment)] == "B"))
  }
})

testthat::test_that("a label upper bound alone does not enforce nonempty grades", {
  obj <- pr_exact_grade_base(3L, 2L); b <- obj$base
  z <- rep(0, length(b$model$objective)); z[b$index$labels] <- 1L
  z[b$index$assignment[, 1L]] <- 1L
  ordinary_activity <- as.numeric(obj$ordinary$model$A %*% z[seq_along(obj$ordinary$model$objective)])
  testthat::expect_true(all(ordinary_activity >= obj$ordinary$model$row_lower & ordinary_activity <= obj$ordinary$model$row_upper))
  activity <- as.numeric(b$model$A %*% z)
  nonempty <- grep("^exact_nonempty_grade_", b$model$row_names)
  testthat::expect_identical(activity[nonempty], c(3, 0))
  testthat::expect_true(any(activity[nonempty] < b$model$row_lower[nonempty]))
  testthat::expect_true(all(z >= b$model$var_lower & z <= b$model$var_upper))
})

testthat::test_that("exact-G preserves original coefficients, maps and the disabled path", {
  obj <- pr_exact_grade_base(3L, 2L); b <- obj$base; old <- obj$ordinary
  testthat::expect_identical(b$model$objective[seq_along(old$model$objective)], old$model$objective)
  testthat::expect_identical(b$index$labels, old$index$labels)
  testthat::expect_identical(b$index$pairs, old$index$pairs)
  testthat::expect_identical(b$pair_map, old$pair_map)
  testthat::expect_equal(as.matrix(b$model$A[seq_len(nrow(old$model$A)), seq_len(ncol(old$model$A)), drop = FALSE]), as.matrix(old$model$A))
  settings <- obj$settings; settings$exact_G <- NULL
  testthat::expect_identical(.pr_add_exact_grades(old, obj$pairwise, settings), old)
})

testthat::test_that("public exact-G keeps the operational upper bound and validates nonempty assignments", {
  p <- postrank_pairwise(pr_test_payload(n = 3L, K = 1L))
  problem <- postrank_problem(p, stats::setNames(1, p$criterion_ids), .4, G_max = 3L, exact_G = 2L)
  testthat::expect_identical(problem$settings$G_max, 3L)
  testthat::expect_identical(problem$settings$exact_G, 2L)
  testthat::expect_true(all(problem$model$var_upper[problem$index$labels] == 2))
  labels <- c(1L, 1L, 2L)
  primal <- rep(0, length(problem$model$objective))
  primal[problem$index$labels] <- labels
  primal[problem$index$pairs] <- as.numeric(labels[problem$index$pair_i] < labels[problem$index$pair_j])
  primal[problem$index$assignment[cbind(seq_along(labels), labels)]] <- 1L
  receipt <- validate_postrank_solution(problem, primal)
  testthat::expect_true(receipt$valid)
  testthat::expect_identical(receipt$evaluation$G, 2L)
  primal[] <- 0; primal[problem$index$labels] <- 1L
  primal[problem$index$assignment[, 1L]] <- 1L
  invalid <- validate_postrank_solution(problem, primal)
  testthat::expect_false(invalid$valid)
  testthat::expect_null(invalid$grade)
})
