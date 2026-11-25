#' Evaluate a Fixed Grading Under Equality-Neutral Loss
#'
#' `postrank_tie_evaluate()` computes posterior expected equality-neutral loss,
#' distinct-pair counts, and error ratios for a fixed grading without running a
#' solver. Under equality-neutral loss, ordering a pair incurs loss only when
#' the targets are strictly reversed (`theta_i < theta_j`), and leaving a pair
#' in the same grade costs `tau` only when the targets are distinct
#' (`theta_i != theta_j`), so exact equality (`theta_i = theta_j`) has zero loss
#' under either decision. Placing two entities in the same grade still leaves
#' them unordered rather than claiming their targets are equal.
#'
#' @param grade Positive integer/numeric vector named in the exact order of
#'   `pairwise$entity_ids` (`1` = highest priority; occupied labels are
#'   renumbered to `1..G` by [canonical_postrank_grade()] without changing
#'   pairwise relations).
#' @param pairwise A validated `postrank_tie_pairwise` object from
#'   [postrank_tie_pairwise()].
#' @param weights Non-negative finite numeric vector named by every criterion in
#'   `pairwise` and summing to `1` (for a single criterion, supply a named
#'   weight of `1`; weights are not normalized automatically).
#' @param tau Cost of withholding a distinct comparison, a finite scalar with
#'   `0 < tau <= 0.5`.
#' @return A `postrank_tie_evaluation` list containing canonical `grade`, `G`,
#'   `M = choose(n, 2)`, `N`, directed-disclosure matrix `x`,
#'   `disclosure_rate = N / M`, `abstention_rate = (M - N) / M`, criterion
#'   counts `E` (also `Eb`, expected strict wrong-direction errors), `D_k`
#'   (expected disclosed-distinct pairs), `T_k` (expected total-distinct pairs),
#'   and `H_k` (expected withheld-distinct pairs), weighted distinct counts `D`
#'   and `T`, ratios `E_over_M`, `E_over_N`, `E_over_D`, `D_k_over_T_k`, and
#'   `D_over_T` (also `distinct_disclosure_rate`; ratios with zero denominator
#'   are `NA_real_`), `criterion_risk`, `criterion_baseline`, `weighted_risk`
#'   and `primary_risk`, `all_withhold_risk` and `R0`, `weighted_raw_objective`
#'   and `raw_Z`, `guard_satisfied`, `guard_classes`, `guard`, and `settings`.
#' @details
#' Criterion risk is `(E + tau * H_k) / M`, and the all-withheld risk is
#' `R0 = tau * T / M` (smaller than `tau` whenever positive equality probability
#' is present on an active criterion). Weighted risk equals `R0 + raw_Z / M`
#' with `raw_Z = sum(weights * E) - tau * D`, and is summed directly from
#' `pairwise$b` and `pairwise$d` independently of any sparse MIP model. For an
#' all-withheld single-grade grading (`G = 1`), `N` and every `D_k` are `0`,
#' `primary_risk` equals `R0`, and `E_over_N` and `E_over_D` are `NA_real_`.
#'
#' Reported ratios (`E_over_N`, `E_over_D`, `D_over_T`) are ratios of posterior
#' expected counts under the supplied posterior rather than expectations of
#' per-draw ratios. `guard_satisfied` records whether `grade` keeps each
#' active-profile equality class (`guard$groups`) in one grade; unlike
#' [postrank_tie_problem()], `postrank_tie_evaluate()` also evaluates gradings
#' that split an equality class for comparison and does not check `G_max`
#' feasibility (use [validate_postrank_tie_solution()] to check solver
#' candidates). Ordinary [postrank_evaluate()] retains its zero-equality
#' weak-error loss.
#' @seealso [postrank_tie_problem()], [postrank_tie_solve()],
#'   [validate_postrank_tie_solution()], [postrank_tie_capabilities()],
#'   `vignette("m4-ties-and-withholding", package = "postrank")`
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
#' pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
#' weights <- c(S = 0.6, C = 0.4)
#' ev <- postrank_tie_evaluate(
#'   c(A = 3L, B = 3L, C = 2L, D = 1L),
#'   pw,
#'   weights,
#'   tau = 0.25
#' )
#' ev[c("primary_risk", "R0", "N", "D", "T", "guard_satisfied")]
#'
#' held <- postrank_tie_evaluate(
#'   c(A = 1L, B = 1L, C = 1L, D = 1L),
#'   pw,
#'   weights,
#'   tau = 0.25
#' )
#' held[c("primary_risk", "E_over_N", "E_over_D")]
#' @concept tie-aware
#' @export
postrank_tie_evaluate <- function(grade, pairwise, weights, tau) {
  settings <- .pr_tie_loss_settings(pairwise, weights, tau)
  g <- canonical_postrank_grade(grade, pairwise$entity_ids)
  n <- length(g)
  K <- length(pairwise$criterion_ids)
  M <- choose(n, 2)
  x <- outer(unname(g), unname(g), `<`)
  h <- outer(unname(g), unname(g), `==`) & upper.tri(x)
  dimnames(x) <- dimnames(h) <- list(entity_i = pairwise$entity_ids, entity_j = pairwise$entity_ids)
  N <- sum(x)
  named_count <- function(fun) stats::setNames(vapply(seq_len(K), fun, numeric(1L)), pairwise$criterion_ids)
  E <- named_count(function(k) sum(pairwise$b[, , k][x]))
  D_k <- named_count(function(k) sum(pairwise$d[, , k][x]))
  T_k <- named_count(function(k) sum(pairwise$d[, , k][upper.tri(x)]))
  H_k <- named_count(function(k) sum(pairwise$d[, , k][h]))
  D <- sum(settings$weights * D_k)
  T <- sum(settings$weights * T_k)
  criterion_risk <- (E + settings$tau * H_k) / M
  criterion_baseline <- settings$tau * T_k / M
  risk <- sum(settings$weights * criterion_risk)
  baseline <- sum(settings$weights * criterion_baseline)
  raw <- sum(settings$weights * E) - settings$tau * D
  ratio <- function(numerator, denominator) {
    out <- numerator / denominator
    out[denominator == 0] <- NA_real_
    out
  }
  guard <- .pr_tie_guard(pairwise, settings$weights)
  out <- list(schema_version = "tie-evaluation-0.1.0", loss = "tie_aware_v1",
    grade = g, G = length(unique(g)), M = M, N = N, x = x,
    disclosure_rate = N / M, abstention_rate = (M - N) / M,
    E = E, Eb = E, D_k = D_k, T_k = T_k, H_k = H_k, D = D, T = T,
    E_over_M = E / M, E_over_N = ratio(E, N), E_over_D = ratio(E, D_k),
    D_k_over_T_k = ratio(D_k, T_k), D_over_T = if (T == 0) NA_real_ else D / T,
    distinct_disclosure_rate = if (T == 0) NA_real_ else D / T,
    criterion_risk = criterion_risk, criterion_baseline = criterion_baseline,
    weighted_risk = risk, primary_risk = risk, all_withhold_risk = baseline, R0 = baseline,
    weighted_raw_objective = raw, raw_Z = raw,
    guard_satisfied = .pr_tie_guard_satisfied(g, guard), guard_classes = guard$classes,
    guard = guard, settings = settings,
    input_identity = pairwise$input_identity, pairwise_identity = pairwise$pairwise_identity)
  class(out) <- c("postrank_tie_evaluation", "list")
  out
}
