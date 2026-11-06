# Pair-probability summary validator. Source input.R first for shared helpers.
p2_validate_pair_summary <- function(spec, common) {
  if (!identical(common$layout, "pairwise_summary") ||
      !identical(unname(common$representation), "pairwise_probability_summary"))
    p2_input_error("Pair summaries require pairwise_summary layout and representation")
  if (!isTRUE(common$intended_law$proper_law))
    p2_input_error("Pair summaries require declared proper-law provenance; unvalidated coefficient mode is unsupported")
  if (!is.null(spec$payloads) && (!is.list(spec$payloads) || length(spec$payloads)))
    p2_input_error("Pair summaries cannot contain state payloads")
  raw <- spec$pair_summary
  if (!is.list(raw) || !p2_nonempty_string(raw$encoding) ||
      !raw$encoding %in% c("two_strict", "strict_plus_equality"))
    p2_input_error("Pair summary encoding must be two_strict or strict_plus_equality")
  if (!identical(raw$identity_compatibility, "asserted_exact"))
    p2_input_error("Pair identity_compatibility must be asserted_exact; unresolved approximate identity is not a pass")
  tab <- raw$data
  prob_cols <- if (raw$encoding == "two_strict") c("p_i_gt_j", "p_j_gt_i") else c("p_i_gt_j", "p_equal")
  required <- c("unit_i", "unit_j", "domain_id", prob_cols)
  if (!is.data.frame(tab) || anyDuplicated(names(tab)) ||
      !setequal(names(tab), required) || length(names(tab)) != length(required))
    p2_input_error("Pair summary data must be a data frame with exactly the ID and designated probability columns")
  expected_rows <- common$n * (common$n - 1) / 2 * common$D
  if (nrow(tab) != expected_rows)
    p2_input_error("Pair summary requires exactly one row for every unordered pair/domain; missing or extra rows")
  for (field in c("unit_i", "unit_j", "domain_id")) {
    z <- tab[[field]]
    if (!is.character(z) || !is.null(dim(z)) || length(z) != nrow(tab) ||
        anyNA(z) || any(!nzchar(trimws(z)))) p2_input_error("Pair summary IDs must be nonempty character vectors")
  }
  i <- match(tab$unit_i, common$unit_ids)
  j <- match(tab$unit_j, common$unit_ids)
  d <- match(tab$domain_id, common$domain_ids)
  if (anyNA(i) || anyNA(j) || anyNA(d)) p2_input_error("Pair summary contains unknown unit or domain IDs")
  if (any(i == j)) p2_input_error("Pair summary must not contain self pairs")
  keys <- paste(d, pmin(i,j), pmax(i,j), sep=":")
  if (anyDuplicated(keys)) p2_input_error("Duplicate unordered pair/domain, including reversed duplicate rows")
  for (field in prob_cols) {
    z <- tab[[field]]
    if (!is.numeric(z) || is.complex(z) || !is.null(dim(z)) ||
        length(z) != nrow(tab) || any(!is.finite(z)) || any(z < 0 | z > 1))
      p2_input_error("Pair probabilities must be finite numeric vectors in [0,1]; no clipping")
  }
  tolerance <- if (is.null(raw$consistency_tolerance)) 1e-12 else raw$consistency_tolerance
  if (!is.numeric(tolerance) || is.complex(tolerance) || !is.null(dim(tolerance)) ||
      length(tolerance) != 1L || !is.finite(tolerance) || tolerance < 0)
    p2_input_error("Pair consistency tolerance must be finite and nonnegative")
  p <- tab$p_i_gt_j
  supplied_other <- tab[[prob_cols[[2L]]]]
  missing_probability <- vapply(seq_along(p), function(k)
    1-p2_compensated_sum(c(p[[k]], supplied_other[[k]])), numeric(1))
  if (any(missing_probability < 0 | missing_probability > 1))
    p2_input_error("Derived probability outside [0,1]; declared tolerance cannot repair probabilities")
  if (raw$encoding == "two_strict") {
    opposite <- supplied_other; equality <- missing_probability
  } else {
    opposite <- missing_probability; equality <- supplied_other
  }
  residual <- vapply(seq_along(p), function(k)
    p2_compensated_sum(c(p[[k]], opposite[[k]], equality[[k]]))-1, numeric(1))
  if (any(abs(residual) > tolerance)) p2_input_error("Pair probability total fails numeric consistency tolerance")
  identity <- vapply(seq_along(i), function(k) {
    cl <- common$equality_classes[[d[[k]]]]
    cl[[i[[k]]]] == cl[[j[[k]]]]
  }, logical(1))
  if (any(identity & (p != 0 | opposite != 0 | equality != 1)))
    p2_input_error("Structural equality incompatible: identity pairs require exact strict 0/0 and equality 1, regardless of loss weight")
  dims <- c(common$n, common$n, common$D)
  dn <- list(common$unit_ids, common$unit_ids, common$domain_ids)
  p_gt <- array(0, dims, dimnames=dn)
  p_equal <- array(0, dims, dimnames=dn)
  for (domain in seq_len(common$D)) for (unit in seq_len(common$n)) p_equal[unit,unit,domain] <- 1
  for (k in seq_along(i)) {
    p_gt[i[[k]],j[[k]],d[[k]]] <- p[[k]]
    p_gt[j[[k]],i[[k]],d[[k]]] <- opposite[[k]]
    p_equal[i[[k]],j[[k]],d[[k]]] <- equality[[k]]
    p_equal[j[[k]],i[[k]],d[[k]]] <- equality[[k]]
  }
  # Necessary only: a directed cycle of probability-one strict inequalities is impossible.
  for (domain in seq_len(common$D)) {
    edge <- matrix(p_gt[,,domain] == 1, common$n, common$n)
    indegree <- colSums(edge)
    queue <- which(indegree == 0L); done <- 0L; head <- 1L
    while (head <= length(queue)) {
      vertex <- queue[[head]]; head <- head+1L; done <- done+1L
      successors <- which(edge[vertex,])
      if (length(successors)) {
        indegree[successors] <- indegree[successors]-1L
        queue <- c(queue, successors[indegree[successors] == 0L])
      }
    }
    if (done != common$n) p2_input_error("Impossible probability-one strict cycle; local checks do not establish global compatibility")
  }
  hash <- common$provenance$pair_summary_hash
  absent_hash <- is.null(hash) || !length(hash) ||
    (is.atomic(hash) && length(hash) == 1L && is.na(hash))
  if (absent_hash) p2_metadata(NULL, "provenance.pair_summary_hash", common$missing_metadata)
  else if (!p2_nonempty_string(hash) || !grepl("^[0-9a-fA-F]{64}$", hash))
    p2_input_error("Invalid pair_summary_hash SHA-256")
  actual_hash <- p2_hash(tab)
  if (!absent_hash && !identical(tolower(hash), actual_hash))
    p2_input_error("Declared pair_summary_hash differs from raw summary data hash")
  receipt <- list(raw_data_hash=actual_hash, declared_data_hash=hash,
    encoding=raw$encoding, probability_arithmetic="stored_numeric_probabilities; floating_complement_derivation",
    derived_rule=if (raw$encoding == "two_strict") "p_equal = 1 - compensated_sum(p_i_gt_j,p_j_gt_i)" else "p_j_gt_i = 1 - compensated_sum(p_i_gt_j,p_equal)",
    consistency_tolerance=tolerance, maximum_absolute_total_residual=max(abs(residual)),
    normalized=FALSE, clipped=FALSE, raw_row_order_preserved=TRUE,
    identity_pair_rows_checked=which(identity), identity_compatibility="asserted_exact",
    probability_one_cycle_check=TRUE, global_summary_compatibility_established=FALSE,
    scientific_identity_established_by_summary_check=FALSE, numerical_guarantee=FALSE)
  input <- common
  input$payloads <- list()
  input$pair_summary <- list(p_gt=p_gt, p_equal=p_equal, encoding=raw$encoding,
                            raw_data=tab, receipt=receipt)
  input$capabilities <- list(expected_additive=TRUE, expected_counts=TRUE,
    within_domain_tails=character(), direct_joint=FALSE, joint_domains=character(),
    cross_domain_bundles=FALSE, numerical_guarantee=FALSE,
    global_summary_compatibility_established=FALSE)
  input$receipts <- list(no_implicit_alignment=TRUE, no_product_adapter_performed=TRUE,
    missing_metadata=common$missing_metadata, source_spec_hash=p2_hash(spec),
    summary=receipt, sampling_status="probability_summary_not_joint_states_or_numerical_certificate")
  class(input) <- c("p2_profile_input", "list")
  input
}
