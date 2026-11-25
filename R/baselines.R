# Score-order baselines: expected-rank and composite scores, plus optimal
# (contiguous-partition DP) or quantile cuts of a declared score order.
# Equal stored scores form indivisible blocks (no epsilon); objective ties
# prefer fewer occupied grades, then the lexicographically earliest cut vector.

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
#' `postrank_expected_rank()` computes each entity's posterior expected rank
#' averaged across criteria, where `1` is the highest priority (smallest score =
#' highest priority). Pass the resulting score vector to [postrank_cuts()] to
#' partition that score order into integer grades.
#'
#' @param pairwise Pairwise directional-error probabilities: a
#'   `postrank_pairwise`, `postrank_coefficients` or [postrank_probabilities()]
#'   object.
#' @param weights Nonnegative finite criterion weights summing to one within
#'   `1e-12`, or `NULL` (the default) for equal weights `1 / K`. Unnamed weights
#'   follow `pairwise$criterion_ids` order; named weights must name every
#'   criterion once.
#' @returns A numeric vector named by `entity_ids`, carrying attribute
#'   `score_method = "expected_rank"`.
#' @details
#' Entity `i`'s score is
#' \eqn{r_i = \sum_k b_k \{1 + \sum_{j \ne i} e_{ij,k}\}}
#' where \eqn{e_{ij,k} = P(\theta_{ik} \le \theta_{jk})} and `b` are `weights`.
#' Columns are summed in sorted `entity_id` order so permuting entity rows
#' preserves exact floating-point scores and tie blocks.
#' @seealso [postrank_cuts()], [postrank_composite()], [postrank_compare()]
#' @concept baselines
#' @examples
#' postrank_expected_rank(pr_tutorial$one)
#'
#' pw <- postrank_pairwise(postrank_toy)
#' postrank_expected_rank(pw, c(need_A = 0.6, need_B = 0.4))
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
#' `postrank_composite()` combines entity posterior means across criteria into a
#' weighted linear score using caller-supplied centers and scales (larger score
#' = higher priority). Pass the resulting score vector to [postrank_cuts()] to
#' partition that order into integer grades.
#'
#' @param means Finite `n x K` numeric matrix of posterior means with entity
#'   row names and criterion column names (for example from
#'   [postrank_posterior_means()] or `coefficients$means`).
#' @param weights Nonnegative finite criterion weights `a` summing to one within
#'   `1e-12`, or `NULL` for equal weights `1 / K`. Unnamed weights follow column
#'   order; named weights must name every criterion once.
#' @param scales Positive finite scale value(s) (default `1`): an unnamed scalar
#'   is recycled across criteria, an unnamed length-`K` vector follows column
#'   order, and a named vector must name every criterion once.
#' @param centers Finite center value(s) (default `0`), following the same
#'   name-matching and recycling rules as `scales`.
#' @returns A numeric vector named by `rownames(means)`, carrying attributes
#'   `score_method = "composite"`, `scales` and `centers`.
#' @details
#' Entity `i`'s composite score is
#' \eqn{c_i = \sum_k a_k (\bar\theta_{ik} - \mathrm{center}_k) / \mathrm{scale}_k}.
#' `postrank_composite()` does not estimate empirical means or standard
#' deviations across entities. Ordering entities by `c_i` and cutting that order
#' under per-criterion pairwise loss differs from forming a posterior
#' distribution of a single composite target; see
#' `vignette("m2-several-criteria", package = "postrank")`.
#' @seealso [postrank_cuts()], [postrank_posterior_means()],
#'   [postrank_compare()]
#' @concept baselines
#' @examples
#' m <- postrank_posterior_means(postrank_toy)
#' postrank_composite(m, c(need_A = 0.6, need_B = 0.4))
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

# Ordered-partition dynamic program with optional exact grade count.
# e: n x n x K (dimnames entity order), w: weights in criterion order. Returns grades,
# cuts (block positions), objective (raw sum of weighted error minus tau over disclosed
# pairs), subtraction-free risk, order, and score blocks.
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
#' `postrank_cuts()` partitions an entity score order into contiguous integer
#' grades (grade 1 = highest priority), keeping entities with equal scores in
#' the same grade. No external optimization solver is required.
#'
#' @param scores Finite numeric vector named by `pairwise$entity_ids`, for
#'   example from [postrank_expected_rank()] or [postrank_composite()].
#' @param pairwise A `postrank_pairwise`, `postrank_coefficients` or
#'   [postrank_probabilities()] object supplying directional-error
#'   probabilities.
#' @param settings A [postrank_settings()] object specifying weighted `weights`,
#'   `tau`, `G_max` and optional `exact_G`.
#' @param direction Score direction: `"ascending"` (smaller score = higher
#'   priority, the default, matching [postrank_expected_rank()]) or
#'   `"descending"` (larger score = higher priority, matching
#'   [postrank_composite()]).
#' @param rule Cut rule: `"optimal"` (the default, dynamic programming over
#'   contiguous cuts) or `"quantile"` (fixed positional cuts).
#' @param G_b Positive integer requested grade count when `rule = "quantile"`
#'   (defaults to `settings$exact_G`, or `settings$G_max`, capped at `n`; must
#'   be `NULL` when `rule = "optimal"`).
#' @param method Optional non-empty label for this baseline; defaults to
#'   `attr(scores, "score_method")`, or `"user_scores"` if unset.
#' @returns A `postrank_baseline` list containing `method`, `scores`,
#'   `direction`, `order`, `score_blocks`, `cut_rule`, `cuts`, `grade`,
#'   `evaluation`, `objective`, `risk`, `optimality_scope`, `tie_policy`, bound
#'   `settings`, `input_identity`, `schema_version`, `provenance` and
#'   `warnings`.
#' @details
#' `rule = "optimal"` uses dynamic programming (in ordinary floating-point
#' arithmetic) to minimize weighted expected loss over contiguous partitions of
#' the given score order under `G_max` or `exact_G` (breaking exact objective
#' ties toward fewer occupied grades and then earlier block cuts). Optimality
#' holds only within contiguous partitions of this score order, not across all
#' allowed gradings. `rule = "quantile"` assigns raw positional grades
#' \eqn{1 + \lfloor (p - 1) G_b / n \rfloor} without optimization, merging any
#' grades straddled by equal scores (which can leave fewer than `G_b` occupied
#' grades, recorded in `warnings`).
#'
#' Settings with `q` error budgets or `objective = "minimax"` stop with
#' `unsupported_baseline_settings`, and `exact_G` exceeding the number of
#' distinct score blocks stops with `exact_G_exceeds_blocks` (or
#' `baseline_exact_grade_violation` when quantile merging leaves fewer grades).
#' [postrank_probabilities()] inputs support at-most-`G_max` cuts without
#' `exact_G`, whereas `postrank_pairwise` and `postrank_coefficients` also allow
#' `exact_G`.
#' @seealso [postrank_expected_rank()], [postrank_composite()],
#'   [postrank_compare()]
#' @concept baselines
#' @examples
#' pw <- postrank_pairwise(postrank_toy)
#' s <- postrank_settings(c(need_A = 0.6, need_B = 0.4), tau = 0.25, G_max = 3L)
#' er <- postrank_cuts(postrank_expected_rank(pw, s$weights), pw, s,
#'   direction = "ascending")
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
