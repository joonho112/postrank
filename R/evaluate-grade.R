#' Evaluate the Posterior Loss of Supplied Grades
#'
#' `postrank_evaluate()` computes the ordered pair count, posterior expected
#' wrong-order errors and posterior expected loss for a supplied integer grade
#' vector, without running an optimization solver. Grade 1 is the highest
#' priority; entities given the same grade are left unordered without claiming
#' they are equal.
#'
#' @param grade Positive integer vector named in the exact `entity_ids` order
#'   of `pairwise`. Occupied grade numbers are renumbered to `1, ..., G` by
#'   [canonical_postrank_grade()].
#' @param pairwise Pairwise directional-error probabilities: a
#'   `postrank_pairwise`, `postrank_coefficients` or [postrank_probabilities()]
#'   object. Normal/mixture posteriors and supplied probabilities support only
#'   `objective = "weighted"` without `minimax_criteria`.
#' @param weights Nonnegative finite weights summing to one within `1e-12`,
#'   uniquely named by criterion (covering every criterion once, including
#'   weight `1` for one criterion). Omit when passing `settings`; never
#'   rescaled automatically.
#' @param tau Cost of leaving a pair unordered (`0 < tau <= 0.5`). Omit when
#'   passing `settings`.
#' @param objective `"weighted"` (the default) or `"minimax"`. Minimax uses the
#'   largest posterior expected criterion loss among the selected criteria, not
#'   the expected statewise maximum.
#' @param minimax_criteria Optional character vector of criterion IDs included
#'   when `objective = "minimax"` (`NULL` uses all criteria). Must be `NULL`
#'   when `objective = "weighted"`.
#' @param settings Optional [postrank_settings()] object supplying `weights`,
#'   `tau`, `objective` and `minimax_criteria` instead of separate arguments;
#'   supplying both stops with `settings_conflict`.
#' @returns An unclassed named list containing:
#'   * `grade` and `G`: the renumbered integer grades (`1, ..., G`) and number
#'     of occupied grades;
#'   * `M`, `N`, `x`, `disclosure_rate` (`N / M`) and `abstention_rate`
#'     (`(M - N) / M`): total unordered pairs, ordered (`disclosed`) pairs,
#'     the `n x n` logical ordering matrix (`x[i, j]` is `TRUE` when
#'     `grade[i] < grade[j]`), and pair fractions;
#'   * `E`, `E_over_M`, `E_over_N` and `criterion_risk`: criterion-named
#'     expected wrong-order pair counts, counts divided by `M` and by `N`
#'     (`NA` when `N = 0`), and per-criterion loss `(E_k + tau * (M - N)) / M`;
#'   * `weighted_risk`, `minimax_risk`, `primary_risk` and
#'     `weighted_raw_objective` (`sum(weights * E) - tau * N`);
#'   * `objective`, `minimax_criteria`, `settings`, `schema_version`,
#'     `input_identity` and `pairwise_identity`.
#' @details
#' When every entity is given the same grade (`G = 1`), `N = 0`, `E_over_N` is
#' `NA`, and every criterion's loss equals `tau`. `postrank_evaluate()` scores
#' any valid grade vector; it does not check whether `grade` satisfies `G_max`,
#' `exact_G` or `q` constraints in `settings` (see [postrank_problem()] and
#' [postrank_compare()]).
#' @seealso [postrank_problem()], [postrank_settings()], [get_profile()],
#'   [canonical_postrank_grade()]
#' @examples
#' grade <- c(A = 1L, B = 1L, C = 2L, D = 2L, E = 3L, F = 3L)
#' ev <- postrank_evaluate(grade, pr_tutorial$one,
#'   weights = c(score_A = 1), tau = 0.2)
#' ev[c("N", "M", "E_over_N", "primary_risk")]
#'
#' held <- postrank_evaluate(setNames(rep(1L, 6), names(grade)),
#'   pr_tutorial$one, weights = c(score_A = 1), tau = 0.2)
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
