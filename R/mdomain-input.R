# Public preparation of the validated multidomain input contract.
.md_input_check <- function(ok, message, field, code="mdomain_input_invalid") {
  if (!isTRUE(ok)) .md_error(message, code, field)
  invisible(TRUE)
}

.md_input_ids <- function(x, size, field) {
  .md_input_check(is.character(x) && is.null(dim(x)) && length(x) == size &&
    !anyNA(x) && all(nzchar(trimws(x))) && !anyDuplicated(x),
    paste0(field, " must contain unique, nonblank IDs in the supplied order."), field,
    "mdomain_input_ids")
  unname(x)
}

.md_input_absent <- function(x) is.null(x) || !length(x) ||
  (is.atomic(x) && (anyNA(x) || (is.character(x) && any(!nzchar(x)))))

# Missing audit information is recorded as missing, never replaced by a
# scientific declaration. These reasons describe this interface's bookkeeping.
.md_missing_reason <- function(spec, value, path, reason="Not supplied by the input producer.") {
  if (.md_input_absent(value) && is.null(spec$missing_metadata[[path]]))
    spec$missing_metadata[[path]] <- reason
  spec
}

.md_input_targets <- function(targets, units, domains, equality_classes=NULL) {
  .md_input_check(is.list(targets) && !is.data.frame(targets) &&
    identical(names(targets), domains),
    "targets must be a named list in the array's domain order.", "targets")
  if (!is.null(equality_classes))
    .md_input_check(is.list(equality_classes) && identical(names(equality_classes), domains),
      "equality_classes must be a domain-ordered named list.", "equality_classes")
  for (d in domains) {
    target <- targets[[d]]
    .md_input_check(is.list(target), "Each target must be a named record.", paste0("targets.",d))
    for (field in c("definition", "units", "equality_provenance"))
      .md_input_check(p2_nonempty_string(target[[field]]),
        paste0("Declare targets.",d,".",field," explicitly."), paste0("targets.",d,".",field))
    .md_input_check(identical(target$orientation,"larger_is_higher"),
      "Targets must already be oriented larger_is_higher.", paste0("targets.",d,".orientation"))
    if (!is.null(equality_classes)) {
      .md_input_check(is.null(target$equality_classes) ||
        identical(target$equality_classes,equality_classes[[d]]),
        "Conflicting equality class declarations.", paste0("targets.",d,".equality_classes"))
      target$equality_classes <- equality_classes[[d]]
    }
    cl <- target$equality_classes
    .md_input_check(is.character(cl) && is.null(dim(cl)) && length(cl)==length(units) &&
      !anyNA(cl) && all(nzchar(trimws(cl))) &&
      (is.null(names(cl)) || identical(names(cl),units)),
      "Declare one equality class per original unit in unit order; distinct labels declare no structural identity.",
      paste0("targets.",d,".equality_classes"))
    if (is.null(target$transformations)) target$transformations <- list()
    targets[[d]] <- target
  }
  targets
}

.md_input_metadata <- function(provenance, units, domains, targets, layout, representation) {
  .md_input_check(is.list(provenance) && !is.data.frame(provenance),
    "provenance must explicitly describe the producer and intended law.", "provenance")
  for (field in c("input_id","law_id"))
    .md_input_check(p2_nonempty_string(provenance[[field]]),
      paste0("Declare provenance.",field," explicitly."), paste0("provenance.",field))
  .md_input_check(identical(provenance$proper_law,TRUE),
    "State inputs require the producer's explicit proper_law = TRUE declaration.", "provenance.proper_law")
  declaration <- if (layout=="joint_array") "joint_generation" else "within_domain_joint"
  .md_input_check(p2_nonempty_string(provenance[[declaration]]),
    paste0("Declare provenance.",declaration," for the complete supplied states."), paste0("provenance.",declaration))
  law <- provenance$intended_law
  if (is.null(law)) law <- list()
  mapped <- list(identifier=provenance$law_id, proper_law=provenance$proper_law,
    producer_class=provenance$producer, model_version=provenance$model_version,
    conditioning_info=provenance$conditioning_info, approximation_status=provenance$approximation_status,
    coupling_justification=provenance[[declaration]])
  for (f in names(mapped)) {
    .md_input_check(is.null(law[[f]]) || is.null(mapped[[f]]) || identical(law[[f]],mapped[[f]]),
      paste0("Conflicting intended law metadata: ",f), paste0("provenance.intended_law.",f))
    if (is.null(law[[f]])) law[f] <- mapped[f]
  }
  if (layout=="joint_array") {
    construction <- list(type="supplied_joint_states",justification=provenance$joint_generation)
    .md_input_check(is.null(law$joint_construction) || identical(law$joint_construction,construction),
      "Friendly arrays declare supplied_joint_states; use a complete specification for a product adapter.",
      "provenance.intended_law.joint_construction")
    law$joint_construction <- construction
  }
  audit <- provenance$provenance
  if (is.null(audit)) audit <- list()
  for (f in c("source_hash","producer_version","code_version","seed","transformation_hash",
              "conditioning_data_id","conditioning_data_hash")) {
    .md_input_check(is.null(audit[[f]]) || is.null(provenance[[f]]) || identical(audit[[f]],provenance[[f]]),
      paste0("Conflicting provenance metadata: ",f), paste0("provenance.",f))
    if (is.null(audit[[f]])) audit[f] <- provenance[f]
  }
  missing <- provenance$missing_metadata
  if (is.null(missing)) missing <- list()
  if (is.character(missing)) missing <- as.list(missing)
  spec <- list(n=length(units),D=length(domains),unit_ids=units,domain_ids=domains,
    input_id=provenance$input_id,layout=layout,representation=representation,
    coupling_status=if(layout=="joint_array") "supplied_joint" else "unknown_cross_domain",
    intended_law=law,provenance=audit,target_spec=targets,
    selection_provenance=if(is.null(provenance$selection_provenance)) list() else provenance$selection_provenance,
    missing_metadata=missing,decision_spec_hash=provenance$decision_spec_hash)
  for (f in c("identifier","producer_class","model_version","conditioning_info","approximation_status","coupling_justification"))
    spec <- .md_missing_reason(spec,law[[f]],paste0("intended_law.",f))
  for (f in c("source_hash","producer_version","code_version","seed","transformation_hash","conditioning_data_id","conditioning_data_hash"))
    spec <- .md_missing_reason(spec,audit[[f]],paste0("provenance.",f))
  spec <- .md_missing_reason(spec,spec$decision_spec_hash,"decision_spec_hash","No decision specification is bound at input construction.")
  for (f in c("sample_adaptive","state_set_relationship","selection_state_ids","validation_state_ids"))
    spec <- .md_missing_reason(spec,spec$selection_provenance[[f]],paste0("selection_provenance.",f))
  spec
}

.md_validate_input <- function(input, mode="expected", domains=NULL) {
  .md_input_check(inherits(input,"postrank_mdomain_input") && is.list(input$original_spec),
    "Use postrank_mdomain_input() to prepare the input.", "input", "mdomain_input_class")
  rebuilt <- .md_attempt(p2_validate_input(input$original_spec),"mdomain_input_invalid","input.original_spec")
  original <- unclass(input)[names(rebuilt)]
  .md_input_check(identical(original,unclass(rebuilt)),
    "The validated input has changed; construct a new input from the modified source specification.",
    "input", "mdomain_input_mutated")
  .md_require_capability(input,mode,domains)
  input
}

#' Prepare Posterior States for Multidomain Grading
#'
#' `postrank_mdomain_input()` binds unit IDs, domain IDs, target definitions,
#' and source metadata to posterior states for multidomain profile grading,
#' where each unit receives a separate integer grade on each domain rather than
#' a single shared grade across criteria. It validates the supplied states and
#' metadata without fitting a statistical model or inventing cross-domain
#' dependence. Requires optional package `gmp`.
#'
#' @param x One of four inputs:
#'   \itemize{
#'     \item a 3D finite numeric array (`state x unit x domain`) with unique
#'       non-blank dimnames on all three axes (`S >= 1`, `n >= 2`, `D >= 1`);
#'     \item a domain-named list of 2D finite numeric matrices (`state x unit`)
#'       sharing identical unit column names in the same order;
#'     \item a validated [postrank_draws()] object (adapted with its stored
#'       targets, representation, and draw history; leave `targets`,
#'       `representation`, `masses`, `state_origin`, and `equality_classes` as
#'       `NULL`);
#'     \item a complete native specification list (`!is.null(x$layout)`) or an
#'       existing `postrank_mdomain_input` object to revalidate (with all extra
#'       arguments `NULL`).
#'   }
#' @param targets Named list in exact domain order. Each domain record requires
#'   non-empty strings `definition`, `units`, and `equality_provenance`,
#'   `orientation = "larger_is_higher"`, character vector `equality_classes`
#'   (one non-blank class label per unit in unit order; distinct labels declare
#'   no structural tie), and optional `transformations` (defaults to `list()`).
#' @param provenance Named list requiring non-empty strings `input_id` and
#'   `law_id`, plus `proper_law = TRUE`. Joint 3D arrays also require non-empty
#'   `joint_generation`; separate domain matrix lists require
#'   `within_domain_joint`. When `representation = "exact_finite_law"`,
#'   `provenance$sampling_assumptions$finite_support_origin` is also required.
#'   Optional source, sampling, and retention fields are kept as supplied, and
#'   omitted optional fields are listed in `missing_metadata` rather than filled
#'   in automatically.
#' @param representation State representation: `"exact_finite_law"`,
#'   `"iid_equal_weight_draws"`, or `"mcmc_equal_weight_draws"` (for separate
#'   domain matrices, may be a domain-ordered named character vector).
#' @param masses State masses required when
#'   `representation = "exact_finite_law"`: exact rational strings summing to
#'   `1` (for example `c("1/10", "9/10")`), numeric weights, or
#'   `list(encoding = ..., values = ...)`. Separate domain inputs take a
#'   domain-ordered named list.
#' @param state_origin Data frame with one row per state and columns
#'   `source_index`, `chain_id`, and `iteration_id` (plus optional `state_id`
#'   matching state dimnames). Required without missing values (`iteration_id >=
#'   1`) when `representation = "mcmc_equal_weight_draws"`. Separate domain
#'   inputs take a domain-ordered named list.
#' @param equality_classes Optional domain-ordered named list of unit equality
#'   class vectors (equivalent to supplying `equality_classes` inside each
#'   `targets` entry). Shared labels declare model-based equality and are never
#'   inferred from observed numerical ties.
#' @return A `postrank_mdomain_input` object (inheriting `p2_profile_input`)
#'   containing `unit_ids`, `domain_ids`, `n`, `D`, `layout`, `representation`,
#'   `coupling_status`, `payloads`, `capabilities`, `missing_metadata`,
#'   `original_spec`, and validation `receipts`.
#' @details
#' Separate domain matrix lists (`layout = "criterionwise_arrays"`) set
#' `coupling_status = "unknown_cross_domain"`: they support additive expected
#' loss and joint events involving at most one active domain, and matching state
#' row names across matrices are never treated as coupled joint draws. Adapting
#' an existing [postrank_draws()] object revalidates it and carries over its
#' target definitions and sampling metadata once `provenance` supplies
#' `input_id`, `law_id`, and `proper_law = TRUE`. Metadata fields record how
#' the input was constructed without verifying model specification or MCMC
#' convergence.
#' @seealso [postrank_mdomain_decision()], [postrank_mdomain_family()],
#'   [postrank_mdomain_evaluate()], [postrank_mdomain_solve()]
#' @examplesIf requireNamespace("gmp", quietly = TRUE)
#' inp <- postrank_mdomain_input(
#'   postrank_toy,
#'   provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
#' )
#' inp
#' inp$domain_ids
#' @concept multidomain
#' @importFrom stats setNames
#' @export
postrank_mdomain_input <- function(x, targets=NULL, provenance=NULL,
    representation=NULL, masses=NULL, state_origin=NULL, equality_classes=NULL) {
  .md_require_gmp()
  extras <- list(targets=targets,provenance=provenance,representation=representation,
    masses=masses,state_origin=state_origin,equality_classes=equality_classes)
  if (inherits(x,"postrank_mdomain_input")) {
    .md_input_check(all(vapply(extras,is.null,logical(1))),
      "Do not override metadata while revalidating an input.","x")
    return(.md_validate_input(x))
  }
  if (inherits(x,"postrank_draws")) {
    .md_input_check(is.null(targets) && is.null(representation) && is.null(masses) &&
      is.null(state_origin) && is.null(equality_classes),
      "Existing draws retain their target, representation, mass and state metadata.","x")
    spec <- .md_attempt(.md_adapt_postrank_draws(x,provenance),"mdomain_input_invalid","x")
    adapter <- list(route="postrank_draws",source_input=.pr_payload(x),
      source_validation=validate_postrank_draws(x))
  } else if (is.list(x) && !is.null(x$layout)) {
    .md_input_check(all(vapply(extras,is.null,logical(1))),
      "A complete specification carries its own metadata; do not supply overrides.","x")
    spec <- x
    adapter <- list(route="complete_specification")
  } else {
    spec <- .md_attempt(.md_build_state_spec(x,targets,provenance,representation,masses,state_origin,equality_classes),
      "mdomain_input_invalid","x")
    adapter <- list(route=if(is.array(x)) "labeled_joint_array" else "separate_domain_vectors",
      producer_declarations=provenance)
  }
  input <- .md_attempt(p2_validate_input(spec),"mdomain_input_invalid","x")
  input$adapter <- adapter
  class(input) <- c("postrank_mdomain_input","p2_profile_input","list")
  input
}
