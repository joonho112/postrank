test_that("the synthetic tutorial preserves the first criterion and its stated law", {
  z <- pr_tutorial
  expect_identical(names(z), c("one", "two", "units", "law"))
  expect_identical(z$one$e[, , 1], z$two$e[, , 1])
  expect_identical(z$one$means[, 1], z$two$means[, 1])
  expect_equal(vapply(seq_len(6), function(i) diag(z$law$covariance[, , i]), numeric(2)),
    matrix(.04, 2, 6), ignore_attr = TRUE)
  expect_true(all(z$law$covariance[1, 2, ] == 0))
  for (k in 1:2) for (i in 1:6) for (j in setdiff(1:6, i)) {
    expected <- stats::pnorm((z$law$means[j, k] - z$law$means[i, k]) / sqrt(.08))
    expect_lte(abs(z$two$e[i, j, k] - expected), 1e-14)
  }
})

test_that("prepared tutorial sensitivity results match all admissible ordered partitions", {
  reader <- new.env()
  sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), reader)
  a <- do.call(rbind, lapply(1:4, function(G) {
    z <- as.matrix(expand.grid(rep(list(seq_len(G)), 6)))
    z[apply(z, 1, function(v) length(unique(v)) == G), , drop = FALSE]
  }))
  expect_equal(nrow(a), 2163)
  G <- apply(a, 1, max); N <- integer(nrow(a)); E <- matrix(0, nrow(a), 2)
  for (i in 1:5) for (j in (i+1):6) {
    forward <- a[, i] < a[, j]; reverse <- a[, i] > a[, j]
    N <- N + forward + reverse
    for (k in 1:2) {
      p <- stats::pnorm((pr_tutorial$law$means[j, k] - pr_tutorial$law$means[i, k]) / sqrt(.08))
      E[, k] <- E[, k] + forward * p + reverse * (1 - p)
    }
  }
  minimum <- function(w, tau, cap) min(((E %*% w)[, 1] + tau * (15 - N))[G <= cap] / 15)
  sensitivity <- reader$load_or_compute("tutorial_sensitivity")
  for (r in seq_len(nrow(sensitivity$table))) {
    s <- sensitivity$settings[[r]]
    expect_equal(sensitivity$table$risk[r], minimum(s$weights, s$tau, s$G_max), tolerance = 1e-12)
  }
  frontier <- reader$load_or_compute("tutorial_frontier")
  for (r in seq_len(nrow(frontier$table)))
    expect_equal(frontier$table$primary_risk[r], minimum(c(.5, .5), frontier$table$tau[r], 3), tolerance = 1e-12)
  cost <- reader$load_or_compute("tutorial_commonality")$table
  for (k in 1:2) {
    own <- minimum(as.numeric(1:2 == k), .2, 3)
    expect_equal(cost$own_best_risk[k], own, tolerance = 1e-12)
    expect_equal(cost$cost_lower[k], cost$common_grade_risk[k] - own, tolerance = 1e-12)
    expect_equal(cost$cost_upper[k], cost$common_grade_risk[k] - own, tolerance = 1e-12)
  }
})

test_that("both prepared tutorial actions match an independent exhaustive oracle", {
  reader <- new.env()
  sys.source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), reader)
  # Every ordered partition of six labelled entities into at most three grades.
  actions <- do.call(rbind, lapply(1:3, function(G) {
    a <- as.matrix(expand.grid(rep(list(seq_len(G)), 6)))
    a[apply(a, 1, function(v) length(unique(v)) == G), , drop = FALSE]
  }))
  expect_equal(nrow(actions), 603)
  direct <- function(g, K) {
    costs <- vapply(1:K, function(k) {
      sum(vapply(1:5, function(i) sum(vapply((i+1):6, function(j) {
        if (g[i] == g[j]) return(.2)
        hi <- if (g[i] < g[j]) i else j; lo <- if (hi == i) j else i
        stats::pnorm((pr_tutorial$law$means[lo, k] - pr_tutorial$law$means[hi, k]) / sqrt(.08))
      }, 0)), 0)) / 15
    }, 0)
    mean(costs)
  }
  for (part in c("one", "two")) {
    a <- reader$load_or_compute(paste0("tutorial_", part))
    K <- if (part == "one") 1L else 2L
    risks <- apply(actions, 1, direct, K = K)
    expect_equal(get_risk(a)$risk, min(risks), tolerance = 1e-12)
    expect_equal(direct(get_grades(a), K), min(risks), tolerance = 1e-12)
    expect_identical(a$input, pr_tutorial[[part]])
    expect_identical(a$report_card$level, .9)
  }
})
