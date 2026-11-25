# Helpers that assemble the declarations list and dispatch draw inputs to the
# strict constructors. All eight descriptions remain required and nothing is
# filled in automatically or added to the validated input structure.

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
#' `postrank_declarations()` collects the eight required descriptions of a
#' posterior-draws input for [postrank_draws()]: what each criterion measures,
#' the data and model context, the software and source that produced the draws,
#' and why target identification, joint sampling and zero exact-tie probability
#' hold. Its components can also be passed separately to
#' [postrank_draws_from_array()].
#'
#' For most numeric arrays, [postrank_describe()] is shorter: it takes each
#' statement as a plain argument, fills all five identifiers from one `label`,
#' and calls `postrank_declarations()`. Use `postrank_declarations()` directly
#' when the five identifiers (`cohort_id`, `artifact_id`, `source_id`, `fit_id`,
#' `model_id`) or the two sampling notes (`construction_note` and
#' `sampling_provenance`) need to differ, or when you want to record an existing
#' `source_transform` or `identification_basis` in `targets`. Every descriptive
#' statement must be written by you; nothing is inferred or filled in
#' automatically.
#'
#' @param targets One record per criterion, as a data frame or a list of named
#'   lists. Required string fields are `criterion_id`, `estimand`,
#'   `entity_population`, `time_reference` and `units`; optional string fields
#'   are `source_transform` and `identification_basis`.
#' @param context Named list of non-empty character strings: `cohort_id`
#'   (identifier for the compared entity cohort), `data_version` (data release
#'   label), `data_conditioning` (which observations or assumptions the
#'   posterior conditions on) and `model_summary` (short summary of the
#'   statistical model).
#' @param provenance Named list of non-empty character strings: `producer`
#'   (software or script that created this draw object), `artifact_id`
#'   (identifier for the draw object) and `construction_note` (how this draw
#'   array or file was assembled from the model output); optional string fields
#'   are `artifact_hash` and `created_at`.
#' @param origin Named list of non-empty character strings: `source_id`
#'   (identifier for the upstream posterior source), `fit_id` (identifier for
#'   the model fit, or `"none"` when there is no fit), `model_id` (identifier
#'   for the model specification), `source_format` (format of the upstream
#'   output, such as `"CmdStan CSV files"` or `"R array"`) and
#'   `source_artifact` (which file or R object holds the draws); optional
#'   string field `source_hash`.
#' @param identification_note One string explaining why each criterion's target
#'   is identified by the model.
#' @param tie_justification One string explaining why distinct entities have
#'   zero probability of exact equality on each criterion. Continuous marginals
#'   alone do not guarantee this when entity targets are dependent.
#' @param joint_generation One string explaining how each draw represents all
#'   entities and criteria together, preserving their dependence under the
#'   model.
#' @param sampling_provenance One string describing the sampling algorithm,
#'   chain count, warmup removal and thinning used to generate the retained
#'   draws (whereas `provenance$construction_note` describes how the array or
#'   file was extracted or packaged).
#' @returns A `postrank_declarations` object, a named list containing these
#'   eight fields in order.
#' @details
#' All eight arguments are required and non-`NULL`. Every required string field
#' except `targets$criterion_id`, `origin$fit_id` and `context$data_version` is
#' checked against generic placeholders such as `"unknown"`, `"TBD"`, `"TODO"`,
#' `"NA"`, `"none"`, `"..."`, `"missing"` or `"not declared"` (error code
#' `placeholder_declaration`), so `cohort_id`, `artifact_id`, `source_id` and
#' `model_id` must also be real labels rather than `"none"`. Optional subfields
#' (`source_transform`, `identification_basis`, `artifact_hash`, `created_at`,
#' `source_hash`) are checked when passed to [postrank_draws_from_array()].
#' Lower-level constructors ([postrank_draws_from_array()],
#' [as_postrank_draws()], [as_postrank_posterior()], [read_postrank_draws()])
#' check that required strings are non-empty without applying this placeholder
#' list.
#'
#' Checking a `postrank_declarations` object verifies that required fields are
#' present and non-placeholder; it does not verify scientific identification,
#' joint sampling, zero tie probability or MCMC convergence. In `targets`,
#' `source_transform` records a transformation that was already applied before
#' calling `postrank`; sign reversal of lower-is-higher criteria is performed
#' separately by the `orientation` argument of [postrank_draws()].
#' @seealso [postrank_describe()] for the flat-argument helper;
#'   [postrank_draws()], [postrank_draws_from_array()],
#'   `vignette("a5-your-posterior-results", package = "postrank")`
#' @concept input
#' @examples
#' set.seed(901)
#' values <- array(rnorm(64 * 3), c(64, 3, 1),
#'   dimnames = list(NULL, c("A", "B", "C"), "need"))
#'
#' # Short form via postrank_describe() (calls postrank_declarations()):
#' decl <- postrank_describe(
#'   estimand = c(need = "Latent site need in a specified standard normal law"),
#'   population = "Three fictional sites A, B and C",
#'   time = "Static illustration; no observation period",
#'   units = "Illustrative standardized need units",
#'   data = "No observations; the law is specified directly",
#'   model = "Independent standard normal coordinates",
#'   identification = "The law directly defines each site's target.",
#'   joint = "Each draw holds one value for every site and criterion.",
#'   sampling = "64 independent draws from rnorm() with seed 901; no warmup or thinning.",
#'   ties = "Independent continuous normal coordinates are equal with probability zero.",
#'   software = "Base R rnorm()",
#'   source = "The array values created in this example",
#'   label = "normal-need", data_version = "1", values = values)
#' draws <- postrank_draws(values, regime = "iid", declarations = decl)
#' draws$criterion_ids
#'
#' # Full form when identifiers such as fit_id ("none") differ from artifact_id:
#' decl_full <- postrank_declarations(
#'   targets = decl$targets,
#'   context = decl$context,
#'   provenance = decl$provenance,
#'   origin = modifyList(decl$origin, list(fit_id = "none")),
#'   identification_note = decl$identification_note,
#'   tie_justification = decl$tie_justification,
#'   joint_generation = decl$joint_generation,
#'   sampling_provenance = decl$sampling_provenance)
#' decl_full$origin$fit_id
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
#' `postrank_draws()` prepares posterior draws from your model for [postrank()]
#' or [postrank_pairwise()], checking the values, entity and criterion labels,
#' sampling layout, and target descriptions. Within each criterion, every draw
#' must hold values for all compared entities together.
#'
#' @param x Posterior draws for `n >= 2` entities in one of four forms:
#'   * a numeric `S x n x K` array (draws x entities x criteria; keep the third
#'     dimension `S x n x 1` when `K = 1`);
#'   * a named list of `S_k x n` numeric matrices, one matrix per criterion;
#'   * a `posterior` package object (`draws_array`, `draws_df` or
#'     `draws_matrix`);
#'   * an existing `postrank_draws` object to revalidate.
#' @param regime Sampling regime for a numeric array: `"iid"` or `"mcmc"`
#'   (required for arrays; leave `NULL` for other inputs).
#' @param chains,warmup_per_chain,thin MCMC chain layout for a numeric array
#'   when `regime = "mcmc"`: the original number of chains (`>= 1`), the number
#'   of warmup iterations removed per chain (`>= 0`), and the thinning interval
#'   between retained iterations (`>= 1`, use `1L` when unthinned). All three
#'   are required when `regime = "mcmc"`, and array rows must be ordered chain
#'   by chain with `S` divisible by `chains`. Leave `NULL` when `regime = "iid"`.
#' @param entity_ids,criterion_ids Character vectors naming the 2nd (entity)
#'   and 3rd (criterion) axes of a numeric array. Required when the
#'   corresponding axis of `dimnames(x)` is `NULL`; optional when `dimnames(x)`
#'   already names those axes (if both are given, they must match).
#' @param orientation Priority direction of the supplied values. `"higher"`
#'   (the default) means larger values already indicate higher priority (toward
#'   grade 1). For numeric arrays only, a character vector named by criterion
#'   may set `"higher"` or `"lower"`; criteria set to `"lower"` are negated
#'   once (`-x[, , k]`) and record that sign flip in `targets`. Unlisted
#'   criteria stay `"higher"`.
#' @param declarations Description of the targets and sampling for a numeric
#'   array, from [postrank_describe()] or [postrank_declarations()] (or a named
#'   list with those eight fields).
#' @param variables Variable-mapping records for `posterior` objects; see
#'   [as_postrank_posterior()].
#' @param metadata Complete posterior-input metadata list (in `postrank`'s
#'   `"applied-0.1"` input format) for matrix-list or `posterior` inputs; see
#'   [as_postrank_draws()] and [as_postrank_posterior()].
#' @param source_coordinates Records mapping each draw row ("slot") to its
#'   iteration and chain position in a `posterior` object; see
#'   [as_postrank_posterior()].
#' @returns A validated `postrank_draws` object storing the oriented draw
#'   values, ordered `entity_ids` and `criterion_ids`, target and source
#'   descriptions, sampling history, and a `validation` record.
#' @details
#' **Numeric arrays.** Most analyses supply an `S x n x K` numeric array with
#' `declarations` built by [postrank_describe()] (or [postrank_declarations()]).
#' If a raw criterion has lower values at higher priority (such as an error rate
#' or cost) and has not yet been negated, pass `orientation = c(cost = "lower")`.
#' If you already negated the values before calling `postrank_draws()`, keep
#' `orientation = "higher"` so they are not negated a second time.
#'
#' **Criterion-wise matrix lists.** When criteria come from separate models or
#' separate MCMC runs (possibly with different draw counts `S_k`), pass a named
#' list of `S_k x n` matrices together with `metadata` setting
#' `dependence_mode = "criterionwise_expected_only"` and one `criterion_blocks`
#' entry per criterion (`criterion_id`, `origin`, `sampling`, `draw_index` and
#' `variable_map`; `postrank_draws()` inserts `matrix`). Each row is joint
#' across entities within its criterion, while aligning rows across separate
#' matrices does not create a cross-criterion joint posterior or recover
#' composite-score or simultaneous-event probabilities. In [postrank()] and
#' [postrank_problem()], criterion-wise inputs support weighted and minimax
#' objectives, `q` budgets and `exact_G`, whereas Monte Carlo fragility and
#' cross-fitting require joint `S x n x K` draws and are unavailable even when
#' `K = 1`.
#'
#' **`posterior` objects and existing `postrank_draws`.** Objects from the
#' optional `posterior` package are converted with `posterior::as_draws_array()`
#' and passed to [as_postrank_posterior()]. Existing `postrank_draws` objects
#' are revalidated with [as_postrank_draws()]. Matrix-list, `posterior` and
#' existing `postrank_draws` inputs must already be oriented so larger values
#' mean higher priority; passing arguments that belong to another input form
#' stops with `input_metadata_conflict`.
#'
#' **Exact ties, sampling regimes and scope of checks.** `postrank_draws()`
#' assumes zero probability of exact equality between distinct entities within
#' any criterion and stops if any draw contains tied entity values on a
#' criterion. Keep draws at full precision rather than rounding, and do not add
#' random noise (which changes the posterior). When exact ties have positive
#' probability, use [as_postrank_tie_draws()]. Record the actual sampling
#' regime: do not relabel MCMC draws as `"iid"` or a finite Monte Carlo sample
#' as an exact finite posterior. Only numeric-array input applies the
#' placeholder-word list of [postrank_declarations()]; matrix-list and
#' `posterior` `metadata` and revalidated `postrank_draws` objects check
#' structure and non-empty strings. Validation checks structure and presence of
#' descriptions; it does not verify scientific identification, jointness or
#' MCMC convergence.
#' @seealso [postrank_describe()], [postrank_declarations()],
#'   [postrank_draws_from_array()], [as_postrank_draws()],
#'   [as_postrank_posterior()],
#'   `vignette("a5-your-posterior-results", package = "postrank")`
#' @concept input
#' @examples
#' # Numeric IID array described with postrank_describe():
#' set.seed(901)
#' values <- array(rnorm(64 * 3), c(64, 3, 1),
#'   dimnames = list(NULL, c("A", "B", "C"), "need"))
#' decl <- postrank_describe(
#'   estimand = c(need = "Site need in a specified standard normal distribution"),
#'   population = "Three fictional sites A, B and C",
#'   time = "Static illustration; no observation period",
#'   units = "Illustrative standardized need units",
#'   data = "No observations; the distribution is specified directly",
#'   model = "Independent standard normal coordinates",
#'   identification = "The specified distribution defines each site's target.",
#'   joint = "Each draw holds one value for every site and criterion.",
#'   sampling = "64 independent draws from rnorm() with seed 901; no warmup or thinning.",
#'   ties = "Independent continuous normal coordinates are equal with probability zero.",
#'   software = "Base R rnorm()",
#'   source = "The array values created in this example",
#'   label = "normal-need", data_version = "1", values = values)
#' iid_draws <- postrank_draws(values, regime = "iid", declarations = decl)
#' iid_draws$entity_ids
#'
#' # Bundled 4-chain MCMC array (512 retained iterations per chain, no warmup):
#' mcmc_draws <- postrank_draws(pr_toy_mcmc, regime = "mcmc",
#'   chains = 4L, warmup_per_chain = 0L, thin = 1L,
#'   declarations = attr(pr_toy_mcmc, "law")$declarations)
#' mcmc_draws$criterion_ids
#' mcmc_draws$validation$valid
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
  # documentation metadata and is stripped before building the input object.
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
