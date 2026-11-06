.pr_big_integer <- function(x) gmp::as.bigz(format(x, scientific = FALSE, trim = TRUE, digits = 22L))

.pr_validate_exact <- function(x) {
  law <- x$finite_law; path <- "$.finite_law"
  .pr_fields(law, c("denominator", "value_representation", "states", "law_definition",
                    "not_empirical_posterior_relabeling"), path = path)
  .pr_assert(identical(law$value_representation, "safe_integer"), "exact-law targets require safe_integer representation", path = path)
  .pr_assert(typeof(law$denominator) %in% c("integer", "double") && length(law$denominator) == 1L && is.null(dim(law$denominator)),
             "denominator must be a scalar safe integer", path = path)
  .pr_safe_integer(law$denominator, TRUE, paste0(path, ".denominator"))
  .pr_string(law$law_definition, paste0(path, ".law_definition"))
  .pr_assert(identical(law$not_empirical_posterior_relabeling, TRUE),
             "exact law requires an explicit nonempirical declaration", "empirical_relabeling", path)
  .pr_records(law$states, paste0(path, ".states"))
  .pr_assert(length(law$states) >= 1L, "finite law must contain positive-mass states", path = path)
  .pr_assert(requireNamespace("gmp", quietly = TRUE), "exact finite-law validation requires optional package gmp", "missing_dependency", path)
  total <- gmp::as.bigz(0); maximum <- gmp::as.bigz("9007199254740991")
  state_ids <- character(length(law$states))
  for (s in seq_along(law$states)) {
    z <- law$states[[s]]; loc <- paste0(path, ".states[", s, "]")
    .pr_fields(z, c("state_id", "mass_numerator", "theta"), path = loc)
    .pr_string(z$state_id, paste0(loc, ".state_id")); state_ids[s] <- z$state_id
    .pr_assert(typeof(z$mass_numerator) %in% c("integer", "double") && length(z$mass_numerator) == 1L && is.null(dim(z$mass_numerator)),
               "state mass must be a scalar safe integer", path = loc)
    .pr_safe_integer(z$mass_numerator, TRUE, paste0(loc, ".mass_numerator"))
    total <- total + .pr_big_integer(z$mass_numerator)
    .pr_assert(total <= maximum, "exact mass sum exceeds safe-integer range", "unsafe_integer", loc)
    theta <- z$theta
    .pr_assert(typeof(theta) %in% c("integer", "double") && is.matrix(theta) &&
                 identical(dim(theta), c(length(x$entity_ids), length(x$criterion_ids))),
               "each exact state must retain an n by K numeric matrix", "invalid_shape", loc)
    .pr_safe_integer(theta, path = paste0(loc, ".theta"))
    .pr_assert(identical(names(dimnames(theta)), c("entity", "criterion")) &&
                 identical(dimnames(theta)$entity, x$entity_ids) && identical(dimnames(theta)$criterion, x$criterion_ids),
               "exact state dimnames differ from declared entity/criterion order", "invalid_id", loc)
    for (k in seq_len(ncol(theta))) {
      dup <- anyDuplicated(theta[, k])
      if (dup) .pr_abort(sprintf(paste("positive-mass state %s has a within-criterion entity tie (criterion %s, entities %s and %s);",
        "exact finite laws must be tie-free in this version"), z$state_id, x$criterion_ids[k],
        x$entity_ids[which(theta[, k] == theta[dup, k])[1L]], x$entity_ids[dup]), "observed_target_tie", loc)
    }
  }
  .pr_ids(state_ids, path = paste0(path, ".states.state_id"))
  .pr_assert(total == .pr_big_integer(law$denominator), "state masses do not sum exactly to denominator", "invalid_exact_mass", path)
  invisible(TRUE)
}
