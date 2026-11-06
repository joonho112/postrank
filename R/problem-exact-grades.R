.pr_add_exact_grades <- function(base, pairwise, settings) {
  if (is.null(settings$exact_G)) return(base)
  n <- length(pairwise$entity_ids); G <- as.integer(settings$exact_G)
  .pr_assert(G >= 1L && G <= n, "exact_G must be between one and the entity count", "invalid_exact_grade_count")
  model <- base$model; old_variables <- length(model$objective); new_variables <- n * G
  # Entity-major variable storage; the explicit matrix is the stable lookup.
  assignment <- matrix(old_variables + seq_len(new_variables), nrow = n, ncol = G, byrow = TRUE,
    dimnames = list(entity = pairwise$entity_ids, grade = as.character(seq_len(G))))
  entity_rows <- rep(seq_len(n), each = G)
  entity_major <- as.vector(t(assignment))
  grade_major <- as.vector(assignment)
  constraints <- Matrix::sparseMatrix(
    i = c(entity_rows, n + seq_len(n), n + entity_rows, 2L * n + rep(seq_len(G), each = n)),
    j = c(entity_major, base$index$labels, entity_major, grade_major),
    x = c(rep(1, new_variables), rep(1, n), -rep(seq_len(G), times = n), rep(1, new_variables)),
    dims = c(2L * n + G, old_variables + new_variables))
  old_expanded <- cbind(model$A, Matrix::sparseMatrix(i = integer(), j = integer(), dims = c(nrow(model$A), new_variables)))
  model$A <- methods::as(rbind(old_expanded, constraints), "CsparseMatrix")
  model$objective <- c(model$objective, rep(0, new_variables))
  model$var_lower <- c(model$var_lower, rep(0, new_variables))
  model$var_upper <- c(model$var_upper, rep(1, new_variables))
  model$types <- c(model$types, rep("B", new_variables))
  model$var_names <- c(model$var_names, paste0("assignment_", rep(seq_len(n), each = G), "_", rep(seq_len(G), times = n)))
  model$row_lower <- c(model$row_lower, rep(1, n), rep(0, n), rep(1, G))
  model$row_upper <- c(model$row_upper, rep(1, n), rep(0, n), rep(Inf, G))
  model$row_names <- c(model$row_names, paste0("exact_onehot_entity_", seq_len(n)),
    paste0("exact_label_link_entity_", seq_len(n)), paste0("exact_nonempty_grade_", seq_len(G)))
  base$model <- model; base$index$assignment <- assignment
  base
}
