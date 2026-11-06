# Fixed-S, fixed-event iid assurance. Declarations are retained, not verified.
p2_iid_count_bound <- function(v, S, alpha="1/10", beta="1/20",
                               max_S=10000L, max_bits=1000000L, max_work=50000000) {
  fail <- function(x) stop(x, call.=FALSE)
  integer_scalar <- function(x, lower) is.numeric(x) && !is.complex(x) &&
    is.null(dim(x)) && length(x)==1L && is.finite(x) && x>=lower && x<=2^53 && x==floor(x)
  if(!integer_scalar(S,1) || !integer_scalar(v,0) || v>S) fail("Require integer S >= 1 and 0 <= v <= S")
  if(!integer_scalar(max_S,1) || !integer_scalar(max_bits,1) || !integer_scalar(max_work,1))
    fail("Workload caps must be positive exact-range integers")
  if(S>max_S) fail("S exceeds max_S workload cap")
  a <- p2_decision_numbers(alpha,"alpha"); b <- p2_decision_numbers(beta,"beta")
  if(length(a$exact)!=1L || a$exact<0 || a$exact>1) fail("alpha must be scalar in [0,1]")
  if(length(b$exact)!=1L || b$exact<=0 || b$exact>=1) fail("beta must be scalar in (0,1)")
  aq <- a$exact; bq <- b$exact
  tailq <- NULL; bit_bound <- 0; work_bound <- 0
  if(aq==1) { pass <- TRUE; method <- "trivial_alpha_one" }
  else if(aq==0) { pass <- FALSE; method <- "alpha_zero_not_certified_by_finite_counts" }
  else if(v==S) { pass <- FALSE; tailq <- gmp::as.bigq(1); method <- "all_trials_violate" }
  else {
    num <- gmp::numerator(aq); den <- gmp::denominator(aq); other <- den-num
    # Conservative integer-size and iteration-work envelopes, checked BEFORE powers.
    bit_bound <- (S+2)*as.numeric(gmp::sizeinbase(den,2)) + ceiling(log2(S+1)) +
      as.numeric(gmp::sizeinbase(gmp::denominator(bq),2)) +
      as.numeric(gmp::sizeinbase(gmp::numerator(bq),2)) + 4
    work_bound <- bit_bound*(v+1)
    if(bit_bound>max_bits || work_bound>max_work) fail("Exact binomial workload exceeds max_bits or max_work cap")
    term <- other^S; total <- term
    if(v>0) for(k in seq.int(0,v-1)) {
      numerator <- term*gmp::as.bigz(S-k)*num
      divisor <- gmp::as.bigz(k+1)*other
      if(numerator %% divisor != 0) fail("Internal noninteger binomial recurrence")
      term <- numerator %/% divisor; total <- total+term
    }
    tailq <- gmp::as.bigq(total,den^S)
    pass <- as.logical(tailq<=bq); method <- "exact_binomial_lower_tail_at_exact_alpha"
  }
  display <- p2_iid_upper_display(v, S, bq)
  structure(list(v=v,S=S,alpha=as.numeric(aq),alpha_exact=as.character(aq),
    beta=as.numeric(bq),beta_exact=as.character(bq),upper_display=display$value,
    upper_display_status=display$status,
    upper_display_is_approximate=TRUE,accept=pass,
    binomial_lower_tail_exact=if(is.null(tailq)) NULL else as.character(tailq),
    method=method,assumptions_verified=FALSE,
    count_rule_only_not_a_sampling_certificate=TRUE,
    receipts=list(alpha_encoding=a$encoding,beta_encoding=b$encoding,
      exact_comparison=TRUE,qbeta_not_used_for_acceptance=TRUE,
      max_S=max_S,max_bits=max_bits,max_work=max_work,
      integer_bit_bound=bit_bound,work_bound=work_bound)),class=c("p2_iid_count_bound","list"))
}

# Floating display for an already decided count rule. Always pass the smaller
# tail on the log scale, so 1-beta remains available even when beta rounds to 1.
p2_iid_upper_display <- function(v, S, beta) {
  if (v == S) return(list(value=1, status="exact_endpoint"))
  lower_tail <- beta > gmp::as.bigq(1, 2)
  mass <- if (lower_tail) 1 - beta else beta
  # A positive rational mass = mantissa * 2^(-shift), with 1/2 < mantissa < 2.
  # This avoids both underflow of the mass and cancellation of two large logs.
  num <- gmp::numerator(mass)
  den <- gmp::denominator(mass)
  shift <- as.numeric(gmp::sizeinbase(den, 2)) - as.numeric(gmp::sizeinbase(num, 2))
  mantissa <- as.numeric(gmp::as.bigq(num * gmp::as.bigz(2)^shift, den))
  log_mass <- log(mantissa) - shift * log(2)
  if (v == 0) {
    if (lower_tail && log_mass < log(.Machine$double.xmin)) {
      # 1-(1-mass)^(1/S) = mass/S * (1+O(mass)) in this range.
      upper <- exp(log_mass - log(S))
    } else {
      log_beta <- if (lower_tail) log1p(-as.numeric(mass)) else log_mass
      upper <- -expm1(log_beta / S)
    }
  } else if (lower_tail) {
    a <- v + 1
    b <- S - v
    # I_x(a,b) = x^a/(a B(a,b)) times a factor between (1-x)^(b-1)
    # and 1. For x this small and S <= 2^53, its correction is far below
    # floating precision. qbeta can floor tiny quantiles near double.xmin.
    log_leading <- (log_mass + log(a) + lbeta(a, b)) / a
    upper <- if (log_leading < log(.Machine$double.xmin) + log(256)) {
      exp(log_leading)
    } else {
      stats::qbeta(log_mass, a, b, lower.tail=TRUE, log.p=TRUE)
    }
  } else {
    upper <- stats::qbeta(log_mass, v+1, S-v, lower.tail=FALSE, log.p=TRUE)
  }
  if (upper == 0) return(list(value=NA_real_, status="positive_bound_rounded_to_zero"))
  list(value=upper, status=if (upper == 1) "rounded_to_one" else "approximate")
}

p2_iid_prepare <- function(input,action,decision=NULL) {
  if(!inherits(input,"p2_profile_input") || !inherits(action,"p2_profile_action"))
    stop("Use validated input and action objects",call.=FALSE)
  if(is.null(decision)) decision <- p2_validate_decision(input)
  if(!inherits(decision,"p2_profile_decision") ||
     !identical(decision$unit_ids,input$unit_ids) || !identical(decision$domain_ids,input$domain_ids))
    stop("Decision must match the input IDs",call.=FALSE)
  expected <- decision$expected; expected$q <- as.character(decision$expected_q_exact)
  joint <- decision$joint; joint$t <- as.character(decision$joint_t_exact)
  decision <- p2_validate_decision(input,weights=decision$weights_exact,tau=decision$tau_exact,
    scopes=decision$scopes,expected=expected,joint=joint,alpha=decision$alpha_exact)
  if(!identical(action$unit_ids,input$unit_ids) || !identical(action$domain_ids,input$domain_ids))
    stop("Action must match the input IDs",call.=FALSE)
  action <- p2_validate_action(action$G,input$unit_ids,input$domain_ids,
    equality_classes=input$equality_classes,grade_caps=action$receipt$grade_caps,canonicalize=FALSE)
  hashes <- list(report=p2_hash(list(G=action$G,unit_ids=input$unit_ids,
    domain_ids=input$domain_ids,equality_classes=input$equality_classes,
    grade_caps=action$receipt$grade_caps)),decision=decision$receipts$local_loss_protection_hash,
    target_law=p2_hash(list(intended_law=input$intended_law,target_spec=input$target_spec,
      conditioning_data_id=input$provenance$conditioning_data_id,
      conditioning_data_hash=input$provenance$conditioning_data_hash,
      transformation_hash=input$provenance$transformation_hash)))
  list(action=action,decision=decision,hashes=hashes)
}

# Obtain this binding before validation; no saved target rows enter these hashes.
p2_iid_spec_hashes <- function(input,action,decision=NULL)
  p2_iid_prepare(input,action,decision)$hashes

p2_validate_iid <- function(input,action,decision=NULL,validation=NULL,beta="1/20",
                            max_S=10000L,max_bits=1000000L,max_work=50000000,
                            keep_traces=TRUE) {
  if(!inherits(input,"p2_profile_input") ||
     !identical(input$representation,"iid_equal_weight_draws"))
    stop("This interface requires declared iid_equal_weight_draws; evaluate exact finite laws separately",call.=FALSE)
  if(!is.logical(keep_traces) || length(keep_traces)!=1L || is.na(keep_traces))
    stop("keep_traces must be one nonmissing logical",call.=FALSE)
  prepared <- p2_iid_prepare(input,action,decision)
  evaluated <- p2_evaluate_joint(input,prepared$action,prepared$decision,keep_traces=TRUE)
  hashes <- prepared$hashes; bound <- NULL; certificate <- FALSE
  if(!evaluated$joint_protection_enabled) status <- "joint_protection_disabled"
  else if(evaluated$receipts$analytical_zero_union) {
    status <- "analytic_zero_event"; certificate <- TRUE
  } else if(prepared$decision$alpha_exact==1) {
    status <- "trivial_alpha_one"; certificate <- TRUE
  } else {
    fail <- function(message) stop(message,call.=FALSE)
    if(!is.list(validation)) fail("A frozen independent-validation record is required")
    if(!identical(validation$spec_hashes,hashes)) fail("Frozen report, decision or target-law hashes do not match")
    beta_record <- p2_decision_numbers(beta,"beta")$exact
    if(length(beta_record)!=1L || beta_record<=0 || beta_record>=1 ||
       !identical(validation$beta_exact,as.character(beta_record)))
      fail("Frozen beta_exact must match the declared numerical budget in (0,1)")
    flags <- c("iid_whole_states","independent_of_exploration","frozen_before_validation",
               "fixed_sample_size","no_validation_reuse","no_optional_stopping")
    if(!all(vapply(flags,function(f) isTRUE(validation[[f]]),logical(1))))
      fail("Every iid, independence, freezing, fixed-S and no-reuse declaration must be TRUE")
    for(f in c("iid_mechanism","independence_justification","exploration_history_id",
               "frozen_record_id","validation_batch_id"))
      if(!p2_nonempty_string(validation[[f]])) fail(paste("Missing validation provenance:",f))
    trace <- evaluated$traces
    if(is.null(trace) || !identical(trace$representation,"iid_equal_weight_draws"))
      fail("An actual iid event trace is required")
    S <- length(trace$union_event)
    if(!is.numeric(validation$fixed_S) || length(validation$fixed_S)!=1L ||
       !is.finite(validation$fixed_S) || validation$fixed_S!=S)
      fail("fixed_S must match the actual relevant validation trace")
    if(!identical(validation$validation_state_ids,trace$state_ids))
      fail("Validation state IDs must match the actual relevant trace in order")
    selection_ids <- validation$exploration_state_ids
    if(!is.character(selection_ids) || !is.null(dim(selection_ids)) || anyNA(selection_ids) ||
       anyDuplicated(selection_ids) || any(!nzchar(trimws(selection_ids))))
      fail("exploration_state_ids must be a unique character vector, possibly empty")
    if(length(intersect(selection_ids,trace$state_ids))) fail("Exploration and validation state IDs overlap")
    known_selection <- input$selection_provenance$selection_state_ids
    known_validation <- input$selection_provenance$validation_state_ids
    if(length(intersect(known_selection,trace$state_ids))) fail("Producer selection IDs overlap the validation trace")
    if(length(known_validation) && !identical(known_validation,trace$state_ids))
      fail("Producer validation IDs conflict with the actual relevant trace")
    # Names/disjointness are consistency checks, never an independence proof.
    bound <- p2_iid_count_bound(sum(trace$union_event),S,prepared$decision$alpha_exact,beta,
                               max_S,max_bits,max_work)
    certificate <- bound$accept
    status <- if(certificate) "certified_conditional_on_declared_iid_independence" else "inconclusive"
  }
  if(!keep_traces) {
    evaluated$traces <- NULL; evaluated$expected$traces <- NULL
    evaluated$receipts$traces_retained <- FALSE; evaluated$expected$receipts$traces_retained <- FALSE
  }
  structure(list(status=status,joint_certificate=certificate,
    joint_protection_enabled=evaluated$joint_protection_enabled,
    evaluated=evaluated,count_bound=bound,spec_hashes=hashes,validation_record=validation,
    receipts=list(assumptions_verified=FALSE,
      certificate_scope="specified supplied-law joint event only",
      finite_sample_claim_conditional_on_declared_assumptions=!is.null(bound),
      no_mean_or_optimality_or_model_certificate=TRUE,
      disjoint_IDs_do_not_establish_independence=TRUE,
      duplicate_target_values_are_allowed=TRUE,
      validation_record_hash=if(is.null(validation)) NULL else p2_hash(validation),
      input_source_spec_hash=input$receipts$source_spec_hash,
      target_law_hash_excludes_draw_rows=TRUE)),class=c("p2_iid_validation","list"))
}
