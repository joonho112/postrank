testthat::test_that("opaque IDs, target declarations and finite values are checked", {
  x<-pr_test_payload(); testthat::expect_true(validate_postrank_draws(x)$valid)
  y<-x;y$targets<-rev(y$targets);testthat::expect_true(validate_postrank_draws(y)$valid)
  y<-x;y$entity_ids<-c("001","1","003");y$joint_draws$tensor$dimnames$entity<-y$entity_ids
  dimnames(y$joint_draws$tensor$values)$entity<-y$entity_ids
  for(i in seq_along(y$joint_draws$variable_map)){r<-y$joint_draws$variable_map[[i]];if(r$entity_id=="002")y$joint_draws$variable_map[[i]]$entity_id<-"1"}
  testthat::expect_identical(as_postrank_draws(y)$entity_ids,c("001","1","003"))
  for(bad in list(c("a","a","b"),c("a"," ","b"),c("a","\u00a0","b"),c("a","\u2003","b"),c(1,2,3))){y<-x;y$entity_ids<-bad;testthat::expect_false(validate_postrank_draws(y)$valid)}
  y<-x;y$identification$status<-"unresolved";testthat::expect_error(as_postrank_draws(y),class="postrank_input_error")
  y<-x;y$targets[[1]]$orientation<-"lower_priority";testthat::expect_false(validate_postrank_draws(y)$valid)
  y<-x;y$targets[[1]]$estimand<-" ";testthat::expect_false(validate_postrank_draws(y)$valid)
  y<-x;y$requested_functional<-"joint_tail";testthat::expect_false(validate_postrank_draws(y)$valid)
  y<-x;y$weights<-rep(1/4,4);testthat::expect_false(validate_postrank_draws(y)$valid)
  y<-x;y$context$model_summary<-matrix("bad");testthat::expect_false(validate_postrank_draws(y)$valid)
})
testthat::test_that("receipt separates structure, source and scientific checks",{
  d<-as_postrank_draws(pr_test_payload());v<-d$validation
  testthat::expect_true(v$valid);testthat::expect_false(v$schema_checked)
  testthat::expect_false(v$source_values_checked);testthat::expect_false(v$jointness_verified);testthat::expect_false(v$convergence_verified)
  testthat::expect_identical(d$schema_version,"0.1.0");testthat::expect_identical(.pr_payload(d)$schema_version,"applied-0.1")
  y<-d;y$joint_draws$tensor$values[1,1,1]<-NA_real_;testthat::expect_false(validate_postrank_draws(y)$valid)
})
