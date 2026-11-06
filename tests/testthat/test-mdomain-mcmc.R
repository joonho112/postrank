# Independent fictional histories: no posterior archive or sampler output is used.
# Their coordinates define supplied values; the MCMC designation is a producer
# assertion made only to test preservation and descriptive event diagnostics.
md_mcmc_fixture <- function(representation="mcmc_equal_weight_draws",
                            hits=c(3L,8L), origin=NULL, assumptions=NULL) {
  states <- paste0("retained-",seq_len(9L))
  values <- array(0,c(9L,2L,2L),
    dimnames=list(state=states,unit=c("A","B"),domain=c("need","cost")))
  values[,1L,] <- 2; values[,2L,] <- 1
  if (length(hits)) values[hits,1L,"need"] <- 0
  if (is.null(origin)) origin <- data.frame(
    source_index=c(3L,7L,11L,12L,20L,21L,28L,31L,40L),
    chain_id=c(rep("chain-A",5L),rep("chain-B",4L)),
    iteration_id=c(101L,104L,111L,120L,135L,201L,205L,218L,230L),
    state_id=states,stringsAsFactors=FALSE)
  if (is.null(assumptions)) assumptions <- if(representation=="exact_finite_law")
    list(finite_support_origin="The nine specified rows, each with mass 1/9, define this fictional finite law.") else
      if(representation=="iid_equal_weight_draws")
        list(iid_mechanism="Producer-declared fictional IID mechanism; not independently verified.",
          target_assertion="Producer-declared fictional two-coordinate target.") else
        list(sampler="Producer-declared fictional sampler; no sampling was performed.",
          chain_details="Two supplied histories of five and four retained states in original order.",
          target_assertion="Producer-declared fictional two-coordinate target.")
  targets <- setNames(lapply(c("need","cost"),function(d)
    list(definition=paste("Fictional",d,"coordinate"),units="illustrative units",
      orientation="larger_is_higher",transformations=list(),
      equality_classes=c(A="A",B="B"),
      equality_provenance="Distinct labels declare no structural identity between these fictional units.")),
    c("need","cost"))
  provenance <- list(input_id="independent-nine-row-history",law_id="fictional-history-target",
    proper_law=TRUE,producer="Independent package test generator",
    joint_generation="Each supplied row specifies both units in both domains as one complete state.",
    sampling_assumptions=assumptions,
    retention=list(warmup_removed=100L,thinning=NA_integer_,
      retention_note="The irregular retained positions are listed explicitly; no regular thinning interval is asserted."))
  postrank_mdomain_input(values,targets=targets,provenance=provenance,
    representation=representation,state_origin=origin,
    masses=if(representation=="exact_finite_law") rep("1/9",9L) else NULL)
}

md_mcmc_grades <- function(input) matrix(c(1L,2L,1L,2L),2L,
  dimnames=list(input$unit_ids,input$domain_ids))

md_mcmc_native <- function(input=md_mcmc_fixture(), decision=NULL,
                           batch_size=2L, keep_traces=TRUE, run_id="fictional-run") {
  card <- postrank_mdomain_evaluate(input,md_mcmc_grades(input),decision)
  p2_diagnose_mcmc(input,card$action,card$decision,batch_size=batch_size,
    keep_traces=keep_traces,run_id=run_id)
}

test_that("MCMC counts pool retained states and preserve chain positions and iterations", {
  skip_if_not_installed("gmp")
  input <- md_mcmc_fixture(); result <- md_mcmc_native(input)
  expect_s3_class(result,"p2_mcmc_diagnostics")
  expect_identical(result$representation,"mcmc_equal_weight_draws")
  expect_identical(result$empirical_J_exact,"2/9")
  expect_equal(result$empirical_J,2/9,tolerance=0)
  expect_identical(result$receipts$chain_lengths,c("chain-A"=5L,"chain-B"=4L))
  expect_true(result$receipts$unequal_chain_lengths)
  expect_true(result$receipts$chain_rates_not_averaged)
  union <- result$chain_table[result$chain_table$event_id=="joint-union",]
  expect_identical(union$chain_id,c("chain-A","chain-B"))
  expect_identical(union$n_retained,c(5L,4L))
  expect_equal(union$hit_count,c(1,1),tolerance=0)
  expect_equal(union$rate,c(1/5,1/4),tolerance=0)
  expect_false(isTRUE(all.equal(result$empirical_J,mean(union$rate),tolerance=0)))
  expect_identical(union$first_hit_chain_position,c(3L,3L))
  expect_identical(union$first_hit_input_row,c(3L,8L))
  expect_identical(union$first_hit_state_id,c("retained-3","retained-8"))
  expect_equal(union$first_hit_iteration,c(111L,218L),tolerance=0)
  # Zero runs count retained positions, not the gaps between original iterations.
  expect_identical(union$max_zero_run,c(2L,2L))
  expect_identical(result$histories$input_row,seq_len(9L))
  expect_identical(result$histories$state_id,input$payloads[[1L]]$state_ids)
  expect_identical(result$histories$source_index,input$payloads[[1L]]$state_origin$source_index)
  expect_identical(result$histories$iteration_id,input$payloads[[1L]]$state_origin$iteration_id)
  expect_false(result$receipts$chains_reordered)
  expect_true(result$receipts$zero_runs_count_retained_rows_not_unobserved_iterations)
})

test_that("MCMC batches retain final partial batches within each original chain", {
  skip_if_not_installed("gmp")
  result <- md_mcmc_native()
  union <- result$chain_table[result$chain_table$event_id=="joint-union",]
  expect_equal(union$batch_count,c(3L,2L),tolerance=0)
  expect_equal(union$full_batch_count,c(2L,2L),tolerance=0)
  expect_equal(union$partial_batch_count,c(1L,0L),tolerance=0)
  expect_equal(union$full_batch_rate_min,c(0,0),tolerance=0)
  expect_equal(union$full_batch_rate_max,c(.5,.5),tolerance=0)
  batches <- result$batch_table[result$batch_table$event_id=="joint-union",]
  expect_identical(batches$chain_id,c(rep("chain-A",3L),rep("chain-B",2L)))
  expect_equal(batches$batch_id,c(1L,2L,3L,1L,2L),tolerance=0)
  expect_equal(batches$n_retained,c(2L,2L,1L,2L,2L),tolerance=0)
  expect_equal(batches$rate,c(0,.5,0,0,.5),tolerance=0)
  expect_identical(batches$partial,c(FALSE,FALSE,TRUE,FALSE,FALSE))
  expect_equal(batches$input_row_start,c(1L,3L,5L,6L,8L),tolerance=0)
  expect_equal(batches$input_row_end,c(2L,4L,5L,7L,9L),tolerance=0)
  expect_equal(batches$iteration_start,c(101L,111L,135L,201L,218L),tolerance=0)
  expect_equal(batches$iteration_end,c(104L,120L,135L,205L,230L),tolerance=0)
  expect_true(result$receipts$final_partial_batches_retained)
  expect_true(result$receipts$batch_rates_are_not_independent_replicates)
  short <- md_mcmc_native(batch_size=20L)
  short_union <- short$chain_table[short$chain_table$event_id=="joint-union",]
  expect_equal(short_union$full_batch_count,c(0L,0L),tolerance=0)
  expect_true(all(is.na(short_union$full_batch_rate_min)))
  expect_true(all(is.na(short_union$full_batch_rate_max)))
})

test_that("no observed MCMC hits and structural zero events have distinct receipts", {
  skip_if_not_installed("gmp")
  input <- md_mcmc_fixture(); result <- md_mcmc_native(input)
  expect_identical(unname(result$event_status),
    c("observed_variation","no_observed_hits","observed_variation"))
  nohit <- result$chain_table[result$chain_table$event_id=="joint-2",]
  expect_identical(nohit$status,rep("no_observed_hits",2L))
  expect_true(all(nohit$zero_hit))
  expect_true(all(is.na(nohit$first_hit_chain_position)))
  expect_true(all(is.na(nohit$first_hit_iteration)))
  expect_true(all(is.na(nohit$first_hit_state_id)))
  expect_identical(nohit$max_zero_run,c(5L,4L))
  expect_false(any(result$event_catalog$structurally_zero))
  structural <- md_mcmc_native(input,postrank_mdomain_decision(t=c(need="0",cost="1")))
  expect_identical(unname(structural$event_status["joint-2"]),"structurally_zero")
  expect_identical(structural$event_catalog$structurally_zero,c(FALSE,TRUE,FALSE))
  expect_identical(structural$chain_table$status[structural$chain_table$event_id=="joint-2"],
    rep("structurally_zero",2L))
  expect_identical(structural$empirical_J_exact,"2/9")
  empty <- md_mcmc_native(md_mcmc_fixture(hits=integer()))
  expect_identical(empty$empirical_J_exact,"0")
  expect_identical(unname(empty$event_status["joint-union"]),"no_observed_hits")
  expect_false(empty$receipts$structurally_zero_union)
  disabled <- md_mcmc_native(input,postrank_mdomain_decision(t=NULL))
  expect_true(disabled$receipts$protection_disabled)
  expect_true(disabled$receipts$structurally_zero_union)
  expect_identical(disabled$empirical_J_exact,"0")
})

test_that("MCMC trace omission preserves source history and diagnostic provenance", {
  skip_if_not_installed("gmp")
  input <- md_mcmc_fixture(); full <- md_mcmc_native(input)
  small <- md_mcmc_native(input,keep_traces=FALSE)
  expect_null(small$trace)
  expect_false(small$receipts$trace_retained)
  expect_true(full$receipts$trace_retained)
  for (field in c("histories","history_receipts","chain_table","batch_table","event_catalog",
                  "event_status","empirical_J","empirical_J_exact","contracts","contract_hashes",
                  "source_input_hash","input_receipts","input_provenance","selection_provenance"))
    expect_identical(small[[field]],full[[field]],info=field)
  receipt <- small$history_receipts[[1L]]
  expect_identical(receipt$state_origin,input$payloads[[1L]]$state_origin)
  expect_identical(receipt$sampling_assumptions,input$payloads[[1L]]$sampling_assumptions)
  expect_identical(receipt$retention,input$payloads[[1L]]$retention)
  expect_true(small$receipts$source_provenance_preserved)
  expect_false(identical(small$diagnostic_hash,full$diagnostic_hash))
})

test_that("MCMC diagnostics reject regime relabeling and unordered or incomplete histories", {
  skip_if_not_installed("gmp")
  for (representation in c("iid_equal_weight_draws","exact_finite_law")) {
    input <- md_mcmc_fixture(representation)
    expect_error(md_mcmc_native(input),"MCMC diagnostics require MCMC representation",info=representation)
    expect_error(md_mcmc_native(input,postrank_mdomain_decision(t=NULL)),
      "MCMC diagnostics require MCMC representation",info=representation)
  }
  origin <- md_mcmc_fixture()$payloads[[1L]]$state_origin
  duplicate <- origin; duplicate$iteration_id[2L] <- duplicate$iteration_id[1L]
  expect_error(md_mcmc_fixture(origin=duplicate),"Duplicate known iteration",
    class="postrank_mdomain_error")
  decreasing <- origin; decreasing$iteration_id[c(2L,3L)] <- decreasing$iteration_id[c(3L,2L)]
  input <- md_mcmc_fixture(origin=decreasing)
  expect_false(input$payloads[[1L]]$receipt$within_chain_strictly_increasing)
  expect_error(md_mcmc_native(input),"strictly increasing.*no sorting")
  for (field in c("source_index","chain_id","iteration_id")) {
    missing <- origin; missing[[field]][2L] <- NA
    expect_error(md_mcmc_fixture(origin=missing),"must be known",class="postrank_mdomain_error",info=field)
  }
  for (bad in list(0L,NA_integer_,1.5))
    expect_error(md_mcmc_native(batch_size=bad),"batch_size")
  expect_error(md_mcmc_native(keep_traces=NA),"keep_traces")
  expect_error(md_mcmc_native(run_id=""),"run_id")
})

test_that("MCMC receipts retain missing producer claims and make no statistical certificate", {
  skip_if_not_installed("gmp")
  input <- md_mcmc_fixture(assumptions=list())
  result <- md_mcmc_native(input)
  expect_identical(input$payloads[[1L]]$sampling_assumptions,list())
  expect_true(all(paste0("payloads.joint.sampling_assumptions.",
    c("sampler","chain_details","target_assertion")) %in% names(input$missing_metadata)))
  expect_identical(result$history_receipts[[1L]]$sampling_assumptions,list())
  expect_identical(unname(input$receipts$sampling_status),"empirical_mcmc_no_iid_or_finite_certificate")
  expect_true(result$diagnostics_not_certificate)
  expect_false(result$numerical_guarantee)
  expect_identical(result$receipts$status,"descriptive_MCMC_events_only")
  for (field in c("numerical_guarantee","intended_posterior_feasibility_certified",
                  "convergence_established","independence_established",
                  "iid_or_binomial_inference_performed","ESS_or_Rhat_computed","split_chain_is_heldout"))
    expect_false(result$receipts[[field]],info=field)
  expect_true(result$receipts$diagnostics_not_certificate)
  expect_true(result$receipts$no_cross_payload_alignment)
})

test_that("repeated MCMC run comparisons remain descriptive with frozen contracts", {
  skip_if_not_installed("gmp")
  one <- md_mcmc_native(run_id="run-one")
  two <- md_mcmc_native(run_id="run-two",keep_traces=FALSE)
  result <- p2_compare_mcmc_runs(list(one,two))
  expect_s3_class(result,"p2_mcmc_run_comparison")
  expect_identical(result$run_table$run_id,c("run-one","run-two"))
  expect_identical(result$run_table$empirical_J_exact,c("2/9","2/9"))
  expect_true(result$diagnostics_not_certificate)
  expect_false(result$numerical_guarantee)
  expect_false(result$receipts$scientific_law_compatibility_independently_verified)
  expect_false(result$receipts$independence_established)
  expect_false(result$receipts$runs_pooled)
  expect_true(result$receipts$identical_source_input_hash_detected)
  expect_true(result$receipts$no_binomial_or_iid_certificate)
  expect_true(result$receipts$stability_is_not_convergence_proof)
  expect_error(p2_compare_mcmc_runs(list(one,one)),"Duplicate run_id")
  changed <- two; changed$empirical_J <- 0
  expect_error(p2_compare_mcmc_runs(list(one,changed)),"modified")
  changed <- md_mcmc_native(decision=postrank_mdomain_decision(alpha="1/2"),run_id="changed")
  expect_error(p2_compare_mcmc_runs(list(one,changed)),"frozen decision contracts")
})

test_that("public MCMC assessments expose native diagnostics without target-law confidence", {
  skip_if_not_installed("gmp")
  input <- md_mcmc_fixture(); grades <- md_mcmc_grades(input)
  design <- list(claimed_converged=TRUE,declared_independent_chains=TRUE,
    role="Caller assertion retained without verification")
  result <- postrank_mdomain_assess(input,grades,method="mcmc",design=design,
    batch_size=2L,run_id="public-history",keep_traces=FALSE)
  expect_s3_class(result,"postrank_mdomain_assessment")
  expect_s3_class(result$native,"p2_mcmc_diagnostics")
  expect_s3_class(result$evaluation,"postrank_mdomain_evaluation")
  expect_identical(result$evaluation$input,input)
  expect_identical(result$method,"mcmc")
  expect_identical(result$status,"descriptive_MCMC_events_only")
  expect_identical(result$design,design)
  expect_identical(result$J_exact,"2/9")
  expect_identical(result$J,result$native$empirical_J)
  expect_identical(result$evaluation$J_exact,"2/9")
  expect_identical(result$risk_exact,result$evaluation$risk_exact)
  expect_identical(result$spec_hashes,result$evaluation$receipts$validation_spec_hashes)
  expect_false(result$joint_certificate)
  expect_identical(result$certificate_scope,"none")
  expect_true(result$assurance$diagnostics_not_certificate)
  expect_false(result$assurance$assumptions_verified)
  expect_identical(result$assurance$proper_law_status,"producer_declaration")
  for (field in c("convergence_established","independence_established",
                  "intended_posterior_feasibility_certified"))
    expect_false(result$assurance[[field]],info=field)
  expect_null(result$native$trace)
  expect_null(result$evaluation$evaluation$traces)
  expect_equal(nrow(result$native$histories),9L)
  frozen <- postrank_mdomain_evaluate(input,grades,mode="expected",keep_traces=FALSE)
  assessed <- postrank_mdomain_assess(input,frozen,method="mcmc",batch_size=2L)
  expect_identical(assessed$J_exact,"2/9")
  expect_identical(assessed$evaluation$grades,frozen$grades)
  expect_false(assessed$joint_certificate)
  for (representation in c("iid_equal_weight_draws","exact_finite_law")) {
    other <- md_mcmc_fixture(representation)
    expect_error(postrank_mdomain_assess(other,md_mcmc_grades(other),method="mcmc"),
      class="postrank_mdomain_error",info=representation)
  }
  expect_error(postrank_mdomain_assess(input,grades,method="exact"),class="postrank_mdomain_error")
  expect_error(postrank_mdomain_assess(input,grades,method="iid",design=list()),
    class="postrank_mdomain_error")
})
