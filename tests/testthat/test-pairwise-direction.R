testthat::test_that("directional errors, zero/one and diagonal have intended meaning",{
  x<-as_postrank_draws(pr_test_payload(S=1L,n=3L,K=1L));a<-.pr_draw_matrices(x)[[1]]
  e<-.pr_pairwise_reference_one(a)
  testthat::expect_true(all(is.na(diag(e))))
  testthat::expect_identical(e[1,2],1);testthat::expect_identical(e[2,1],0)
  testthat::expect_equal((e+t(e))[row(e)!=col(e)],rep(1,6))
  y<-pr_test_payload();y$joint_draws$tensor$values[1,1,1]<-y$joint_draws$tensor$values[1,2,1]
  testthat::expect_error(as_postrank_draws(y),"tie",class="postrank_input_error")
})

testthat::test_that("aggregated coefficient identity catches accidental mutation",{
  d<-as_postrank_draws(pr_test_payload());e<-.pr_empty_e(d$entity_ids,d$criterion_ids)
  mats<-.pr_draw_matrices(d);for(k in seq_along(mats))e[,,k]<-.pr_pairwise_reference_one(mats[[k]])
  p<-.pr_new_pairwise(d,e,rep(4,2),"reference")
  p$e[1,2,1]<-.2;p$e[2,1,1]<-.8
  testthat::expect_error(.pr_validate_pairwise(p),"changed after aggregation",class="postrank_input_error")
})
