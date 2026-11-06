.pr_pairwise_exact <- function(draws) {
  .pr_assert(requireNamespace("gmp", quietly = TRUE),
             "exact pairwise coefficients require optional package gmp", "missing_dependency")
  law <- draws$finite_law; n <- length(draws$entity_ids); K <- length(draws$criterion_ids)
  denominator <- .pr_big_integer(law$denominator)
  masses <- gmp::as.bigz(vapply(law$states, function(z) as.character(.pr_big_integer(z$mass_numerator)), character(1L)))
  e <- .pr_empty_e(draws$entity_ids, draws$criterion_ids)
  numerators <- rationals <- projection_differences <- array(NA_character_, dim(e), dimnames(e))
  maximum_difference <- gmp::as.bigq(0)
  for (k in seq_len(K)) for (i in seq_len(n)) for (j in seq_len(n)) if (i != j) {
    numerator <- gmp::as.bigz(0)
    for (s in seq_along(law$states))
      if (law$states[[s]]$theta[i, k] <= law$states[[s]]$theta[j, k]) numerator <- numerator + masses[s]
    probability <- gmp::as.bigq(numerator, denominator)
    projected <- as.numeric(probability)
    difference <- gmp::as.bigq(projected) - probability
    e[i, j, k] <- projected
    numerators[i, j, k] <- as.character(numerator)
    rationals[i, j, k] <- as.character(probability)
    projection_differences[i, j, k] <- as.character(difference)
    if (abs(difference) > maximum_difference) maximum_difference <- abs(difference)
  }
  exact <- list(numerators = numerators, denominator = as.character(denominator), rationals = rationals,
    state_count = length(law$states), arithmetic = "gmp arbitrary-precision integer masses and rational probabilities",
    projection_difference_rationals = projection_differences,
    maximum_absolute_projection_difference_rational = as.character(maximum_difference),
    projection_note = paste("e contains double projections for downstream numerical arithmetic.",
      "Each recorded difference is the rational representation of the actual projected double minus the exact probability.",
      "These coefficient diagnostics do not certify downstream risk summation, coefficient enclosure, or solver numerical correctness."),
    numerical_certification = FALSE, law_definition = law$law_definition,
    nonempirical_declaration = law$not_empirical_posterior_relabeling)
  .pr_new_pairwise(draws, e, rep(NA_real_, K), "exact_finite_law", exact)
}
