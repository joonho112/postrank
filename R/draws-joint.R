# Numeric storage is checked without coercion, sorting or singleton-axis drop.
.pr_validate_numeric_axes <- function(spec, axes, ids, path) {
  .pr_fields(spec, c("axis_order", "shape", "dimnames", "values"), path = path)
  .pr_assert(identical(spec$axis_order, axes), "axis_order differs from canonical order", path = path)
  shape_names <- c(draw = "S", entity = "n", criterion = "K")[axes]
  .pr_fields(spec$shape, unname(shape_names), path = paste0(path, ".shape"))
  .pr_fields(spec$dimnames, axes, path = paste0(path, ".dimnames"))
  shape <- numeric(length(axes))
  for (a in seq_along(axes)) {
    z <- spec$shape[[shape_names[a]]]
    .pr_assert(typeof(z) %in% c("integer", "double") && length(z) == 1L && is.null(dim(z)),
               "shape entries must be scalar integers", path = paste0(path, ".shape"))
    .pr_safe_integer(z, TRUE, paste0(path, ".shape.", shape_names[a]))
    .pr_ids(spec$dimnames[[axes[a]]], if (axes[a] == "entity") 2L else 1L,
            paste0(path, ".dimnames.", axes[a]))
    .pr_assert(length(spec$dimnames[[axes[a]]]) == z,
               "shape differs from dimname length", path = path)
    if (!is.null(ids[[axes[a]]]))
      .pr_assert(identical(spec$dimnames[[axes[a]]], ids[[axes[a]]]),
                 "dimnames differ from declared ID order", "invalid_id", path)
    shape[a] <- z
  }
  values <- spec$values
  .pr_assert(typeof(values) %in% c("integer", "double") &&
               length(dim(values)) == length(axes) && all(dim(values) == shape),
             "numeric values must retain exactly the declared dimensions", "invalid_shape", path)
  .pr_assert(!anyNA(values) && all(is.finite(values)), "nonfinite or missing target cell", "nonfinite_target", path)
  .pr_assert(identical(names(dimnames(values)), axes), "values require named canonical dimnames", "invalid_shape", path)
  for (a in seq_along(axes))
    .pr_assert(identical(dimnames(values)[[a]], spec$dimnames[[axes[a]]]),
               "values dimnames differ from declared dimnames", "invalid_id", path)
  invisible(TRUE)
}

.pr_validate_tie_free <- function(values, path, tensor = TRUE) {
  K <- if (tensor) dim(values)[3L] else 1L
  slice <- function(s, k) if (tensor) values[s, , k] else values[s, ]
  count <- 0L; first <- NULL
  for (k in seq_len(K)) for (s in seq_len(dim(values)[1L])) {
    v <- slice(s, k); dup <- anyDuplicated(v)
    if (dup) {
      count <- count + 1L
      if (is.null(first)) first <- c(s = s, k = k, i = unname(which(v == v[dup])[1L]), j = dup)
    }
  }
  if (count) {
    label <- function(axis, index) {
      ids <- dimnames(values)[[axis]]
      if (is.null(ids)) as.character(index) else ids[index]
    }
    where <- sprintf("first at draw %s%s, entities %s and %s", label(1L, first[["s"]]),
      if (tensor) paste0(", criterion ", label(3L, first[["k"]])) else "",
      label(2L, first[["i"]]), label(2L, first[["j"]]))
    .pr_abort(paste0("within-criterion entity tie in ", count, " draw-criterion slice(s) (", where,
      "); exact ties are rejected and no jitter is applied. For a continuous posterior this usually means",
      " reduced output precision (e.g. CmdStan sig_figs=6): re-export the draws at full precision",
      " (e.g. sig_figs=18). Discrete-support posteriors with ties are not supported in this version."),
      "observed_target_tie", path)
  }
  invisible(TRUE)
}

.pr_validate_joint <- function(x) {
  path <- "$.joint_draws"; block <- x$joint_draws
  .pr_fields(block, c("tensor", "origin", "sampling", "draw_index", "variable_map",
                      "cross_criterion_joint_provenance"), path = path)
  .pr_validate_numeric_axes(block$tensor, c("draw", "entity", "criterion"),
    list(draw = NULL, entity = x$entity_ids, criterion = x$criterion_ids), paste0(path, ".tensor"))
  .pr_validate_tie_free(block$tensor$values, paste0(path, ".tensor.values"))
  .pr_string(block$cross_criterion_joint_provenance, paste0(path, ".cross_criterion_joint_provenance"))
  .pr_validate_origin_map(block, x$entity_ids, x$criterion_ids, path)
  .pr_validate_history(block, block$tensor$shape$S, block$tensor$dimnames$draw, path)
  invisible(TRUE)
}
