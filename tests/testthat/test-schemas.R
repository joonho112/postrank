# T-obj-02: every new constructor has its documented ordered schema; legacy objects keep
# their source field sets without new audit fields.
audit <- c("schema_version", "provenance", "warnings")

test_that("new classes use their exact ordered fields", {
  expect_identical(names(postrank_settings(c(a = 1))), c("weights", "tau", "G_max", "q", "exact_G", "objective",
    "minimax_criteria", "minimax_refine", "label", "weight_sum_tolerance", audit))
  expect_identical(names(postrank_control()), c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap",
    "strategy", "engine", "verbose", "output", "tolerances", audit))
  d <- postrank_declarations(targets = list(list(criterion_id = "k", estimand = "Synthetic target", entity_population = "Two sites",
    time_reference = "One period", units = "units")), context = list(cohort_id = "c", data_version = "1", data_conditioning = "Synthetic conditioning statement",
    model_summary = "toy"), provenance = list(producer = "p", artifact_id = "a", construction_note = "n"),
    origin = list(source_id = "s", fit_id = "f", model_id = "m", source_format = "R", source_artifact = "x"),
    identification_note = "Declared coordinates.", tie_justification = "Distinct values.",
    joint_generation = "One joint state per draw.", sampling_provenance = "Synthetic values.")
  expect_identical(names(d), c("targets", "context", "provenance", "origin", "identification_note", "tie_justification",
    "joint_generation", "sampling_provenance"))
  expect_identical(class(d), c("postrank_declarations", "list"))
})

test_that("legacy objects gain no audit or display fields", {
  pw <- postrank_pairwise(postrank_toy)
  expect_false(any(c("summaries", "metadata", "provenance_display") %in% names(postrank_toy)))
  # Source-derived legacy receipt fields (0.0.1.9002 validate_postrank_draws()).
  expect_identical(names(postrank_toy$validation), c("valid", "schema_checked", "semantic_checks_completed",
    "source_values_checked", "jointness_verified", "convergence_verified", "eligible_functional", "input_identity",
    "validator_version", "check_results", "issues", "limitations"))
  p <- postrank_problem(pw, settings = postrank_settings(c(need_A = .6, need_B = .4), .25, 3L, label = "x"))
  expect_identical(names(p$settings), c("weights", "tau", "weight_sum", "weight_sum_tolerance", "G_max", "objective", "q",
    "exact_G", "minimax_criteria"))
  expect_false(any(c("label", "provenance", "warnings") %in% names(p$settings)))
  expect_identical(names(pr_example_gaussian), c("schema_version", "input_kind", "entity_ids", "criterion_ids", "means", "e",
    "source", "provenance", "capabilities", "validation", "coefficient_identity", "input_identity", "pairwise_identity"))
})
