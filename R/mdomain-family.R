# Public candidate construction is deliberately bounded independently of the
# Cartesian action cap. This limit also bounds temporary core bank generation.
.md_family_bank_limit <- 1000L

.md_family_domains <- function(x, input, field, empty) {
  if (is.null(x)) return(setNames(rep(list(empty), input$D), input$domain_ids))
  if (!is.list(x) || is.data.frame(x) || !identical(names(x), input$domain_ids))
    .md_error(paste0(field, " must be a named list in exact input domain order."),
      "mdomain_family_identity", field, requested=names(x), available=input$domain_ids)
  x
}

.md_family_cap_error <- function(message, field, requested, available) {
  .md_error(message, "mdomain_family_cap", field,
    requested=as.character(requested), available=as.character(available))
}

# Count generated columns and seed overlaps without constructing any ordered
# partitions. A canonical seed belongs to the ordered bank exactly when it is
# nondecreasing along that order and every transition is an eligible cut.
.md_family_preflight <- function(input, domain, seeds, ordering, cuts, cap, bank_limit) {
  if (!is.list(seeds) || is.data.frame(seeds))
    p2_candidate_error("Each columns entry must be a list of unit-named numeric grade vectors")
  if (length(seeds) > bank_limit)
    .md_family_cap_error("Raw column count exceeds the hard per-domain bank cap; no allocation or truncation.",
      paste0("columns.", domain), length(seeds), bank_limit)
  if (length(seeds) && !is.null(names(seeds)))
    p2_ids(names(seeds), length(seeds), "column IDs")
  if (!is.numeric(cuts) || is.complex(cuts) || !is.null(dim(cuts)) || anyNA(cuts) ||
      any(!is.finite(cuts)) || any(cuts != floor(cuts)) ||
      any(cuts < 1 | cuts >= input$n) || anyDuplicated(cuts))
    p2_candidate_error("cuts must contain distinct integers from 1 to n-1")
  cuts <- sort(as.integer(cuts))
  if (is.null(ordering)) {
    if (length(cuts)) p2_candidate_error("cuts require an explicit order")
  } else {
    ordering <- p2_ids(ordering, input$n, "order")
    if (!setequal(ordering, input$unit_ids))
      p2_candidate_error("order must permute input unit IDs")
  }
  guard <- input$equality_classes[[domain]]
  blocked <- integer()
  if (!is.null(ordering) && !is.null(guard)) {
    ordered_guard <- guard[match(ordering, input$unit_ids)]
    for (identity in unique(ordered_guard)) {
      positions <- which(ordered_guard == identity)
      if (length(positions) > 1L)
        blocked <- union(blocked, cuts[cuts >= min(positions) & cuts < max(positions)])
    }
  }
  eligible <- setdiff(cuts, blocked)
  ordered_count <- p2_candidate_partition_count(length(eligible), min(length(eligible), cap-1L))
  if (ordered_count > gmp::as.bigz(bank_limit))
    .md_family_cap_error(paste0("Ordered partition preflight requires ", as.character(ordered_count),
      " entries, exceeding the hard per-domain bank cap; no allocation or truncation."),
      paste0("cuts.", domain), ordered_count, bank_limit)
  guards <- setNames(list(guard), domain)
  canonical <- lapply(seeds, function(g) {
    if (!is.numeric(g) || is.complex(g) || !is.null(dim(g)) || length(g) != input$n ||
        !identical(names(g), input$unit_ids))
      .md_error("Every supplied column must have numeric grades named in exact input unit order.",
        "mdomain_family_identity", paste0("columns.", domain),
        requested=names(g), available=input$unit_ids)
    unname(p2_validate_action(matrix(unname(g), input$n, 1L), input$unit_ids, domain,
      equality_classes=guards, grade_caps=cap, canonicalize=TRUE)$G[, 1L])
  })
  keys <- vapply(canonical, paste, character(1), collapse=",")
  canonical <- canonical[!duplicated(keys)]
  in_ordered_bank <- function(g) {
    if (all(g == 1L)) return(TRUE)
    if (is.null(ordering)) return(FALSE)
    ordered_g <- g[match(ordering, input$unit_ids)]
    all(diff(ordered_g) >= 0L) && all(which(diff(ordered_g) != 0L) %in% eligible)
  }
  additional <- sum(!vapply(canonical, in_ordered_bank, logical(1)))
  count <- ordered_count + gmp::as.bigz(additional)
  if (count > gmp::as.bigz(bank_limit))
    .md_family_cap_error("Deduplicated column count exceeds the hard per-domain bank cap; no allocation or truncation.",
      paste0("columns.", domain), count, bank_limit)
  list(count_exact=as.character(count), ordered_count_exact=as.character(ordered_count),
    eligible_cuts=eligible, blocked_cuts=sort(as.integer(blocked)),
    unique_external_columns=length(canonical), external_columns_outside_ordered_bank=additional)
}

.md_family_mean_order <- function(input, domain) {
  payloads <- input$payloads[vapply(input$payloads,
    function(p) domain %in% p$domain_ids, logical(1))]
  if (length(payloads) != 1L)
    .md_error("posterior_mean order requires complete state vectors for every domain.",
      "mdomain_capability", "order", requested=domain,
      available=input$capabilities$within_domain_tails)
  payload <- payloads[[1L]]
  d <- match(domain, payload$domain_ids)
  weights <- if (!is.null(payload$weights_exact)) payload$weights_exact else
    if (payload$representation %in% c("iid_equal_weight_draws", "mcmc_equal_weight_draws"))
      gmp::as.bigq(rep(1L, length(payload$state_ids)), length(payload$state_ids)) else
      gmp::as.bigq(payload$weights)
  means <- gmp::as.bigq(rep(0L, input$n))
  for (i in seq_len(input$n))
    means[i] <- sum(gmp::as.bigq(payload$values[, i, d]) * weights)
  # Rank exact means by comparison, with a stable UTF-8 bytewise ID tie break.
  indices <- base::order(enc2utf8(input$unit_ids), method="radix")
  indices <- indices[order(means[indices], decreasing=TRUE)]
  list(order=input$unit_ids[indices], means_exact=setNames(as.character(means), input$unit_ids),
    payload_id=payload$payload_id, state_ids=payload$state_ids, state_origin=payload$state_origin)
}

.md_family_integrity_hash <- function(family) {
  content <- unclass(family)
  content$receipt_hash <- NULL
  p2_hash(content)
}

#' Build a Bounded Multidomain Candidate Family
#'
#' Construct explicit domain banks and their Cartesian product description.
#' A tied grade withholds direction. All-withheld columns are always included.
#'
#' @param input A validated [postrank_mdomain_input()] object.
#' @param columns A list named in input domain order, each entry a list of
#'   numeric grade vectors named in exact input unit order. Labels are
#'   canonicalized and duplicate columns removed, preserving ties and direction.
#' @param order A list named in input domain order of explicit unit-ID
#'   permutations, or the explicit choice `"posterior_mean"`. The latter orders
#'   the current supplied states by decreasing weighted mean and uses unit IDs
#'   to break ties; it is recorded as sample-adaptive. `NULL` generates no
#'   ordered partitions beyond all-withheld.
#' @param cuts A list named in input domain order of permitted cut positions
#'   between consecutive units. Cuts require an order; no cuts are guessed.
#' @param max_grades A positive integer or domain-ordered vector of grade caps.
#'   `NULL` permits up to the input unit count.
#' @param max_actions Maximum exact product size, checked before banks are
#'   materialized. Each domain also has a hard cap of 1,000 raw supplied columns
#'   and 1,000 deduplicated bank entries. Exceeding a cap errors without truncation.
#' @details Structural equality guards also apply to zero-weight domains.
#'   Generated cuts that split an equality class are excluded; supplied columns
#'   that split a class are rejected. Construction and evaluation refer to the
#'   same input. External-column adaptation is not scientifically verified,
#'   and construction receipts do not provide numerical assurance.
#' @return A `postrank_mdomain_family` wrapping an immutable native candidate
#'   family, source hashes, construction provenance, and exact size receipts.
#' @concept multidomain
#' @export
postrank_mdomain_family <- function(input, columns=NULL, order=NULL, cuts=NULL,
                                   max_grades=NULL, max_actions=100000L) {
  input <- .md_validate_input(input)
  .md_attempt({
    limit <- p2_integer_scalar(max_actions, 1L, "max_actions")
    bank_limit <- .md_family_bank_limit
    columns <- .md_family_domains(columns, input, "columns", list())
    cuts <- .md_family_domains(cuts, input, "cuts", integer())
    cuts <- lapply(cuts, function(x) if (is.null(x)) integer() else x)
    adaptive <- identical(order, "posterior_mean")
    mean_construction <- if (adaptive)
      setNames(lapply(input$domain_ids, function(d) .md_family_mean_order(input, d)), input$domain_ids) else NULL
    orders <- if (adaptive) lapply(mean_construction, `[[`, "order") else
      .md_family_domains(order, input, "order", NULL)
    if (is.null(max_grades)) max_grades <- rep(input$n, input$D)
    if (length(max_grades) == 1L && is.null(names(max_grades)))
      max_grades <- rep(max_grades, input$D)
    if (!is.numeric(max_grades) || is.complex(max_grades) || !is.null(dim(max_grades)) ||
        length(max_grades) != input$D || anyNA(max_grades) || any(!is.finite(max_grades)) ||
        any(max_grades < 1 | max_grades != floor(max_grades) | max_grades > .Machine$integer.max) ||
        (!is.null(names(max_grades)) && !identical(names(max_grades), input$domain_ids)))
      p2_candidate_error("max_grades must supply positive integer caps in input domain order")
    caps <- setNames(as.integer(pmin(max_grades, input$n)), input$domain_ids)
    preflight <- setNames(lapply(input$domain_ids, function(d)
      .md_family_preflight(input, d, columns[[d]], orders[[d]], cuts[[d]], caps[[d]], bank_limit)), input$domain_ids)
    product_size <- gmp::as.bigz(1)
    for (d in input$domain_ids) product_size <- product_size * gmp::as.bigz(preflight[[d]]$count_exact)
    if (product_size > gmp::as.bigz(limit))
      .md_family_cap_error(paste0("Exact candidate product has ", as.character(product_size),
        " actions, exceeding max_actions; no banks or Cartesian actions were materialized or truncated."),
        "max_actions", product_size, limit)
    source_hash <- p2_hash(input$original_spec)
    provenance <- setNames(lapply(input$domain_ids, function(d) {
      m <- if (adaptive) mean_construction[[d]] else NULL
      list(construction_method=if (adaptive) "explicit_posterior_mean_order_and_columns" else
          "explicit_order_and_columns", source_input_hash=source_hash, source_ids=input$input_id,
        construction_draw_ids=if (adaptive) m$state_ids else character(),
        construction_state_ids=if (adaptive) m$state_ids else character(),
        construction_payload_id=if (adaptive) m$payload_id else NULL,
        construction_state_origin=if (adaptive) m$state_origin else NULL,
        posterior_means_exact=if (adaptive) m$means_exact else NULL,
        source_artifact_hashes=c(input_spec=source_hash),
        sample_adaptive=c(order=adaptive, seeds=FALSE, cut_positions=FALSE, configuration=FALSE),
        depends_on_y=adaptive, fixed_universe_claim=FALSE,
        selection_validation_relationship="Construction and evaluation reference the same supplied input; no independent validation is asserted.",
        adaptation_claim_scope="Wrapper computations only; dependence of externally supplied columns, cuts and configuration is not established.",
        mean_arithmetic=if (adaptive) "Exact stored-binary state values; rational finite masses, exact equal MC weights, or stored normalized float masses." else NULL,
        tie_break=if (adaptive) "Increasing UTF-8 unit ID, independent of input row order." else NULL)
    }), input$domain_ids)
    banks <- setNames(lapply(input$domain_ids, function(d)
      p2_build_domain_bank(input, d, order=orders[[d]], cut_positions=cuts[[d]],
        max_grades=caps[[d]], seeds=columns[[d]], max_bank_entries=bank_limit,
        provenance=provenance[[d]])), input$domain_ids)
    native <- p2_build_candidate_family(input, banks)
    if (!identical(native$product_size_exact, as.character(product_size)))
      p2_candidate_error("Materialized bank count differs from exact preflight")
    result <- structure(list(family=native, input_id=input$input_id,
      source_input_hash=source_hash, family_hash=native$family_hash, family_id=native$family_id,
      provenance=lapply(native$banks, `[[`, "provenance"),
      receipts=list(schema_version="postrank-mdomain-family-v1", max_actions=limit,
        hard_bank_cap=bank_limit, preflight=preflight, product_size_exact=as.character(product_size),
        product_checked_before_bank_materialization=TRUE,
        cartesian_product_materialized=FALSE, implicit_order=FALSE, implicit_cuts=FALSE,
        sample_adaptive_order=adaptive, external_adaptation_verified=FALSE,
        numerical_guarantee=FALSE)), class=c("postrank_mdomain_family", "list"))
    result$receipt_hash <- .md_family_integrity_hash(result)
    result
  }, "mdomain_family_invalid", "family")
}

.md_validate_family <- function(input, family) {
  input <- .md_validate_input(input)
  if (!inherits(family, "postrank_mdomain_family") || !inherits(family$family, "p2_candidate_family"))
    .md_error("Use postrank_mdomain_family() to prepare the candidate family.",
      "mdomain_family_class", "family")
  .md_attempt({
    source_hash <- p2_hash(input$original_spec)
    if (!identical(family$input_id, input$input_id) ||
        !identical(family$source_input_hash, source_hash) ||
        !identical(family$family$source_input_hash, source_hash))
      .md_error("Candidate family must use the same unchanged construction input.",
        "mdomain_family_source", "family")
    if (!identical(family$receipt_hash, .md_family_integrity_hash(family)))
      .md_error("Candidate family or its construction receipts have changed; rebuild the family.",
        "mdomain_family_mutated", "family")
    native <- family$family
    content <- unclass(native); content$family_hash <- NULL; content$family_id <- NULL
    if (!identical(native$family_hash, p2_hash(content)) ||
        !identical(native$family_id, paste0("family-", native$family_hash)))
      p2_candidate_error("Native family integrity hash changed")
    rebuilt <- p2_build_candidate_family(input, native$banks)
    if (!identical(native, rebuilt) || !identical(family$family_hash, native$family_hash) ||
        !identical(family$family_id, native$family_id) ||
        !identical(family$provenance, lapply(native$banks, `[[`, "provenance")))
      p2_candidate_error("Family metadata does not match its frozen construction banks")
    if (any(native$column_counts > .md_family_bank_limit) ||
        gmp::as.bigz(native$product_size_exact) > gmp::as.bigz(family$receipts$max_actions))
      .md_family_cap_error("Candidate family exceeds its recorded construction caps.",
        "family", native$product_size_exact, family$receipts$max_actions)
    native
  }, "mdomain_family_invalid", "family")
}
