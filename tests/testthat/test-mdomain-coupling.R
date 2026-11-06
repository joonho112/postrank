# These laws are authored directly from their complete finite support. They do
# not import a scored fixture, sampled posterior, or reference engine result.
coupling_fixed_input <- function(coupling=c("coincident", "disjoint")) {
  coupling <- match.arg(coupling)
  domains <- c("priority", "benefit")
  units <- c("site-A", "site-B")
  wrong <- if (coupling == "coincident") {
    rbind(c(FALSE, FALSE), c(TRUE, TRUE))
  } else {
    rbind(c(FALSE, FALSE), c(TRUE, FALSE), c(FALSE, TRUE))
  }
  masses <- if (coupling == "coincident") c("9/10", "1/10") else
    c("4/5", "1/10", "1/10")
  values <- array(0, c(nrow(wrong), 2L, 2L),
    dimnames=list(state=paste0(coupling, "-", seq_len(nrow(wrong))),
                  unit=units, domain=domains))
  for (d in seq_along(domains)) values[, 1L, d] <- ifelse(wrong[, d], -1, 1)
  targets <- setNames(lapply(domains, function(d) list(
    definition=paste("Fictional", d, "coordinate defined by the listed finite states"),
    units="illustrative coordinate units", orientation="larger_is_higher",
    transformations=list(), equality_classes=setNames(units, units),
    equality_provenance="Distinct sites are distinct model coordinates; no structural identities.")), domains)
  postrank_mdomain_input(values, targets=targets,
    provenance=list(input_id=paste0("two-site-", coupling),
      law_id=paste0("specified-", coupling, "-error-law"), proper_law=TRUE,
      producer="Independent finite-support test construction",
      joint_generation="Each listed row specifies both sites in both domains; the rational masses define the complete law.",
      sampling_assumptions=list(finite_support_origin="The listed states and exact masses define the complete finite law.")),
    representation="exact_finite_law", masses=masses)
}

coupling_fixed_grades <- function(card=c("both", "one", "withheld")) {
  card <- match.arg(card)
  G <- matrix(1L, 2L, 2L,
    dimnames=list(c("site-A", "site-B"), c("priority", "benefit")))
  if (card %in% c("both", "one")) G[2L, 1L] <- 2L
  if (card == "both") G[2L, 2L] <- 2L
  G
}

coupling_fixed_decision <- function() postrank_mdomain_decision(
  weights=c(priority="1/2", benefit="1/2"), tau="1/4", q=NULL,
  t="0", alpha="3/20")

test_that("the same two-domain card distinguishes coincident and disjoint errors", {
  skip_if_not_installed("gmp")
  G <- coupling_fixed_grades("both")
  coincident <- postrank_mdomain_evaluate(coupling_fixed_input("coincident"),
    G, coupling_fixed_decision())
  disjoint <- postrank_mdomain_evaluate(coupling_fixed_input("disjoint"),
    G, coupling_fixed_decision())
  expect_s3_class(coincident, "postrank_mdomain_evaluation")
  expect_identical(postrank_mdomain_grades(coincident), G)
  expect_identical(postrank_mdomain_grades(disjoint), G)
  expect_identical(coincident$risk_exact, "1/10")
  expect_identical(disjoint$risk_exact, "1/10")
  expect_identical(coincident$J_exact, "1/10")
  expect_identical(disjoint$J_exact, "1/5")
  expect_equal(coincident$risk, 1/10)
  expect_equal(disjoint$risk, 1/10)
  expect_equal(coincident$J, 1/10)
  expect_equal(disjoint$J, 1/5)
  expect_identical(coincident$domain_table$EF_exact, rep("1/10", 2L))
  expect_identical(disjoint$domain_table$EF_exact, rep("1/10", 2L))
  expect_identical(coincident$event_table$p_exact, rep("1/10", 2L))
  expect_identical(disjoint$event_table$p_exact, rep("1/10", 2L))
  expect_true(coincident$mean_feasible)
  expect_true(disjoint$mean_feasible)
  expect_true(coincident$joint_feasible)
  expect_false(disjoint$joint_feasible)
  expect_true(coincident$feasible_for_represented_measure)
  expect_false(disjoint$feasible_for_represented_measure)
  expect_true(coincident$joint_evaluated)
  expect_true(disjoint$joint_evaluated)
})

test_that("one disclosure retains its marginal risk under either coupling", {
  skip_if_not_installed("gmp")
  G <- coupling_fixed_grades("one")
  for (law in c("coincident", "disjoint")) {
    result <- postrank_mdomain_evaluate(coupling_fixed_input(law),
      G, coupling_fixed_decision())
    expect_identical(postrank_mdomain_grades(result), G)
    expect_identical(result$risk_exact, "7/40")
    expect_identical(result$J_exact, "1/10")
    expect_equal(result$risk, 7/40)
    expect_equal(result$J, 1/10)
    expect_equal(result$domain_table$N, c(1, 0))
    expect_identical(result$domain_table$loss_exact, c("1/10", "1/4"))
    expect_identical(result$domain_table$weighted_loss_exact, c("1/20", "1/8"))
    expect_true(is.na(result$domain_table$eFDP[2L]))
    expect_identical(result$domain_table$eFDP_exact[2L], NA_character_)
    expect_equal(result$domain_table$eFDP_zero[2L], 0)
    expect_identical(result$event_table$p_exact, c("1/10", "0"))
    expect_identical(result$event_table$analytically_inactive, c(FALSE, TRUE))
    expect_true(result$feasible_for_represented_measure)
  }
})

test_that("complete withholding displays undefined disclosure fractions and zero events", {
  skip_if_not_installed("gmp")
  G <- coupling_fixed_grades("withheld")
  for (law in c("coincident", "disjoint")) {
    result <- postrank_mdomain_evaluate(coupling_fixed_input(law),
      G, coupling_fixed_decision())
    expect_identical(postrank_mdomain_grades(result), G)
    expect_identical(result$risk_exact, "1/4")
    expect_identical(result$J_exact, "0")
    expect_equal(result$domain_table$N, c(0, 0))
    expect_true(all(is.na(result$domain_table$eFDP)))
    expect_true(all(is.na(result$scope_table$eFDP)))
    expect_identical(result$domain_table$eFDP_exact, rep(NA_character_, 2L))
    expect_equal(result$domain_table$eFDP_zero, c(0, 0))
    expect_identical(result$event_table$p_exact, c("0", "0"))
    expect_true(all(result$event_table$analytically_inactive))
    expect_identical(result$event_table$inactive_reason, rep("no_disclosure", 2L))
    expect_false(any(result$evaluation$traces$union_event))
    expect_true(result$joint_protection_enabled)
    expect_true(result$feasible_for_represented_measure)
  }
})

test_that("the public path treats 25 of 500 as equality and 26 as strict exceedance", {
  skip_if_not_installed("gmp")
  units <- sprintf("unit-%02d", seq_len(33L))
  states <- c("exactly-25-errors", "exactly-26-errors")
  values <- array(rep(33:1, each=2L), c(2L, 33L, 1L),
    dimnames=list(state=states, unit=units, domain="threshold"))
  # Only unit 1 moves: 25 or 26 other values exceed its coordinate.
  values[, 1L, 1L] <- c(7.5, 6.5)
  input <- postrank_mdomain_input(values,
    targets=list(threshold=list(definition="Specified ordering coordinate",
      units="illustrative coordinate units", orientation="larger_is_higher",
      transformations=list(), equality_classes=setNames(units, units),
      equality_provenance="The 33 model coordinates have no structural identities.")),
    provenance=list(input_id="strict-25-versus-26", law_id="two-state-boundary-law",
      proper_law=TRUE, producer="Independent finite-support test construction",
      joint_generation="Two full states, each with mass 1/2, completely specify this law.",
      sampling_assumptions=list(finite_support_origin="The two listed states with exact masses 1/2 define the complete finite law.")),
    representation="exact_finite_law", masses=c("1/2", "1/2"))
  mask <- matrix(1L, 33L, 33L, dimnames=list(units, units))
  diag(mask) <- 0L
  # Remove 28 pairs among units 2:33. Every unit-1 pair stays protected.
  omit <- utils::combn(2:33, 2L)[, seq_len(28L), drop=FALSE]
  mask[cbind(omit[1L, ], omit[2L, ])] <- 0L
  mask[cbind(omit[2L, ], omit[1L, ])] <- 0L
  G <- matrix(seq_len(33L), 33L, 1L, dimnames=list(units, "threshold"))
  decision <- postrank_mdomain_decision(tau="1/4", scope=list(protected=mask),
    q=NULL, joint=data.frame(domain_id="threshold", scope_id="protected", t="1/20"),
    alpha="1/2")
  result <- postrank_mdomain_evaluate(input, G, decision)
  expect_identical(postrank_mdomain_grades(result), G)
  expect_equal(result$evaluation$expected$M, 528)
  expect_equal(result$domain_table$N, 528)
  expect_equal(result$scope_table$N, 500)
  expect_identical(result$domain_table$EF_exact, "51/2")
  expect_identical(result$risk_exact, "17/352")
  expect_identical(result$scope_table$eFDP_exact, "51/1000")
  expect_identical(result$event_table$t_exact, "1/20")
  expect_identical(result$event_table$cutoff_exact, "26")
  expect_equal(result$evaluation$expected$traces$threshold$scope_F[, "protected"],
    setNames(c(25L, 26L), states))
  expect_identical(unname(result$evaluation$traces$event_matrix[, 1L]), c(FALSE, TRUE))
  expect_identical(unname(result$evaluation$traces$union_event), c(FALSE, TRUE))
  expect_identical(result$J_exact, "1/2")
  expect_true(result$joint_feasible)
})
