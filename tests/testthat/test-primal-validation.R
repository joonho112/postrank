pr_primal_fixture <- function(grade=c(1,2,3),G_max=3L) {
  p <- postrank_pairwise(pr_test_payload())
  problem <- postrank_problem(p,c(need1=.7,need2=.3),.25,G_max)
  solution <- numeric(length(problem$model$objective))
  solution[problem$index$labels] <- grade
  solution[problem$index$pairs] <- as.numeric(grade[problem$index$pair_i]<grade[problem$index$pair_j])
  list(problem=problem,solution=solution)
}
pr_validation_codes <- function(x) vapply(x$issues,`[[`,character(1L),"code")
pr_reidentify_problem <- function(x) {x$problem_identity<-NULL;x$problem_identity<-.pr_identity(x);x}

test_that("valid primal is fully re-evaluated and canonicalized", {
  for(grade in list(c(1,2,3),c(1,1,3),c(2,2,2))) {
    fixture <- pr_primal_fixture(grade)
    result <- validate_postrank_solution(fixture$problem,fixture$solution)
    expect_true(result$valid);expect_length(result$issues,0L)
    expect_identical(result$grade,canonical_postrank_grade(stats::setNames(grade,fixture$problem$pairwise$entity_ids),fixture$problem$pairwise$entity_ids))
    expect_identical(result$rounded_solution,fixture$solution)
    expect_identical(result$raw_residuals$bounds_max,0)
    expect_identical(result$raw_residuals$rows_max,0)
    expect_identical(result$integrality_residual,0)
    expect_equal(result$recomputed_raw_objective,result$evaluation$weighted_raw_objective,tolerance=1e-15)
  }
})

test_that("invalid and absent primal vectors return non-publishable receipts", {
  fixture <- pr_primal_fixture();p <- fixture$problem;z <- fixture$solution
  for(value in list(NULL,numeric(),z[-1],as.list(z),as.character(z),z+0i,matrix(z,nrow=1),replace(z,1,NA),replace(z,1,Inf),replace(z,1,NaN))) {
    result <- validate_postrank_solution(p,value)
    expect_false(result$valid);expect_null(result$grade);expect_null(result$evaluation)
    expect_true(all(c("grade","evaluation","raw_residuals","rounded_residuals")%in%names(result)))
    expect_true(length(result$issues)>0L)
  }
})

test_that("grade risk is independently compared with model objective", {
  fixture <- pr_primal_fixture();p <- fixture$problem;z <- fixture$solution
  p$model$objective[p$index$pairs[1]] <- p$model$objective[p$index$pairs[1]]+.01
  p <- pr_reidentify_problem(p)
  result <- validate_postrank_solution(p,z)
  expect_false(result$valid)
  expect_true("objective_reconstruction_mismatch"%in%pr_validation_codes(result))
  expect_null(result$grade)
})

test_that("bounds, rows and integer residuals are checked on the rounded action", {
  # 014 repair policy (CP-4): validity is judged on the rounded integer solution;
  # raw-primal residuals are diagnostics and warnings, not separate failures.
  fixture <- pr_primal_fixture();p <- fixture$problem;z <- fixture$solution
  outside <- z;outside[p$index$pairs[1]] <- 2
  result <- validate_postrank_solution(p,outside)
  expect_false(result$valid);expect_true("rounded_bound_violation"%in%pr_validation_codes(result))
  expect_false("raw_bound_violation"%in%pr_validation_codes(result))
  expect_match(result$warnings,"Raw primal bound residual",all=FALSE)
  fractional <- z;fractional[p$index$pairs[1]] <- .5
  result <- validate_postrank_solution(p,fractional)
  expect_false(result$valid);expect_equal(result$integrality_residual,.5)
  expect_true("integrality_violation"%in%pr_validation_codes(result))
  # Objective zero is also the valid all-tie objective; it cannot certify rows.
  bad_rows <- z;bad_rows[p$index$pairs] <- 0
  result <- validate_postrank_solution(p,bad_rows)
  expect_false(result$valid);expect_identical(result$recomputed_raw_objective,0)
  expect_true(result$raw_residuals$rows_max>0)
  expect_true("rounded_row_violation"%in%pr_validation_codes(result))
})

test_that("raw residuals within solver tolerance do not reject a valid rounded action", {
  fixture <- pr_primal_fixture(c(1,2,3));p <- fixture$problem;z <- fixture$solution
  # Solver-style slack: labels within 5e-7 of integers (integral within 1e-6)
  # shrink an adjacent label difference to 1-1e-6, so the raw lower encoding row
  # for that disclosed pair is violated by 1e-6 > 1e-7. The rounded action is exact.
  z[p$index$labels[1]] <- 1+5e-7; z[p$index$labels[2]] <- 2-5e-7
  result <- validate_postrank_solution(p,z)
  expect_true(result$valid)
  expect_true(result$raw_residuals$rows_max>result$tolerances$feasibility)
  expect_identical(result$rounded_residuals$rows_max,0)
  expect_match(result$warnings,"Raw primal row residual",all=FALSE)
})

test_that("near-integer primal is rounded only within declared tolerance", {
  fixture <- pr_primal_fixture(c(2,2,2));p <- fixture$problem;z <- fixture$solution
  z[p$index$labels] <- z[p$index$labels]+1e-8
  z[p$index$pairs] <- 1e-8
  result <- validate_postrank_solution(p,z)
  expect_true(result$valid);expect_true(result$integrality_residual>0)
  expect_identical(result$rounded_solution,fixture$solution)
  expect_identical(result$evaluation$N,0L)
  strict <- validate_postrank_solution(p,z,tolerances=list(integrality=0))
  expect_false(strict$valid);expect_true("integrality_violation"%in%pr_validation_codes(strict))
})

test_that("all linear rows are rechecked after rounding", {
  fixture <- pr_primal_fixture(c(2,2,2));p <- fixture$problem;z <- fixture$solution
  # Synthetic extra linear row represents a generic noninteger-coefficient
  # constraint; current integer encoding alone cannot exercise this distinction.
  extra <- Matrix::sparseMatrix(i=1L,j=p$index$labels[1],x=1000,dims=c(1L,length(z)))
  p$model$A <- rbind(p$model$A,extra)
  p$model$row_lower <- c(p$model$row_lower,-Inf)
  p$model$row_upper <- c(p$model$row_upper,1000*(2-5e-8))
  p$model$row_names <- c(p$model$row_names,"synthetic_rounding_boundary")
  p <- pr_reidentify_problem(p)
  z[p$index$labels] <- 2-5e-8
  result <- validate_postrank_solution(p,z)
  expect_true(result$raw_residuals$rows_max<=result$tolerances$feasibility)
  expect_true(result$integrality_residual<=result$tolerances$integrality)
  expect_false(result$valid)
  expect_true(result$rounded_residuals$rows_max>result$tolerances$feasibility)
  expect_true("rounded_row_violation"%in%pr_validation_codes(result))
  expect_null(result$grade)
})

test_that("grade relations are reconstructed independently of matrix feasibility", {
  fixture <- pr_primal_fixture();p <- fixture$problem;z <- fixture$solution
  # Deliberately broken formulation variant: all-zero matrix would accept this
  # integer primal, so relation reconstruction must still reject it.
  p$model$A <- p$model$A*0;p <- pr_reidentify_problem(p)
  z[p$index$pairs] <- 0
  result <- validate_postrank_solution(p,z)
  expect_identical(result$raw_residuals$rows_max,0)
  expect_false(result$valid)
  expect_true("pair_relation_mismatch"%in%pr_validation_codes(result))
  expect_null(result$evaluation)
})

test_that("malformed problems and invalid tolerance configuration throw", {
  fixture <- pr_primal_fixture();p <- fixture$problem;z <- fixture$solution
  p$model$var_upper[1] <- 100
  expect_error(validate_postrank_solution(p,z),"changed",class="postrank_input_error")
  for(tolerance in list(1,list(unknown=1),list(integrality=-1),list(objective=Inf),list(feasibility=NA),list(feasibility=1i),list(objective=c(1,2)),list(objective=NULL),stats::setNames(list(1,2),c("objective","objective"))))
    expect_error(validate_postrank_solution(fixture$problem,z,tolerance),class="postrank_input_error")
  for(bad in c("G_max","q","exact_G")) {
    malformed <- fixture$problem;malformed$settings[[bad]] <- NA_real_
    malformed <- pr_reidentify_problem(malformed)
    expect_error(validate_postrank_solution(malformed,z),class="postrank_input_error")
  }
})
