# Bounded, explicit candidate banks; these constructors do not optimize or certify MC.
p2_candidate_dependencies <- function() {
  dependency_environment <- environment()
  needed <- c("p2_hash", "p2_ids", "p2_integer_scalar", "p2_nonempty_string", "p2_validate_action")
  if (!all(vapply(needed, function(z) exists(z, envir = dependency_environment,
      mode = "function", inherits = TRUE), logical(1))))
    stop("Source input.R and action.R before candidates.R", call. = FALSE)
}
p2_candidate_error <- function(x) stop(x, call. = FALSE)
p2_candidate_provenance <- function(x, input) {
  if (!is.list(x)) p2_candidate_error("provenance must be an explicit list")
  for (field in c("construction_method", "source_input_hash", "selection_validation_relationship"))
    if (!p2_nonempty_string(x[[field]])) p2_candidate_error(paste("provenance requires", field))
  if (!identical(x$source_input_hash, p2_hash(input$original_spec)))
    p2_candidate_error("provenance source_input_hash does not match construction input")
  x$source_ids <- p2_ids(x$source_ids, length(x$source_ids), "provenance source_ids")
  if (!length(x$source_ids)) p2_candidate_error("provenance source_ids must not be empty")
  x$construction_draw_ids <- p2_ids(x$construction_draw_ids,
    length(x$construction_draw_ids), "provenance construction_draw_ids (character(0) is allowed)")
  h <- x$source_artifact_hashes
  if (!is.character(h) || !is.null(dim(h)) || anyNA(h) ||
      (length(h) && (is.null(names(h)) || anyDuplicated(names(h)) || any(!nzchar(names(h))) ||
                     any(!grepl("^[0-9a-f]{64}$", h)))))
    p2_candidate_error("source_artifact_hashes must be a named SHA256 vector; character(0) is allowed")
  if (length(h)) x$source_artifact_hashes <- h[order(names(h))]
  flags <- c("order", "seeds", "cut_positions", "configuration")
  if (!is.logical(x$sample_adaptive) || !identical(names(x$sample_adaptive), flags) ||
      length(x$sample_adaptive) != 4L || anyNA(x$sample_adaptive))
    p2_candidate_error("sample_adaptive must name logical order, seeds, cut_positions, configuration in order")
  for (field in c("depends_on_y", "fixed_universe_claim"))
    if (!is.logical(x[[field]]) || length(x[[field]]) != 1L || is.na(x[[field]]))
      p2_candidate_error(paste("provenance requires scalar logical", field))
  if (x$fixed_universe_claim && any(x$sample_adaptive))
    p2_candidate_error("fixed_universe_claim is inconsistent with sample-adaptive construction")
  if (x$fixed_universe_claim && !p2_nonempty_string(x$fixed_universe_justification))
    p2_candidate_error("fixed_universe_claim requires fixed_universe_justification")
  x
}
p2_candidate_partition_count <- function(m, k) {
  coefficient <- total <- gmp::as.bigz(1)
  if (k > 0L) for (j in seq_len(k)) {
    coefficient <- (coefficient * (m - j + 1L)) %/% j
    total <- total + coefficient
  }
  total
}
p2_candidate_integrity_hash <- function(bank) {
  content <- unclass(bank)
  content$bank_id <- NULL
  content$bank_hash <- NULL
  p2_hash(content)
}

p2_build_domain_bank <- function(input, domain_id, order = NULL,
    cut_positions = integer(), max_grades = NULL, seeds = list(),
    max_bank_entries = 1000L, provenance) {
  p2_candidate_dependencies()
  if (!inherits(input, "p2_profile_input")) p2_candidate_error("input must be validated p2_profile_input")
  if (!p2_nonempty_string(domain_id) || !domain_id %in% input$domain_ids)
    p2_candidate_error("domain_id must name one input domain")
  n <- input$n
  cap <- if (is.null(max_grades)) n else p2_integer_scalar(max_grades, 1, "max_grades")
  cap <- min(cap, n)
  limit <- p2_integer_scalar(max_bank_entries, 1, "max_bank_entries")
  provenance <- p2_candidate_provenance(provenance, input)
  if (!is.list(seeds) || is.data.frame(seeds)) p2_candidate_error("seeds must be a list of grade vectors")
  if (length(seeds) > limit) p2_candidate_error("raw seed count exceeds max_bank_entries; no truncation")
  seed_ids <- names(seeds)
  if (is.null(seed_ids)) seed_ids <- paste0("seed-", seq_along(seeds))
  if (length(seeds)) seed_ids <- p2_ids(seed_ids, length(seeds), "seed IDs")
  if (!is.numeric(cut_positions) || !is.null(dim(cut_positions)) || anyNA(cut_positions) ||
      any(!is.finite(cut_positions)) || any(cut_positions != floor(cut_positions)) ||
      any(cut_positions < 1 | cut_positions >= n) || anyDuplicated(cut_positions))
    p2_candidate_error("cut_positions must be distinct integers from 1 to n-1")
  cuts <- sort(as.integer(cut_positions))
  if (is.null(order)) {
    if (length(cuts)) p2_candidate_error("cut_positions require an explicit order")
  } else {
    order <- p2_ids(order, n, "order")
    if (!setequal(order, input$unit_ids)) p2_candidate_error("order must permute input unit IDs")
  }
  guard <- input$equality_classes[[domain_id]]
  guards <- setNames(list(guard), domain_id)
  validate_column <- function(g) {
    if (!is.numeric(g) || !is.null(dim(g)) || length(g) != n)
      p2_candidate_error("every seed must be a numeric grade vector of length n")
    if (!is.null(names(g)) && !identical(names(g), input$unit_ids))
      p2_candidate_error("seed names must match input unit order")
    result <- p2_validate_action(matrix(unname(g), n, 1L), input$unit_ids, domain_id,
      equality_classes = guards, grade_caps = cap, canonicalize = TRUE)
    unname(result$G[, 1L])
  }
  # An identity spanning order positions forbids every intervening cut. This
  # restricts generated partitions; externally supplied seeds are never repaired.
  blocked <- integer()
  if (!is.null(order) && !is.null(guard)) {
    ordered_guard <- guard[match(order, input$unit_ids)]
    for (identity in unique(ordered_guard)) {
      positions <- which(ordered_guard == identity)
      if (length(positions) > 1L) blocked <- union(blocked,
        cuts[cuts >= min(positions) & cuts < max(positions)])
    }
  }
  blocked <- sort(as.integer(blocked)); eligible <- setdiff(cuts, blocked)
  max_cuts <- min(length(eligible), cap - 1L)
  ordered_count <- p2_candidate_partition_count(length(eligible), max_cuts)
  if (ordered_count > gmp::as.bigz(limit))
    p2_candidate_error(paste0("ordered partition preflight requires ", as.character(ordered_count),
      " entries, exceeding max_bank_entries; no allocation or truncation"))
  # The raw seed count and generated count are independently bounded before
  # generation; at most 2*limit columns are temporarily materialized.
  seed_columns <- lapply(seeds, validate_column)
  columns <- list(rep(1L, n)); origins <- list("all_withheld")
  append_column <- function(g, origin) {
    columns[[length(columns) + 1L]] <<- g
    origins[[length(origins) + 1L]] <<- origin
  }
  if (!is.null(order) && max_cuts > 0L) {
    ordering <- match(order, input$unit_ids)
    for (k in seq_len(max_cuts)) {
      subsets <- utils::combn(seq_along(eligible), k, simplify = FALSE)
      for (indices in subsets) {
        cut <- eligible[indices]
        ordered_grades <- as.integer(cumsum(c(1L, as.integer(seq_len(n - 1L) %in% cut))))
        g <- integer(n); g[ordering] <- ordered_grades
        append_column(g, paste0("order_cuts:", paste(cut, collapse = ",")))
      }
    }
  }
  for (j in seq_along(seed_columns)) append_column(seed_columns[[j]], paste0("seed:", seed_ids[j]))
  keys <- vapply(columns, paste, character(1), collapse = ",")
  unique_keys <- unique(keys)
  if (length(unique_keys) > limit)
    p2_candidate_error("deduplicated bank exceeds max_bank_entries; no truncation")
  groups <- lapply(unique_keys, function(key) which(keys == key))
  matrix_columns <- do.call(rbind, lapply(groups, function(i) columns[[i[1L]]]))
  origins <- lapply(groups, function(i) sort(unique(unlist(origins[i], use.names = FALSE))))
  sorting <- do.call(base::order, c(lapply(seq_len(n), function(i) matrix_columns[, i]), list(method = "radix")))
  matrix_columns <- matrix_columns[sorting, , drop = FALSE]; origins <- origins[sorting]
  candidate_ids <- vapply(seq_len(nrow(matrix_columns)), function(i)
    paste0("column-", p2_hash(list(domain_id = domain_id, unit_ids = input$unit_ids,
                                  grades = unname(matrix_columns[i, ])))), character(1))
  if (anyDuplicated(candidate_ids)) p2_candidate_error("candidate ID hash collision")
  dimnames(matrix_columns) <- list(candidate_ids, input$unit_ids)
  K <- as.integer(apply(matrix_columns, 1L, max))
  metadata <- data.frame(candidate_id = candidate_ids, K = K,
    all_withheld = K == 1L, stringsAsFactors = FALSE)
  names(origins) <- candidate_ids
  result <- structure(list(domain_id = domain_id, unit_ids = input$unit_ids,
    source_input_hash = p2_hash(input$original_spec), columns = matrix_columns,
    candidate_ids = candidate_ids, metadata = metadata, origins = origins,
    all_withheld_id = candidate_ids[K == 1L], max_grades = cap, max_bank_entries = limit,
    equality_classes = guard, column_count = nrow(matrix_columns),
    order = order, requested_cut_positions = cuts, identity_blocked_cut_positions = blocked,
    eligible_cut_positions = eligible, ordered_partition_count_exact = as.character(ordered_count),
    raw_seed_count = length(seeds), provenance = provenance,
    receipts = list(construction = "explicit_order_and_external_seeds", no_implicit_target_order = TRUE,
      generated_guard_filter = TRUE, seeds_repaired = FALSE,
      all_withheld_preserved = TRUE, duplicate_columns_removed = length(columns) - nrow(matrix_columns),
      temporary_column_bound_exact = as.character(ordered_count + length(seeds)),
      provenance_assertions_independently_verified = FALSE,
      fixed_universe_verified = FALSE, numerical_guarantee = FALSE,
      global_optimization_claim = FALSE)), class = "p2_candidate_bank")
  result$bank_hash <- p2_candidate_integrity_hash(result)
  result$bank_id <- paste0("bank-", result$bank_hash)
  result
}

p2_build_candidate_family <- function(input, banks) {
  p2_candidate_dependencies()
  if (!inherits(input, "p2_profile_input")) p2_candidate_error("input must be validated p2_profile_input")
  if (!is.list(banks) || !identical(names(banks), input$domain_ids))
    p2_candidate_error("banks must be named in exact input domain order")
  source_hash <- p2_hash(input$original_spec)
  for (domain in input$domain_ids) {
    bank <- banks[[domain]]
    if (!inherits(bank, "p2_candidate_bank") || !identical(bank$domain_id, domain) ||
        !identical(bank$unit_ids, input$unit_ids) || !identical(bank$source_input_hash, source_hash) ||
        !identical(bank$equality_classes, input$equality_classes[[domain]]))
      p2_candidate_error("bank construction input, IDs, domain or equality guards do not match")
    if (!identical(bank$bank_hash, p2_candidate_integrity_hash(bank)) ||
        !identical(bank$bank_id, paste0("bank-", bank$bank_hash)))
      p2_candidate_error("bank integrity hash changed; rebuild instead of mutating construction provenance")
    if (bank$column_count > bank$max_bank_entries || !any(bank$metadata$all_withheld))
      p2_candidate_error("bank violates entry cap or lacks all-withheld candidate")
  }
  counts <- vapply(banks, function(b) b$column_count, integer(1))
  product_size <- gmp::as.bigz(1)
  for (count in counts) product_size <- product_size * count
  result <- structure(list(unit_ids = input$unit_ids, domain_ids = input$domain_ids,
    source_input_hash = source_hash, banks = banks, column_counts = counts,
    max_grades = vapply(banks, function(b) b$max_grades, integer(1)),
    equality_classes = input$equality_classes, product_size_exact = as.character(product_size),
    family_type = "product_of_explicit_domain_banks",
    receipts = list(cartesian_product_materialized = FALSE, product_exhaustive_search_performed = FALSE,
      full_ordered_partition_family_claim = FALSE, global_optimization_claim = FALSE,
      numerical_guarantee = FALSE, construction_provenance_preserved = TRUE)),
    class = "p2_candidate_family")
  result$family_hash <- p2_hash(unclass(result))
  result$family_id <- paste0("family-", result$family_hash)
  result
}
