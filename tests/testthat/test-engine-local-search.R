# 014 repair Phase 2: single-entity local search keeps the rows feasible, never
# worsens the start, returns its exact objective (incremental updates do not
# drift) and stops at a single-move local optimum.
pr_single_moves <- function(g) {
  G <- max(g); out <- list()
  for (i in seq_along(g)) for (b in c(seq_len(G), seq_len(G + 1L) - .5)) {
    if (b == g[i]) next
    h <- g; h[i] <- b; out[[length(out) + 1L]] <- .pr_engine_canonical(h)
  }
  out
}

testthat::test_that("local search is feasible, monotone, exact and locally optimal", {
  for (case in list(list(seed = 31L, S = 30L, n = 6L, K = 2L, conflict = TRUE),
                    list(seed = 32L, S = 30L, n = 7L, K = 3L, conflict = FALSE))) {
    x <- do.call(pr_random_payload, case); pw <- postrank_pairwise(x)
    w <- rep(1 / case$K, case$K); names(w) <- pw$criterion_ids
    for (s in list(list(G_max = 3L), list(G_max = 3L, exact_G = 3L), list(G_max = 3L, objective = "minimax"),
                   list(G_max = 4L, q = stats::setNames(.2, pw$criterion_ids[2])))) {
      objective <- if (is.null(s$objective)) "weighted" else s$objective
      problem <- postrank_problem(pw, w, .25, s$G_max, objective = objective, q = s$q, exact_G = s$exact_G)
      spec <- .pr_engine_spec(problem)
      starts <- Filter(function(z) .pr_engine_evaluate(spec, z$grade)$feasible, .pr_engine_candidates(spec, seed = 1L))
      testthat::expect_true(length(starts) > 0L)
      for (incremental in c(TRUE, FALSE)) for (z in utils::head(starts, 3L)) {
        label <- paste("case", case$seed, objective, paste(names(s), unlist(s), collapse = " "), "incremental", incremental)
        before <- .pr_engine_evaluate(spec, z$grade)
        ls <- .pr_engine_local_search(spec, z$grade, max_passes = 50L, incremental = incremental)
        after <- .pr_engine_evaluate(spec, ls$grade)
        testthat::expect_true(after$feasible, info = label)
        testthat::expect_true(after$raw <= before$raw + 1e-12, info = label)
        testthat::expect_equal(ls$value[1L], after$raw, tolerance = 1e-12, info = label)
        testthat::expect_false(ls$timed_out, info = label)
        neighbours <- lapply(pr_single_moves(ls$grade), function(h) .pr_engine_evaluate(spec, h))
        improving <- vapply(neighbours, function(v) v$feasible && v$raw < after$raw - 1e-9, logical(1L))
        testthat::expect_false(any(improving), info = label)
      }
    }
  }
})

testthat::test_that("local search stops at the deadline", {
  x <- pr_random_payload(33L, 30L, 7L, 2L); pw <- postrank_pairwise(x)
  problem <- postrank_problem(pw, c(need1 = .5, need2 = .5), .25, 3L)
  spec <- .pr_engine_spec(problem)
  ls <- .pr_engine_local_search(spec, rep(1L, 7L), deadline = proc.time()[["elapsed"]] - 1)
  testthat::expect_true(ls$timed_out); testthat::expect_identical(ls$moves, 0L)
})
