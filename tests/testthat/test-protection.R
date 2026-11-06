pr_protection_fixture <- function(q=c(need2=.2)) {
  x <- pr_test_payload(S=1L,n=2L,K=2L)
  x$joint_draws$tensor$values[1,,1] <- c(2,1)
  x$joint_draws$tensor$values[1,,2] <- c(1,2)
  hash <- digest::digest(x$joint_draws$tensor$values,algo="sha256")
  x$provenance$artifact_hash <- hash;x$joint_draws$origin$source_hash <- hash
  p <- postrank_pairwise(x)
  settings <- list(weights=c(need1=1,need2=0),tau=.25,G_max=2L,q=q)
  base <- .pr_weighted_model(p,settings)
  list(pairwise=p,settings=settings,base=base)
}
pr_optional_primal <- function(base,grade,t=NULL) {
  z <- numeric(length(base$model$objective))
  z[base$index$labels] <- grade
  z[base$index$pairs] <- as.numeric(grade[base$index$pair_i]<grade[base$index$pair_j])
  if(!is.null(t)) z[base$index$t] <- t
  z
}

test_that("zero-weight criterion is independently protected and all-tie is feasible", {
  fixture <- pr_protection_fixture();base <- fixture$base
  protected <- .pr_add_protection(base,fixture$pairwise,fixture$settings)
  z <- pr_optional_primal(protected,c(1,2))
  expect_identical(sum(base$model$objective*z),-.25)
  expect_equal(tail(as.numeric(protected$model$A%*%z),1),.8,tolerance=1e-15)
  tied <- pr_optional_primal(protected,c(1,1))
  expect_identical(tail(as.numeric(protected$model$A%*%tied),1),0)
  expect_identical(protected$model$objective,base$model$objective)
  expect_identical(protected$model$row_names[length(protected$model$row_names)],"protection_2")
  expect_equal(protected$model$A[seq_len(nrow(base$model$A)),,drop=FALSE],base$model$A,tolerance=0)
})

test_that("named protection budgets select their own criteria and extreme budgets", {
  fixture <- pr_protection_fixture(q=c(need2=.2,need1=.8))
  protected <- .pr_add_protection(fixture$base,fixture$pairwise,fixture$settings)
  z <- pr_optional_primal(protected,c(1,2))
  expect_equal(tail(as.numeric(protected$model$A%*%z),2),c(.8,-.8),tolerance=1e-15)
  for(q in c(0,1)) {
    fixture <- pr_protection_fixture(q=c(need2=q))
    protected <- .pr_add_protection(fixture$base,fixture$pairwise,fixture$settings)
    forward <- tail(as.numeric(protected$model$A%*%pr_optional_primal(protected,c(1,2))),1)
    backward <- tail(as.numeric(protected$model$A%*%pr_optional_primal(protected,c(2,1))),1)
    expect_equal(forward,1-q,tolerance=0);expect_equal(backward,-q,tolerance=0)
  }
  fixture <- pr_protection_fixture(q=NULL)
  expect_identical(.pr_add_protection(fixture$base,fixture$pairwise,fixture$settings),fixture$base)
})

test_that("protection appends sparse rows across pre-existing extra variable columns", {
  fixture <- pr_protection_fixture();base <- fixture$base
  nrows <- nrow(base$model$A);old <- ncol(base$model$A)
  base$model$A <- cbind(base$model$A,Matrix::sparseMatrix(i=integer(),j=integer(),x=numeric(),dims=c(nrows,2L)))
  base$model$objective <- c(base$model$objective,0,0)
  base$model$var_lower <- c(base$model$var_lower,0,0);base$model$var_upper <- c(base$model$var_upper,1,1)
  base$model$types <- c(base$model$types,"B","B");base$model$var_names <- c(base$model$var_names,"extra1","extra2")
  base$index$assignment <- matrix(old+1:2,1L,2L)
  protected <- .pr_add_protection(base,fixture$pairwise,fixture$settings)
  expect_identical(ncol(protected$model$A),old+2L)
  expect_equal(as.numeric(protected$model$A[nrows+1L,c(old+1L,old+2L)]),c(0,0),tolerance=0)
  expect_identical(protected$index,base$index)
  expect_identical(protected$pair_map,base$pair_map)
})
