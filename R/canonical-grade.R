#' Renumber Grades While Preserving Comparisons
#'
#' `canonical_postrank_grade()` renumbers occupied grades to `1, 2, ..., G`
#' without changing which entity pairs are ordered or left unordered. Grade 1
#' is the highest priority, and entities sharing a grade are left unordered
#' without claiming they are equal.
#'
#' @param grade Positive integer vector named in the exact order of
#'   `entity_ids`. Gaps between occupied grade numbers are allowed.
#' @param entity_ids Character vector of at least two distinct entity IDs, in
#'   input order.
#' @returns An integer vector named in the order of `entity_ids`, taking values
#'   `1, ..., G` where `G` is the number of distinct labels in `grade`.
#' @details This function only relabels existing grade numbers; it does not
#'   reorder entities, compute posterior loss or choose grades.
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
