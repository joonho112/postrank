# Local decision specification; source input.R before this module's entry points.
p2_decision_dependencies <- function() {
  needed <- c("p2_parse_rational", "p2_compensated_sum", "p2_hash", "p2_input_error", "p2_ids", "p2_integer_scalar")
  dependency_environment <- environment()
  if (!all(vapply(needed, function(name)
      exists(name, envir=dependency_environment, mode="function", inherits=TRUE), logical(1))))
    stop("Source R/profile/input.R before using decision.R", call.=FALSE)
}

p2_decision_numbers <- function(x, field, allow_empty=FALSE) {
  p2_decision_dependencies()
  if (!is.null(dim(x)) || (!length(x) && !allow_empty))
    p2_input_error(paste(field, "must be a nonempty scalar/vector, not a matrix"))
  if (!length(x)) return(list(exact=gmp::as.bigq(integer()), numeric=numeric(), encoding="empty"))
  if (inherits(x, "bigq")) {
    if (any(is.na(x))) p2_input_error(paste(field, "contains missing rational values"))
    exact <- x
    encoding <- "supplied_bigq"
  } else if (is.character(x)) {
    exact <- p2_parse_rational(x)
    encoding <- "rational_text"
  } else if (is.numeric(x) && !is.complex(x) && all(is.finite(x))) {
    exact <- gmp::as.bigq(x)
    encoding <- "stored_binary_rational"
  } else p2_input_error(paste(field, "must use finite numeric, rational-text, or bigq values"))
  list(exact=exact, numeric=as.numeric(exact), encoding=encoding)
}

p2_decision_domain_vector <- function(x, domains, field, broadcast=FALSE) {
  if (!is.null(dim(x))) p2_input_error(paste(field, "must be a vector"))
  if (broadcast && length(x)==1L && is.null(names(x))) return(rep(x, length(domains)))
  if (length(x) != length(domains)) p2_input_error(paste(field, "must align with every domain; no recycling"))
  if (!is.null(names(x)) && !identical(names(x), domains))
    p2_input_error(paste(field, "names must match declared domain order exactly"))
  x
}

# Return bigz even at N=2^53, where N+1 cannot be represented exactly as a double.
p2_integer_cutoff <- function(t, N) {
  p2_decision_dependencies()
  if (length(t) != 1L) p2_input_error("t must be scalar for p2_integer_cutoff")
  threshold <- p2_decision_numbers(t, "t")$exact
  if (threshold < 0 || threshold > 1) p2_input_error("t must lie in [0,1]")
  if (!is.numeric(N) || is.complex(N) || !is.null(dim(N)) || length(N) != 1L ||
      !is.finite(N) || N < 0 || N > 2^53 || N != floor(N))
    p2_input_error("N must be a nonnegative exact-range numeric integer <= 2^53")
  floor(threshold * gmp::as.bigz(N)) + gmp::as.bigz(1)
}

p2_decision_scopes <- function(scopes, n, unit_ids) {
  if (is.null(scopes)) {
    full <- matrix(1L, n, n, dimnames=list(unit_ids, unit_ids)); diag(full) <- 0L
    scopes <- list(full=full)
  }
  if (!is.list(scopes) || is.data.frame(scopes)) p2_input_error("scopes must be a named list of binary matrices")
  if (!length(scopes)) return(scopes)
  p2_ids(names(scopes), length(scopes), "scope IDs")
  for (id in names(scopes)) {
    a <- scopes[[id]]
    if (!(is.numeric(a) || is.logical(a)) || is.complex(a) || !is.matrix(a) ||
        !identical(dim(a), c(n,n)) || any(!is.finite(a)) || any(!a %in% c(0,1)) ||
        any(diag(a) != 0) || !all(a == t(a)))
      p2_input_error(paste("Scope", id, "must be finite binary symmetric n x n with zero diagonal"))
    if (!is.null(rownames(a)) && !identical(rownames(a), unit_ids))
      p2_input_error(paste("Scope", id, "row IDs conflict with original unit order"))
    if (!is.null(colnames(a)) && !identical(colnames(a), unit_ids))
      p2_input_error(paste("Scope", id, "column IDs conflict with original unit order"))
    storage.mode(a) <- "integer"
    dimnames(a) <- list(unit_ids, unit_ids)
    scopes[[id]] <- a
  }
  scopes
}

p2_decision_events <- function(rows, value_name, domains, scope_ids) {
  empty <- data.frame(domain_id=character(), scope_id=character(), stringsAsFactors=FALSE)
  empty[[value_name]] <- numeric()
  if (is.null(rows) || (is.data.frame(rows) && nrow(rows)==0L))
    return(list(table=empty, exact=gmp::as.bigq(integer()), receipt=list(encoding="empty", row_count=0L)))
  needed <- c("domain_id", "scope_id", value_name)
  if (!is.data.frame(rows) || anyDuplicated(names(rows)) || !setequal(names(rows), needed))
    p2_input_error(paste("Protection rows require exactly", paste(needed, collapse=", ")))
  for (id in c("domain_id", "scope_id"))
    if (!is.character(rows[[id]]) || !is.null(dim(rows[[id]])) || anyNA(rows[[id]]) || any(!nzchar(trimws(rows[[id]]))))
      p2_input_error(paste(id, "must contain nonempty character IDs"))
  if (!all(rows$domain_id %in% domains) || !all(rows$scope_id %in% scope_ids))
    p2_input_error("Protection rows reference unknown domain/scope IDs")
  if (anyDuplicated(rows[c("domain_id", "scope_id")]))
    p2_input_error("Duplicate domain-scope protection row")
  parsed <- p2_decision_numbers(rows[[value_name]], value_name)
  if (length(parsed$exact) != nrow(rows) || any(parsed$exact < 0) || any(parsed$exact > 1))
    p2_input_error(paste(value_name, "must have one [0,1] value per protection row"))
  out <- rows[needed]
  out[[value_name]] <- unname(parsed$numeric)
  list(table=out, exact=parsed$exact,
       receipt=list(encoding=parsed$encoding, raw_values=rows[[value_name]],
                    exact_values=as.character(parsed$exact), row_count=nrow(rows), input_row_order_preserved=TRUE))
}

p2_validate_decision <- function(input, weights=NULL, tau="1/4", scopes=NULL,
                                expected=NULL, joint=NULL, alpha="1/10", weight_tolerance=1e-12) {
  p2_decision_dependencies()
  if (!inherits(input, "p2_profile_input")) p2_input_error("input must be a validated p2_profile_input")
  n <- p2_integer_scalar(input$n, 2L, "input n")
  D <- p2_integer_scalar(input$D, 1L, "input D")
  units <- p2_ids(input$unit_ids, n, "input unit IDs")
  domains <- p2_ids(input$domain_ids, D, "input domain IDs")
  M_exact <- gmp::as.bigz(n) * gmp::as.bigz(n-1L) / 2
  if (M_exact > gmp::as.bigz(2)^53) p2_input_error("Original pair count exceeds the supported exact numeric range")
  M <- as.numeric(M_exact)
  if (!is.numeric(weight_tolerance) || is.complex(weight_tolerance) || !is.null(dim(weight_tolerance)) ||
      length(weight_tolerance) != 1L || !is.finite(weight_tolerance) || weight_tolerance < 0)
    p2_input_error("weight_tolerance must be a finite nonnegative scalar")
  raw_weights <- weights
  if (is.null(weights)) {
    exact_weights <- gmp::as.bigq(rep(1, D), D)
    weight_receipt <- list(encoding="default_equal_rational", raw_values=NULL,
                          exact_values=as.character(exact_weights), normalization_performed=FALSE,
                          arithmetic_status="exact_rational_weights; numeric_projection_approximate")
  } else {
    weights <- p2_decision_domain_vector(weights, domains, "weights")
    parsed <- p2_decision_numbers(weights, "weights")
    if (any(parsed$exact < 0)) p2_input_error("weights must be nonnegative")
    if (parsed$encoding == "stored_binary_rational") {
      total <- p2_compensated_sum(weights)
      if (!is.finite(total) || total <= 0 || abs(total-1) > weight_tolerance)
        p2_input_error("Numeric weight total fails declared tolerance")
      total_exact <- sum(parsed$exact)
      exact_weights <- parsed$exact / total_exact
      weight_receipt <- list(encoding=parsed$encoding, raw_values=raw_weights,
        raw_hash=p2_hash(raw_weights), compensated_total=total, residual=total-1, tolerance=weight_tolerance,
        raw_total_exact=as.character(total_exact), normalization_performed=TRUE,
        normalization_rule="exact stored binary-rational values divided by their exact rational sum",
        exact_values=as.character(exact_weights), arithmetic_status="exact_normalized_binary_rational_weights; numeric_projection_approximate")
    } else {
      if (sum(parsed$exact) != 1) p2_input_error("Rational weights must sum exactly to one")
      exact_weights <- parsed$exact
      weight_receipt <- list(encoding=parsed$encoding, raw_values=raw_weights,
        raw_hash=p2_hash(raw_weights), exact_values=as.character(exact_weights), normalization_performed=FALSE,
        arithmetic_status="exact_rational_weights; numeric_projection_approximate")
    }
  }
  if (sum(exact_weights) != 1) p2_input_error("Internal weight normalization failure")
  raw_tau <- tau
  tau <- p2_decision_domain_vector(tau, domains, "tau", broadcast=TRUE)
  parsed_tau <- p2_decision_numbers(tau, "tau")
  if (any(parsed_tau$exact <= 0) || any(parsed_tau$exact > gmp::as.bigq(1,2)))
    p2_input_error("tau must lie in (0,1/2]")
  if (length(alpha) != 1L) p2_input_error("alpha must be scalar")
  parsed_alpha <- p2_decision_numbers(alpha, "alpha")
  if (parsed_alpha$exact < 0 || parsed_alpha$exact > 1) p2_input_error("alpha must lie in [0,1]")
  raw_scopes <- scopes
  scopes <- p2_decision_scopes(scopes, n, units)
  default_joint <- is.null(joint)
  default_scope_id <- NULL
  if (default_joint) {
    full_ids <- names(scopes)[vapply(scopes, function(a) sum(a)==2*M, logical(1))]
    if (!length(full_ids)) p2_input_error("A custom catalog without a full mask requires explicit joint rows, including an empty data.frame to disable")
    default_scope_id <- if ("full" %in% full_ids) "full" else full_ids[1L]
    joint <- data.frame(domain_id=domains, scope_id=rep(default_scope_id,D), t=rep("0",D), stringsAsFactors=FALSE)
  }
  exp_rows <- p2_decision_events(expected, "q", domains, names(scopes))
  joint_rows <- p2_decision_events(joint, "t", domains, names(scopes))
  normalized <- list(n=n, D=D, unit_ids=units, domain_ids=domains, M=M,
    weights_exact=as.character(exact_weights), tau_exact=as.character(parsed_tau$exact),
    alpha_exact=as.character(parsed_alpha$exact), scopes=scopes,
    expected=exp_rows$table[c("domain_id","scope_id")], expected_q_exact=as.character(exp_rows$exact),
    joint=joint_rows$table[c("domain_id","scope_id")], joint_t_exact=as.character(joint_rows$exact))
  result <- list(n=n, D=D, unit_ids=units, domain_ids=domains, M=M,
    weights=setNames(as.numeric(exact_weights),domains), weights_exact=exact_weights,
    tau=setNames(parsed_tau$numeric,domains), tau_exact=parsed_tau$exact,
    alpha=unname(parsed_alpha$numeric), alpha_exact=parsed_alpha$exact,
    scopes=scopes, expected=exp_rows$table, expected_q_exact=exp_rows$exact,
    joint=joint_rows$table, joint_t_exact=joint_rows$exact,
    receipts=list(weights=weight_receipt,
      tau=list(raw_values=raw_tau, encoding=parsed_tau$encoding, exact_values=as.character(parsed_tau$exact)),
      alpha=list(raw_values=alpha, encoding=parsed_alpha$encoding, exact_value=as.character(parsed_alpha$exact)),
      expected=exp_rows$receipt, joint=joint_rows$receipt,
      scopes=list(default_catalog=is.null(raw_scopes), default_joint=default_joint, default_joint_scope_id=default_scope_id,
                  catalog_order_preserved=TRUE, original_unit_order_preserved=TRUE),
      joint_protection_enabled=nrow(joint_rows$table)>0L,
      local_loss_protection_hash=p2_hash(normalized), local_hash_scheme="p2_reference_decision_exact_fields_r_serialize_sha256_v1",
      external_full_decision_spec_hash=input$decision_spec_hash,
      external_full_spec_binding_verified=FALSE,
      arithmetic_status="decision parameters retained exactly as rationals; numeric fields are projections",
      no_scientific_or_sampling_certificate=TRUE))
  class(result) <- c("p2_profile_decision", "list")
  result
}
