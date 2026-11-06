# Length-prefix keys preserve opaque IDs, including separator characters.
.pr_scoped_key <- function(parts) paste0(nchar(parts, type = "bytes"), ":", parts, collapse = "")

.pr_validate_cross_block_origins <- function(blocks) {
  sources <- new.env(parent = emptyenv()); fits <- new.env(parent = emptyenv())
  variables <- new.env(parent = emptyenv()); draws <- new.env(parent = emptyenv())
  regimes <- new.env(parent = emptyenv()); warmups <- new.env(parent = emptyenv())
  origin_fields <- c("source_id", "fit_id", "model_id", "source_format", "source_artifact",
                      "source_hash", "vector_generation_provenance", "within_criterion_joint_declared")
  for (j in seq_along(blocks)) {
    b <- blocks[[j]]; o <- b$origin; loc <- paste0("$.criterion_blocks[", j, "]")
    source_key <- .pr_scoped_key(o$source_id); fit_key <- .pr_scoped_key(o$fit_id)
    declaration <- unname(o[origin_fields])
    if (exists(source_key, sources, inherits = FALSE))
      .pr_assert(identical(get(source_key, sources), declaration), "repeated source_id has contradictory origin metadata", "inconsistent_origin", loc)
    else assign(source_key, declaration, sources)
    if (exists(fit_key, fits, inherits = FALSE))
      .pr_assert(identical(get(fit_key, fits), o$model_id), "repeated fit_id has contradictory model_id", "inconsistent_origin", loc)
    else assign(fit_key, o$model_id, fits)
    origin_key <- .pr_scoped_key(c(o$source_id, o$fit_id))
    if (exists(origin_key, regimes, inherits = FALSE))
      .pr_assert(identical(get(origin_key, regimes), b$sampling$regime), "same source fit declares contradictory sampling regimes", "inconsistent_origin", loc)
    else assign(origin_key, b$sampling$regime, regimes)
    for (v in b$variable_map) {
      key <- .pr_scoped_key(c(o$source_id, v$source_target_variable_id))
      .pr_assert(!exists(key, variables, inherits = FALSE), "source target-variable ID reused within an origin", "inconsistent_origin", loc)
      assign(key, TRUE, variables)
    }
    for (d in b$draw_index) {
      key <- .pr_scoped_key(c(o$source_id, o$fit_id, d$original_draw_id))
      identity <- list(chain_id = d$chain_id, iteration = if (is.null(d$iteration)) NULL else as.numeric(d$iteration),
                       regime = b$sampling$regime)
      if (exists(key, draws, inherits = FALSE))
        .pr_assert(identical(get(key, draws), identity), "repeated original draw ID has contradictory original coordinates", "inconsistent_origin", loc)
      else assign(key, identity, draws)
    }
    for (h in b$sampling$chain_history) {
      key <- .pr_scoped_key(c(o$fit_id, h$chain_id))
      history <- as.numeric(h$warmup_iterations)
      if (exists(key, warmups, inherits = FALSE))
        .pr_assert(identical(get(key, warmups), history), "same fit and chain declare contradictory warmup history", "inconsistent_origin", loc)
      else assign(key, history, warmups)
    }
  }
  invisible(TRUE)
}

.pr_validate_criterionwise <- function(x) {
  .pr_records(x$criterion_blocks, "$.criterion_blocks")
  .pr_assert(length(x$criterion_blocks) == length(x$criterion_ids),
             "criterion blocks must cover all criteria exactly once", path = "$.criterion_blocks")
  ids <- character(length(x$criterion_blocks))
  for (j in seq_along(x$criterion_blocks)) {
    b <- x$criterion_blocks[[j]]; path <- paste0("$.criterion_blocks[", j, "]")
    .pr_fields(b, c("criterion_id", "matrix", "origin", "sampling", "draw_index", "variable_map"), path = path)
    .pr_string(b$criterion_id, paste0(path, ".criterion_id")); ids[j] <- b$criterion_id
    .pr_assert(b$criterion_id %in% x$criterion_ids, "unknown block criterion", "invalid_id", path)
    .pr_validate_numeric_axes(b$matrix, c("draw", "entity"),
      list(draw = NULL, entity = x$entity_ids), paste0(path, ".matrix"))
    .pr_validate_tie_free(b$matrix$values, paste0(path, ".matrix.values"), FALSE)
    .pr_validate_origin_map(b, x$entity_ids, b$criterion_id, path)
    .pr_validate_history(b, b$matrix$shape$S, b$matrix$dimnames$draw, path)
  }
  .pr_ids(ids, path = "$.criterion_blocks.criterion_id")
  .pr_assert(setequal(ids, x$criterion_ids), "criterion block coverage differs from criterion IDs", path = "$.criterion_blocks")
  .pr_validate_cross_block_origins(x$criterion_blocks)
  invisible(TRUE)
}
