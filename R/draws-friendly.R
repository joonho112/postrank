# Bookkeeping convenience over the strict input schemas (Chapter 11, PR-DEC-11-B).
# Every route ends in an unchanged strict constructor; the eight scientific
# declarations remain required and nothing is fabricated or added to a legacy
# payload or validation receipt.

.pr_declaration_fields <- c("targets", "context", "provenance", "origin", "identification_note",
  "tie_justification", "joint_generation", "sampling_provenance")
# Free-text scientific statements may not be generic placeholders.
.pr_placeholder_text <- c("unknown", "tbd", "todo", "na", "n/a", "none", "placeholder", "xxx", "-", "?", "missing", "not declared",
  "...", "\u2026", "tba", "fill in", "edit me")

.pr_declaration_text <- function(x, name) {
  .pr_builder_text(x, name)
  .pr_assert(!tolower(trimws(x)) %in% .pr_placeholder_text,
    paste0(name, " must state the actual declaration, not a placeholder such as \"", x, "\""),
    "placeholder_declaration", paste0("$.declarations.", name))
  x
}

#' Describe the Targets and Source of Posterior Draws
#'
#' The declarations specify the targets represented by the posterior draws, the
#' information on which they are conditioned and the procedure used to generate
#' them. The resulting bundle provides the eight required scientific
#' declarations for [postrank_draws()]. Its components can also be passed
#' separately to [postrank_draws_from_array()].
#'
#' @param targets One record per criterion, as a data frame or list of named
#'   lists. Required fields are `criterion_id`, `estimand`, `entity_population`,
#'   `time_reference` and `units`; `source_transform` and `identification_basis`
#'   are optional. Describe the actual target and any transformation.
#' @param context Named list with `cohort_id`, `data_version`,
#'   `data_conditioning` and `model_summary`.
#' @param provenance Named list with `producer`, `artifact_id` and
#'   `construction_note`; optional `artifact_hash` and `created_at`.
#' @param origin Named list with `source_id`, `fit_id`, `model_id`,
#'   `source_format` and `source_artifact`; optional `source_hash`.
#' @param identification_note Why each labeled target is identified.
#' @param tie_justification Why distinct entities have zero probability of
#'   exact equality on each criterion. A continuous marginal alone need not
#'   imply this when entity targets are dependent.
#' @param joint_generation How each retained draw represents one joint state
#'   of all entities and criteria, preserving the model's dependence.
#' @param sampling_provenance How the draws were produced, including the
#'   sampling regime and any selection of retained draws.
#' @return A `postrank_declarations` list containing these eight fields.
#' @details
#' All eight declarations are required. The bundle checks completeness and
#' rejects generic placeholders such as `"unknown"`, `"TBD"` or `"..."` in
#' required descriptive text. IDs follow their own rules; `fit_id` and
#' `data_version` may legitimately be labels such as `"none"`. This text check
#' also applies to the high-level numeric-array route of [postrank_draws()].
#' Direct strict constructors and canonical metadata readers check required
#' text and structure without this additional placeholder check.
#'
#' Identification, joint generation, zero equality probability and convergence
#' remain scientific declarations; validation does not establish their truth.
#' The example declarations therefore require replacement by descriptions of
#' the actual analysis. `source_transform` records an existing transformation,
#' whereas array orientation is performed separately by [postrank_draws()].
#' @seealso [postrank_draws()], [postrank_draws_from_array()],
#'   `vignette("a5-your-posterior-results", package = "postrank")`
#' @concept input
#' @examples
#' # One criterion: a specified synthetic law, not a fitted data analysis.
#' set.seed(901)
#' values <- array(rnorm(64 * 3), c(64, 3, 1),
#'   dimnames = list(NULL, c("A", "B", "C"), "need"))
#' decl <- postrank_declarations(
#'   targets = data.frame(criterion_id = "need",
#'     estimand = "Latent site need in a specified standard Normal law",
#'     entity_population = "Three fictional sites A, B and C",
#'     time_reference = "Static illustration; no observation period",
#'     units = "Illustrative standardized need units"),
#'   context = list(cohort_id = "three-fictional-sites", data_version = "1",
#'     data_conditioning = "No observations; the target law is specified directly",
#'     model_summary = "Independent standard Normal coordinates"),
#'   provenance = list(producer = "Help-page R generator", artifact_id = "normal-need",
#'     construction_note = "64 IID states sampled with seed 901"),
#'   origin = list(source_id = "specified-normal-law", fit_id = "no-model-fit",
#'     model_id = "independent-standard-normal", source_format = "R array",
#'     source_artifact = "The rnorm array generated in this example"),
#'   identification_note = "The law directly defines every labeled site target.",
#'   tie_justification = "Independent continuous Normal coordinates have zero probability of exact equality.",
#'   joint_generation = "Every row is one state of all sites and included criteria; all coordinates are independent in this example.",
#'   sampling_provenance = "Base R rnorm with seed 901; IID states, no warmup or thinning.")
#' draws <- postrank_draws(values, regime = "iid", declarations = decl)
#' draws$criterion_ids
#'
#' # Add an independent criterion while retaining every first-criterion draw.
#' two <- array(c(values, rnorm(64 * 3)), c(64, 3, 2),
#'   dimnames = list(NULL, c("A", "B", "C"), c("need", "cost")))
#' decl2 <- unclass(decl)
#' decl2$targets <- rbind(decl$targets, transform(decl$targets,
#'   criterion_id = "cost", estimand = "Latent cost in a standard Normal law",
#'   units = "Illustrative standardized cost units"))
#' decl2$provenance$artifact_id <- "normal-need-and-cost"
#' decl2 <- do.call(postrank_declarations, decl2)
#' two_draws <- postrank_draws(two, regime = "iid", declarations = decl2)
#' two_draws$criterion_ids
#' @export
postrank_declarations <- function(targets, context, provenance, origin, identification_note,
                                  tie_justification, joint_generation, sampling_provenance) {
  absent <- setdiff(.pr_declaration_fields, .pr_supplied(.pr_declaration_fields))
  if (length(absent)) .pr_abort(paste("missing required scientific declarations:", paste(absent, collapse = ", "),
    "(they are not inferred or filled with placeholders)"), "missing_declarations", "$.declarations")
  out <- list(targets = targets, context = context, provenance = provenance, origin = origin,
    identification_note = identification_note, tie_justification = tie_justification,
    joint_generation = joint_generation, sampling_provenance = sampling_provenance)
  nulls <- names(out)[vapply(out, is.null, TRUE)]
  if (length(nulls)) .pr_abort(paste("NULL scientific declarations:", paste(nulls, collapse = ", ")),
    "missing_declarations", "$.declarations")
  .pr_validate_declarations(structure(out, class = c("postrank_declarations", "list")))
}

.pr_validate_declarations <- function(x) {
  .pr_assert(inherits(x, "postrank_declarations") && is.list(x) && identical(names(x), .pr_declaration_fields),
    "declarations must be a postrank_declarations bundle with the eight fields in order", "invalid_declarations",
    "$.declarations")
  for (f in c("identification_note", "tie_justification", "joint_generation", "sampling_provenance"))
    .pr_declaration_text(x[[f]], f)
  targets <- x$targets
  if (is.data.frame(targets)) targets <- lapply(seq_len(nrow(targets)), function(r) as.list(targets[r, , drop = FALSE]))
  .pr_assert(is.list(targets) && length(targets) >= 1L, "targets needs one record per criterion", "invalid_builder_input", "$.declarations.targets")
  for (t in targets) {
    t <- lapply(t, function(v) if (is.factor(v)) as.character(v) else v)
    req <- c("criterion_id", "estimand", "entity_population", "time_reference", "units")
    .pr_builder_record(t, req, "targets")
    for (f in req[-1]) .pr_declaration_text(t[[f]], paste0("targets$", f))
  }
  records <- list(context = c("cohort_id", "data_version", "data_conditioning", "model_summary"),
    provenance = c("producer", "artifact_id", "construction_note"),
    origin = c("source_id", "fit_id", "model_id", "source_format", "source_artifact"))
  for (nm in names(records)) {
    r <- .pr_builder_record(x[[nm]], records[[nm]], nm)
    # Identifiers such as fit_id may legitimately read "none"; descriptive statements may not be placeholders.
    for (f in setdiff(records[[nm]], c("fit_id", "data_version"))) .pr_declaration_text(r[[f]], paste0(nm, "$", f))
  }
  x
}

.pr_as_declarations <- function(declarations) {
  if (inherits(declarations, "postrank_declarations")) return(.pr_validate_declarations(declarations))
  .pr_assert(is.list(declarations) && !is.data.frame(declarations) && !is.null(names(declarations)),
    "declarations must come from postrank_declarations()", "invalid_declarations", "$.declarations")
  missing_fields <- setdiff(.pr_declaration_fields, names(declarations))
  if (length(missing_fields)) .pr_abort(paste("missing required scientific declarations:", paste(missing_fields, collapse = ", ")),
    "missing_declarations", "$.declarations")
  extra <- setdiff(names(declarations), .pr_declaration_fields)
  .pr_assert(!length(extra), paste("unknown declaration fields:", paste(extra, collapse = ", ")), "invalid_declarations", "$.declarations")
  do.call(postrank_declarations, declarations[.pr_declaration_fields])
}

.pr_conflict <- function(args, route) {
  if (length(args)) .pr_abort(paste0("these arguments do not apply to ", route, " input: ", paste(args, collapse = ", ")),
    "input_metadata_conflict", "$")
  invisible(TRUE)
}

#' Prepare Posterior Draws for One or Several Criteria
#'
#' Posterior output is prepared for [postrank_pairwise()] or [postrank()] from
#' the retained values and their target, source and sampling descriptions. Each
#' row must retain the joint state of the entities being compared.
#'
#' @param x A numeric `S x n x K` array (draw, entity, criterion), a named list
#'   of `S_k x n` matrices, a `posterior` draws object, or a `postrank_draws`.
#'   For one criterion retain the third axis: `S x n x 1`.
#' @param regime For numeric arrays, `"iid"` or `"mcmc"`; required.
#' @param chains,warmup_per_chain,thin For MCMC arrays, the original number of
#'   chains, number of removed warmup iterations per chain, and retained
#'   iteration spacing. All three are required. Rows must be stored chain by
#'   chain with equal retained lengths; use `thin = 1L` for no thinning.
#'   Leave these arguments unset for IID draws.
#' @param entity_ids,criterion_ids Optional IDs for numeric array axes without
#'   dimnames. Supplied IDs must agree with any existing dimnames.
#' @param orientation `"higher"` by default: larger values already mean higher
#'   priority. For numeric arrays, a criterion-named character vector may
#'   instead specify `"higher"` or `"lower"`; unlisted criteria stay unchanged.
#' @param declarations A [postrank_declarations()] bundle for numeric arrays.
#' @param variables For `posterior` objects, explicit variable-mapping records
#'   as described in [as_postrank_posterior()].
#' @param metadata For matrix lists or `posterior` objects, complete canonical
#'   `applied-0.1` metadata describing the corresponding input.
#' @param source_coordinates For `posterior` objects, records mapping retained
#'   slots to source iteration and chain positions; see [as_postrank_posterior()].
#' @return A validated `postrank_draws` object retaining entity and criterion
#'   order, target descriptions and sampling history. Numeric array criteria
#'   requested as `"lower"` are negated once and that change is recorded.
#' @details The numeric-array route calls [postrank_draws_from_array()] with
#' the eight required declarations. Larger oriented values indicate higher
#' priority, and grade 1 therefore denotes the highest-priority group. For a
#' raw criterion whose preferred direction is lower, `orientation = c(rate =
#' "lower")` applies the required negation. A target already supplied as
#' `-rate` instead requires `orientation = "higher"`, since a second negation
#' would reverse the intended direction.
#'
#' A named matrix list uses `dependence_mode = "criterionwise_expected_only"`
#' and one `criterion_blocks` record per criterion in `metadata`. Each record
#' needs `criterion_id`, `origin`, `sampling`, `draw_index` and `variable_map`;
#' the function inserts its `matrix` values. Column order must match entity
#' IDs and rows must match the declared draw slots. Different draw counts are
#' allowed. Each row remains joint across entities within a criterion; aligning
#' rows from separate criteria does not create a cross-criterion joint law.
#' These inputs support additive criterion-wise expected loss, not recovery
#' of composite-target or simultaneous-event probabilities.
#'
#' A `posterior::draws_array`, `draws_df` or `draws_matrix` is converted with
#' `posterior::as_draws_array()` and passed to [as_postrank_posterior()].
#' Existing `postrank_draws` inputs are revalidated. These routes and matrix
#' lists must already have higher-priority orientation. Arguments belonging to
#' a different route raise `input_metadata_conflict`.
#'
#' All ordinary draw routes require a scientific zero-equality declaration
#' and reject observed within-criterion ties. Preserve original precision;
#' jitter would change the values. Genuine equality mass requires
#' [as_postrank_tie_draws()]. Do not relabel MCMC draws as IID or a finite
#' Monte Carlo sample as an exact finite posterior.
#'
#' Only the high-level numeric-array route applies the additional placeholder
#' checks of [postrank_declarations()]. Matrix-list and `posterior` metadata,
#' existing objects, direct strict constructors and JSON readers retain their
#' structural and declaration-presence checks. No route establishes scientific
#' jointness or convergence from those declarations.
#' @seealso [postrank_declarations()], [postrank_draws_from_array()],
#'   [as_postrank_draws()], [as_postrank_posterior()],
#'   `vignette("a5-your-posterior-results", package = "postrank")`
#' @concept input
#' @examples
#' # The bundled two-criterion Markov-chain toy includes its actual declarations.
#' # Its four original chains each have 512 retained iterations and no warmup.
#' # See postrank_declarations() for a complete K = 1 construction example.
#' draws <- postrank_draws(pr_toy_mcmc, regime = "mcmc",
#'   chains = 4L, warmup_per_chain = 0L, thin = 1L,
#'   declarations = attr(pr_toy_mcmc, "law")$declarations)
#' dim(draws$joint_draws$tensor$values)
#' draws$joint_draws$draw_index[[513L]] # first iteration of original chain 2
#' @export
postrank_draws <- function(x, regime = NULL, chains = NULL, warmup_per_chain = NULL, thin = NULL,
                           entity_ids = NULL, criterion_ids = NULL, orientation = "higher", declarations = NULL,
                           variables = NULL, metadata = NULL, source_coordinates = NULL) {
  supplied <- .pr_supplied(c("regime", "chains", "warmup_per_chain", "thin", "entity_ids", "criterion_ids",
    "orientation", "declarations", "variables", "metadata", "source_coordinates"))
  non_default_orientation <- !identical(orientation, "higher")
  if (inherits(x, "postrank_draws")) {
    .pr_conflict(supplied[supplied != "orientation" | non_default_orientation], "an existing postrank_draws")
    return(as_postrank_draws(x))
  }
  if (inherits(x, c("draws_array", "draws_df", "draws_matrix", "draws"))) {
    .pr_conflict(intersect(supplied, c("regime", "chains", "warmup_per_chain", "thin", "entity_ids", "criterion_ids",
      "declarations")), "posterior draws (the layout and declarations come from metadata)")
    .pr_assert(!non_default_orientation, "posterior metadata must already be oriented higher-priority",
      "input_metadata_conflict", "$.orientation")
    .pr_assert(!is.null(metadata) && !is.null(variables) && !is.null(source_coordinates),
      "posterior draws need canonical joint metadata, variables mapping records and source_coordinates",
      "missing_metadata", "$.metadata")
    .pr_assert(requireNamespace("posterior", quietly = TRUE),
      "the optional posterior package is required for posterior draws input", "missing_dependency")
    return(as_postrank_posterior(posterior::as_draws_array(x), variable_map = variables, metadata = metadata,
      source_coordinates = source_coordinates))
  }
  if (is.array(x) && is.numeric(x) && length(dim(x)) == 3L)
    return(.pr_draws_from_array_route(x, regime, chains, warmup_per_chain, thin, entity_ids, criterion_ids,
      orientation, declarations, supplied))
  if (is.list(x) && !is.data.frame(x) && length(x) && all(vapply(x, function(m) is.matrix(m) && is.numeric(m), TRUE)))
    return(.pr_draws_from_matrices(x, metadata, supplied, non_default_orientation))
  .pr_abort("x must be a numeric S x n x K array, a named list of S_k x n matrices, posterior draws or postrank_draws",
    "unsupported_source", "$")
}

.pr_draws_from_array_route <- function(x, regime, chains, warmup_per_chain, thin, entity_ids, criterion_ids,
                                       orientation, declarations, supplied) {
  .pr_conflict(intersect(supplied, c("variables", "metadata", "source_coordinates")), "array")
  .pr_assert(!is.null(regime), "array input needs an explicit regime: \"iid\" or \"mcmc\"", "missing_regime", "$.regime")
  .pr_assert(is.character(regime) && length(regime) == 1L && regime %in% c("iid", "mcmc"),
    "regime must be \"iid\" or \"mcmc\"", "invalid_builder_input", "$.regime")
  if (is.null(declarations)) .pr_abort(paste("array input needs the eight scientific declarations from postrank_declarations():",
    paste(.pr_declaration_fields, collapse = ", ")), "missing_declarations", "$.declarations")
  d <- .pr_as_declarations(declarations)
  # Only dim/dimnames are values; any other attribute (such as pr_toy_mcmc's "law") is
  # documentation and never enters the sealed payload.
  attributes(x) <- list(dim = dim(x), dimnames = dimnames(x))
  dn <- dimnames(x); if (is.null(dn)) dn <- vector("list", 3L)
  for (axis in list(list(2L, entity_ids, "entity_ids"), list(3L, criterion_ids, "criterion_ids"))) {
    ids <- axis[[2L]]
    if (is.null(ids)) next
    .pr_ids(as.character(ids), path = paste0("$.", axis[[3L]]))
    .pr_assert(length(ids) == dim(x)[axis[[1L]]], paste(axis[[3L]], "length must match the array axis"),
      "input_metadata_conflict", paste0("$.", axis[[3L]]))
    .pr_assert(is.null(dn[[axis[[1L]]]]) || identical(as.character(dn[[axis[[1L]]]]), as.character(ids)),
      paste(axis[[3L]], "contradicts the array dimnames"), "input_metadata_conflict", paste0("$.", axis[[3L]]))
    dn[[axis[[1L]]]] <- as.character(ids)
  }
  dimnames(x) <- dn
  criteria <- as.character(dn[[3L]])
  targets <- d$targets
  if (is.data.frame(targets)) targets <- lapply(seq_len(nrow(targets)), function(r)
    lapply(as.list(targets[r, , drop = FALSE]), function(v) if (is.factor(v)) as.character(v) else v))
  if (!identical(orientation, "higher")) {
    .pr_assert(is.character(orientation) && !is.null(names(orientation)) && !anyDuplicated(names(orientation)) &&
      all(names(orientation) %in% criteria) && all(orientation %in% c("higher", "lower")),
      "orientation must be \"higher\" or a criterion-named vector of \"higher\"/\"lower\"", "invalid_orientation",
      "$.orientation")
    lower <- names(orientation)[orientation == "lower"]
    tid <- vapply(targets, function(t) as.character(t$criterion_id), "")
    for (k in lower) {
      x[, , k] <- -x[, , k]
      j <- match(k, tid)
      .pr_assert(!is.na(j), paste("no target record for criterion", k), "invalid_builder_input", "$.declarations.targets")
      old <- if (is.null(targets[[j]]$source_transform)) "identity" else targets[[j]]$source_transform
      targets[[j]]$source_transform <- paste0(old, "; then negated once by postrank_draws(orientation = \"lower\") ",
        "so that larger values mean higher priority")
    }
  }
  postrank_draws_from_array(x, regime = regime, chains = chains, targets = targets, context = d$context,
    provenance = d$provenance, origin = d$origin, identification_note = d$identification_note,
    tie_justification = d$tie_justification, joint_generation = d$joint_generation,
    sampling_provenance = d$sampling_provenance, warmup_per_chain = warmup_per_chain, thin = thin)
}

.pr_draws_from_matrices <- function(x, metadata, supplied, non_default_orientation) {
  .pr_conflict(intersect(supplied, c("regime", "chains", "warmup_per_chain", "thin", "entity_ids", "criterion_ids",
    "declarations", "variables", "source_coordinates")), "matrix-list (criterionwise) metadata-driven")
  .pr_assert(!non_default_orientation, "criterionwise metadata must already be oriented higher-priority",
    "input_metadata_conflict", "$.orientation")
  .pr_assert(is.list(metadata) && identical(metadata$dependence_mode, "criterionwise_expected_only") &&
    is.list(metadata$criterion_blocks), "matrix-list input needs complete canonical criterionwise metadata",
    "missing_metadata", "$.metadata")
  .pr_assert(!is.null(names(x)) && !anyDuplicated(names(x)) && setequal(names(x), metadata$criterion_ids),
    "the matrix list must be named by exactly the metadata criterion_ids", "input_metadata_conflict", "$")
  blocks <- metadata$criterion_blocks
  for (b in seq_along(blocks)) {
    k <- blocks[[b]]$criterion_id; m <- x[[k]]
    .pr_assert(ncol(m) == length(metadata$entity_ids) &&
      (is.null(colnames(m)) || identical(colnames(m), metadata$entity_ids)),
      paste("matrix", k, "columns must be the metadata entity_ids in order"), "input_metadata_conflict", "$")
    slots <- vapply(blocks[[b]]$draw_index, function(z) z$slot_id, "")
    .pr_assert(nrow(m) == length(slots) && (is.null(rownames(m)) || identical(rownames(m), slots)),
      paste("matrix", k, "rows must match the declared draw_index"), "input_metadata_conflict", "$")
    storage.mode(m) <- "double"
    dimnames(m) <- list(draw = slots, entity = metadata$entity_ids)
    matrix_record <- list(axis_order = c("draw", "entity"), shape = list(S = nrow(m), n = ncol(m)),
      dimnames = dimnames(m), values = m)
    # Canonical block order: criterion_id, matrix, origin, sampling, draw_index, variable_map.
    if ("matrix" %in% names(blocks[[b]])) blocks[[b]]$matrix <- matrix_record
    else {
      at <- match("criterion_id", names(blocks[[b]]))
      blocks[[b]] <- append(blocks[[b]], list(matrix = matrix_record), after = if (is.na(at)) 0L else at)
    }
  }
  metadata$criterion_blocks <- blocks
  as_postrank_draws(metadata)
}
