.pr_abort <- function(message, code = "invalid_input", path = "$") {
  cond <- structure(list(message = paste0(path, ": ", message), call = NULL,
                         code = code, path = path),
                    class = c("postrank_input_error", "postrank_error", "error", "condition"))
  stop(cond)
}
.pr_assert <- function(ok, message, code = "invalid_input", path = "$") {
  if (!isTRUE(ok)) .pr_abort(message, code, path)
  invisible(TRUE)
}
.pr_fields <- function(x, required, allowed = required, path = "$") {
  .pr_assert(is.list(x) && !is.data.frame(x) && !is.null(names(x)) &&
               !anyNA(names(x)) && !anyDuplicated(names(x)), "expected uniquely named record", path = path)
  .pr_assert(all(required %in% names(x)), paste("missing fields:", paste(setdiff(required, names(x)), collapse = ", ")), path = path)
  .pr_assert(all(names(x) %in% allowed), paste("unknown fields:", paste(setdiff(names(x), allowed), collapse = ", ")), path = path)
  invisible(TRUE)
}
.pr_ids <- function(x, min = 1L, path = "$") {
  .pr_assert(is.character(x) && is.null(dim(x)) && length(x) >= min &&
               !anyNA(x) && all(grepl("(*UCP)\\S", x, perl = TRUE)) && !anyDuplicated(x),
             "IDs must be unique nonblank strings in declared order", "invalid_id", path)
  invisible(TRUE)
}
.pr_string <- function(x, path = "$") {
  .pr_assert(is.character(x) && is.null(dim(x)) && length(x) == 1L && !is.na(x) && grepl("(*UCP)\\S", x, perl = TRUE),
             "expected nonblank string", path = path)
}
.pr_safe_integer <- function(x, positive = FALSE, path = "$") {
  .pr_assert(typeof(x) %in% c("integer", "double") && !anyNA(x) && all(is.finite(x)) &&
               all(x == floor(x)) && all(abs(x) <= 9007199254740991) &&
               (!positive || all(x >= 1)), "expected safe integers", "unsafe_integer", path)
  invisible(TRUE)
}
.pr_records <- function(x, path = "$") {
  .pr_assert(is.list(x) && is.null(dim(x)) && !is.data.frame(x), "expected list of records", path = path)
  invisible(TRUE)
}
.pr_validate_common <- function(x) {
  fields <- c("schema_version", "input_kind", "dependence_mode", "requested_functional",
              "entity_ids", "criterion_ids", "targets", "context", "identification", "tie_policy", "provenance")
  .pr_fields(x, fields, c(fields, "joint_draws", "criterion_blocks", "finite_law"))
  .pr_assert(identical(x$schema_version, "applied-0.1"), "unsupported input schema version", "unsupported_version")
  .pr_assert(identical(x$requested_functional, "expected_rank_loss"), "only expected_rank_loss is supported", "unsupported_functional")
  .pr_ids(x$entity_ids, 2L, "$.entity_ids"); .pr_ids(x$criterion_ids, 1L, "$.criterion_ids")
  .pr_records(x$targets, "$.targets")
  .pr_assert(length(x$targets) == length(x$criterion_ids), "one target record required per criterion", path = "$.targets")
  target_fields <- c("criterion_id", "estimand", "entity_population", "time_reference", "units", "source_transform", "identification_basis", "orientation")
  for (k in seq_along(x$targets)) {
    z <- x$targets[[k]]; path <- paste0("$.targets[", k, "]")
    .pr_fields(z, target_fields, path = path)
    for (f in target_fields) .pr_string(z[[f]], paste0(path, ".", f))
    .pr_assert(z$criterion_id %in% x$criterion_ids, "unknown target criterion ID", path = path)
    .pr_assert(identical(z$orientation, "higher_priority"), "targets must already be oriented higher_priority", path = path)
  }
  target_ids <- vapply(x$targets, `[[`, character(1), "criterion_id")
  .pr_ids(target_ids, path = "$.targets.criterion_id")
  .pr_assert(setequal(target_ids, x$criterion_ids), "targets must cover each criterion exactly once", path = "$.targets")
  .pr_fields(x$context, c("cohort_id", "data_version", "data_conditioning", "model_summary"), path = "$.context")
  for (f in names(x$context)) .pr_string(x$context[[f]], paste0("$.context.", f))
  .pr_fields(x$identification, c("status", "note"), path = "$.identification")
  .pr_assert(identical(x$identification$status, "identified_declared"), "unresolved target identification", "unresolved_identification")
  .pr_string(x$identification$note, "$.identification.note")
  .pr_fields(x$tie_policy, c("rule", "declared", "justification", "observed_tie_action"), path = "$.tie_policy")
  .pr_assert(identical(x$tie_policy$rule, "pairwise_tie_free") && isTRUE(x$tie_policy$declared) &&
               identical(x$tie_policy$observed_tie_action, "reject_and_review"), "tie-free declaration/review policy required", path = "$.tie_policy")
  .pr_string(x$tie_policy$justification, "$.tie_policy.justification")
  .pr_fields(x$provenance, c("producer", "artifact_id", "artifact_hash", "construction_note", "created_at"), path = "$.provenance")
  for (f in names(x$provenance)) .pr_string(x$provenance[[f]], paste0("$.provenance.", f))
  branches <- intersect(c("joint_draws", "criterion_blocks", "finite_law"), names(x))
  .pr_assert(length(branches) == 1L, "exactly one input branch is required")
  if (identical(x$input_kind, "equal_weight_draws") && identical(x$dependence_mode, "joint_model")) {
    .pr_assert(identical(branches, "joint_draws"), "joint_model requires joint_draws"); .pr_validate_joint(x)
  } else if (identical(x$input_kind, "equal_weight_draws") && identical(x$dependence_mode, "criterionwise_expected_only")) {
    .pr_assert(identical(branches, "criterion_blocks"), "criterionwise mode requires criterion_blocks"); .pr_validate_criterionwise(x)
  } else if (identical(x$input_kind, "exact_finite_posterior") && identical(x$dependence_mode, "joint_model")) {
    .pr_assert(identical(branches, "finite_law"), "exact input requires finite_law"); .pr_validate_exact(x)
  } else .pr_abort("unsupported input kind/dependence mode", "unsupported_input")
  invisible(TRUE)
}
