pr_basic_trace <- function(values,regime="iid") {
  ids <- paste0("d",seq_along(values))
  list(trace_id="test_trace",quantity="criterion_error_over_M",criterion_id="need1",values=values,draw_ids=ids,
    draw_index=lapply(ids,function(id)list(slot_id=id,chain_id=NULL,iteration=NULL)),
    sampling=list(regime=regime,chain_history=list()))
}

test_that("IID summaries give descriptive SE without MCMC or certification claims", {
  trace <- pr_basic_trace(c(0,1,1))
  summary <- .pr_summarize_trace(trace)
  expect_identical(summary$mean,2/3)
  expect_equal(summary$diagnostics$mcse_mean$value,1/3,tolerance=1e-14)
  expect_identical(summary$diagnostics$rhat$unavailable_reason,"not_applicable_iid")
  expect_identical(summary$chain_count,0L);expect_false(summary$finite_sample_certificate)
  single <- .pr_summarize_trace(pr_basic_trace(0))
  expect_false(single$diagnostics$mcse_mean$available)
  expect_identical(single$diagnostics$mcse_mean$unavailable_reason,"insufficient_iid_draws")
  constant <- .pr_summarize_trace(pr_basic_trace(rep(0,4)))
  expect_identical(constant$naive_iid_mcse,0)
  expect_true(length(constant$diagnostics$mcse_mean$warnings)>0L)
})

test_that("unequal MCMC chains keep all retained values and count-weighted mean", {
  trace <- pr_basic_trace(c(0,1,0,1,1,1),"mcmc")
  chains <- c("a","b","a","b","b","b");iterations <- c(11,21,13,22,24,30)
  trace$draw_index <- rev(lapply(seq_along(chains),function(i)list(slot_id=trace$draw_ids[i],chain_id=chains[i],iteration=iterations[i])))
  trace$sampling$chain_history <- list(list(chain_id="a",retained_iterations=c(11,13)),list(chain_id="b",retained_iterations=c(21,22,24,30)))
  summary <- .pr_summarize_trace(trace)
  expect_identical(summary$S,6L);expect_identical(summary$mean,2/3)
  expect_identical(unname(summary$chain_lengths),c(2L,4L))
  expect_identical(unname(summary$chain_means),c(0,1))
  expect_identical(summary$per_chain$a$original_iterations,c(11,13))
  expect_identical(summary$per_chain$b$original_iterations,c(21,22,24,30))
  expect_true(all(vapply(summary$diagnostics,function(x)identical(x$unavailable_reason,"unequal_chain_lengths"),logical(1))))
  expect_true(all(vapply(summary$diagnostics,function(x)!x$available&&x$result_kind=="not_computed",logical(1))))
  expect_identical(summary$unavailable_reason,"unequal_chain_lengths")
})

test_that("original chronological transitions survive reordered index records", {
  trace <- pr_basic_trace(c(0,1,1,0,1,1,0,0),"mcmc")
  trace$draw_index <- rev(lapply(seq_along(trace$values),function(i)
    list(slot_id=trace$draw_ids[i],chain_id=if(i<=4)"a" else "b",iteration=c(11,12,15,20)[(i-1)%%4+1])))
  trace$sampling$chain_history <- lapply(c("a","b"),function(id)list(chain_id=id,retained_iterations=c(11,12,15,20)))
  summary <- .pr_summarize_trace(trace)
  expect_identical(summary$per_chain$a$transitions,2L)
  expect_identical(summary$per_chain$b$transitions,1L)
  expect_identical(summary$per_chain$a$original_iterations,c(11,12,15,20))
})

test_that("finite-law summaries use declared weights without inventing rational arithmetic", {
  trace <- pr_basic_trace(c(0,1),"exact_law");trace$draw_index <- NULL
  trace$exact_weights <- c(.9,.1)
  summary <- .pr_summarize_trace(trace)
  expect_identical(summary$mean,.1)
  expect_identical(summary$mean_source,"finite_law_weighted_double_projection")
  expect_true(all(vapply(summary$diagnostics,function(x)identical(x$unavailable_reason,"exact_law_MC_not_used"),logical(1))))
  expect_true(is.na(summary$naive_iid_mcse));expect_false(summary$numerical_certification)
  trace$mean_override <- .10000000000000002
  override <- .pr_summarize_trace(trace)
  expect_identical(override$mean,trace$mean_override)
  expect_identical(override$mean_source,"finite_law_weighted_double_projection")
  trace$mean_source <- "exact_rational_double_projection"
  expect_identical(.pr_summarize_trace(trace)$mean_source,"exact_rational_double_projection")
})

test_that("malformed traces do not silently change regime history or values", {
  trace <- pr_basic_trace(c(0,1))
  bad <- trace;bad$values[1] <- NA
  expect_error(.pr_summarize_trace(bad),class="postrank_input_error")
  bad <- trace;bad$draw_ids[1] <- "unknown"
  expect_error(.pr_summarize_trace(bad),"cover",class="postrank_input_error")
  bad <- trace;bad$mean_override <- .5
  expect_error(.pr_summarize_trace(bad),"override",class="postrank_input_error")
  bad <- trace;bad$sampling$regime <- "unknown"
  expect_error(.pr_summarize_trace(bad),"regime",class="postrank_input_error")
  bad <- trace;bad$sampling$regime <- "exact_law";bad$exact_weights <- c(.8,.8)
  expect_error(.pr_summarize_trace(bad),"sum to one",class="postrank_input_error")
})
