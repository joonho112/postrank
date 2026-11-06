test_that("pair blocks match reference across asymmetric shapes and block boundaries", {
  set.seed(20261019)
  for(shape in list(c(1L,2L),c(1L,5L),c(7L,2L),c(31L,5L),c(3L,7L))) {
    values <- matrix(rnorm(prod(shape)),shape[1],shape[2],
                     dimnames=list(draw=paste0("d",seq_len(shape[1])),entity=sprintf("%03d",seq_len(shape[2]))))
    expected <- .pr_pairwise_reference_one(values)
    for(size in c(1L,2L,3L,8L,ncol(values)*(ncol(values)-1L)+7L)) {
      result <- .pr_pairwise_blocks_one(values,size)
      expect_equal(result,expected,tolerance=0)
      expect_identical(dimnames(result),list(entity_i=colnames(values),entity_j=colnames(values)))
      expect_true(all(is.na(diag(result))))
    }
  }
})

test_that("single draw preserves exact directional zero and one", {
  values <- matrix(c(3,2,1),1L,3L,dimnames=list(draw="one",entity=c("001","010","100")))
  result <- .pr_pairwise_blocks_one(values,2L)
  expected <- matrix(c(NA,1,1,0,NA,1,0,0,NA),3L,3L,
                     dimnames=list(entity_i=colnames(values),entity_j=colnames(values)))
  expect_identical(result,expected)
  expect_identical(.pr_pairwise_blocks_one(values,9007199254740991),expected)
})

test_that("pair blocks retain within-row site coupling and full draw count", {
  coupled <- cbind(`001`=0:3,`002`=c(.5,1.5,2.5,3.5))
  shuffled <- coupled; shuffled[,2] <- rev(shuffled[,2])
  original <- .pr_pairwise_blocks_one(coupled,1L)
  changed <- .pr_pairwise_blocks_one(shuffled,2L)
  expect_identical(original[1,2],1)
  expect_identical(changed[1,2],.5)
  expect_identical(sort(coupled[,2]),sort(shuffled[,2]))
  expect_identical(.pr_pairwise_blocks_one(coupled[c(4,2,1,3),,drop=FALSE],2L),original)
  # Three retained states give denominator 3; no padding/truncation is permitted.
  expect_equal(.pr_pairwise_blocks_one(shuffled[1:3,,drop=FALSE],1L)[1,2],2/3,tolerance=0)
})

test_that("joint fixture matrices retain singleton and criterion-specific values", {
  for(x in list(pr_test_payload(S=1L,n=2L,K=1L),pr_test_payload(),pr_test_criterionwise())) {
    matrices <- .pr_draw_matrices(as_postrank_draws(x))
    for(values in matrices)
      expect_equal(.pr_pairwise_blocks_one(values,2L),.pr_pairwise_reference_one(values),tolerance=0)
  }
})

test_that("invalid pair-block sizes fail before aggregation", {
  values <- matrix(1:4,2L,2L)
  for(size in list(0,-1,1.5,NA_real_,Inf,TRUE,"2",c(1,2),matrix(2,1,1)))
    expect_error(.pr_pairwise_blocks_one(values,size),class="postrank_input_error")
})
