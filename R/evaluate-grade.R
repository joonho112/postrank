#' Evaluate the Posterior Loss of Supplied Grades
#'
#' Disclosed comparisons, expected directional errors and loss are calculated
#' for an existing grade vector without optimization. Smaller grades indicate
#' higher priority. Equal grades withhold a direction without asserting
#' equality of the latent targets. The resulting quantities are conditional on
#' the supplied posterior probabilities and chosen loss.
#'
#' @param grade Numeric vector of positive integer grades, named in exactly
#'   the input's entity order. Occupied labels are renumbered consecutively.
#' @param pairwise A `postrank_pairwise`, `postrank_coefficients`, or
#'   [postrank_probabilities()] object. Gaussian/mixture coefficients and
#'   supplied probabilities currently support weighted expected risk only.
#' @param weights Nonnegative finite criterion-named weights summing to one.
#'   Supply every criterion exactly once, including weight 1 for a single
#'   criterion, unless using `settings`. Weights are not normalized automatically.
#' @param tau Cost of a withheld comparison, with `0 < tau <= 0.5`.
#' @param settings Optional [postrank_settings()] supplying weights, tau,
#'   objective and minimax criteria instead of the separate arguments.
#'   Explicitly supplying both is a `settings_conflict` error.
#' @param objective `"weighted"` or `"minimax"`. The latter uses the largest
#'   expected criterion risk, not an expectation of statewise maximum loss.
#' @param minimax_criteria Optional nonempty criterion subset for minimax;
#'   `NULL` uses all criteria. Only allowed with `objective = "minimax"`.
#' @return An unclassed list with the canonical `grade`, occupied count `G`,
#'   total unordered pairs `M`, disclosed pairs `N`, and directed disclosure
#'   matrix `x`. `disclosure_rate = N/M` and `abstention_rate = (M-N)/M`.
#'   Criterion-named `E`, `E_over_M`, `E_over_N` and `criterion_risk` give
#'   expected error counts, their two normalizations and loss including
#'   withholding. `weighted_risk`, `minimax_risk` and `primary_risk` distinguish
#'   the weighted, largest selected-criterion and requested objectives.
#'   `weighted_raw_objective = sum(weights * E) - tau * N` is in centered raw
#'   units. `objective`, `minimax_criteria`, `settings`, `schema_version` and
#'   input/pairwise identities record what was evaluated.
#' @details For criterion k, risk is `(E_k + tau * (M - N)) / M`.
#'   When all comparisons are withheld, N=0, conditional error ratios
#'   `E_over_N` are `NA`, and risk is tau. This is a valid action, distinct
#'   from a solve with no validated grade.
#'
#'   Evaluation does not check membership in a grade-cap, exact-grade or
#'   error-budget family, even when those restrictions appear in `settings`.
#'   Use [postrank_problem()] to specify that family; [postrank_compare()]
#'   records membership separately when comparing actions.
#' @seealso [postrank_problem()], [postrank_settings()], [get_profile()]
#' @examples
#' grade <- c(A = 1L, B = 1L, C = 2L, D = 2L, E = 3L, F = 3L)
#' ev <- postrank_evaluate(grade, pr_tutorial$one,
#'   weights = c(score_A = 1), tau = .2)
#' ev[c("N", "M", "E_over_N", "primary_risk")]
#' held <- postrank_evaluate(setNames(rep(1L, 6), names(grade)),
#'   pr_tutorial$one, weights = c(score_A = 1), tau = .2)
#' held[c("N", "E_over_N", "primary_risk")]
#' @concept decision
#' @export
postrank_evaluate <- function(grade, pairwise, weights = NULL, tau = NULL, objective = c("weighted", "minimax"),
                              minimax_criteria = NULL, settings = NULL) {
  if (is.null(settings)) return(.pr_evaluate_core(grade, pairwise, weights, tau, objective, minimax_criteria))
  .pr_settings_conflict(.pr_supplied(c("weights", "tau", "objective", "minimax_criteria")))
  .pr_validate_pairwise(pairwise)
  p <- .pr_settings_bind(settings, pairwise)$policy
  .pr_evaluate_core(grade, pairwise, p$weights, p$tau, p$objective, p$minimax_criteria)
}

# Unchanged 0.0.1.9003 (C3) body, moved behind the public adapter (freeze manifest: moved_from postrank_evaluate).
.pr_evaluate_core <- function(grade,pairwise,weights,tau,objective=c("weighted","minimax"),minimax_criteria=NULL) {
  .pr_validate_pairwise(pairwise);settings<-.pr_loss_settings(pairwise,weights,tau)
  objective<-match.arg(objective)
  .pr_cf_problem_scope(pairwise,objective,minimax_criteria=minimax_criteria)
  if(objective=="weighted") .pr_assert(is.null(minimax_criteria),"minimax_criteria requires minimax objective","invalid_minimax_criteria")
  selected<-if(is.null(minimax_criteria))pairwise$criterion_ids else minimax_criteria
  .pr_assert(is.character(selected)&&is.null(dim(selected))&&length(selected)>0L&&!anyNA(selected)&&
    !anyDuplicated(selected)&&all(selected%in%pairwise$criterion_ids),"invalid minimax criterion subset","invalid_minimax_criteria")
  g<-canonical_postrank_grade(grade,pairwise$entity_ids);n<-length(g);K<-length(pairwise$criterion_ids)
  x<-outer(unname(g),unname(g),`<`)
  dimnames(x)<-list(entity_i=pairwise$entity_ids,entity_j=pairwise$entity_ids)
  M<-choose(n,2);N<-sum(x)
  E<-stats::setNames(vapply(seq_len(K),function(k)sum(pairwise$e[,,k][x]),numeric(1L)),pairwise$criterion_ids)
  Rk<-(E+settings$tau*(M-N))/M
  R<-(sum(settings$weights*E)+settings$tau*(M-N))/M
  list(schema_version="0.1.0",grade=g,G=length(unique(g)),M=M,N=N,x=x,
    disclosure_rate=N/M,abstention_rate=(M-N)/M,E=E,E_over_M=E/M,
    E_over_N=if(N==0)stats::setNames(rep(NA_real_,K),pairwise$criterion_ids) else E/N,
    criterion_risk=Rk,weighted_risk=R,minimax_risk=max(Rk[selected]),
    primary_risk=if(objective=="weighted")R else max(Rk[selected]),objective=objective,
    minimax_criteria=if(objective=="minimax")selected else NULL,weighted_raw_objective=sum(settings$weights*E)-settings$tau*N,
    settings=settings,input_identity=pairwise$input_identity,pairwise_identity=pairwise$pairwise_identity)
}
