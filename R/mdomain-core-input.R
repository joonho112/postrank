# Local P2 reference input validation; no production export or sampling certificate.
p2_input_error <- function(message) stop(message, call. = FALSE)
p2_nonempty_string <- function(x) is.character(x) && is.null(dim(x)) && length(x) == 1L &&
  !is.na(x) && nzchar(trimws(x))
p2_hash <- function(x) digest::digest(x, algo = "sha256", serialize = TRUE)
p2_ids <- function(x, size, label) {
  if (!is.character(x) || !is.null(dim(x)) || length(x) != size || anyNA(x) ||
      any(!nzchar(trimws(x))) || anyDuplicated(x)) p2_input_error(paste(label, "must be unique nonempty string vectors"))
  unname(x)
}
p2_integer_scalar <- function(x, minimum, label) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) ||
      x < minimum || x != floor(x) || x > .Machine$integer.max)
    p2_input_error(paste(label, "must be a finite integer >=", minimum))
  as.integer(x)
}

# Safe grammar: signed integer, integer/positive integer, or finite decimal.
# No expression evaluation, scientific notation, NaN or Inf is accepted.
p2_parse_rational <- function(x) {
  if (!is.character(x) || !is.null(dim(x)) || !length(x) || anyNA(x) ||
      any(!grepl("^[+-]?[0-9]+(/[0-9]+|\\.[0-9]+)?$", x)))
    p2_input_error("rational_text requires integer, fraction, or finite-decimal strings")
  out <- gmp::as.bigq(rep(0, length(x)))
  decimal_integer <- function(z) {
    negative <- startsWith(z, "-")
    digits <- sub("^[+-]", "", z)
    digits <- sub("^0+", "", digits)
    if (!nzchar(digits)) digits <- "0"
    # gmp interprets leading-zero text as octal and does not accept leading '+'.
    gmp::as.bigz(paste0(if (negative && digits != "0") "-" else "", digits))
  }
  for (i in seq_along(x)) {
    z <- x[[i]]
    if (grepl("/", z, fixed = TRUE)) {
      a <- strsplit(z, "/", fixed = TRUE)[[1L]]
      denominator <- decimal_integer(a[[2L]])
      if (denominator <= 0) p2_input_error("rational denominator must be positive")
      out[i] <- gmp::as.bigq(decimal_integer(a[[1L]]), denominator)
    } else if (grepl(".", z, fixed = TRUE)) {
      a <- strsplit(z, ".", fixed = TRUE)[[1L]]
      out[i] <- gmp::as.bigq(decimal_integer(paste0(a[[1L]], a[[2L]])),
                           gmp::as.bigz(10)^nchar(a[[2L]]))
    } else out[i] <- gmp::as.bigq(decimal_integer(z))
  }
  out
}

p2_compensated_sum <- function(x) {
  total <- correction <- 0
  for (v in x) {
    t <- total + v
    correction <- correction + if (abs(total) >= abs(v)) (total-t)+v else (v-t)+total
    total <- t
  }
  total + correction
}

p2_metadata <- function(value, path, missing_metadata) {
  absent <- is.null(value) || !length(value) ||
    (is.atomic(value) && (anyNA(value) || (is.character(value) && any(!nzchar(value)))))
  if (absent && !p2_nonempty_string(missing_metadata[[path]]))
    p2_input_error(paste("Missing metadata requires an explicit reason:", path))
  invisible(!absent)
}

p2_validate_common_spec <- function(spec) {
  if (!is.list(spec)) p2_input_error("spec must be a list")
  n <- p2_integer_scalar(spec$n, 2, "n")
  D <- p2_integer_scalar(spec$D, 1, "D")
  unit_ids <- p2_ids(spec$unit_ids, n, "unit_ids")
  domain_ids <- p2_ids(spec$domain_ids, D, "domain_ids")
  if (!p2_nonempty_string(spec$input_id)) p2_input_error("input_id is required")
  if (!p2_nonempty_string(spec$layout) || !spec$layout %in%
      c("joint_array", "criterionwise_arrays", "pairwise_summary")) p2_input_error("Unsupported layout")
  if (!p2_nonempty_string(spec$coupling_status) || !spec$coupling_status %in%
      c("supplied_joint", "scientifically_declared_product", "unknown_cross_domain"))
    p2_input_error("Unsupported coupling_status")
  reps <- c("exact_finite_law", "iid_equal_weight_draws", "mcmc_equal_weight_draws")
  representation <- spec$representation
  if (is.list(representation)) representation <- unlist(representation, use.names = TRUE)
  if (!is.character(representation) || anyNA(representation) || !length(representation))
    p2_input_error("representation is required")
  if (length(representation) > 1L) {
    if (spec$layout != "criterionwise_arrays" ||
        !identical(names(representation), domain_ids) || !all(representation %in% reps))
      p2_input_error("Heterogeneous representation must be a domain-ordered map")
  } else if (!representation %in% c(reps, "pairwise_probability_summary"))
    p2_input_error("Unsupported representation")
  if (spec$layout == "pairwise_summary" &&
      !identical(unname(representation), "pairwise_probability_summary"))
    p2_input_error("pairwise_summary needs pairwise_probability_summary representation")
  if (spec$layout != "pairwise_summary" && any(representation == "pairwise_probability_summary"))
    p2_input_error("State arrays cannot use pairwise summary representation")
  missing <- spec$missing_metadata
  if (is.null(missing) || !(is.list(missing) || is.character(missing)) ||
      (length(missing) && (is.null(names(missing)) || anyDuplicated(names(missing)) ||
       any(!nzchar(names(missing))) || !all(vapply(as.list(missing), p2_nonempty_string, logical(1))))))
    p2_input_error("missing_metadata must be a named reason map (empty list allowed)")
  missing <- as.list(missing)
  for (field in c("intended_law", "provenance", "target_spec", "selection_provenance"))
    if (!is.list(spec[[field]])) p2_input_error(paste(field, "must be a list"))
  for (f in c("identifier", "producer_class", "model_version", "conditioning_info",
              "approximation_status", "coupling_justification"))
    p2_metadata(spec$intended_law[[f]], paste0("intended_law.", f), missing)
  if (!is.logical(spec$intended_law$proper_law) || length(spec$intended_law$proper_law) != 1L ||
      is.na(spec$intended_law$proper_law)) p2_input_error("intended_law.proper_law must be declared TRUE/FALSE")
  for (f in c("source_hash", "producer_version", "code_version", "seed", "transformation_hash",
              "conditioning_data_id", "conditioning_data_hash"))
    p2_metadata(spec$provenance[[f]], paste0("provenance.", f), missing)
  p2_metadata(spec$decision_spec_hash, "decision_spec_hash", missing)
  for (f in c("source_hash", "transformation_hash", "conditioning_data_hash")) {
    h <- spec$provenance[[f]]
    if (!is.null(h) && length(h) && !anyNA(h) &&
        (!p2_nonempty_string(h) || !grepl("^[0-9a-fA-F]{64}$", h))) p2_input_error(paste("Invalid SHA-256", f))
  }
  h <- spec$decision_spec_hash
  if (!is.null(h) && length(h) && !anyNA(h) &&
      (!p2_nonempty_string(h) || !grepl("^[0-9a-fA-F]{64}$", h))) p2_input_error("Invalid decision_spec_hash SHA-256")
  for (f in c("sample_adaptive", "state_set_relationship"))
    p2_metadata(spec$selection_provenance[[f]], paste0("selection_provenance.", f), missing)
  for (f in c("selection_state_ids", "validation_state_ids")) {
    z <- spec$selection_provenance[[f]]
    if (is.null(z)) p2_metadata(z, paste0("selection_provenance.", f), missing)
    else if (!is.character(z) || anyNA(z) || anyDuplicated(z)) p2_input_error(paste("Invalid", f))
  }
  adaptive <- spec$selection_provenance$sample_adaptive
  if (!is.null(adaptive) && length(adaptive) && !anyNA(adaptive) &&
      (!is.logical(adaptive) || !identical(names(adaptive), c("actions", "candidates", "masks", "thresholds", "config"))))
    p2_input_error("sample_adaptive must be the named logical actions/candidates/masks/thresholds/config vector")
  if (!identical(names(spec$target_spec), domain_ids))
    p2_input_error("target_spec must be a domain-ordered named list")
  equality_classes <- setNames(vector("list", D), domain_ids)
  for (d in domain_ids) {
    target <- spec$target_spec[[d]]
    if (!is.list(target)) p2_input_error("Each target_spec entry must be a list")
    for (f in c("definition", "units")) p2_metadata(target[[f]], paste0("target_spec.", d, ".", f), missing)
    if (!identical(target$orientation, "larger_is_higher")) p2_input_error("Targets must already be oriented larger_is_higher")
    if (is.null(target$transformations) || !(is.list(target$transformations) || is.character(target$transformations)))
      p2_input_error("Declare ordered target transformations; empty list means none")
    cl <- target$equality_classes
    if (!is.character(cl) || !is.null(dim(cl)) || length(cl) != n || anyNA(cl) || any(!nzchar(trimws(cl))))
      p2_input_error("equality_classes must give one nonempty class label per original unit")
    if (!is.null(names(cl)) && !identical(names(cl), unit_ids))
      p2_input_error("Named equality_classes must match declared unit order exactly")
    if (!p2_nonempty_string(target$equality_provenance))
      p2_input_error("Scientific equality provenance is required, including an explicit no-identities declaration")
    equality_classes[[d]] <- unname(cl)
  }
  if (spec$coupling_status == "scientifically_declared_product" &&
      !p2_nonempty_string(spec$intended_law$factorization_justification))
    p2_input_error("Product coupling needs conditional-law factorization justification")
  if (spec$layout == "joint_array") {
    if (spec$coupling_status == "unknown_cross_domain") p2_input_error("joint_array requires a supplied joint construction, not unknown coupling")
    construction <- spec$intended_law$joint_construction
    if (!is.list(construction) || !p2_nonempty_string(construction$type) ||
        !p2_nonempty_string(construction$justification)) p2_input_error("joint_construction type and justification are required")
    allowed <- if (spec$coupling_status == "supplied_joint") "supplied_joint_states" else c("product_enumeration", "product_sampling")
    if (!construction$type %in% allowed) p2_input_error("Joint construction type conflicts with coupling status")
    if (spec$coupling_status == "scientifically_declared_product" &&
        (!p2_nonempty_string(construction$adapter_id) || !p2_nonempty_string(construction$construction_record)))
      p2_input_error("Product joint states need an explicit adapter and construction record")
  }
  list(n=n, D=D, unit_ids=unit_ids, domain_ids=domain_ids, input_id=spec$input_id,
       layout=spec$layout, representation=representation, coupling_status=spec$coupling_status,
       equality_classes=equality_classes, provenance=spec$provenance,
       intended_law=spec$intended_law, target_spec=spec$target_spec,
       selection_provenance=spec$selection_provenance, missing_metadata=missing,
       decision_spec_hash=spec$decision_spec_hash, original_spec=spec)
}

p2_validate_weights <- function(weights, representation, S) {
  if (representation == "exact_finite_law") {
    if (!is.list(weights) || !p2_nonempty_string(weights$encoding)) p2_input_error("Finite law needs encoded masses")
    raw <- weights$values
    if (!is.null(dim(raw)) || length(raw) != S) p2_input_error("Mass values must be a vector matching state count")
    if (weights$encoding == "rational_text") {
      exact <- p2_parse_rational(raw)
      if (any(exact < 0) || sum(exact) != 1) p2_input_error("Finite rational masses must be nonnegative and sum exactly to one")
      numeric <- as.numeric(exact)
      return(list(weights=numeric, weights_exact=exact, positive=as.logical(exact > 0),
                  receipt=list(encoding="rational_text", arithmetic_status="exact_rational_masses; numeric_projection_approximate",
                               raw_values=raw, raw_hash=p2_hash(raw), total_exact="1", normalized=FALSE,
                               numeric_projection_underflow=any(exact > 0 & numeric == 0))))
    }
    if (weights$encoding != "float64" || !is.numeric(raw) || is.complex(raw) || any(!is.finite(raw)) || any(raw < 0))
      p2_input_error("float64 masses must be finite and nonnegative; no clipping")
    tolerance <- if (is.null(weights$tolerance)) 1e-12 else weights$tolerance
    if (!is.numeric(tolerance) || length(tolerance) != 1L || !is.finite(tolerance) || tolerance < 0)
      p2_input_error("Mass tolerance must be finite and nonnegative")
    total <- p2_compensated_sum(raw)
    if (!is.finite(total) || total <= 0 || abs(total-1) > tolerance) p2_input_error("Float mass sum fails declared tolerance")
    normalized <- raw / total
    return(list(weights=normalized, weights_exact=NULL, positive=raw > 0,
                receipt=list(encoding="float64", arithmetic_status="floating_point_normalized_finite_law",
                             raw_values=raw, raw_hash=p2_hash(raw), compensated_total=total,
                             residual=total-1, tolerance=tolerance, normalization_rule="p_s = r_s / sum(r); compensated double evaluation",
                             resulting_weights=normalized, resulting_hash=p2_hash(normalized), normalized=TRUE)))
  }
  if (!is.null(weights)) {
    if (!is.list(weights) || !p2_nonempty_string(weights$encoding) ||
        !is.null(dim(weights$values)) || length(weights$values) != S)
      p2_input_error("Explicit Monte Carlo weights require encoding and one value per state")
    if (weights$encoding == "rational_text") {
      q <- p2_parse_rational(weights$values)
      if (any(q != gmp::as.bigq(1, S))) p2_input_error("Monte Carlo weights must equal exact 1/S")
    } else if (weights$encoding == "float64") {
      z <- weights$values
      if (!is.numeric(z) || is.complex(z) || any(!is.finite(z)) || any(z != 1/S))
        p2_input_error("Monte Carlo float weights must equal stored 1/S exactly")
    } else p2_input_error("Unsupported Monte Carlo weight encoding")
  }
  list(weights=rep(1/S, S), weights_exact=NULL, positive=rep(TRUE, S),
       receipt=list(encoding="implicit_equal_1_over_S", explicit_weights=weights,
                    arithmetic_status="empirical_equal_weight_floating_point", original_sample_size=S,
                    no_sampling_certificate=TRUE))
}

p2_validate_state_payload <- function(payload, common, expected_domains) {
  if (!is.list(payload) || !p2_nonempty_string(payload$payload_id)) p2_input_error("Each payload needs payload_id")
  path <- paste0("payloads.", payload$payload_id)
  missing <- common$missing_metadata
  if (!identical(payload$domain_ids, expected_domains)) p2_input_error("Payload domain order does not match declaration")
  rep <- payload$representation
  expected_rep <- common$representation
  if (length(expected_rep) > 1L) expected_rep <- unname(expected_rep[expected_domains])
  if (!p2_nonempty_string(rep) || !identical(rep, unname(expected_rep))) p2_input_error("Payload representation conflicts with common representation")
  values <- payload$values
  dims <- dim(values)
  if (!is.numeric(values) || is.complex(values) || length(dims) != 3L || dims[1] < 1L ||
      !identical(as.integer(dims[2:3]), c(common$n, as.integer(length(expected_domains)))) || any(!is.finite(values)))
    p2_input_error("State values must be finite numeric S x n x covered-domain array")
  S <- dims[1]
  state_ids <- p2_ids(payload$state_ids, S, "state_ids")
  dn <- dimnames(values)
  expected_names <- list(state_ids, common$unit_ids, expected_domains)
  if (!is.null(dn)) for (k in 1:3) if (!is.null(dn[[k]]) && !identical(dn[[k]], expected_names[[k]]))
    p2_input_error("Array dimnames conflict with explicit IDs; no silent reordering")
  origin <- payload$state_origin
  if (!is.data.frame(origin) || nrow(origin) != S ||
      !all(c("source_index", "chain_id", "iteration_id") %in% names(origin)))
    p2_input_error("state_origin needs one row per state and source_index/chain_id/iteration_id")
  for (f in c("source_index", "iteration_id")) {
    z <- origin[[f]]
    if (!is.numeric(z) || any(!is.na(z) & (!is.finite(z) | z < 0 | z > 2^53 | z != floor(z))))
      p2_input_error(paste("Invalid original", f))
    if (anyNA(z)) p2_metadata(z, paste0(path, ".state_origin.", f), missing)
  }
  if (!is.character(origin$chain_id) || any(!is.na(origin$chain_id) & !nzchar(origin$chain_id))) p2_input_error("Invalid chain IDs")
  if (anyNA(origin$chain_id)) p2_metadata(origin$chain_id, paste0(path, ".state_origin.chain_id"), missing)
  known <- !is.na(origin$chain_id) & !is.na(origin$iteration_id)
  if (anyDuplicated(origin[known, c("chain_id", "iteration_id"), drop=FALSE]))
    p2_input_error("Duplicate known iteration within an identified chain")
  retention <- payload$retention
  if (!is.list(retention) || !identical(retention$retained_original_indices, origin$source_index) ||
      !identical(retention$row_order, "as_supplied")) p2_input_error("Retention must preserve original indices and declared as_supplied row order")
  for (f in c("warmup_removed", "thinning")) {
    z <- retention[[f]]
    if (is.null(z) || anyNA(z)) p2_metadata(z, paste0(path, ".retention.", f), missing)
    else p2_integer_scalar(z, if (f == "thinning") 1 else 0, f)
  }
  assumptions <- payload$sampling_assumptions
  if (!is.list(assumptions)) p2_input_error("sampling_assumptions must be declared")
  if (rep == "exact_finite_law") {
    if (!p2_nonempty_string(assumptions$finite_support_origin)) p2_input_error("Finite support needs its complete-law origin, not a sample relabel")
  } else if (rep == "iid_equal_weight_draws") {
    p2_metadata(assumptions$iid_mechanism, paste0(path, ".sampling_assumptions.iid_mechanism"), missing)
    p2_metadata(assumptions$target_assertion, paste0(path, ".sampling_assumptions.target_assertion"), missing)
  } else for (f in c("sampler", "chain_details", "target_assertion"))
    p2_metadata(assumptions[[f]], paste0(path, ".sampling_assumptions.", f), missing)
  weight <- p2_validate_weights(payload$weights, rep, S)
  checked <- which(weight$positive)
  for (d in seq_along(expected_domains)) {
    classes <- common$equality_classes[[expected_domains[[d]]]]
    for (cl in unique(classes)) {
      members <- which(classes == cl)
      if (length(members) > 1L) for (j in members[-1L])
        if (any(values[checked, j, d] != values[checked, members[1L], d]))
          p2_input_error(paste("Structural equality incompatible in domain", expected_domains[[d]], "class", cl))
    }
  }
  hashes <- common$provenance$payload_hashes
  if (!is.null(hashes) && !is.list(hashes)) p2_input_error("provenance.payload_hashes must be a named list")
  stated_hash <- hashes[[payload$payload_id]]
  p2_metadata(stated_hash, paste0("provenance.payload_hashes.", payload$payload_id), missing)
  if (!is.null(stated_hash) && !anyNA(stated_hash) && !identical(stated_hash, p2_hash(values)))
    p2_input_error("Declared payload hash differs from raw values hash")
  by_chain <- split(origin$iteration_id[known], origin$chain_id[known])
  increasing <- if (!length(by_chain) || any(!known)) NA else all(vapply(by_chain, function(z) all(diff(z) > 0), logical(1)))
  status <- switch(rep, exact_finite_law="declared_finite_law_with_arithmetic_qualification",
                   iid_equal_weight_draws="empirical_iid_assertion_not_shape_verified",
                   mcmc_equal_weight_draws="empirical_mcmc_no_iid_or_finite_certificate")
  list(payload_id=payload$payload_id, values=values, domain_ids=expected_domains, representation=rep,
       weights=weight$weights, weights_exact=weight$weights_exact, state_ids=state_ids,
       state_origin=origin, retention=retention, sampling_assumptions=assumptions,
       receipt=list(mass=weight$receipt, raw_values_hash=p2_hash(values), positive_mass_rows=checked,
                    equality_rows_checked=checked, input_order_preserved=TRUE,
                    within_chain_strictly_increasing=increasing, sampling_status=status,
                    scientific_identity_established_by_state_check=FALSE,
                    no_numerical_guarantee=TRUE))
}

p2_require_capability <- function(input, mode="expected", domains=input$domain_ids) {
  aliases <- c(direct_J="joint", cross_domain_bundle="bundle")
  if (length(mode) != 1L || is.na(mode)) p2_input_error("Specify one capability mode")
  if (mode %in% names(aliases)) mode <- unname(aliases[[mode]])
  if (!mode %in% c("expected", "within_domain", "joint", "bundle")) p2_input_error("Unknown capability mode")
  if (is.null(domains)) domains <- input$domain_ids
  if (!is.character(domains) || anyNA(domains) || anyDuplicated(domains) || !all(domains %in% input$domain_ids))
    p2_input_error("Requested domains must be unique declared IDs")
  cap <- input$capabilities
  okay <- switch(mode,
    expected=isTRUE(cap$expected_additive),
    within_domain=all(domains %in% cap$within_domain_tails),
    joint=length(domains)==0L || (length(domains)==1L && all(domains %in% cap$within_domain_tails)) ||
      (isTRUE(cap$direct_joint) && all(domains %in% cap$joint_domains)),
    bundle=length(domains)==0L || (length(domains)==1L && all(domains %in% cap$within_domain_tails)) ||
      (isTRUE(cap$cross_domain_bundles) && all(domains %in% cap$joint_domains)))
  if (!okay) p2_input_error(paste("Input lacks", mode, "capability for requested domains; no coupling is fabricated"))
  invisible(input)
}

p2_validate_input <- function(spec, mode="expected", protected_domains=NULL) {
  common <- p2_validate_common_spec(spec)
  if (common$layout == "pairwise_summary") {
    if (!exists("p2_validate_pair_summary", mode="function", inherits=TRUE))
      p2_input_error("pairwise_summary module is not sourced; Step 6.10 supplies p2_validate_pair_summary")
    input <- p2_validate_pair_summary(spec, common)
  } else {
    if (!isTRUE(common$intended_law$proper_law)) p2_input_error("State evaluation needs declared proper-law provenance")
    payloads <- spec$payloads
    count <- if (common$layout == "joint_array") 1L else common$D
    if (!is.list(payloads) || length(payloads) != count) p2_input_error("Incorrect number of state payloads")
    ids <- vapply(payloads, function(x) if (p2_nonempty_string(x$payload_id)) x$payload_id else "", character(1))
    p2_ids(ids, count, "payload IDs")
    normalized <- lapply(seq_along(payloads), function(k) p2_validate_state_payload(payloads[[k]], common,
      if (common$layout == "joint_array") common$domain_ids else common$domain_ids[k]))
    names(normalized) <- ids
    joint <- common$layout == "joint_array"
    input <- common
    input$payloads <- normalized
    input["pair_summary"] <- list(NULL)
    input$capabilities <- list(expected_additive=TRUE, expected_counts=TRUE,
      within_domain_tails=common$domain_ids, direct_joint=joint,
      joint_domains=if (joint) common$domain_ids else character(), cross_domain_bundles=joint,
      numerical_guarantee=FALSE, global_summary_compatibility_established=FALSE)
    input$receipts <- list(no_implicit_alignment=TRUE, no_product_adapter_performed=TRUE,
      missing_metadata=common$missing_metadata, source_spec_hash=p2_hash(spec),
      sampling_status=vapply(normalized, function(x) x$receipt$sampling_status, character(1)))
    class(input) <- c("p2_profile_input", "list")
  }
  p2_require_capability(input, mode, if (is.null(protected_domains)) input$domain_ids else protected_domains)
  input
}
