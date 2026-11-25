# Scope checks for typed normal/mixture and supplied-probability inputs;
# draw and exact-finite-law paths remain unchanged.
.pr_cf_problem_scope <- function(pairwise,objective,q=NULL,exact_G=NULL,minimax_criteria=NULL) {
  if (inherits(pairwise, "postrank_probabilities")) {
    validate_postrank_probabilities(pairwise)
    .pr_assert(identical(objective, "weighted") && is.null(q) &&
      is.null(exact_G) && is.null(minimax_criteria),
      "supplied probabilities currently support weighted expected risk with an at-most-G limit only",
      "unsupported_probability_problem")
    return(invisible(TRUE))
  }
  if(!inherits(pairwise,"postrank_coefficients"))return(invisible(TRUE))
  validate_postrank_coefficients(pairwise)
  .pr_assert(identical(objective,"weighted")&&is.null(q)&&is.null(exact_G)&&is.null(minimax_criteria),
    "typed coefficients currently support weighted expected risk with an at-most-G limit only",
    "unsupported_coefficient_problem")
  invisible(TRUE)
}
