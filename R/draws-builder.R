# Array input builder: the eight scientific declarations remain required
# arguments while slot IDs, draw indices, variable maps, chain history, and
# content hashes are derived from the array and its declared layout.

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
#' `postrank_draws_from_array()` builds a `postrank_draws` object from a
#' numeric `S x n x K` array of joint posterior draws and its eight required
#' descriptions, generating draw IDs, variable mappings, MCMC chain histories
#' and array SHA-256 hashes before validating with [as_postrank_draws()]. Most
#' users can call [postrank_draws()] with [postrank_describe()] instead.
#'
#' @param values Numeric `S x n x K` array (draws x entities x criteria) with
#'   entity (2nd axis) and criterion (3rd axis) `dimnames`. Keep the third axis
#'   `S x n x 1` when `K = 1`. Larger values must already mean higher priority;
#'   this function does not negate criteria. Draw names on the 1st axis are
#'   generated (`"draw_000001"`, ...) when absent.
#' @param regime `"iid"` (the default) or `"mcmc"`.
#' @param chains Number of original MCMC chains when `regime = "mcmc"`
#'   (required; `S` must be divisible by `chains`, with rows ordered chain by
#'   chain). Leave `NULL` when `regime = "iid"`.
#' @param targets One record per criterion, as a data frame or a list of named
#'   lists. Required fields are `criterion_id`, `estimand`,
#'   `entity_population`, `time_reference` and `units`. Optional
#'   `source_transform` defaults to `"identity"` and `identification_basis`
#'   defaults to `identification_note`.
#' @param context Named list with `cohort_id`, `data_version`,
#'   `data_conditioning` and `model_summary`.
#' @param provenance Named list with `producer`, `artifact_id` and
#'   `construction_note`. Optional `artifact_hash` defaults to the SHA-256 of
#'   `values`, and `created_at` defaults to the current UTC timestamp.
#' @param origin Named list with `source_id`, `fit_id`, `model_id`,
#'   `source_format` and `source_artifact`. Optional `source_hash` defaults to
#'   the SHA-256 of `values`.
#' @param identification_note One non-empty string explaining why each target
#'   is identified.
#' @param tie_justification One non-empty string explaining why distinct
#'   entities have zero probability of exact equality on each criterion.
#'   Observed ties in `values` still stop the call.
#' @param joint_generation One non-empty string explaining how each draw holds
#'   all entities and criteria together, preserving model dependence.
#' @param sampling_provenance One non-empty string describing how the retained
#'   draws were produced.
#' @param warmup_per_chain Number of warmup iterations removed per chain before
#'   the retained draws when `regime = "mcmc"` (`0L` if none; leave `NULL` when
#'   `regime = "iid"`).
#' @param thin Iteration spacing between retained draws when `regime = "mcmc"`
#'   (`1L` if unthinned; leave `NULL` when `regime = "iid"`).
#' @returns A validated `postrank_draws` object storing `values`, ordered
#'   `entity_ids` and `criterion_ids`, the supplied descriptions, generated
#'   draw indices and variable mappings, and a `validation` record.
#' @details
#' When `regime = "mcmc"`, `chains`, `warmup_per_chain` and `thin` are all
#' required, and retained iteration numbers within each chain are recorded as
#' `warmup_per_chain + thin * seq_len(S / chains)`. For irregular chain lengths
#' or custom iteration numbers, pass full `applied-0.1` metadata to
#' [as_postrank_draws()] or [as_postrank_posterior()]; do not split one MCMC
#' chain into artificial chains.
#'
#' `postrank_draws_from_array()` checks that all required strings are present
#' and non-empty, whereas [postrank_declarations()] and the array route of
#' [postrank_draws()] also reject generic placeholder words such as `"TBD"`.
#' Validation checks structure and presence of descriptions, not scientific
#' identification, jointness or MCMC convergence, and generated SHA-256 hashes
#' identify the in-memory `values` array rather than an external file.
#'
#' To negate lower-is-higher criteria automatically, use the `orientation`
#' argument of [postrank_draws()]. For posteriors with positive probability of
#' exact ties, use [as_postrank_tie_draws()].
#' @seealso [postrank_draws()], [postrank_describe()],
#'   [postrank_declarations()], [as_postrank_draws()]
#' @concept input
#' @examples
#' # Rebuild the bundled two-criterion IID toy array from its stored fields:
#' x <- postrank_toy
#' b <- x$joint_draws
#' draws <- postrank_draws_from_array(b$tensor$values, regime = "iid",
#'   targets = x$targets, context = x$context, provenance = x$provenance,
#'   origin = b$origin, identification_note = x$identification$note,
#'   tie_justification = x$tie_policy$justification,
#'   joint_generation = b$cross_criterion_joint_provenance,
#'   sampling_provenance = b$sampling$sampling_provenance)
#' identical(draws$joint_draws$tensor$values, b$tensor$values)
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
