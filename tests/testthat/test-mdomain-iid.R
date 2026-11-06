# Independent synthetic count-rule fixtures. The supplied rows are specified
# realizations of a declared two-point iid mechanism, not evidence that any
# observed sample is independent. No posterior archive or external data is used.
md_iid_test_input <- function(S, batch, hits=integer(), selection_ids=character(),
    validation_ids=character()) {
  ids <- paste0(batch, "-", seq_len(S))
  values <- array(0, c(S, 2L, 1L),
    dimnames=list(state=ids, unit=c("A", "B"), domain="benefit"))
  values[, "A", "benefit"] <- 2
  values[, "B", "benefit"] <- 1
  if (length(hits)) {
    values[hits, "A", "benefit"] <- 1
    values[hits, "B", "benefit"] <- 2
  }
  targets <- list(benefit=list(definition="Fictional two-unit benefit coordinate",
    units="illustrative units", orientation="larger_is_higher", transformations=list(),
    equality_classes=c(A="A", B="B"),
    equality_provenance="The specified two-point law has no identities between units."))
  mechanism <- paste("Declared whole-state iid sampling from a two-point law:",
    "(A,B)=(2,1) has probability 99/100 and (1,2) has probability 1/100.",
    "The test supplies a specified possible realization; its declarations are not verified.")
  provenance <- list(input_id=paste0("synthetic-iid-", batch),
    law_id="specified-two-point-iid-law", proper_law=TRUE,
    producer="Independent synthetic package test specification",
    model_version="two-point-law-v1", conditioning_info="No observed conditioning data",
    approximation_status="The specified two-point law is the intended law",
    joint_generation="Each row contains the complete state of both fictional coordinates.",
    conditioning_data_id="no-conditioning-data",
    conditioning_data_hash=digest::digest("no-conditioning-data", algo="sha256"),
    transformation_hash=digest::digest("identity-transformation", algo="sha256"),
    sampling_assumptions=list(iid_mechanism=mechanism,
      target_assertion="The explicitly specified proper two-point law."),
    selection_provenance=list(sample_adaptive=c(actions=FALSE, candidates=FALSE,
      masks=FALSE, thresholds=FALSE, config=FALSE),
      state_set_relationship="Declared independent exploration and validation batches",
      selection_state_ids=selection_ids, validation_state_ids=validation_ids))
  postrank_mdomain_input(values, targets=targets, provenance=provenance,
    representation="iid_equal_weight_draws")
}

md_iid_test_fixture <- function(S=59L, hits=integer(), alpha="1/20", t="0") {
  exploration_ids <- paste0("exploration-", 1:4)
  exploration <- md_iid_test_input(4L, "exploration", hits=4L,
    selection_ids=exploration_ids)
  grades <- matrix(c(1L, 2L), 2L, 1L,
    dimnames=list(c("A", "B"), "benefit"))
  decision <- postrank_mdomain_decision(t=t, alpha=alpha)
  # Freeze the report, event and target-law binding from exploration before the
  # validation realization is supplied. Changing S makes a separate test design.
  card <- postrank_mdomain_evaluate(exploration, grades, decision)
  frozen_hashes <- card$receipts$validation_spec_hashes
  ids <- paste0("validation-", seq_len(S))
  design <- list(spec_hashes=frozen_hashes, beta_exact="1/20",
    iid_whole_states=TRUE, independent_of_exploration=TRUE,
    frozen_before_validation=TRUE, fixed_sample_size=TRUE,
    no_validation_reuse=TRUE, no_optional_stopping=TRUE,
    iid_mechanism=exploration$payloads$joint$sampling_assumptions$iid_mechanism,
    independence_justification=paste("Exploration and validation are declared",
      "independent batches under the specified iid whole-state mechanism.",
      "Distinct IDs are consistency checks, not an independence proof."),
    exploration_history_id="specified-exploration-history",
    frozen_record_id=paste0("fixed-event-and-S-", S),
    validation_batch_id=paste0("specified-validation-batch-", S),
    fixed_S=S, validation_state_ids=ids, exploration_state_ids=exploration_ids)
  validation <- md_iid_test_input(S, "validation", hits=hits,
    selection_ids=exploration_ids, validation_ids=ids)
  list(input=validation, exploration=exploration, card=card, grades=grades,
    decision=decision, design=design)
}

md_iid_test_assess <- function(fixture, ...) postrank_mdomain_assess(
  fixture$input, fixture$card, method="iid", design=fixture$design, ...)

test_that("public fixed-event iid assessment distinguishes 59 from 58 zero hits", {
  skip_if_not_installed("gmp")
  f59 <- md_iid_test_fixture(59L)
  f58 <- md_iid_test_fixture(58L)
  a59 <- md_iid_test_assess(f59)
  a58 <- md_iid_test_assess(f58)
  # Independently, P_{alpha}(V=0)=(19/20)^S, without a beta-quantile call.
  tail59 <- gmp::as.bigq(gmp::as.bigz(19)^59, gmp::as.bigz(20)^59)
  tail58 <- gmp::as.bigq(gmp::as.bigz(19)^58, gmp::as.bigz(20)^58)
  expect_true(tail59 <= gmp::as.bigq(1,20))
  expect_true(tail58 > gmp::as.bigq(1,20))
  expect_s3_class(a59, "postrank_mdomain_assessment")
  expect_identical(a59$method, "iid")
  expect_identical(a59$status, "certified_conditional_on_declared_iid_independence")
  expect_true(a59$joint_certificate)
  expect_identical(a58$status, "inconclusive")
  expect_false(a58$joint_certificate)
  expect_s3_class(a59$native, "p2_iid_validation")
  expect_identical(a59$native$count_bound$v, 0L)
  expect_identical(a59$native$count_bound$S, 59L)
  expect_identical(a59$native$count_bound$alpha_exact, "1/20")
  expect_identical(a59$native$count_bound$beta_exact, "1/20")
  expect_identical(a59$native$count_bound$binomial_lower_tail_exact, as.character(tail59))
  expect_identical(a58$native$count_bound$binomial_lower_tail_exact, as.character(tail58))
  expect_identical(a59$spec_hashes, f59$card$receipts$validation_spec_hashes)
  expect_identical(a59$design, f59$design)
  expect_identical(a59$J_exact, "0")
  expect_identical(a59$evaluation$input, f59$input)
  expect_identical(a59$evaluation$grades, f59$grades)
  expect_identical(a59$evaluation$event_table$cutoff_exact, "1")
  expect_false(any(a59$evaluation$event_table$analytically_inactive))
  expect_false(a59$native$receipts$assumptions_verified)
  expect_true(a59$native$receipts$disjoint_IDs_do_not_establish_independence)
  expect_true(a59$native$receipts$duplicate_target_values_are_allowed)
  expect_true(a59$native$receipts$no_mean_or_optimality_or_model_certificate)
  expect_true(a59$native$count_bound$receipts$exact_comparison)
  expect_true(a59$native$count_bound$receipts$qbeta_not_used_for_acceptance)
  expect_true(a59$native$count_bound$count_rule_only_not_a_sampling_certificate)
  expect_false(a59$native$count_bound$assumptions_verified)
})

test_that("t zero fixes the strict event at any false disclosed direction", {
  skip_if_not_installed("gmp")
  f <- md_iid_test_fixture(59L, hits=c(1L,59L))
  a <- md_iid_test_assess(f)
  expected <- setNames(seq_len(59L) %in% c(1L,59L), f$design$validation_state_ids)
  expect_identical(a$native$evaluated$traces$union_event, expected)
  expect_identical(a$native$count_bound$v, 2L)
  expect_identical(a$J_exact, "2/59")
  expect_identical(a$evaluation$event_table$cutoff_exact, "1")
  expect_identical(a$status, "inconclusive")
  expect_false(a$joint_certificate)
  thin <- md_iid_test_assess(f, keep_traces=FALSE)
  expect_identical(thin$status, a$status)
  expect_identical(thin$native$count_bound, a$native$count_bound)
  expect_identical(thin$risk_exact, a$risk_exact)
  expect_identical(thin$J_exact, a$J_exact)
  expect_null(thin$native$evaluated$traces)
  expect_null(thin$native$evaluated$expected$traces)
  expect_null(thin$evaluation$evaluation$traces)
})

test_that("alpha zero empirical zero is inconclusive while all-withheld is analytic", {
  skip_if_not_installed("gmp")
  f <- md_iid_test_fixture(59L, alpha="0")
  a <- md_iid_test_assess(f)
  expect_identical(a$J_exact, "0")
  expect_identical(a$status, "inconclusive")
  expect_false(a$joint_certificate)
  expect_identical(a$native$count_bound$method, "alpha_zero_not_certified_by_finite_counts")
  expect_false(a$native$count_bound$accept)
  withheld <- postrank_mdomain_assess(f$input, f$grades*0,
    f$decision, method="iid")
  expect_identical(withheld$status, "analytic_zero_event")
  expect_true(withheld$joint_certificate)
  expect_identical(withheld$J_exact, "0")
  expect_null(withheld$native$count_bound)
  expect_true(all(withheld$evaluation$event_table$analytically_inactive))
  expect_identical(withheld$evaluation$event_table$inactive_reason, "no_disclosure")
  disabled <- postrank_mdomain_assess(f$input, f$grades,
    postrank_mdomain_decision(t=NULL, alpha="0"), method="iid")
  expect_identical(disabled$status, "joint_protection_disabled")
  expect_false(disabled$joint_certificate)
  expect_false(disabled$native$joint_protection_enabled)
  expect_null(disabled$native$count_bound)
  one <- md_iid_test_fixture(1L, hits=1L, alpha="1")
  trivial <- postrank_mdomain_assess(one$input, one$card, method="iid")
  expect_identical(trivial$status, "trivial_alpha_one")
  expect_true(trivial$joint_certificate)
  expect_null(trivial$native$count_bound)
})

test_that("iid declarations require fixed S, freezing, no stopping and no reuse", {
  skip_if_not_installed("gmp")
  f <- md_iid_test_fixture()
  error <- tryCatch(postrank_mdomain_assess(f$input, f$card, method="iid"), error=identity)
  expect_s3_class(error, "postrank_mdomain_error")
  expect_identical(error$code, "mdomain_assessment_design")
  flags <- c("iid_whole_states", "independent_of_exploration", "frozen_before_validation",
    "fixed_sample_size", "no_validation_reuse", "no_optional_stopping")
  for (field in flags) {
    changed <- f; changed$design[[field]] <- FALSE
    expect_error(md_iid_test_assess(changed), "declaration", class="postrank_mdomain_error",
      info=field)
  }
  for (field in c("iid_mechanism", "independence_justification", "exploration_history_id",
      "frozen_record_id", "validation_batch_id")) {
    changed <- f; changed$design[[field]] <- ""
    expect_error(md_iid_test_assess(changed), "provenance", class="postrank_mdomain_error",
      info=field)
  }
  changed <- f; changed$design$fixed_S <- 58L
  expect_error(md_iid_test_assess(changed), "fixed_S", class="postrank_mdomain_error")
  changed <- f; changed$design$validation_state_ids <- rev(changed$design$validation_state_ids)
  expect_error(md_iid_test_assess(changed), "state IDs", class="postrank_mdomain_error")
  changed <- f; changed$design$exploration_state_ids <- "validation-1"
  expect_error(md_iid_test_assess(changed), "overlap", class="postrank_mdomain_error")
  changed <- f; changed$design$exploration_state_ids <- c("selection-1", "selection-1")
  expect_error(md_iid_test_assess(changed), "unique character", class="postrank_mdomain_error")
  changed <- f; changed$design$beta_exact <- "0.05"
  expect_error(md_iid_test_assess(changed), "beta_exact", class="postrank_mdomain_error")
  expect_error(md_iid_test_assess(f, beta="1/10"), "beta_exact", class="postrank_mdomain_error")
  expect_identical(md_iid_test_assess(f, beta="0.05")$native$count_bound$beta_exact, "1/20")
})

test_that("frozen report decision and law hashes are checked against actual validation", {
  skip_if_not_installed("gmp")
  f <- md_iid_test_fixture()
  for (field in c("report", "decision", "target_law")) {
    changed <- f; changed$design$spec_hashes[[field]] <- "changed"
    expect_error(md_iid_test_assess(changed), "hash", class="postrank_mdomain_error", info=field)
  }
  e <- tryCatch(postrank_mdomain_assess(f$input, f$card,
    postrank_mdomain_decision(t="1/2"), method="iid", design=f$design), error=identity)
  expect_s3_class(e, "postrank_mdomain_error")
  expect_identical(e$code, "mdomain_frozen_event_mismatch")
  spec <- f$input$original_spec
  spec$intended_law$identifier <- "another-proper-specified-law"
  changed <- f; changed$input <- postrank_mdomain_input(spec)
  e <- tryCatch(md_iid_test_assess(changed), error=identity)
  expect_identical(e$code, "mdomain_frozen_event_mismatch")
  changed <- f
  spec <- f$input$original_spec
  spec$selection_provenance$selection_state_ids <- c("exploration-1", "validation-1")
  changed$input <- postrank_mdomain_input(spec)
  expect_error(md_iid_test_assess(changed), "Producer selection IDs overlap",
    class="postrank_mdomain_error")
  spec <- f$input$original_spec
  spec$selection_provenance$validation_state_ids <- rev(f$design$validation_state_ids)
  changed$input <- postrank_mdomain_input(spec)
  expect_error(md_iid_test_assess(changed), "Producer validation IDs conflict",
    class="postrank_mdomain_error")
})

test_that("the count rule compares exact tails separately from its floating display", {
  skip_if_not_installed("gmp")
  # With v=0, S=1 and alpha=1/3 the binomial lower tail is exactly 2/3.
  # The two surrounding beta values have identical numeric projections.
  equal <- p2_iid_count_bound(0L, 1L, alpha="1/3", beta="2/3")
  below <- p2_iid_count_bound(0L, 1L, alpha="1/3",
    beta="2305843009213693951/3458764513820540928")
  above <- p2_iid_count_bound(0L, 1L, alpha="1/3",
    beta="768614336404564651/1152921504606846976")
  expect_identical(equal$binomial_lower_tail_exact, "2/3")
  expect_true(equal$accept)
  expect_false(below$accept)
  expect_true(above$accept)
  expect_identical(below$beta, above$beta)
  expect_true(equal$upper_display_is_approximate)
  expect_true(below$receipts$qbeta_not_used_for_acceptance)
  expect_true(above$receipts$exact_comparison)
  testthat::local_mocked_bindings(p2_iid_upper_display=function(...) {
    list(value=NA_real_, status="test_display_unavailable")
  })
  expect_true(p2_iid_count_bound(0L, 1L, "1/3", "2/3")$accept)
  expect_false(p2_iid_count_bound(0L, 1L, "1/3",
    "2305843009213693951/3458764513820540928")$accept)
})

test_that("near-one beta retains positive upper displays below complement resolution", {
  skip_if_not_installed("gmp")
  beta <- "1152921504606846976/1152921504606846977"
  mass <- 1/(2^60+1)
  zero <- p2_iid_count_bound(0L, 1L, alpha="1/2", beta=beta)
  one <- p2_iid_count_bound(1L, 2L, alpha="1/2", beta=beta)
  expect_lte(abs(zero$beta-1), .Machine$double.eps)
  expect_identical(zero$beta_exact, beta)
  expect_gt(zero$upper_display, 0)
  expect_equal(zero$upper_display/mass, 1, tolerance=1e-14)
  expect_identical(zero$upper_display_status, "approximate")
  # For Beta(2,1), the lower-tail quantile is sqrt(1-beta).
  expect_gt(one$upper_display, 0)
  expect_equal(one$upper_display/sqrt(mass), 1, tolerance=1e-13)
  expect_identical(one$upper_display_status, "approximate")
  expect_true(zero$accept)
  expect_true(one$accept)
  expect_true(zero$receipts$qbeta_not_used_for_acceptance)
})

test_that("subnormal display endpoints are explicit without changing exact acceptance", {
  skip_if_not_installed("gmp")
  two <- gmp::as.bigz(2)
  beta <- as.character(gmp::as.bigq(two^1074-1, two^1074))
  subnormal <- p2_iid_count_bound(0L, 1L, alpha="1/2", beta=beta)
  expect_identical(subnormal$upper_display, .Machine$double.xmin*.Machine$double.eps)
  expect_identical(subnormal$upper_display_status, "approximate")
  expect_true(subnormal$accept)
  # A much smaller positive bound cannot be displayed as a positive double.
  beta_tiny <- as.character(gmp::as.bigq(two^1200-1, two^1200))
  unavailable <- p2_iid_count_bound(0L, 1L, alpha="1/2", beta=beta_tiny)
  expect_identical(unavailable$upper_display, NA_real_)
  expect_identical(unavailable$upper_display_status, "positive_bound_rounded_to_zero")
  expect_true(unavailable$accept)
  # The v>0 small-quantile branch stays positive in the subnormal range.
  beta_square <- as.character(gmp::as.bigq(two^2140-1, two^2140))
  positive <- p2_iid_count_bound(1L, 2L, alpha="1/2", beta=beta_square)
  expect_gt(positive$upper_display, 0)
  expect_lt(positive$upper_display, .Machine$double.xmin)
  expect_equal(positive$upper_display/(2^-1070), 1, tolerance=1e-12)
  expect_identical(positive$upper_display_status, "approximate")
  expect_true(positive$accept)
  endpoint <- p2_iid_count_bound(3L, 3L, alpha="1/2", beta="1/20")
  expect_identical(endpoint$upper_display, 1)
  expect_identical(endpoint$upper_display_status, "exact_endpoint")
  expect_false(endpoint$accept)
})

test_that("iid workload guards reject oversized exact work before display", {
  skip_if_not_installed("gmp")
  calls <- 0L
  testthat::local_mocked_bindings(p2_iid_upper_display=function(...) {
    calls <<- calls+1L
    stop("unexpected display")
  })
  expect_error(p2_iid_count_bound(0L, 59L, max_S=58L), "max_S")
  expect_error(p2_iid_count_bound(0L, 59L, max_bits=1L), "max_bits or max_work")
  expect_error(p2_iid_count_bound(0L, 59L, max_work=1L), "max_bits or max_work")
  expect_identical(calls, 0L)
  for (args in list(list(v=-1L,S=2L),list(v=3L,S=2L),list(v=0L,S=0L),
      list(v=0.5,S=2L),list(v=0L,S=2L,beta="0"),list(v=0L,S=2L,beta="1")))
    expect_error(do.call(p2_iid_count_bound,args))
  expect_identical(calls, 0L)
})
