# Strict joint events under one actual relevant state law; no implicit recoupling.
p2_evaluate_joint <- function(input, action, decision = NULL, keep_traces = TRUE) {
  needed <- c("p2_evaluate_expected", "p2_integer_cutoff", "p2_require_capability")
  dependency_environment <- environment()
  if (!all(vapply(needed, function(name)
      exists(name, envir=dependency_environment, mode="function", inherits=TRUE), logical(1))) ||
      !requireNamespace("gmp", quietly=TRUE))
    stop("Source input, action, decision and evaluate-expected modules; gmp is required", call.=FALSE)
  fail <- function(message) stop(message, call.=FALSE)
  if (!is.logical(keep_traces) || length(keep_traces)!=1L || is.na(keep_traces))
    fail("keep_traces must be one nonmissing logical value")
  expected <- p2_evaluate_expected(input, action, decision, keep_traces=TRUE)
  action <- expected$action; decision <- expected$decision
  events <- decision$joint; nr <- nrow(events)
  events$event_id <- if(nr) paste0("joint-", seq_len(nr)) else character()
  events$N <- integer(nr)
  events$t_exact <- as.character(decision$joint_t_exact)
  events$cutoff <- numeric(nr); events$cutoff_exact <- character(nr)
  events$analytically_inactive <- logical(nr); events$inactive_reason <- character(nr)
  events$p <- numeric(nr); events$p_exact <- rep(NA_character_,nr)
  events$arithmetic <- character(nr)
  cutoffs <- vector("list",nr)
  for (r in seq_len(nr)) {
    row <- which(expected$scope_table$domain_id==events$domain_id[r] &
                 expected$scope_table$scope_id==events$scope_id[r])
    if (length(row)!=1L) fail("Joint row must reference exactly one evaluated domain-scope count")
    N <- expected$scope_table$N[row]
    cutoff <- p2_integer_cutoff(decision$joint_t_exact[r],N)
    cutoffs[[r]] <- cutoff
    inactive <- N==0 || isTRUE(as.logical(cutoff>gmp::as.bigz(N)))
    events$N[r] <- N; events$cutoff[r] <- as.numeric(cutoff)
    events$cutoff_exact[r] <- as.character(cutoff)
    events$analytically_inactive[r] <- inactive
    events$inactive_reason[r] <- if(N==0) "no_disclosure" else if(inactive) "cutoff_exceeds_N" else ""
    if(inactive) { events$p_exact[r] <- "0"; events$arithmetic[r] <- "analytic_zero" }
  }
  active <- which(!events$analytically_inactive)
  active_domains <- unique(events$domain_id[active])
  basis <- NULL; basis_domain <- NULL
  if(length(active)) {
    p2_require_capability(input,"joint",active_domains)
    if(length(active_domains)>1L && input$layout!="joint_array")
      fail("Multiple active domains require an actual supplied joint payload; no marginal row pairing")
    basis_domain <- active_domains[[1L]]
    basis <- expected$traces[[basis_domain]]
    if(is.null(basis)) fail("Nontrivial joint events require complete state traces")
    payload_at <- which(vapply(input$payloads,function(p) identical(p$payload_id,basis$payload_id),logical(1)))
    if(length(payload_at)!=1L || !all(active_domains %in% input$payloads[[payload_at]]$domain_ids))
      fail("Active event domains must belong to the same actual relevant payload")
    shared_fields <- c("payload_id","state_ids","state_origin","representation","weights","retention","sampling_assumptions")
    for(d in active_domains) {
      tr <- expected$traces[[d]]
      if(is.null(tr) || !all(vapply(shared_fields,function(f) identical(tr[[f]],basis[[f]]),logical(1))) ||
         !identical(as.character(tr$weights_exact),as.character(basis$weights_exact)))
        fail("Joint traces must share original states, history and weights; no alignment or recoupling")
    }
  } else if(!is.null(expected$traces)) {
    # Optional trace of an existing common law; never align criterionwise histories.
    relevant <- unique(events$domain_id)
    if(input$layout=="joint_array") basis_domain <- input$domain_ids[[1L]]
    else if(length(relevant)==1L) basis_domain <- relevant[[1L]]
    else if(input$D==1L) basis_domain <- input$domain_ids[[1L]]
    if(!is.null(basis_domain)) basis <- expected$traces[[basis_domain]]
  }
  event_matrix <- union_event <- NULL
  if(!is.null(basis)) {
    S <- length(basis$state_ids)
    event_matrix <- matrix(FALSE,S,nr,dimnames=list(basis$state_ids,events$event_id))
    for(r in active) {
      tr <- expected$traces[[events$domain_id[r]]]
      counts <- tr$scope_F[,events$scope_id[r]]
      event_matrix[,r] <- as.logical(gmp::as.bigz(counts)>=cutoffs[[r]])
    }
    union_event <- setNames(rowSums(event_matrix)>0L,basis$state_ids)
  }
  if(!length(active)) {
    Jq <- gmp::as.bigq(0); J <- 0
    arithmetic <- "analytic_zero_for_all_target_states"
    comparison <- "exact_analytic_comparison"
  } else {
    wq <- basis$weights_exact
    probability <- function(indicator) {
      if(!is.null(wq)) {
        exact <- sum(wq*gmp::as.bigq(as.integer(indicator)))
        list(value=as.numeric(exact),exact=exact)
      } else list(value=p2_compensated_sum(basis$weights*as.integer(indicator)),exact=NULL)
    }
    arithmetic <- if(basis$representation %in% c("iid_equal_weight_draws","mcmc_equal_weight_draws"))
      paste0("exact_empirical_",basis$representation) else if(!is.null(wq))
        "exact_rational_finite_law_events" else "approximate_float_mass_events"
    for(r in active) {
      pr <- probability(event_matrix[,r])
      events$p[r] <- pr$value
      events$p_exact[r] <- if(is.null(pr$exact)) NA_character_ else as.character(pr$exact)
      events$arithmetic[r] <- arithmetic
    }
    pr <- probability(union_event); J <- pr$value; Jq <- pr$exact
    comparison <- if(is.null(Jq)) "approximate_probability_compared_to_exact_cap" else "exact_represented_measure_comparison"
  }
  joint_feasible <- as.logical((if(is.null(Jq)) gmp::as.bigq(J) else Jq)<=decision$alpha_exact)
  trace <- if(is.null(basis)) NULL else list(
    payload_id=basis$payload_id, basis_domain=basis_domain, active_domains=active_domains,
    state_ids=basis$state_ids, state_origin=basis$state_origin,
    representation=basis$representation, weights=basis$weights, weights_exact=basis$weights_exact,
    weights_exact_origin=basis$weights_exact_origin, retention=basis$retention,
    sampling_assumptions=basis$sampling_assumptions, payload_receipt=basis$payload_receipt,
    event_matrix=event_matrix, union_event=union_event)
  if(!keep_traces) {
    trace <- NULL; expected$traces <- NULL; expected$receipts$traces_retained <- FALSE
  }
  structure(list(expected=expected, action=action, decision=decision,
    event_table=events,J=J,J_exact=if(is.null(Jq)) NULL else as.character(Jq),
    joint_protection_enabled=nr>0L,joint_evaluated=TRUE,
    mean_feasible=expected$mean_feasible,joint_feasible=joint_feasible,
    feasible_for_represented_measure=expected$mean_feasible && joint_feasible,
    traces=trace,
    receipts=list(arithmetic_status=arithmetic,joint_comparison_status=comparison,
      active_event_rows=active,active_domains=active_domains,
      analytical_zero_union=!length(active),joint_protection_disabled=nr==0L,
      relevant_payload_id=if(is.null(basis)) NULL else basis$payload_id,
      no_cross_payload_alignment=TRUE,no_independent_event_multiplication=TRUE,
      threshold_source="decision$joint_t_exact via p2_integer_cutoff; cutoff_exact is authoritative",
      event_row_order_preserved=TRUE, input_capabilities=input$capabilities,
      numerical_guarantee=FALSE,intended_posterior_feasibility_certified=FALSE,
      empirical_arithmetic_is_not_intended_posterior_certification=TRUE,
      candidate_family_membership_checked=FALSE,
      input_receipts=input$receipts,selection_provenance=input$selection_provenance,
      local_loss_protection_hash=decision$receipts$local_loss_protection_hash,
      traces_retained=!is.null(trace))),class=c("p2_joint_evaluation","list"))
}
