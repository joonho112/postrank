pr_trace_from_matrix <- function(x,id="synthetic_trace") {
  if(is.null(colnames(x))) colnames(x) <- paste0("chain",seq_len(ncol(x)))
  ids <- paste0("slot",seq_len(length(x)));iterations <- seq_len(nrow(x))+100L
  index <- lapply(seq_len(length(x)),function(s)list(slot_id=ids[s],chain_id=colnames(x)[(s-1L)%/%nrow(x)+1L],iteration=iterations[(s-1L)%%nrow(x)+1L]))
  list(trace_id=id,quantity="pair_indicator",values=as.numeric(x),draw_ids=ids,draw_index=rev(index),
    sampling=list(regime="mcmc",chain_history=lapply(colnames(x),function(chain)
      list(chain_id=chain,retained_iterations=iterations,warmup_iterations=1:100,discarded_sampling_iterations=integer()))),
    interpretation="post_selection_descriptive")
}

test_that("equal MCMC summaries preserve raw posterior function results", {
  skip_if_not_installed("posterior")
  set.seed(20261019)
  matrix <- matrix(rnorm(128*4),128,4,dimnames=list(NULL,c("a|b","b:c","003","chain4")))
  summary <- .pr_summarize_trace(pr_trace_from_matrix(matrix))
  functions <- list(rhat=posterior::rhat,ess_bulk=posterior::ess_bulk,ess_tail=posterior::ess_tail,
    ess_mean=posterior::ess_mean,mcse_mean=posterior::mcse_mean)
  for(name in names(functions)) {
    expected <- suppressWarnings(functions[[name]](matrix))
    expect_equal(summary$diagnostics[[name]]$raw_value,unname(expected),tolerance=1e-14)
    expect_identical(summary$diagnostics[[name]]$available,is.finite(expected))
  }
  expect_identical(summary$matrix_shape,list(iteration=128L,chain=4L))
  expect_identical(unname(summary$chain_lengths),rep(128L,4))
  expect_identical(summary$S,512L)
  expect_false(summary$convergence_verified);expect_false(summary$finite_sample_certificate)
  expect_identical(summary$interpretation,"post_selection_descriptive")
})

test_that("scalar affine loss MCSE scales after draw-level construction", {
  skip_if_not_installed("posterior")
  set.seed(1304)
  indicator <- matrix(rbinom(512,1,.2),128,4)
  pair <- .pr_summarize_trace(pr_trace_from_matrix(indicator,"pair"))
  loss <- .pr_summarize_trace(pr_trace_from_matrix(2/15+2*indicator/3,"fixed_loss"))
  expect_equal(loss$diagnostics$mcse_mean$value,(2/3)*pair$diagnostics$mcse_mean$value,tolerance=1e-12)
  expect_equal(loss$mean,2/15+2*pair$mean/3,tolerance=1e-14)
})

test_that("raw warnings errors and nonfinite diagnostic kinds remain distinguishable", {
  functions <- list(rhat=function(x){warning("original warning");NaN},
    ess_mean=function(x)stop("original diagnostic failure"),mcse_mean=function(x)Inf)
  metrics <- .pr_mcmc_trace_metrics(matrix(0,8,2),functions)
  expect_true(is.nan(metrics$rhat$raw_value));expect_identical(metrics$rhat$result_kind,"NaN")
  expect_false(metrics$rhat$available);expect_identical(metrics$rhat$warnings,"original warning")
  expect_identical(metrics$ess_mean$result_kind,"error")
  expect_identical(metrics$ess_mean$error,"original diagnostic failure")
  expect_identical(metrics$mcse_mean$result_kind,"Inf")
  expect_identical(metrics$mcse_mean$raw_value,Inf)
  unavailable <- .pr_mcmc_trace_metrics(matrix(0,8,2),functions=NULL)
  expect_true(all(vapply(unavailable,function(x)identical(x$unavailable_reason,"posterior_package_unavailable"),logical(1))))
})

test_that("constant and separately stuck chains retain visible evidence", {
  constant <- .pr_summarize_trace(pr_trace_from_matrix(matrix(0,8,2)))
  expect_true(constant$constant_pooled);expect_true(all(constant$constant_chains))
  expect_true(all(vapply(constant$per_chain,function(x)x$transitions==0,logical(1))))
  expect_true(length(constant$warnings)>0L);expect_false(constant$finite_sample_certificate)
  stuck <- .pr_summarize_trace(pr_trace_from_matrix(cbind(rep(0,8),rep(1,8))))
  expect_false(stuck$constant_pooled);expect_true(all(stuck$constant_chains))
  expect_identical(unname(stuck$chain_means),c(0,1))
  expect_true(any(grepl("chain is constant",stuck$warnings,fixed=TRUE)))
})

test_that("single short chain keeps actual posterior availability rather than filling values", {
  skip_if_not_installed("posterior")
  matrix <- matrix(c(0,1),2,1)
  summary <- .pr_summarize_trace(pr_trace_from_matrix(matrix))
  expect_true(summary$single_chain);expect_true(summary$short_chain)
  expected <- .pr_mcmc_trace_metrics(matrix)
  for(name in names(expected)) expect_equal(summary$diagnostics[[name]]$raw_value,expected[[name]]$raw_value,tolerance=0)
  expect_false(summary$convergence_verified)
})

test_that("exploration guidelines surface high Rhat and low ESS without convergence pass", {
  skip_if_not_installed("posterior")
  matrix <- outer(seq(-1,1,length.out=64),c(0,2,4,6),`+`)
  summary <- .pr_summarize_trace(pr_trace_from_matrix(matrix))
  expect_true(summary$practical_flags$rhat_above_guideline)
  expect_true(any(grepl("Rhat",summary$warnings,fixed=TRUE)))
  expect_identical(summary$practical_thresholds$ess_total_min,400)
  expect_false(summary$convergence_verified)
  boundary <- list(rhat=.pr_diagnostic_record(1.01,"rhat"),
    ess_mean=.pr_diagnostic_record(400,"ess_mean"),ess_bulk=.pr_diagnostic_record(NA_real_,"ess_bulk"))
  practical <- .pr_mcmc_practical_flags(boundary,4L)
  expect_false(practical$flags$rhat_above_guideline)
  expect_false(practical$flags$ess_mean_below_guideline)
  expect_true(is.na(practical$flags$ess_bulk_below_guideline))
  expect_length(practical$warnings,0L)
})

test_that("all-abstain action constants are distinguished from observed stuck traces", {
  trace <- pr_trace_from_matrix(matrix(.25,8,2))
  trace$quantity <- "weighted_total_loss"
  ordinary <- .pr_summarize_trace(trace)
  trace$structural_constant_from_action <- TRUE
  trace$structural_constant_reason <- "all_comparisons_withheld"
  action <- .pr_summarize_trace(trace)
  expect_true(action$structural_constant_from_action)
  expect_identical(action$structural_constant_reason,"all_comparisons_withheld")
  expect_true(any(grepl("constant by the all-abstain action",action$warnings,fixed=TRUE)))
  expect_false(any(grepl("observed MCMC chain is constant",action$warnings,fixed=TRUE)))
  for(name in names(ordinary$diagnostics)) expect_identical(action$diagnostics[[name]]$raw_value,ordinary$diagnostics[[name]]$raw_value)
  trace$quantity <- "pair_indicator"
  expect_error(.pr_summarize_trace(trace),"pair indicator",class="postrank_input_error")
})
