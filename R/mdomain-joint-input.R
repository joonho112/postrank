.md_state_component <- function(x, domain, separate) {
  if (separate && is.list(x) && !is.data.frame(x)) x[[domain]] else x
}

.md_state_payload <- function(values, payload_id, domains, representation,
    masses, state_origin, producer, spec) {
  S <- dim(values)[1L]
  states <- .md_input_ids(dimnames(values)[[1L]],S,paste0("payloads.",payload_id,".state_ids"))
  .md_input_check(is.character(representation) && length(representation)==1L &&
    !is.na(representation) && representation %in%
      c("exact_finite_law","iid_equal_weight_draws","mcmc_equal_weight_draws"),
    "Declare the representation of every payload explicitly.","representation")
  representation <- unname(representation)
  if (!is.null(masses) && !is.list(masses)) {
    .md_input_check(is.null(names(masses)) || identical(names(masses),states),
      "Named masses must match state IDs in supplied order.","masses")
    masses <- list(encoding=if(is.character(masses)) "rational_text" else "float64",values=masses)
  }
  if (!is.null(masses) && !is.null(names(masses$values)))
    .md_input_check(identical(names(masses$values),states),
      "Named masses must match state IDs in supplied order.","masses")
  if (representation=="exact_finite_law")
    .md_input_check(!is.null(masses),"An exact finite law requires explicit state masses.","masses")
  origin_path <- paste0("payloads.",payload_id,".state_origin.")
  if (is.null(state_origin)) {
    .md_input_check(representation!="mcmc_equal_weight_draws",
      "MCMC input requires original source indices, chain IDs and iteration IDs.","state_origin")
    state_origin <- data.frame(source_index=seq_len(S),chain_id=rep(NA_character_,S),
      iteration_id=rep(NA_real_,S),stringsAsFactors=FALSE)
  }
  .md_input_check(is.data.frame(state_origin) && nrow(state_origin)==S &&
    all(c("source_index","chain_id","iteration_id") %in% names(state_origin)) && !anyDuplicated(names(state_origin)),
    "state_origin must have one row per state and source_index, chain_id, iteration_id columns.","state_origin")
  if ("state_id" %in% names(state_origin))
    .md_input_check(identical(state_origin$state_id,states),
      "state_origin state IDs differ from array state order.","state_origin.state_id","mdomain_input_ids")
  if (representation=="mcmc_equal_weight_draws") {
    .md_input_check(!anyNA(state_origin[c("source_index","chain_id","iteration_id")]),
      "MCMC original source, chain and iteration coordinates must be known.","state_origin")
    .md_input_check(is.numeric(state_origin$iteration_id) && all(state_origin$iteration_id>=1),
      "MCMC iterations must be positive original iteration numbers.","state_origin.iteration_id")
  }
  for (f in c("source_index","chain_id","iteration_id"))
    spec <- .md_missing_reason(spec,state_origin[[f]],paste0(origin_path,f),
      "No original sampler coordinate supplied; supplied array row order is retained.")
  retention <- producer$retention
  if (is.null(retention)) retention <- list()
  .md_input_check(is.null(retention$retained_original_indices) ||
    identical(retention$retained_original_indices,state_origin$source_index),
    "Retention indices conflict with state_origin.","provenance.retention.retained_original_indices")
  .md_input_check(is.null(retention$row_order) || identical(retention$row_order,"as_supplied"),
    "Retention row_order must be as_supplied.","provenance.retention.row_order")
  retention$retained_original_indices <- state_origin$source_index
  retention$row_order <- "as_supplied"
  for (f in c("warmup_removed","thinning"))
    spec <- .md_missing_reason(spec,retention[[f]],paste0("payloads.",payload_id,".retention.",f))
  assumptions <- producer$sampling_assumptions
  if (is.null(assumptions)) assumptions <- list()
  if (representation=="exact_finite_law") {
    .md_input_check(p2_nonempty_string(assumptions$finite_support_origin),
      "Declare provenance.sampling_assumptions.finite_support_origin for a complete finite law.",
      "provenance.sampling_assumptions.finite_support_origin")
  } else {
    fields <- if(representation=="iid_equal_weight_draws") c("iid_mechanism","target_assertion") else
      c("sampler","chain_details","target_assertion")
    for(f in fields) spec <- .md_missing_reason(spec,assumptions[[f]],
      paste0("payloads.",payload_id,".sampling_assumptions.",f))
  }
  if (is.null(spec$provenance$payload_hashes)) spec$provenance$payload_hashes <- list()
  stated <- spec$provenance$payload_hashes[[payload_id]]
  .md_input_check(is.null(stated) || identical(stated,p2_hash(values)),
    "The supplied payload hash differs from the raw array.","provenance.payload_hashes")
  spec$provenance$payload_hashes[[payload_id]] <- p2_hash(values)
  payload <- list(payload_id=payload_id,domain_ids=domains,representation=representation,
    values=values,state_ids=states,state_origin=state_origin,retention=retention,
    sampling_assumptions=assumptions,weights=masses)
  list(spec=spec,payload=payload)
}

.md_build_state_spec <- function(x, targets, provenance, representation, masses,
    state_origin, equality_classes) {
  joint <- is.array(x) && length(dim(x))==3L
  separate <- is.list(x) && !is.data.frame(x) && !is.array(x)
  .md_input_check(joint || separate,
    "x must be a labeled three-dimensional joint array, separate domain matrices, or a complete specification.","x")
  if (joint) {
    .md_input_check(is.numeric(x) && !is.complex(x) && all(is.finite(x)) &&
      dim(x)[1L]>=1L && dim(x)[2L]>=2L && dim(x)[3L]>=1L,
      "Joint values must be finite numeric state by unit by domain values.","x")
    units <- .md_input_ids(dimnames(x)[[2L]],dim(x)[2L],"unit_ids")
    domains <- .md_input_ids(dimnames(x)[[3L]],dim(x)[3L],"domain_ids")
  } else {
    domains <- .md_input_ids(names(x),length(x),"domain_ids")
    .md_input_check(length(x)>=1L && all(vapply(x,function(z)
      is.matrix(z) && is.numeric(z) && !is.complex(z) && nrow(z)>=1L && ncol(z)>=2L && all(is.finite(z)),logical(1))),
      "Each domain must retain a finite numeric state by unit matrix.","x")
    units <- .md_input_ids(colnames(x[[1L]]),ncol(x[[1L]]),"unit_ids")
    for(d in domains) .md_input_check(identical(colnames(x[[d]]),units),
      "Separate domain matrices must share exactly the declared unit order; no reordering is performed.",
      paste0("x.",d,".unit_ids"),"mdomain_input_ids")
    for(f in c("masses","state_origin")) {
      z <- get(f)
      .md_input_check(is.null(z) || (is.list(z) && !is.data.frame(z) && identical(names(z),domains)),
        paste0(f," for separate domains must be a domain-ordered named list."),f)
    }
  }
  if (length(representation)>1L) .md_input_check(separate &&
    is.character(representation) && identical(names(representation),domains),
    "Heterogeneous representations must be a domain-ordered named vector.","representation")
  targets <- .md_input_targets(targets,units,domains,equality_classes)
  spec <- .md_input_metadata(provenance,units,domains,targets,
    if(joint) "joint_array" else "criterionwise_arrays",representation)
  payloads <- list()
  for(k in seq_len(if(joint) 1L else length(domains))) {
    d <- domains[k]
    values <- if(joint) x else array(x[[d]],c(nrow(x[[d]]),length(units),1L),
      dimnames=list(rownames(x[[d]]),units,d))
    producer <- provenance
    if(separate) for(f in c("sampling_assumptions","retention")) {
      if(is.list(provenance[[f]]) && identical(names(provenance[[f]]),domains))
        producer[[f]] <- provenance[[f]][[d]]
    }
    result <- .md_state_payload(values,if(joint) "joint" else d,
      if(joint) domains else d,
      if(length(representation)>1L) representation[[d]] else representation,
      .md_state_component(masses,d,separate),.md_state_component(state_origin,d,separate),producer,spec)
    spec <- result$spec
    payloads[[k]] <- result$payload
  }
  spec$payloads <- payloads
  spec
}

.md_adapt_postrank_draws <- function(x, provenance) {
  receipt <- validate_postrank_draws(x)
  .md_input_check(isTRUE(receipt$valid),
    if(length(receipt$issues)) receipt$issues[[1L]]$message else "Invalid existing posterior input.",
    "x","mdomain_legacy_input_invalid")
  units <- x$entity_ids; domains <- x$criterion_ids
  targets <- setNames(lapply(domains,function(d) {
    t <- x$targets[[match(d,vapply(x$targets,`[[`,character(1),"criterion_id"))]]
    list(definition=t$estimand,units=t$units,orientation="larger_is_higher",
      transformations=list(t$source_transform),equality_classes=setNames(units,units),
      equality_provenance=paste("Existing pairwise_tie_free producer declaration:",x$tie_policy$justification),
      original_target=t)
  }),domains)
  .md_input_check(is.list(provenance),
    "Existing inputs additionally require input_id, law_id and proper_law declarations.","provenance")
  # Adaptation preserves declarations bound to the validated source. New
  # nonoverlapping metadata may supplement them; it cannot replace them.
  set_source_bound <- function(p, f, value, prefix="provenance") {
    if (is.null(value)) return(p)
    supplied <- p[[f]]
    path <- paste0(prefix, ".", f)
    named_record <- function(z) is.list(z) && !is.data.frame(z) &&
      (length(z) == 0L || (!is.null(names(z)) && !anyNA(names(z)) &&
        all(nzchar(names(z))) && !anyDuplicated(names(z))))
    if (!is.null(supplied) && named_record(value) && named_record(supplied)) {
      for (key in names(value))
        supplied <- set_source_bound(supplied, key, value[[key]], path)
      p[f] <- list(supplied)
    } else {
      .md_input_check(is.null(supplied) || identical(supplied, value),
        paste0("Supplemental metadata conflicts with the validated source: ", path, "."),
        path, "mdomain_legacy_metadata_conflict")
      p[f] <- list(value)
    }
    p
  }
  provenance <- set_source_bound(provenance,"producer",x$provenance$producer)
  provenance <- set_source_bound(provenance,"model_version",x$context$model_summary)
  provenance <- set_source_bound(provenance,"conditioning_info",x$context$data_conditioning)
  provenance <- set_source_bound(provenance,"conditioning_data_id",x$context$data_version)
  # The hash binds the actual validated input, rather than pretending that an
  # opaque producer artifact label is a verified SHA-256 content digest.
  provenance <- set_source_bound(provenance,"source_hash",receipt$input_identity)
  if(identical(x$input_kind,"exact_finite_posterior")) {
    law <- x$finite_law
    values <- array(0,c(length(law$states),length(units),length(domains)),
      dimnames=list(vapply(law$states,`[[`,character(1),"state_id"),units,domains))
    for(s in seq_along(law$states)) values[s,,] <- law$states[[s]]$theta
    masses <- vapply(law$states,function(z) paste0(format(z$mass_numerator,scientific=FALSE,trim=TRUE),"/",
      format(law$denominator,scientific=FALSE,trim=TRUE)),character(1))
    provenance <- set_source_bound(provenance,"joint_generation",law$law_definition)
    provenance <- set_source_bound(provenance,"sampling_assumptions",list(finite_support_origin=law$law_definition))
    return(.md_build_state_spec(values,targets,provenance,"exact_finite_law",masses,NULL,NULL))
  }
  joint <- identical(x$dependence_mode,"joint_model")
  blocks <- if(joint) list(x$joint_draws) else
    x$criterion_blocks[match(domains,vapply(x$criterion_blocks,`[[`,character(1),"criterion_id"))]
  if(joint) provenance <- set_source_bound(provenance,"joint_generation",blocks[[1L]]$cross_criterion_joint_provenance)
  else provenance <- set_source_bound(provenance,"within_domain_joint",
    paste(vapply(blocks,function(b)b$origin$vector_generation_provenance,character(1)),collapse="; "))
  values <- origins <- sampling <- retention <- vector("list",length(blocks))
  reps <- character(length(blocks))
  for(k in seq_along(blocks)) {
    b <- blocks[[k]]
    v <- if(joint) b$tensor$values else b$matrix$values
    slots <- dimnames(v)[[1L]]
    index <- b$draw_index[match(slots,vapply(b$draw_index,`[[`,character(1),"slot_id"))]
    origins[[k]] <- data.frame(source_index=seq_along(slots),
      chain_id=vapply(index,function(z) if(is.null(z$chain_id)) NA_character_ else z$chain_id,character(1)),
      iteration_id=vapply(index,function(z) if(is.null(z$iteration)) NA_real_ else as.numeric(z$iteration),numeric(1)),
      original_draw_id=vapply(index,`[[`,character(1),"original_draw_id"),
      state_id=slots,stringsAsFactors=FALSE)
    reps[k] <- if(b$sampling$regime=="mcmc") "mcmc_equal_weight_draws" else "iid_equal_weight_draws"
    sampling[[k]] <- if(b$sampling$regime=="mcmc")
      list(sampler=b$sampling$sampling_provenance,chain_details=b$sampling$chain_history,
        target_assertion=b$sampling$target_distribution) else
      list(iid_mechanism=b$sampling$sampling_provenance,target_assertion=b$sampling$target_distribution)
    retention[[k]] <- list(original_sampling=b$sampling,original_origin=b$origin,
      original_draw_index=b$draw_index,original_variable_map=b$variable_map)
    values[[k]] <- v
  }
  if(joint) {
    provenance <- set_source_bound(provenance,"sampling_assumptions",sampling[[1L]])
    provenance <- set_source_bound(provenance,"retention",retention[[1L]])
    .md_build_state_spec(values[[1L]],targets,provenance,reps[[1L]],NULL,origins[[1L]],NULL)
  } else {
    names(values) <- names(origins) <- names(sampling) <- names(retention) <- names(reps) <- domains
    provenance <- set_source_bound(provenance,"sampling_assumptions",sampling)
    provenance <- set_source_bound(provenance,"retention",retention)
    .md_build_state_spec(values,targets,provenance,reps,NULL,origins,NULL)
  }
}
