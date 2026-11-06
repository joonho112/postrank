# Score-order baselines (Chapter 6, PR-DEC-06-A, PR-DEC-11-C): expected-rank and composite
# scores, and optimal (contiguous-partition DP) or quantile cuts of a declared score order.
# Ported from the pilot's R/scores.R and R/optimal-cuts.R with the tie policy intact:
# exactly equal stored scores are indivisible blocks (no epsilon); objective ties prefer
# fewer occupied grades, then the lexicographically earlier vector of block cut positions.

.pr_baseline_fields <- c("method", "scores", "direction", "order", "score_blocks", "cut_rule", "cuts", "grade",
  "evaluation", "objective", "risk", "optimality_scope", "tie_policy", "settings", "input_identity",
  "schema_version", "provenance", "warnings")
.pr_tie_policy <- list(scores = "exact_score_blocks", objective = "fewer_grades_then_lexicographic_cuts", epsilon = 0)

.pr_score_weights <- function(weights, ids, what = "weights") {
  K <- length(ids)
  if (is.null(weights)) return(stats::setNames(rep(1 / K, K), ids))
  .pr_assert(typeof(weights) %in% c("integer", "double") && is.null(dim(weights)) && length(weights) == K &&
    all(is.finite(weights)) && all(weights >= 0) && abs(sum(weights) - 1) <= 1e-12,
    paste(what, "must be K nonnegative finite numbers summing to one"), "invalid_weights", paste0("$.", what))
  if (is.null(names(weights))) names(weights) <- ids
  .pr_assert(setequal(names(weights), ids) && !anyDuplicated(names(weights)), paste(what, "must be named by the criteria"),
    "invalid_weights", paste0("$.", what))
  weights[ids]
}

.pr_coefficient_source <- function(pairwise) {
  if (inherits(pairwise, "postrank_coefficients")) validate_postrank_coefficients(pairwise) else .pr_validate_pairwise(pairwise)
  pairwise
}

#' Weighted Expected-Rank Scores from Pairwise Errors
#'
#' Each entity receives a score equal to its posterior expected rank averaged
#' over the chosen criteria. Smaller scores indicate higher reporting priority.
#' The resulting order can be partitioned into grades by [postrank_cuts()].
#'
#' @details The expected-rank score is
#' \eqn{r_i = \sum_k b_k \{1 + \sum_{j \ne i} e_{ij,k}\}}
#' with \eqn{e_{ij,k} = P(\theta_{ik} \le \theta_{jk} \mid Y)}: the posterior
#' expected rank of entity `i` (1 = highest priority), averaged over criteria
#' with weights `b`. Columns are summed in a stable entity-ID order.
#' Reordering input rows while retaining their IDs therefore preserves each
#' named score and its exact-score tie block.
#'
#' @param pairwise A `postrank_pairwise`, `postrank_coefficients`, or
#'   `postrank_probabilities` object with tie-free directional errors.
#' @param weights `NULL` for equal weights, or nonnegative criterion weights
#'   summing to one. An unnamed vector follows criterion order; names must
#'   cover every criterion exactly once.
#' @return A named numeric vector, one score per entity (attribute
#'   `score_method = "expected_rank"`).
#' @seealso [postrank_cuts()], [postrank_compare()]
#' @concept baselines
#' @examples
#' postrank_expected_rank(pr_tutorial$one)
#' pw <- postrank_pairwise(postrank_toy)
#' postrank_expected_rank(pw, c(need_A = .6, need_B = .4))
#' @export
postrank_expected_rank <- function(pairwise, weights = NULL) {
  pw <- .pr_coefficient_source(pairwise)
  ids <- pw$entity_ids; ks <- pw$criterion_ids
  b <- .pr_score_weights(weights, ks)
  n <- length(ids); ranks <- matrix(0, n, length(ks))
  column_order <- order(ids, method = "radix")
  for (k in seq_along(ks)) {
    slice <- matrix(pw$e[, , k], n, n); diag(slice) <- 0
    ranks[, k] <- 1 + rowSums(slice[, column_order, drop = FALSE])
  }
  out <- stats::setNames(as.vector(ranks %*% unname(b)), ids)
  attr(out, "score_method") <- "expected_rank"
  out
}

#' Posterior-Mean Composite Scores with Declared Scales
#'
#' Posterior means are combined using declared criterion weights, scales and
#' centers. Larger scores indicate higher reporting priority. The resulting
#' deterministic score defines an order; it does not specify a posterior
#' distribution for the composite or the probability that one uncertain
#' composite exceeds another.
#'
#' @details The score is
#' \eqn{c_i = \sum_k a_k (\bar\theta_{ik} - \mathrm{center}_k) / \mathrm{scale}_k}.
#' Scales and centers are supplied by the caller; this function does not
#' estimate standardization parameters. Ranking these scores and then cutting
#' their order under criterion-weighted loss is different from grading a
#' composite target's posterior. See
#' `vignette("m2-several-criteria", package = "postrank")`.
#'
#' @param means An `n x K` numeric matrix of posterior means with entity
#'   rownames and criterion colnames (for example from
#'   [postrank_posterior_means()] or `coefficients$means`).
#' @param weights Nonnegative criterion weights `a` summing to one, or `NULL`
#'   for equal weights. Names are matched to criterion columns; an unnamed
#'   vector follows column order.
#' @param scales Positive scales: an unnamed scalar is recycled, an unnamed
#'   length-K vector follows the columns of `means`, and a named vector must
#'   contain every criterion ID exactly once (matched by name).
#' @param centers Centers, with the same name-matching and recycling rules
#'   as `scales`.
#' @return A named numeric vector (attribute `score_method = "composite"`).
#' @seealso [postrank_cuts()], [postrank_posterior_means()]
#' @concept baselines
#' @examples
#' m <- postrank_posterior_means(postrank_toy)
#' postrank_composite(m, c(need_A = .6, need_B = .4))
#' @export
postrank_composite <- function(means, weights, scales = 1, centers = 0) {
  .pr_assert(is.matrix(means) && is.numeric(means) && all(is.finite(means)) && !is.null(rownames(means)) &&
    !is.null(colnames(means)), "means must be a finite n x K matrix with entity rownames and criterion colnames",
    "invalid_means", "$.means")
  ks <- colnames(means); K <- length(ks)
  .pr_ids(rownames(means), path = "$.means.rownames")
  .pr_ids(ks, path = "$.means.colnames")
  a <- .pr_score_weights(weights, ks)
  rec <- function(v, label, positive) {
    .pr_assert(is.numeric(v) && all(is.finite(v)) && length(v) %in% c(1L, K), paste(label, "must be finite, length 1 or K"),
      "invalid_scales", paste0("$.", label))
    if (positive) .pr_assert(all(v > 0), paste(label, "must be positive"), "invalid_scales", paste0("$.", label))
    if (!is.null(names(v))) {
      .pr_assert(length(v) == K && !anyNA(names(v)) && !anyDuplicated(names(v)) && setequal(names(v), ks),
        paste(label, "must be named by every criterion exactly once; use an unnamed scalar for recycling"),
        "invalid_scales", paste0("$.", label))
      v <- v[ks]
    }
    stats::setNames(rep_len(as.numeric(v), K), ks)
  }
  sc <- rec(scales, "scales", TRUE); ce <- rec(centers, "centers", FALSE)
  standardized <- sweep(sweep(means[, ks, drop = FALSE], 2L, ce, "-"), 2L, sc, "/")
  out <- stats::setNames(as.vector(standardized %*% unname(a)), rownames(means))
  .pr_assert(all(is.finite(out)), "composite scores overflow", "invalid_means", "$.means")
  attr(out, "score_method") <- "composite"; attr(out, "scales") <- sc; attr(out, "centers") <- ce
  out
}

# The pilot's ordered-partition DP (pilot R/optimal-cuts.R), extended with an exact grade
# count. e: n x n x K (dimnames entity order), w: weights in criterion order. Returns grades,
# cuts (block positions), objective (raw sum of weighted error minus tau over disclosed
# pairs), subtraction-free risk, order and score blocks.
.pr_lexicographic_less <- function(x, y) {
  if (is.null(y)) return(TRUE)
  different <- which(x != y)
  if (!length(different)) return(FALSE)
  x[different[1L]] < y[different[1L]]
}
.pr_cuts_core <- function(e, scores, w, tau, G_max, exact_G = NULL, direction = c("descending", "ascending"),
                          rule = c("optimal", "quantile"), G_b = NULL) {
  direction <- match.arg(direction); rule <- match.arg(rule)
  n <- dim(e)[1L]; entity_ids <- dimnames(e)[[1L]]
  order_index <- order(if (direction == "descending") -scores else scores, entity_ids, method = "radix")
  ordered_scores <- unname(scores[order_index])
  block <- cumsum(c(TRUE, ordered_scores[-1L] != ordered_scores[-n]))
  B <- max(block)
  if (rule == "optimal") {
    H <- matrix(0, B, B)
    if (B > 1L) for (u in seq_len(n - 1L)) for (v in (u + 1L):n) {
      p <- block[u]; q <- block[v]
      if (p != q) H[p, q] <- H[p, q] + sum(w * e[order_index[u], order_index[v], ]) - tau
    }
    column_prefix <- apply(H, 2L, cumsum)
    if (B == 1L) column_prefix <- matrix(column_prefix, 1L, 1L)
    cross <- matrix(0, B, B)
    if (B > 1L) for (a in 2L:B) {
      running <- 0
      for (b in a:B) { running <- running + column_prefix[a - 1L, b]; cross[a, b] <- running }
    }
    G <- if (is.null(exact_G)) min(G_max, B) else exact_G
    value <- matrix(Inf, G, B); paths <- vector("list", G * B)
    path_at <- function(g, b) (g - 1L) * B + b
    value[1L, ] <- 0
    for (b in seq_len(B)) paths[[path_at(1L, b)]] <- integer()
    if (G >= 2L) for (g in 2L:G) for (b in g:B) {
      best_path <- NULL
      for (a in g:b) {
        candidate <- value[g - 1L, a - 1L] + cross[a, b]
        candidate_path <- c(paths[[path_at(g - 1L, a - 1L)]], a - 1L)
        if (candidate < value[g, b] || (candidate == value[g, b] && .pr_lexicographic_less(candidate_path, best_path))) {
          value[g, b] <- candidate; best_path <- candidate_path
        }
      }
      paths[[path_at(g, b)]] <- best_path
    }
    # Fewer occupied grades on exact objective ties (which.min returns the first minimum).
    occupied_G <- if (is.null(exact_G)) which.min(value[, B]) else exact_G
    cuts <- paths[[path_at(occupied_G, B)]]
    block_grades <- 1L + findInterval(seq_len(B) - 1L, cuts)
    objective <- value[occupied_G, B]
  } else {
    Gb <- G_b
    raw <- as.integer(1L + floor((seq_len(n) - 1L) * Gb / n))
    # Symmetric collapse: every raw grade an exact-score block straddles becomes one grade.
    parent <- seq_len(Gb)  # integer union-find over raw grades
    find <- function(i) { while (parent[i] != i) i <- parent[i]; as.integer(i) }
    for (bl in unique(block)) {
      g <- unique(raw[block == bl])
      if (length(g) > 1L) { root <- find(min(g)); for (h in g) parent[find(h)] <- root }
    }
    merged <- vapply(raw, find, 1L)
    block_grades <- vapply(seq_len(B), function(bl) merged[block == bl][1L], 1L)
    block_grades <- match(block_grades, sort(unique(block_grades)))
    cuts <- which(diff(block_grades) != 0L)
    objective <- NA_real_
  }
  grades <- integer(n); grades[order_index] <- block_grades[block]
  grades <- stats::setNames(as.integer(grades), entity_ids)
  M <- n * (n - 1) / 2; loss_numerator <- 0; Z <- 0
  for (u in seq_len(n - 1L)) for (v in (u + 1L):n) {
    i <- order_index[u]; j <- order_index[v]
    if (grades[i] == grades[j]) loss_numerator <- loss_numerator + tau else {
      hi <- if (grades[i] < grades[j]) i else j; lo <- if (hi == i) j else i
      loss_numerator <- loss_numerator + sum(w * e[hi, lo, ]); Z <- Z + sum(w * e[hi, lo, ]) - tau
    }
  }
  if (rule == "quantile") objective <- Z
  list(grades = grades, occupied_G = as.integer(max(block_grades)), cuts = as.integer(cuts), risk = loss_numerator / M,
    objective = objective, order = entity_ids[order_index], score_blocks = unname(split(entity_ids[order_index], block)),
    blocks = B)
}

#' Optimal or Quantile Cuts of a Declared Score Order
#'
#' A declared score order is partitioned into ordered grades, with exactly tied
#' scores retained in the same grade. Optimal cuts minimize weighted loss over
#' partitions of that order, whereas quantile cuts use fixed positions. The
#' search therefore remains conditional on the declared order.
#'
#' @details `rule = "optimal"` uses a contiguous-partition dynamic program
#' (subject to ordinary floating-point arithmetic) under the settings' grade
#' cap `G_max`, or the exact grade count `exact_G`; its optimality is
#' restricted to contiguous partitions of this score order. `rule = "quantile"`
#' uses the fixed positional labels \eqn{1 + \lfloor (p - 1) G_b / n \rfloor}
#' and performs no optimization. Exactly equal stored scores are never split;
#' a quantile boundary inside an exact-score block merges the grades it
#' straddles, so the realized number of grades can be below `G_b`. The realized
#' grade count must still satisfy `G_max` and `exact_G`; violations raise
#' `baseline_grade_limit_violation` or `baseline_exact_grade_violation`.
#'
#' The dynamic program optimizes the weighted objective only: settings with
#' error budgets `q` or the minimax objective are refused
#' (`unsupported_baseline_settings`); an `exact_G` larger than the number of
#' exact-score blocks is refused (`exact_G_exceeds_blocks`). Typed Gaussian
#' and mixture coefficients permit exact-count cuts within this fixed order,
#' although their native joint problem constructor does not support exact-G.
#' Direct [postrank_probabilities()] inputs are restricted to weighted
#' at-most-G cuts, as well as weighted at-most-G native problems.
#'
#' @param scores A named score vector (one per entity), for example from
#'   [postrank_expected_rank()] or [postrank_composite()].
#' @param pairwise The `postrank_pairwise`, `postrank_coefficients`, or
#'   `postrank_probabilities` object whose directional errors define the loss.
#' @param settings A [postrank_settings()] object (weights, tau, grade rule).
#' @param direction `"ascending"` (smaller score = higher priority, as for
#'   expected rank) or `"descending"` (larger = higher, as for composites).
#' @param rule `"optimal"` or `"quantile"`.
#' @param G_b For `rule = "quantile"`, the requested number of grades
#'   (default: the settings' `exact_G`, else `G_max`, capped at `n`).
#' @param method Optional label; defaults to the score's `score_method`
#'   attribute, else `"user_scores"`.
#' @return A `postrank_baseline` list. `scores`, `direction`, `order` and
#'   `score_blocks` record the declared order and its indivisible exact-score
#'   blocks. `cut_rule`, `cuts` (block positions) and the entity-named `grade`
#'   record the action. `evaluation` contains the fixed-action metrics;
#'   `risk` is the weighted loss and `objective` its raw optimization value.
#'   `optimality_scope` distinguishes optimal partitions of this score order
#'   from quantile cuts; neither provides a full-family solver bound.
#'   `method`, `tie_policy`, bound `settings`, `input_identity`,
#'   `schema_version`, `provenance` and `warnings` retain the construction
#'   record. When the requested grade count is impossible, the function raises
#'   an error rather than returning an all-withheld report.
#' @seealso [postrank_expected_rank()], [postrank_composite()], [postrank_compare()]
#' @concept baselines
#' @examples
#' pw <- postrank_pairwise(postrank_toy)
#' s <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
#' er <- postrank_cuts(postrank_expected_rank(pw, s$weights), pw, s, direction = "ascending")
#' get_grades(er)
#' @export
postrank_cuts <- function(scores, pairwise, settings, direction = c("ascending", "descending"),
                          rule = c("optimal", "quantile"), G_b = NULL, method = NULL) {
  direction <- match.arg(direction); rule <- match.arg(rule)
  pw <- .pr_coefficient_source(pairwise)
  .pr_validate_settings(settings)
  if (inherits(pw, "postrank_probabilities"))
    .pr_cf_problem_scope(pw, settings$objective, settings$q, settings$exact_G,
      settings$minimax_criteria)
  if (!is.null(settings$q) || identical(settings$objective, "minimax"))
    .pr_abort("baseline cuts optimize the weighted objective only; settings with q or objective = \"minimax\" are not supported",
      "unsupported_baseline_settings", "$.settings")
  bound <- .pr_settings_bind(settings, pw)
  ids <- pw$entity_ids
  .pr_assert(is.numeric(scores) && is.null(dim(scores)) && length(scores) == length(ids) && all(is.finite(scores)) &&
    !is.null(names(scores)) && setequal(names(scores), ids) && !anyDuplicated(names(scores)),
    "scores must be a finite numeric vector named by exactly the entities", "invalid_scores", "$.scores")
  score_method <- attr(scores, "score_method")
  sc <- stats::setNames(as.numeric(scores[ids]), ids)
  if (is.null(method)) method <- if (is.null(score_method)) "user_scores" else score_method
  .pr_assert(is.character(method) && length(method) == 1L && nzchar(method), "method must be one nonempty string", "invalid_method", "$.method")
  w <- bound$policy$weights[pw$criterion_ids]; tau <- bound$policy$tau
  e <- pw$e; dimnames(e) <- list(ids, ids, pw$criterion_ids)
  exact_G <- bound$policy$exact_G
  n_blocks <- length(unique(sc))
  if (!is.null(exact_G) && exact_G > n_blocks)
    .pr_abort(sprintf("exact_G = %d exceeds the %d exact-score blocks of this order", exact_G, n_blocks),
      "exact_G_exceeds_blocks", "$.settings.exact_G")
  if (rule == "quantile") {
    if (is.null(G_b)) G_b <- if (is.null(exact_G)) bound$policy$G_max else exact_G
    .pr_assert(is.numeric(G_b) && length(G_b) == 1L && is.finite(G_b) && G_b >= 1 && G_b == floor(G_b),
      "G_b must be a positive integer", "invalid_grade_limit", "$.G_b")
    G_b <- as.integer(min(G_b, length(ids)))
  } else .pr_assert(is.null(G_b), "G_b applies to rule = \"quantile\" only", "invalid_grade_limit", "$.G_b")
  core <- .pr_cuts_core(e, sc, w, tau, bound$policy$G_max, if (rule == "optimal") exact_G else NULL, direction, rule, G_b)
  ev <- postrank_evaluate(core$grades, pw, settings = bound$settings)
  .pr_baseline_grade_rule(ev$G, bound$settings)
  warn <- character()
  if (rule == "quantile" && core$occupied_G < G_b)
    warn <- sprintf("Exact-score blocks merged quantile grades: requested G_b = %d, realized G = %d.", G_b, core$occupied_G)
  out <- list(method = method, scores = sc, direction = direction, order = core$order, score_blocks = core$score_blocks,
    cut_rule = rule, cuts = core$cuts, grade = ev$grade, evaluation = ev, objective = core$objective, risk = core$risk,
    optimality_scope = if (rule == "optimal") paste0("contiguous partitions of the declared ", gsub("_", " ", method), " score order only") else
      "quantile cuts at fixed positions; no optimization performed",
    tie_policy = .pr_tie_policy, settings = bound$settings, input_identity = pw$input_identity, schema_version = "1",
    provenance = .pr_provenance("postrank_cuts", requested_G_b = if (rule == "quantile") G_b else NULL,
      score_attributes = attributes(scores)[setdiff(names(attributes(scores)), "names")]),
    warnings = warn)
  class(out) <- c("postrank_baseline", "list")
  .pr_validate_baseline(out)
  out
}

.pr_baseline_grade_rule <- function(G, settings) {
  .pr_assert(G <= settings$G_max, "the realized baseline grade count exceeds G_max",
    "baseline_grade_limit_violation", "$.settings.G_max")
  if (!is.null(settings$exact_G)) .pr_assert(G == settings$exact_G,
    "the realized baseline grade count differs from exact_G; score ties are never split",
    "baseline_exact_grade_violation", "$.settings.exact_G")
  invisible(TRUE)
}

.pr_validate_baseline <- function(x) {
  .pr_assert(inherits(x, "postrank_baseline") && identical(names(x), .pr_baseline_fields),
    "expected a postrank_baseline with its documented ordered fields", "invalid_baseline")
  .pr_assert(x$cut_rule %in% c("optimal", "quantile") && x$direction %in% c("ascending", "descending"),
    "invalid baseline rule or direction", "invalid_baseline")
  .pr_assert(identical(x$tie_policy, .pr_tie_policy), "baseline tie policy must be the frozen exact-block policy", "invalid_baseline")
  .pr_assert(abs(x$risk - x$evaluation$weighted_risk) <= 1e-12, "baseline risk disagrees with its evaluation", "invalid_baseline")
  .pr_validate_settings(x$settings)
  .pr_baseline_grade_rule(length(unique(x$grade)), x$settings)
  invisible(TRUE)
}

#' @export
get_grades.postrank_baseline <- function(x, ...) x$grade
