# Input builder (014 repair, AP-2): the scientific declarations stay required
# arguments; the bookkeeping (slot IDs, draw index, variable map, chain
# history, hashes) is generated from the array and the declared layout.

.pr_builder_text <- function(x, name) {
  .pr_assert(is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x)),
    paste(name, "must be one nonempty character string"), "invalid_builder_input")
  x
}

.pr_builder_record <- function(x, required, name) {
  .pr_assert(is.list(x) && !is.data.frame(x) && !is.null(names(x)) && all(required %in% names(x)),
    paste0(name, " must be a named list with ", paste(required, collapse = ", ")), "invalid_builder_input")
  for (f in required) .pr_builder_text(x[[f]], paste0(name, "$", f))
  x[required]
}

#' Build a Posterior Input from a Joint Array
#'
#' The builder constructs a posterior input from an already oriented array of
#' joint draws, together with target definitions, source information and
#' sampling history. Draw IDs, variable mappings and content hashes are
#' generated before the input is validated by [as_postrank_draws()].
#'
#' @param values Numeric `S x n x K` array (draw, entity, criterion) with
#'   entity and criterion dimnames. Keep `K = 1` as a third axis. Larger values
#'   must already mean higher priority; this function performs no negation.
#'   Draw names are generated when absent.
#' @param regime `"iid"` (the default) or `"mcmc"`; select the actual regime.
#' @param chains For MCMC, the original number of chains. Rows must be stored
#'   chain by chain with equal retained lengths. Leave unset for IID draws.
#' @param targets One record per criterion as a list of named lists or a data
#'   frame. Required fields: `criterion_id`, `estimand`, `entity_population`,
#'   `time_reference`, `units`. Optional `source_transform` defaults to
#'   `"identity"`; `identification_basis` defaults to `identification_note`.
#' @param context Named list with `cohort_id`, `data_version`,
#'   `data_conditioning` and `model_summary`.
#' @param provenance Named list with `producer`, `artifact_id` and
#'   `construction_note`. Optional `artifact_hash` defaults to the SHA-256 of
#'   the supplied array; `created_at` defaults to the current UTC time.
#' @param origin Named list with `source_id`, `fit_id`, `model_id`,
#'   `source_format` and `source_artifact`. Optional `source_hash` defaults
#'   to the SHA-256 of the supplied array.
#' @param identification_note Why every labeled target is identified.
#' @param tie_justification Why exact equality between distinct entities has
#'   probability zero on each criterion. Observed ties are still rejected.
#' @param joint_generation How each draw holds one joint state of all entities
#'   and criteria, including their dependence.
#' @param sampling_provenance How the retained draws were produced.
#' @param warmup_per_chain For MCMC, the number of removed warmup iterations
#'   per chain. Zero declares no removed warmup. Leave unset for IID draws.
#' @param thin For MCMC, retained-iteration spacing; use `1L` for no thinning.
#'   Leave unset for IID draws.
#' @return A validated `postrank_draws` object with the supplied values and
#'   entity/criterion order, plus their declarations and generated bookkeeping.
#' @details
#' For MCMC, `chains`, `warmup_per_chain` and `thin` are required declarations,
#' not estimates. Within each chain, retained iteration numbers are
#' `warmup_per_chain + thin * seq_len(S / chains)`. This regular layout must
#' match the producer's actual history. Use canonical metadata and
#' [as_postrank_posterior()] for an explicit source mapping with other histories;
#' never split a single chain into artificial independent chains.
#'
#' The eight scientific declarations are required. This strict builder checks
#' required text and structure; the additional placeholder-text checks apply
#' to [postrank_declarations()] and the numeric-array route of [postrank_draws()].
#' Neither kind of validation proves scientific jointness, identification,
#' zero equality probability or convergence. A generated hash identifies the
#' supplied in-memory array; it does not verify an external source file.
#'
#' `source_transform` describes a transformation already performed. To
#' negate raw criteria automatically, use [postrank_draws()] with its
#' `orientation` argument. Use [as_postrank_tie_draws()] for genuine equality
#' mass, and [as_postrank_draws()] for a completely specified exact finite law.
#' @seealso [postrank_draws()], [postrank_declarations()], [as_postrank_posterior()]
#' @concept input
#' @examples
#' # Rebuild the unchanged two-criterion IID toy array with its own records.
#' # Reuse is appropriate here because the values and specified law are identical.
#' # For newly generated data, write declarations as in postrank_declarations().
#' x <- postrank_toy
#' b <- x$joint_draws
#' draws <- postrank_draws_from_array(b$tensor$values, regime = "iid",
#'   targets = x$targets, context = x$context, provenance = x$provenance,
#'   origin = b$origin, identification_note = x$identification$note,
#'   tie_justification = x$tie_policy$justification,
#'   joint_generation = b$cross_criterion_joint_provenance,
#'   sampling_provenance = b$sampling$sampling_provenance)
#' identical(draws$joint_draws$tensor$values, b$tensor$values)
#' # The builder creates bookkeeping; use canonical input to retain custom draw IDs.
#' @export
postrank_draws_from_array <- function(values, regime = c("iid", "mcmc"), chains = NULL, targets, context, provenance,
                                      origin, identification_note, tie_justification, joint_generation,
                                      sampling_provenance, warmup_per_chain = NULL, thin = NULL) {
  regime <- match.arg(regime)
  .pr_assert(is.array(values) && is.numeric(values) && length(dim(values)) == 3L,
    "values must be a numeric S x n x K array", "invalid_builder_input")
  d <- dim(values); S <- d[1L]; n <- d[2L]; K <- d[3L]
  dn <- dimnames(values)
  .pr_assert(!is.null(dn) && !is.null(dn[[2L]]) && !is.null(dn[[3L]]),
    "values needs entity (2nd axis) and criterion (3rd axis) dimnames", "invalid_builder_input")
  entities <- as.character(dn[[2L]]); criteria <- as.character(dn[[3L]])
  slots <- if (is.null(dn[[1L]])) sprintf("draw_%06d", seq_len(S)) else as.character(dn[[1L]])
  storage.mode(values) <- "double"
  dimnames(values) <- list(draw = slots, entity = entities, criterion = criteria)
  if (is.data.frame(targets)) targets <- lapply(seq_len(nrow(targets)), function(r) as.list(targets[r, , drop = FALSE]))
  .pr_assert(is.list(targets) && length(targets) == K, "targets needs one record per criterion", "invalid_builder_input")
  required_target <- c("criterion_id", "estimand", "entity_population", "time_reference", "units")
  targets <- lapply(targets, function(z) {
    z <- lapply(z, function(v) if (is.factor(v)) as.character(v) else v)
    out <- .pr_builder_record(z, required_target, "targets")
    out$source_transform <- if (is.null(z$source_transform)) "identity" else .pr_builder_text(z$source_transform, "targets$source_transform")
    out$identification_basis <- if (is.null(z$identification_basis)) identification_note else .pr_builder_text(z$identification_basis, "targets$identification_basis")
    out$orientation <- "higher_priority"
    out
  })
  context <- .pr_builder_record(context, c("cohort_id", "data_version", "data_conditioning", "model_summary"), "context")
  value_hash <- digest::digest(values, algo = "sha256", serialize = TRUE)
  prov <- .pr_builder_record(provenance, c("producer", "artifact_id", "construction_note"), "provenance")
  prov$artifact_hash <- if (is.null(provenance$artifact_hash)) value_hash else .pr_builder_text(provenance$artifact_hash, "provenance$artifact_hash")
  prov$created_at <- if (is.null(provenance$created_at)) format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC") else
    .pr_builder_text(provenance$created_at, "provenance$created_at")
  orig <- .pr_builder_record(origin, c("source_id", "fit_id", "model_id", "source_format", "source_artifact"), "origin")
  orig$source_hash <- if (is.null(origin$source_hash)) value_hash else .pr_builder_text(origin$source_hash, "origin$source_hash")
  orig$vector_generation_provenance <- .pr_builder_text(joint_generation, "joint_generation")
  orig$within_criterion_joint_declared <- TRUE
  variable_map <- unlist(lapply(seq_len(K), function(k) lapply(seq_len(n), function(i)
    list(entity_id = entities[i], criterion_id = criteria[k], source_target_variable_id = sprintf("theta[%d,%d]", i, k),
      derivation_note = "Array coordinate (entity, criterion) of the supplied values; identity transform."))), recursive = FALSE)
  layout <- list(chains = chains, warmup_per_chain = warmup_per_chain, thin = thin)
  unset <- vapply(layout, is.null, logical(1L))
  if (identical(regime, "iid")) {
    .pr_assert(all(unset), "chains, warmup_per_chain and thin describe MCMC chains; leave them unset for IID draws",
      "invalid_builder_input")
    draw_index <- lapply(seq_len(S), function(s) list(slot_id = slots[s], original_draw_id = slots[s], chain_id = NULL, iteration = NULL))
    sampling <- list(regime = "iid", target_distribution = "declared_posterior", equal_weight = TRUE, warmup_status = "not_applicable",
      sampling_provenance = .pr_builder_text(sampling_provenance, "sampling_provenance"), chain_history = list())
  } else {
    .pr_assert(!any(unset), paste0("MCMC draws need explicit ", paste(names(layout)[unset], collapse = ", "),
      ": the number of chains, the warmup iterations removed before the retained draws on each chain and the ",
      "retained-iteration spacing are declarations and are not assumed"), "invalid_builder_input")
    for (a in layout) .pr_assert(typeof(a) %in% c("integer", "double") && length(a) == 1L && is.finite(a) && a == floor(a),
      "chains, warmup_per_chain and thin must be whole numbers", "invalid_builder_input")
    .pr_assert(chains >= 1L && warmup_per_chain >= 0L && thin >= 1L && S %% chains == 0L,
      "MCMC draws must split into equal chain-major blocks", "invalid_builder_input")
    L <- S %/% chains; ids <- sprintf("chain%d", seq_len(chains))
    iter <- warmup_per_chain + thin * seq_len(L)
    draw_index <- lapply(seq_len(S), function(s) list(slot_id = slots[s], original_draw_id = slots[s],
      chain_id = ids[(s - 1L) %/% L + 1L], iteration = iter[(s - 1L) %% L + 1L]))
    history <- lapply(ids, function(c) list(chain_id = c, retained_iterations = iter,
      warmup_iterations = if (warmup_per_chain > 0) seq_len(warmup_per_chain) else numeric(),
      discarded_sampling_iterations = setdiff(seq.int(warmup_per_chain + 1L, max(iter)), iter),
      selection_note = sprintf("Builder layout: %d warmup iterations removed, thinning %d.", as.integer(warmup_per_chain), as.integer(thin))))
    sampling <- list(regime = "mcmc", target_distribution = "declared_posterior", equal_weight = TRUE, warmup_status = "removed",
      sampling_provenance = .pr_builder_text(sampling_provenance, "sampling_provenance"), chain_history = history)
  }
  payload <- list(schema_version = "applied-0.1", input_kind = "equal_weight_draws", dependence_mode = "joint_model",
    requested_functional = "expected_rank_loss", entity_ids = entities, criterion_ids = criteria, targets = targets,
    context = context, identification = list(status = "identified_declared", note = .pr_builder_text(identification_note, "identification_note")),
    tie_policy = list(rule = "pairwise_tie_free", declared = TRUE, justification = .pr_builder_text(tie_justification, "tie_justification"),
      observed_tie_action = "reject_and_review"),
    provenance = prov,
    joint_draws = list(tensor = list(axis_order = c("draw", "entity", "criterion"), shape = list(S = S, n = n, K = K),
      dimnames = dimnames(values), values = values), origin = orig, sampling = sampling, draw_index = draw_index,
      variable_map = variable_map, cross_criterion_joint_provenance = orig$vector_generation_provenance))
  as_postrank_draws(payload)
}
