pr_minimax_fixture <- function(anticorrelated=FALSE,selected=NULL) {
  x <- pr_test_payload(S=2L,n=2L,K=2L)
  x$joint_draws$tensor$values[1,,1] <- c(2,1)
  x$joint_draws$tensor$values[2,,1] <- c(1,2)
  x$joint_draws$tensor$values[1,,2] <- if(anticorrelated)c(1,2) else c(2,1)
  x$joint_draws$tensor$values[2,,2] <- if(anticorrelated)c(2,1) else c(1,2)
  hash <- digest::digest(x$joint_draws$tensor$values,algo="sha256")
  x$provenance$artifact_hash <- hash;x$joint_draws$origin$source_hash <- hash
  p <- postrank_pairwise(x)
  settings <- list(weights=c(need1=.9,need2=.1),tau=.25,G_max=2L,q=NULL,minimax_criteria=selected)
  base <- .pr_weighted_model(p,settings)
  list(input=x,pairwise=p,settings=settings,base=base)
}
pr_minimax_primal <- function(base,grade,t) {
  z <- numeric(length(base$model$objective));z[base$index$labels] <- grade
  z[base$index$pairs] <- as.numeric(grade[base$index$pair_i]<grade[base$index$pair_j])
  z[base$index$t] <- t;z
}

test_that("minimax adds a risk-unit continuous epigraph and clears weighted objective", {
  fixture <- pr_minimax_fixture();base <- fixture$base
  minimax <- .pr_add_minimax(base,fixture$pairwise,fixture$settings)
  t <- minimax$index$t
  expect_identical(t,ncol(base$model$A)+1L)
  expect_identical(minimax$model$types[t],"C")
  expect_identical(minimax$model$var_lower[t],0);expect_identical(minimax$model$var_upper[t],1)
  expect_identical(minimax$model$objective,c(rep(0,t-1L),1))
  expect_equal(minimax$model$A[seq_len(nrow(base$model$A)),seq_len(t-1L),drop=FALSE],base$model$A,tolerance=0)
  feasible <- pr_minimax_primal(minimax,c(1,2),.5)
  expect_equal(tail(as.numeric(minimax$model$A%*%feasible)-minimax$model$row_upper,2),c(0,0),tolerance=0)
  low <- pr_minimax_primal(minimax,c(1,2),.49)
  expect_true(all(tail(as.numeric(minimax$model$A%*%low)-minimax$model$row_upper,2)>0))
  tied <- pr_minimax_primal(minimax,c(1,1),.25)
  expect_equal(tail(as.numeric(minimax$model$A%*%tied)-minimax$model$row_upper,2),c(0,0),tolerance=0)
  expect_identical(sum(minimax$model$objective*feasible),.5)
})

test_that("minimax is maximum expected loss rather than expectation of draw maximum", {
  coupled <- pr_minimax_fixture(FALSE);opposed <- pr_minimax_fixture(TRUE)
  expect_identical(coupled$pairwise$e,opposed$pairwise$e)
  a <- .pr_add_minimax(coupled$base,coupled$pairwise,coupled$settings)
  b <- .pr_add_minimax(opposed$base,opposed$pairwise,opposed$settings)
  expect_identical(a$model$A,b$model$A)
  expect_identical(a$model$objective,b$model$objective)
  draw_errors <- function(x) sapply(1:2,function(k)as.numeric(x$joint_draws$tensor$values[,1,k]<=x$joint_draws$tensor$values[,2,k]))
  positive <- draw_errors(coupled$input);negative <- draw_errors(opposed$input)
  expect_identical(max(colMeans(positive)),.5);expect_identical(max(colMeans(negative)),.5)
  expect_identical(mean(apply(positive,1,max)),.5)
  expect_identical(mean(apply(negative,1,max)),1)
})

test_that("minimax selected criterion and prior extra columns remain correctly indexed", {
  fixture <- pr_minimax_fixture(selected="need2");base <- fixture$base
  old <- ncol(base$model$A);rows <- nrow(base$model$A)
  base$model$A <- cbind(base$model$A,Matrix::sparseMatrix(i=integer(),j=integer(),x=numeric(),dims=c(rows,2L)))
  base$model$objective <- c(base$model$objective,.37,.19)
  base$model$var_lower <- c(base$model$var_lower,0,0);base$model$var_upper <- c(base$model$var_upper,1,1)
  base$model$types <- c(base$model$types,"B","B");base$model$var_names <- c(base$model$var_names,"extra1","extra2")
  base$index$assignment <- matrix(old+1:2,1L,2L)
  minimax <- .pr_add_minimax(base,fixture$pairwise,fixture$settings)
  expect_identical(minimax$index$t,old+3L)
  expect_identical(minimax$index$assignment,base$index$assignment)
  expect_equal(as.numeric(minimax$model$A[rows+1L,c(old+1L,old+2L)]),c(0,0),tolerance=0)
  expect_identical(minimax$model$objective,c(rep(0,old+2L),1))
  expect_identical(tail(minimax$model$row_names,1),"minimax_2")
  expect_identical(minimax$pair_map,base$pair_map)
})
