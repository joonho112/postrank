#' Renumber Grades While Preserving Comparisons
#'
#' Occupied grade labels are replaced by consecutive integers starting at 1.
#' Smaller grades indicate higher priority and equal grades withhold a
#' comparison. The relabelling preserves all disclosed directions and withheld
#' comparisons.
#'
#' @param grade Numeric vector of positive integers, with names in exactly
#'   the order of `entity_ids`. Gaps between occupied labels are allowed.
#' @param entity_ids Character vector of distinct entity IDs, in input order.
#' @return A named integer vector in the same entity order, using grades
#'   `1, ..., G`, where G is the number of distinct supplied labels.
#' @details This function does not sort entities, evaluate posterior risk or
#'   optimize grades. A shared grade does not assert equality of latent targets.
#' @seealso [postrank_evaluate()], [get_grades()]
#' @examples
#' canonical_postrank_grade(c(A = 10, B = 10, C = 30), c("A", "B", "C"))
#' @concept decision
#' @export
canonical_postrank_grade <- function(grade,entity_ids) {
  .pr_ids(entity_ids,2L,"$.entity_ids")
  .pr_assert(typeof(grade)%in%c("integer","double")&&is.null(dim(grade))&&length(grade)==length(entity_ids)&&
    identical(names(grade),entity_ids),"grades must be numeric and named in declared entity order","invalid_grade")
  .pr_safe_integer(grade,TRUE,"$.grade")
  stats::setNames(as.integer(match(grade,sort(unique(grade)))),entity_ids)
}
.pr_loss_settings <- function(pairwise,weights,tau) {
  .pr_assert(typeof(weights)%in%c("integer","double")&&is.null(dim(weights))&&length(weights)==length(pairwise$criterion_ids)&&
    !anyNA(weights)&&all(is.finite(weights))&&all(weights>=0)&&!is.null(names(weights))&&
    !anyDuplicated(names(weights))&&setequal(names(weights),pairwise$criterion_ids),
    "weights must be a nonnegative finite named vector covering criteria exactly once","invalid_weights")
  .pr_assert(abs(sum(weights)-1)<=1e-12,"weights must sum to one; automatic normalization is not used","invalid_weights")
  .pr_assert(typeof(tau)%in%c("integer","double")&&is.null(dim(tau))&&length(tau)==1L&&is.finite(tau)&&tau>0&&tau<=.5,
    "tau must satisfy 0 < tau <= 0.5","invalid_tau")
  list(weights=weights[pairwise$criterion_ids],tau=as.numeric(tau),weight_sum=sum(weights),weight_sum_tolerance=1e-12)
}
