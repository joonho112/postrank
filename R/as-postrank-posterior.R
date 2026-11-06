#' Import Explicitly Mapped Posterior Draws
#'
#' This adapter maps a `posterior::draws_array` to the declared entities and
#' criteria, retaining its source history. Each imported target value is
#' compared with the corresponding source cell. Variable names are matched
#' through an explicit mapping; entity and criterion labels are not inferred
#' from those names.
#'
#' @param x A `posterior::draws_array` with iteration, chain and variable axes.
#'   The optional `posterior` package is required.
#' @param variable_map List of records containing `entity_id`, `criterion_id`,
#'   `source_target_variable_id` and `derivation_note`. Map each entity/criterion
#'   target once to a distinct source variable. Unused source variables are allowed.
#' @param metadata Complete canonical `applied-0.1` metadata for joint
#'   equal-weight draws, including the tensor shape and ordered IDs, target
#'   definitions, source records and sampling history. Tensor values may be
#'   omitted; if present, they must equal the mapped source values exactly.
#' @param source_coordinates One record per declared draw slot, containing
#'   `slot_id`, `iteration_index` and `chain_index`. Indices are positions in
#'   `x`, not original iteration numbers or chain IDs. Every source
#'   iteration-by-chain position must be used exactly once.
#' @return A validated `postrank_draws` object with
#'   `validation$source_values_checked = TRUE` and a `validation$source_audit`
#'   describing the mappings and comparisons performed.
#' @details
#' Source values must already be the higher-priority targets. No negation or
#' other numerical transformation is performed. The target array has shape
#' `S x n x K`, where `S` is the number of source iteration-by-chain positions;
#' `K = 1` retains its third axis.
#'
#' Original MCMC chain IDs and iteration numbers come from `metadata`, not
#' from the source axis labels. Each source chain must map to one distinct
#' declared chain, with original iterations increasing in source iteration
#' order. Preserve actual warmup, discarding and thinning history. For IID
#' input the source chain axis is only a container grouping and makes no
#' MCMC claim. [postrank_draws()] also accepts `posterior` data-frame and
#' matrix formats through `posterior::as_draws_array()`; a conversion cannot
#' recover a chain history that the export lost.
#'
#' The audit's `source_object_sha256` identifies serialized `unclass(x)`.
#' The separately retained origin `source_hash` may identify an external
#' file; this adapter does not verify that file's bytes. Source-value equality
#' verifies the conversion, not scientific jointness, identification or
#' convergence. Canonical declaration checks apply without the additional
#' placeholder-text checks of [postrank_declarations()].
#' @seealso [postrank_draws()], [postrank_draws_from_array()],
#'   [validate_postrank_draws()]
#' @concept input
#' @examples
#' if (requireNamespace("posterior", quietly = TRUE)) {
#'   # Re-express the unchanged bundled two-criterion IID sample.
#'   # Its original declarations apply because no values or law are replaced.
#'   metadata <- unclass(postrank_toy)
#'   metadata$schema_version <- metadata$input_schema_version
#'   metadata$input_schema_version <- metadata$validation <- NULL
#'   a <- metadata$joint_draws$tensor$values
#'   map <- metadata$joint_draws$variable_map
#'   variable_ids <- vapply(map, `[[`, character(1), "source_target_variable_id")
#'   source_array <- array(as.numeric(a), c(dim(a)[1], 1, length(map)),
#'     dimnames = list(iteration = as.character(seq_len(dim(a)[1])),
#'       chain = "1", variable = variable_ids))
#'   source_draws <- posterior::as_draws_array(source_array)
#'   coordinates <- lapply(seq_len(dim(a)[1]), function(s)
#'     list(slot_id = dimnames(a)$draw[s], iteration_index = s, chain_index = 1L))
#'   imported <- as_postrank_posterior(source_draws, map, metadata, coordinates)
#'   imported$validation$source_values_checked
#'   identical(imported$joint_draws$tensor$values, a)
#' }
#' @export
as_postrank_posterior <- function(x, variable_map, metadata, source_coordinates) {
  .pr_assert(requireNamespace("posterior", quietly = TRUE),
    "the optional posterior package is required for this adapter", "missing_dependency")
  .pr_assert(posterior::is_draws_array(x), "x must be posterior::draws_array",
    "unsupported_source", "$.source")
  source_shape <- dim(x)
  source_names <- dimnames(x)
  .pr_assert(length(source_shape) == 3L && all(source_shape >= 1L) &&
    identical(names(source_names), c("iteration", "chain", "variable")),
    "source requires explicit iteration/chain/variable axes", "invalid_source_shape", "$.source")
  .pr_ids(source_names$variable, 1L, "$.source.variable_ids")
  .pr_assert(is.list(metadata) && !inherits(metadata, "postrank_draws"),
    "metadata must be a canonical applied-0.1 named-list payload", path = "$.metadata")
  .pr_assert(identical(metadata$schema_version, "applied-0.1") &&
    identical(metadata$input_kind, "equal_weight_draws") &&
    identical(metadata$dependence_mode, "joint_model"),
    "posterior adapter requires joint equal-weight applied-0.1 metadata",
    "unsupported_input", "$.metadata")
  .pr_ids(metadata$entity_ids, 2L, "$.metadata.entity_ids")
  .pr_ids(metadata$criterion_ids, 1L, "$.metadata.criterion_ids")
  joint <- metadata$joint_draws
  .pr_assert(is.list(joint) && is.list(joint$tensor),
    "joint tensor declarations are required", path = "$.metadata.joint_draws")
  tensor <- joint$tensor
  S <- prod(as.double(source_shape[1:2]))
  n <- length(metadata$entity_ids)
  K <- length(metadata$criterion_ids)
  .pr_assert(S <= .Machine$integer.max, "source draw count exceeds supported array size",
    "invalid_source_shape", "$.source")
  .pr_assert(identical(tensor$axis_order, c("draw", "entity", "criterion")) &&
    is.list(tensor$shape) && setequal(names(tensor$shape), c("S", "n", "K")) &&
    isTRUE(tensor$shape$S == S) && isTRUE(tensor$shape$n == n) && isTRUE(tensor$shape$K == K),
    "declared tensor shape must equal all source iteration/chain positions and declared targets",
    "invalid_shape", "$.metadata.joint_draws.tensor")
  .pr_assert(is.list(tensor$dimnames) &&
    setequal(names(tensor$dimnames), c("draw", "entity", "criterion")) &&
    identical(tensor$dimnames$entity, metadata$entity_ids) &&
    identical(tensor$dimnames$criterion, metadata$criterion_ids),
    "declared tensor dimnames must equal ordered target IDs", "invalid_dimnames",
    "$.metadata.joint_draws.tensor.dimnames")
  slots <- tensor$dimnames$draw
  .pr_ids(slots, 1L, "$.metadata.joint_draws.tensor.dimnames.draw")
  .pr_assert(length(slots) == S, "draw slots must cover every source position", "invalid_shape")

  .pr_records(variable_map, "$.variable_map")
  .pr_assert(length(variable_map) == n * K, "variable_map must have n*K records",
    "invalid_variable_map", "$.variable_map")
  map_entity <- map_criterion <- map_variable <- character(length(variable_map))
  map_fields <- c("entity_id", "criterion_id", "source_target_variable_id", "derivation_note")
  for (m in seq_along(variable_map)) {
    z <- variable_map[[m]]
    path <- paste0("$.variable_map[", m, "]")
    .pr_fields(z, map_fields, path = path)
    for (field in map_fields) .pr_string(z[[field]], paste0(path, ".", field))
    map_entity[[m]] <- z$entity_id
    map_criterion[[m]] <- z$criterion_id
    map_variable[[m]] <- z$source_target_variable_id
  }
  .pr_assert(all(map_entity %in% metadata$entity_ids) && all(map_criterion %in% metadata$criterion_ids),
    "map contains unknown target IDs", "invalid_variable_map", "$.variable_map")
  .pr_assert(!anyDuplicated(map_variable) && all(map_variable %in% source_names$variable),
    "map variables must be unique and present in the source", "invalid_variable_map", "$.variable_map")
  target_positions <- match(map_entity, metadata$entity_ids) + n * (match(map_criterion, metadata$criterion_ids) - 1L)
  .pr_assert(!anyDuplicated(target_positions) && setequal(target_positions, seq_len(n * K)),
    "map must cover every entity/criterion target exactly once", "invalid_variable_map", "$.variable_map")
  # If metadata already declares a map, only record order may differ.
  if (!is.null(joint$variable_map)) {
    .pr_records(joint$variable_map, "$.metadata.joint_draws.variable_map")
    .pr_assert(length(joint$variable_map) == length(variable_map) &&
      all(vapply(variable_map, function(z) any(vapply(joint$variable_map,
        function(w) identical(unname(w[map_fields]), unname(z[map_fields])), logical(1L))), logical(1L))),
      "metadata variable_map contradicts the supplied explicit map", "invalid_variable_map")
  }

  .pr_records(source_coordinates, "$.source_coordinates")
  .pr_assert(length(source_coordinates) == S, "one coordinate per declared draw slot is required",
    "invalid_source_coordinates", "$.source_coordinates")
  coordinate_slots <- character(S)
  iteration_positions <- chain_positions <- integer(S)
  for (s in seq_len(S)) {
    z <- source_coordinates[[s]]
    path <- paste0("$.source_coordinates[", s, "]")
    .pr_fields(z, c("slot_id", "iteration_index", "chain_index"), path = path)
    .pr_string(z$slot_id, paste0(path, ".slot_id"))
    for (field in c("iteration_index", "chain_index")) {
      .pr_safe_integer(z[[field]], positive = TRUE, path = paste0(path, ".", field))
      .pr_assert(length(z[[field]]) == 1L && is.null(dim(z[[field]])),
        "coordinate indices must be scalars", path = path)
    }
    .pr_assert(z$iteration_index <= source_shape[[1L]] && z$chain_index <= source_shape[[2L]],
      "coordinate index is outside source axes", "invalid_source_coordinates", path)
    coordinate_slots[[s]] <- z$slot_id
    iteration_positions[[s]] <- as.integer(z$iteration_index)
    chain_positions[[s]] <- as.integer(z$chain_index)
  }
  .pr_assert(!anyDuplicated(coordinate_slots) && setequal(coordinate_slots, slots),
    "coordinate slots must cover declared tensor slots exactly once", "invalid_source_coordinates")
  source_positions <- iteration_positions + source_shape[[1L]] * (chain_positions - 1L)
  .pr_assert(!anyDuplicated(source_positions) && setequal(source_positions, seq_len(S)),
    "coordinates must cover every source iteration/chain position exactly once",
    "invalid_source_coordinates")
  row_order <- match(slots, coordinate_slots)
  iteration_by_row <- iteration_positions[row_order]
  chain_by_row <- chain_positions[row_order]
  values <- array(NA_real_, dim = c(S, n, K),
    dimnames = tensor$dimnames[c("draw", "entity", "criterion")])
  for (m in seq_along(variable_map)) {
    i <- match(map_entity[[m]], metadata$entity_ids)
    k <- match(map_criterion[[m]], metadata$criterion_ids)
    v <- match(map_variable[[m]], source_names$variable)
    for (s in seq_len(S)) values[s, i, k] <- x[iteration_by_row[[s]], chain_by_row[[s]], v]
  }
  if (!is.null(tensor$values)) {
    .pr_assert(is.numeric(tensor$values) && identical(dim(tensor$values), dim(values)) &&
      identical(dimnames(tensor$values), dimnames(values)) &&
      identical(as.numeric(tensor$values), as.numeric(values)),
      "metadata tensor values disagree with explicitly mapped source cells",
      "source_value_mismatch", "$.metadata.joint_draws.tensor.values")
  }
  metadata$joint_draws$tensor$values <- values
  metadata$joint_draws$variable_map <- variable_map
  result <- as_postrank_draws(metadata)

  index_slots <- vapply(metadata$joint_draws$draw_index, `[[`, character(1L), "slot_id")
  index_by_row <- metadata$joint_draws$draw_index[match(slots, index_slots)]
  source_chain_mapping <- list()
  if (identical(metadata$joint_draws$sampling$regime, "mcmc")) {
    declared_chain_by_source <- character(source_shape[[2L]])
    for (chain in seq_len(source_shape[[2L]])) {
      rows <- which(chain_by_row == chain)
      rows <- rows[order(iteration_by_row[rows])]
      ids <- vapply(index_by_row[rows], `[[`, character(1L), "chain_id")
      original_iterations <- vapply(index_by_row[rows], function(z) as.numeric(z$iteration), numeric(1L))
      .pr_assert(length(unique(ids)) == 1L && all(diff(original_iterations) > 0),
        "source chain must map to one declared chain with increasing original iterations",
        "source_history_mismatch", "$.source_coordinates")
      declared_chain_by_source[[chain]] <- ids[[1L]]
      source_chain_mapping[[chain]] <- list(source_chain_index = chain,
        source_chain_axis_label = source_names$chain[[chain]], declared_chain_id = ids[[1L]],
        original_iterations_in_source_order = original_iterations)
    }
    .pr_assert(!anyDuplicated(declared_chain_by_source),
      "distinct source chains must map to distinct declared chains", "source_history_mismatch")
  }
  cells_checked <- 0
  for (m in seq_along(variable_map)) {
    i <- match(map_entity[[m]], metadata$entity_ids)
    k <- match(map_criterion[[m]], metadata$criterion_ids)
    v <- match(map_variable[[m]], source_names$variable)
    for (s in seq_len(S)) {
      .pr_assert(identical(as.numeric(result$joint_draws$tensor$values[s, i, k]),
        as.numeric(x[iteration_by_row[[s]], chain_by_row[[s]], v])),
        "post-conversion source cell comparison failed", "source_value_mismatch")
      cells_checked <- cells_checked + 1
    }
  }
  result$validation$source_values_checked <- TRUE
  result$validation$check_results$source_values <- "passed"
  result$validation$source_audit <- list(adapter = "as_postrank_posterior", adapter_version = "0.1.0",
    source_object_sha256 = digest::digest(unclass(x), algo = "sha256"),
    source_object_hash_identity = "R serialized unclass(x); distinct from raw CSV/file bytes",
    provided_source_declaration = metadata$joint_draws$origin,
    external_source_hash_verified = FALSE,
    source_shape = unname(source_shape), source_dimnames = source_names,
    variable_map = variable_map, unused_variable_ids = setdiff(source_names$variable, map_variable),
    source_coordinates = source_coordinates, source_chain_mapping = source_chain_mapping,
    coordinate_interpretation = "Indices are source-array axis positions; original identities come only from supplied draw_index/history",
    source_chain_axis_interpretation = if (identical(metadata$joint_draws$sampling$regime, "mcmc"))
      "Each source chain mapped to one distinct declared MCMC chain with ordered original iterations" else
      "IID container grouping only; source chain axis does not establish MCMC sampling",
    source_cells_checked = cells_checked, complete_source_draws_checked = S,
    limitations = c("External source artifact/hash declarations are retained but not verified against file bytes.",
      "Source-value equality verifies this conversion only; it does not verify scientific jointness, provenance truth or convergence."))
  result
}
