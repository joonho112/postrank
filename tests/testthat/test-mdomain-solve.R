md_solve_input <- function(tied=FALSE, approximate=FALSE, separate=FALSE) {
  units <- c("A", "B"); domains <- c("site1", "site2")
  values <- array(0, c(2L, 2L, 2L),
    dimnames=list(state=c("s1", "s2"), unit=units, domain=domains))
  for (d in seq_along(domains)) values[, , d] <-
    if (tied) rbind(c(2,1), c(1,2)) else rbind(c(2,1), c(2,1))
  targets <- setNames(lapply(domains, function(d) list(
    definition=paste("Fictional", d, "coordinate"), units="illustrative units",
    orientation="larger_is_higher", transformations=list(),
    equality_classes=setNames(units, units),
    equality_provenance="The declared finite law has no structural identities.")), domains)
  provenance <- list(input_id="two-unit-two-site-law", law_id="two-state-law",
    proper_law=TRUE, producer="Independent package test generator",
    joint_generation="Each of two listed rows is a complete joint state.",
    within_domain_joint="Each listed row gives both unit coordinates.",
    sampling_assumptions=list(finite_support_origin=
      "The two listed states and declared masses specify the complete law."))
  masses <- if (approximate) list(encoding="float64", values=c(.5,.5)) else c("1/2", "1/2")
  if (separate) {
    values <- setNames(lapply(seq_along(domains), function(d) values[, , d]), domains)
    masses <- setNames(rep(list(masses), length(domains)), domains)
  }
  postrank_mdomain_input(values, targets=targets, provenance=provenance,
    representation="exact_finite_law", masses=masses)
}

md_solve_family <- function(input) {
  columns <- setNames(lapply(input$domain_ids, function(d) list(
    forward=setNames(c(1,2), input$unit_ids),
    reverse=setNames(c(2,1), input$unit_ids))), input$domain_ids)
  postrank_mdomain_family(input, columns=columns)
}

test_that("public candidate solve selects the unique finite-law optimum and retains scope", {
  skip_if_not_installed("gmp")
  input <- md_solve_input(); family <- md_solve_family(input)
  fit <- postrank_mdomain_solve(input, family,
    decision=postrank_mdomain_decision(alpha="0"))
  expect_s3_class(fit, "postrank_mdomain_fit")
  expect_s3_class(fit$solution, "p2_candidate_solution")
  expect_s3_class(fit$evaluation, "postrank_mdomain_evaluation")
  expect_identical(fit$input, input)
  expect_identical(fit$family, family)
  expect_identical(fit$solution$family, family$family)
  expect_identical(fit$decision, fit$evaluation$decision)
  expect_identical(fit$decision, fit$solution$decision)
  expect_identical(fit$grades, matrix(c(1L,2L,1L,2L), 2L,
    dimnames=list(input$unit_ids, input$domain_ids)))
  expect_identical(postrank_mdomain_grades(fit), fit$grades)
  expect_identical(fit$evaluation$risk_exact, "0")
  expect_identical(fit$evaluation$J_exact, "0")
  expect_true(fit$evaluation$feasible_for_represented_measure)
  expect_identical(fit$optimizer_count, 1L)
  expect_identical(fit$status$optimum, "unique")
  expect_identical(fit$selected_id, fit$optimizer_ids)
  expect_identical(fit$candidate_table, fit$solution$candidate_table)
  expect_equal(nrow(fit$candidate_table), 9L)
  expect_identical(fit$search_scope$product_size_exact, "9")
  expect_equal(fit$search_scope$examined_actions, 9L)
  expect_true(fit$search_scope$full_declared_product_examined)
  expect_false(fit$search_scope$full_ordered_partition_optimality_claim)
  expect_identical(fit$status$optimality, "candidate_restricted")
  expect_identical(fit$solution$receipts$objective_comparison, "exact_rational")
  expect_identical(fit$solution$receipts$construction_provenance, family$provenance)
  expect_identical(fit$solution$receipts$evaluation_input_hash, family$source_input_hash)
  expect_false(fit$receipts$search_truncated)
  expect_false(fit$assurance$numerical_guarantee)
  expect_false(fit$assurance$intended_posterior_feasibility_certified)
})

test_that("exact ties retain the complete optimizer set without secondary objectives", {
  skip_if_not_installed("gmp")
  input <- md_solve_input(tied=TRUE)
  fit <- postrank_mdomain_solve(input, md_solve_family(input),
    postrank_mdomain_decision(tau="1/2", t=NULL))
  # In each site a strict direction errs in exactly one of two states, and
  # withholding costs 1/2. All nine report cards therefore have risk 1/2.
  expect_identical(fit$status$optimum, "tied")
  expect_identical(fit$optimizer_count, 9L)
  expect_identical(fit$optimizer_ids, fit$candidate_table$action_id)
  expect_true(all(fit$candidate_table$optimal))
  expect_equal(sum(fit$candidate_table$selected), 1L)
  expect_identical(fit$selected_id, fit$optimizer_ids[1L])
  expect_identical(fit$candidate_table$risk_exact, rep("1/2", 9L))
  expect_identical(fit$grades, matrix(1L, 2L, 2L,
    dimnames=list(input$unit_ids, input$domain_ids)))
  expect_match(fit$solution$receipts$tie_break, "no secondary objective")
})

test_that("action caps stop before the native search and never return a truncated card", {
  skip_if_not_installed("gmp")
  input <- md_solve_input(); family <- md_solve_family(input)
  called <- FALSE
  local_mocked_bindings(p2_solve_candidates=function(...) {
    called <<- TRUE; stop("native search must not be entered")
  })
  error <- tryCatch(postrank_mdomain_solve(input, family, max_actions=8L), error=identity)
  expect_s3_class(error, "postrank_mdomain_error")
  expect_identical(error$code, "mdomain_action_cap")
  expect_identical(error$field, "max_actions")
  expect_identical(error$requested, list(product_size_exact="9"))
  expect_identical(error$available, list(max_actions=8L))
  expect_match(conditionMessage(error), "no product enumeration or truncation")
  expect_false(called)
  expect_false(inherits(error, "postrank_mdomain_fit"))
  for (cap in list(0, -1, NA_real_, Inf, 1.5, "9", c(1,2))) {
    error <- tryCatch(postrank_mdomain_solve(input, family, max_actions=cap), error=identity)
    expect_identical(error$code, "mdomain_solve_invalid")
    expect_identical(error$field, "max_actions")
  }
  expect_false(called)
})

test_that("source identities and decision recipes are revalidated before search", {
  skip_if_not_installed("gmp")
  input <- md_solve_input(); family <- md_solve_family(input)
  changed <- input; changed$unit_ids <- rev(changed$unit_ids)
  error <- tryCatch(postrank_mdomain_solve(changed, family, max_actions=0), error=identity)
  expect_identical(error$code, "mdomain_input_mutated")
  changed <- input$original_spec; changed$input_id <- "another-input-id"
  changed <- postrank_mdomain_input(changed)
  error <- tryCatch(postrank_mdomain_solve(changed, family), error=identity)
  expect_identical(error$code, "mdomain_family_source")
  bad <- family; bad$family$banks[[1L]]$columns[1L,1L] <- 2L
  error <- tryCatch(postrank_mdomain_solve(input, bad), error=identity)
  expect_identical(error$code, "mdomain_family_mutated")
  decision <- postrank_mdomain_decision(); decision$alpha <- "2"
  error <- tryCatch(postrank_mdomain_solve(input, family, decision), error=identity)
  expect_identical(error$code, "mdomain_decision_invalid")
})

test_that("approximate masses preserve computed-value status and restricted claims", {
  skip_if_not_installed("gmp")
  input <- md_solve_input(tied=TRUE, approximate=TRUE)
  fit <- postrank_mdomain_solve(input, md_solve_family(input),
    postrank_mdomain_decision(tau="1/2", t=NULL))
  expect_identical(fit$status$search,
    "candidate_restricted_optimum_of_computed_approximate_values")
  expect_identical(fit$solution$receipts$objective_comparison,
    "floating_values_without_tie_tolerance")
  expect_null(fit$evaluation$risk_exact)
  expect_true(all(is.na(fit$candidate_table$risk_exact)))
  expect_identical(fit$status$arithmetic, "contains_approximate_expectations")
  expect_identical(fit$optimizer_count, 9L)
  expect_false(fit$search_scope$full_ordered_partition_optimality_claim)
  expect_false(fit$solution$receipts$intended_posterior_feasibility_certified)
  expect_identical(postrank_mdomain_grades(fit), fit$grades)
})

test_that("missing coupling errors without discarding candidates as infeasible", {
  skip_if_not_installed("gmp")
  input <- md_solve_input(separate=TRUE)
  error <- tryCatch(postrank_mdomain_solve(input, md_solve_family(input)), error=identity)
  expect_s3_class(error, "postrank_mdomain_error")
  expect_identical(error$code, "mdomain_capability")
  expect_identical(error$field, "capabilities")
  expect_identical(error$available, input$capabilities)
  expect_match(conditionMessage(error), "no candidate is silently dropped")
  # Turning off nontrivial joint events permits the declared separate laws.
  fit <- postrank_mdomain_solve(input, md_solve_family(input),
    postrank_mdomain_decision(t=NULL))
  expect_identical(fit$evaluation$J_exact, "0")
  expect_false(fit$evaluation$joint_protection_enabled)
})

test_that("serialized fits retain scientific records and reject altered search choices", {
  skip_if_not_installed("gmp")
  input <- md_solve_input(tied=TRUE)
  fit <- postrank_mdomain_solve(input, md_solve_family(input),
    postrank_mdomain_decision(tau="1/2", t=NULL))
  file <- tempfile(fileext=".rds"); on.exit(unlink(file), add=TRUE)
  saveRDS(fit, file)
  restored <- readRDS(file)
  expect_identical(restored, fit)
  for (field in c("grades", "decision", "solution", "evaluation", "family",
      "candidate_table", "optimizer_ids", "optimizer_count", "selected_id", "search_scope"))
    expect_identical(restored[[field]], fit[[field]], info=field)
  expect_identical(postrank_mdomain_grades(restored), fit$grades)
  changes <- list(
    solution_risk=function(x) {x$solution$candidate_table$risk[1L] <- 0; x},
    solution_choice=function(x) {x$solution$selected_id <- x$optimizer_ids[2L]; x},
    solution_grades=function(x) {x$solution$selected_action$G[1L,1L] <- 2L; x},
    removed_solution=function(x) {x$solution <- NULL; x},
    removed_family=function(x) {x$family <- NULL; x},
    top_choice=function(x) {x$selected_id <- x$optimizer_ids[2L]; x},
    optimal_set=function(x) {x$optimizer_ids <- x$optimizer_ids[-1L]; x},
    top_grades=function(x) {x$grades[1L,1L] <- 2L; x},
    decision=function(x) {x$decision$alpha_exact <- gmp::as.bigq(1); x},
    search_scope=function(x) {x$search_scope$full_ordered_partition_optimality_claim <- TRUE; x})
  for (name in names(changes)) {
    altered <- changes[[name]](restored)
    error <- tryCatch(postrank_mdomain_grades(altered), error=identity)
    expect_s3_class(error, "postrank_mdomain_error")
    expect_identical(error$code, "mdomain_result_mutated", info=name)
  }
  # A hash is only one guard: source and selected-card relationships are also
  # checked explicitly, independently of the stored checksum.
  for (change in list(
      function(x) {x$solution$receipts$evaluation_input_hash <- "another-law"; x},
      function(x) {x$solution$receipts$construction_provenance <- list(); x},
      function(x) {x$solution$selected_id <- x$optimizer_ids[2L]
        x$selected_id <- x$optimizer_ids[2L]; x})) {
    altered <- change(restored)
    altered$receipts$validated_result_hash <- postrank:::.md_fit_hash(altered)
    error <- tryCatch(postrank_mdomain_grades(altered), error=identity)
    expect_identical(error$code, "mdomain_result_mutated")
  }
})

test_that("fit print and summary only read stored display records", {
  skip_if_not_installed("gmp")
  input <- md_solve_input()
  fit <- postrank_mdomain_solve(input, md_solve_family(input))
  expected <- summary(fit)
  boom <- function(...) stop("display must not call computational paths")
  local_mocked_bindings(p2_solve_candidates=boom, postrank_mdomain_evaluate=boom,
    p2_evaluate_joint=boom, p2_evaluate_expected=boom,
    .md_validate_input=boom, .md_validate_fit=boom, .md_require_gmp=boom)
  fit$solution <- NULL; fit$input$payloads <- NULL
  expect_output(print(fit), "1 optimizer \\(unique\\)")
  expect_output(print(fit), "Risk: 0; joint probability: 0")
  expect_output(print(fit), "unrestricted optimality not established")
  actual <- summary(fit)
  expect_s3_class(actual, "summary.postrank_mdomain_fit")
  expect_identical(actual, expected)
  expect_identical(actual$optimizer_ids, fit$optimizer_ids)
  expect_identical(actual$search_scope, fit$search_scope)
  expect_identical(actual$candidate_table, fit$candidate_table)
  expect_output(print(actual), "9 declared actions examined")
  expect_output(print(actual), "Intended posterior feasibility certificate: none")
})
