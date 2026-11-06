# Weak-order LP relaxation with lazily separated triangle inequalities.
#
# Variables y_ij (i != j, "i strictly ahead of j") plus t for the max objective.
# Rows: asymmetry y_ij + y_ji <= 1; the disclosure-count range implied by the
# grade-count mode; objective-specific rows; spec rows; cuts
# y_ki - y_kj - y_ji <= 0 (negative transitivity of strict weak orders). Every
# feasible ordered partition of the mode satisfies these rows, so the LP
# optimum is a valid lower bound for the G_max, exact-G and protected problems.
.pr_engine_pair_index <- function(n) {
  idx <- matrix(0L, n, n); idx[row(idx) != col(idx)] <- seq_len(n * (n - 1L)); idx
}

# Range of the number of strictly ordered (disclosed) pairs of an ordered
# partition of n entities: at most G grades leave at least the balanced
# within-grade pairs tied; exactly G nonempty grades disclose at least the pairs
# of one block of n - G + 1 entities plus G - 1 singletons. Both are valid
# inequalities for the grade-count modes that the triangle relaxation drops.
.pr_engine_disclosure_limits <- function(n, G_max, exact_G = NULL) {
  M <- choose(n, 2); G <- min(as.integer(if (is.null(exact_G)) G_max else exact_G), n)
  sizes <- rep(n %/% G, G) + as.integer(seq_len(G) <= n %% G)
  c(lower = if (is.null(exact_G)) 0 else M - choose(n - G + 1, 2), upper = M - sum(choose(sizes, 2)))
}

# Most violated triangle inequalities of a fractional (or integral) Y.
.pr_engine_separate <- function(Y, eps = 1e-7, max_cuts = 5000L) {
  n <- nrow(Y); tY <- t(Y); found <- vector("list", n)
  # Keep at most per_k violations for each k before the global top selection,
  # so memory stays O(max_cuts) instead of O(number of violated triangles).
  per_k <- max(4L, as.integer(ceiling(4 * max_cuts / n)))
  for (k in seq_len(n)) {
    yk <- Y[k, ]
    if (max(yk) <= eps) next
    V <- matrix(yk, n, n) - matrix(yk, n, n, byrow = TRUE) - tY
    V[k, ] <- -Inf; V[, k] <- -Inf; diag(V) <- -Inf
    hit <- which(V > eps)
    if (length(hit) > per_k) hit <- hit[order(-V[hit])[seq_len(per_k)]]
    if (length(hit)) found[[k]] <- cbind(k = k, i = (hit - 1L) %% n + 1L, j = (hit - 1L) %/% n + 1L, violation = V[hit])
  }
  cuts <- do.call(rbind, found)
  if (is.null(cuts) || !nrow(cuts)) return(matrix(numeric(), 0L, 4L, dimnames = list(NULL, c("k", "i", "j", "violation"))))
  cuts <- cuts[order(-cuts[, "violation"]), , drop = FALSE]
  cuts[seq_len(min(nrow(cuts), max_cuts)), , drop = FALSE]
}

# Sparse rows for cuts in an arbitrary column map: col(i, j) gives the column.
.pr_engine_cut_rows <- function(cuts, col_of, ncol) {
  m <- nrow(cuts)
  Matrix::sparseMatrix(i = rep(seq_len(m), each = 3L),
    j = as.vector(rbind(col_of[cbind(cuts[, "k"], cuts[, "i"])], col_of[cbind(cuts[, "k"], cuts[, "j"])],
                        col_of[cbind(cuts[, "j"], cuts[, "i"])])),
    x = rep(c(1, -1, -1), m), dims = c(m, ncol))
}

.pr_engine_lp_model <- function(spec) {
  n <- spec$n; idx <- .pr_engine_pair_index(n); P <- n * (n - 1L)
  max_obj <- identical(spec$objective, "max"); ncol <- P + as.integer(max_obj)
  ut <- which(upper.tri(idx), arr.ind = TRUE); na <- nrow(ut)
  blocks <- list(Matrix::sparseMatrix(i = rep(seq_len(na), 2L), j = c(idx[ut], idx[ut[, 2:1, drop = FALSE]]),
    x = 1, dims = c(na, ncol)))
  lhs <- rep(-Inf, na); rhs <- rep(1, na); obj <- numeric(ncol)
  limits <- .pr_engine_disclosure_limits(n, spec$G_max, spec$exact_G)
  dense_row <- function(A, extra = NULL) {
    v <- numeric(ncol); off <- row(A) != col(A); v[idx[off]] <- A[off]
    if (!is.null(extra)) v[ncol] <- extra
    Matrix::Matrix(v, nrow = 1L, sparse = TRUE)
  }
  if (max_obj) {
    obj[ncol] <- 1
    for (A in spec$terms) { blocks[[length(blocks) + 1L]] <- dense_row(A, -spec$M); lhs <- c(lhs, -Inf); rhs <- c(rhs, -spec$M * spec$tau) }
  } else {
    off <- row(spec$C) != col(spec$C); obj[idx[off]] <- spec$C[off]
  }
  for (r in spec$rows) { blocks[[length(blocks) + 1L]] <- dense_row(r$A); lhs <- c(lhs, -Inf); rhs <- c(rhs, r$b) }
  A <- methods::as(do.call(rbind, blocks), "CsparseMatrix")
  list(A = A, obj = obj, lhs = lhs, rhs = rhs, lower = rep(0, ncol), upper = rep(1, ncol),
       idx = idx, ncol = ncol, P = P, max_obj = max_obj, limits = limits,
       disclosure_rowable = limits[["lower"]] > 0 || limits[["upper"]] < choose(n, 2))
}

.pr_engine_Y <- function(x, idx, n) { Y <- matrix(0, n, n); Y[row(Y) != col(Y)] <- x[idx[row(idx) != col(idx)]]; Y }

# Solve the relaxation with cutting rounds. Returns the bound of the last LP
# solved to optimality (NA if none), the final Y, cuts and diagnostics. The
# budget is in wall-clock seconds, and each round records the time limit the
# solver held for its call. With cuts_after_budget = FALSE (no MIP stage will
# use the cuts), no cuts are separated once the budget is spent.
.pr_engine_lp_bound <- function(spec, backend, control, time_budget, max_rounds = 60L, cuts_per_round = NULL,
                                cuts_after_budget = TRUE) {
  started <- proc.time()[["elapsed"]]; lp <- .pr_engine_lp_model(spec); n <- spec$n
  if (is.null(cuts_per_round)) cuts_per_round <- max(200L, 10L * n)
  tolerance <- .pr_solution_tolerances(control$tolerances)
  all_cuts <- matrix(numeric(), 0L, 4L, dimnames = list(NULL, c("k", "i", "j", "violation")))
  rounds <- list(); bound <- NA_real_; Y <- NULL; status <- "not_run"; warnings <- character()
  remaining <- function() time_budget - (proc.time()[["elapsed"]] - started)
  quiet <- function(expr) withCallingHandlers(expr, warning = function(w) {
    warnings <<- c(warnings, paste("Engine LP:", conditionMessage(w))); invokeRestart("muffleWarning") })
  # The disclosure-count row is dense (all pair columns); it is added only when
  # an LP solution violates it, like a cut.
  disclosure_lhs <- if (lp$limits[["lower"]] > 0) lp$limits[["lower"]] else -Inf
  disclosure_rhs <- lp$limits[["upper"]]; disclosure_added <- FALSE
  if (identical(backend, "highs")) {
    ctl <- highs::highs_control(threads = as.integer(control$threads), time_limit = max(.1, remaining()),
      random_seed = as.integer(control$seed), output_flag = FALSE, log_to_console = FALSE,
      primal_feasibility_tolerance = .pr_solver_tolerance(.5 * tolerance$feasibility, 1e-10, Inf))
    model <- highs::highs_model(L = lp$obj, lower = lp$lower, upper = lp$upper, A = lp$A, lhs = lp$lhs, rhs = lp$rhs,
      types = rep("C", lp$ncol))
    solver <- quiet(highs::highs_solver(model, control = ctl))
    # HiGHS checks time_limit against the solver object's cumulative run time
    # (verified with highs 1.12.0.3), which leaves out the cut separation
    # between calls; so each call gets the run time used so far plus the
    # remaining wall-clock budget. A call that still runs well past the budget
    # (a HiGHS that timed each call separately) is reported.
    used <- 0
    run <- function() quiet({
      allowed <- max(.1, remaining())
      highs::hi_solver_set_options(solver$solver, list(time_limit = used + allowed))
      limit <- highs::hi_solver_get_option(solver$solver, "time_limit", type = "double")
      t0 <- proc.time()[["elapsed"]]; highs::hi_solver_run(solver$solver); took <- proc.time()[["elapsed"]] - t0
      used <<- used + took
      if (took > allowed + 1) warnings <<- c(warnings, sprintf(
        "Engine LP: a HiGHS call ran %.1f s with %.1f s left in the LP budget.", took, allowed))
      list(status = highs::hi_solver_status_message(solver$solver),
           objective = highs::hi_solver_info(solver$solver)$objective_function_value,
           x = highs::hi_solver_get_solution(solver$solver)$col_value, time_limit = limit) })
    add <- function(cuts) {
      m <- nrow(cuts)
      cols <- as.vector(rbind(lp$idx[cbind(cuts[, "k"], cuts[, "i"])], lp$idx[cbind(cuts[, "k"], cuts[, "j"])],
                              lp$idx[cbind(cuts[, "j"], cuts[, "i"])])) - 1L
      quiet(highs::hi_solver_add_rows(solver$solver, lhs = rep(-Inf, m), rhs = rep(0, m),
        start = as.integer(3L * (seq_len(m) - 1L)), index = as.integer(cols), value = rep(c(1, -1, -1), m)))
    }
    add_disclosure <- function() quiet(highs::hi_solver_add_rows(solver$solver, lhs = disclosure_lhs, rhs = disclosure_rhs,
      start = 0L, index = as.integer(seq_len(lp$P) - 1L), value = rep(1, lp$P)))
  } else {
    params <- list(OutputFlag = 0L, Threads = as.integer(control$threads), Seed = as.integer(control$seed),
      FeasibilityTol = .pr_solver_tolerance(.5 * tolerance$feasibility, 1e-9, 1e-2))
    A_current <- lp$A; rhs_current <- lp$rhs; lhs_current <- lp$lhs
    run <- function() {
      gm <- .pr_gurobi_model(list(A = A_current, objective = lp$obj, var_lower = lp$lower, var_upper = lp$upper,
        row_lower = lhs_current, row_upper = rhs_current, types = rep("C", lp$ncol),
        var_names = paste0("y", seq_len(lp$ncol)), row_names = paste0("r", seq_len(nrow(A_current))), sense = "min"))
      params$TimeLimit <- max(.1, remaining())
      r <- quiet(gurobi::gurobi(gm$model, params = params))
      list(status = if (identical(r$status, "OPTIMAL")) "Optimal" else as.character(r$status),
           objective = if (is.null(r$objval)) NA_real_ else r$objval, x = r$x, time_limit = params$TimeLimit)
    }
    add <- function(cuts) {
      A_current <<- rbind(A_current, .pr_engine_cut_rows(cuts, lp$idx, lp$ncol))
      lhs_current <<- c(lhs_current, rep(-Inf, nrow(cuts))); rhs_current <<- c(rhs_current, rep(0, nrow(cuts)))
    }
    add_disclosure <- function() {
      A_current <<- rbind(A_current, Matrix::sparseMatrix(i = rep(1L, lp$P), j = seq_len(lp$P), x = 1, dims = c(1L, lp$ncol)))
      lhs_current <<- c(lhs_current, disclosure_lhs); rhs_current <<- c(rhs_current, disclosure_rhs)
    }
  }
  for (round in seq_len(max_rounds)) {
    if (remaining() <= 0) { status <- "time_budget_exhausted"; break }
    res <- tryCatch(run(), error = function(e) list(status = paste("error:", conditionMessage(e)), objective = NA_real_, x = NULL))
    optimal <- identical(res$status, "Optimal") && is.finite(res$objective) && !is.null(res$x)
    rounds[[round]] <- list(round = round, status = res$status, objective = res$objective, cuts_total = nrow(all_cuts),
                            elapsed = proc.time()[["elapsed"]] - started,
                            time_limit = if (is.null(res$time_limit)) NA_real_ else res$time_limit)
    if (!optimal) { status <- paste0("lp_not_optimal:", res$status); break }
    bound <- if (is.na(bound)) res$objective else max(bound, res$objective)
    Y <- .pr_engine_Y(res$x, lp$idx, n)
    # Once the budget is spent, new cuts could only serve a later MIP stage.
    if (!cuts_after_budget && remaining() <= 0) { status <- "time_budget_exhausted"; break }
    added <- 0L
    disclosed <- sum(res$x[seq_len(lp$P)])
    if (lp$disclosure_rowable && !disclosure_added && (disclosed > disclosure_rhs + 1e-7 || disclosed < disclosure_lhs - 1e-7)) {
      add_disclosure(); disclosure_added <- TRUE; added <- 1L
    }
    cuts <- .pr_engine_separate(Y, eps = 1e-7, max_cuts = cuts_per_round)
    if (nrow(cuts)) { add(cuts); all_cuts <- rbind(all_cuts, cuts); added <- added + nrow(cuts) }
    if (!added) { status <- "no_violated_triangle"; break }
    status <- "max_rounds"
  }
  list(bound_raw = bound, Y = Y, cuts = all_cuts, status = status, rounds = rounds, time_budget = time_budget,
       elapsed = proc.time()[["elapsed"]] - started, variables = lp$ncol, base_rows = nrow(lp$A),
       disclosure_row_added = disclosure_added, warnings = unique(warnings))
}
