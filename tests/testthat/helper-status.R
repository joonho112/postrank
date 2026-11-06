# Mock Gurobi raw records for normalization tests (shared by several files).
pr_status_problem <- function() postrank_problem(postrank_pairwise(pr_test_payload()),
  c(need1 = .5, need2 = .5), tau = .25, G_max = 3L)
pr_status_raw <- function(problem, status = "OPTIMAL", lower = 0, primal = NULL) {
  if (is.null(primal)) {
    primal <- rep(0, length(problem$model$objective))
    primal[problem$index$labels] <- 1
  }
  .pr_gurobi_raw_result(list(status = status, x = primal, objval = 0,
    objbound = lower, mipgap = 0, runtime = .01),
    backend = list(name = "gurobi_mock", wrapper_version = "mock", solver_version = NA_character_, options = list()))
}
