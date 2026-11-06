test_that("HiGHS receives the same ranged sparse model and binary feasible set", {
  model <- list(A=Matrix::sparseMatrix(i=c(1,2,3),j=1:3,x=c(2,-1,3),dims=c(3,3)),
    objective=c(-1,0,1),var_lower=c(-Inf,1,0),var_upper=c(Inf,5,1),
    row_lower=c(-Inf,2,0),row_upper=c(5,2,Inf),types=c("C","I","B"),sense="min")
  converted <- .pr_highs_model(model)
  expect_identical(converted$A,model$A)
  expect_identical(converted$L,model$objective)
  expect_identical(converted$lower,model$var_lower);expect_identical(converted$upper,model$var_upper)
  expect_identical(converted$lhs,model$row_lower);expect_identical(converted$rhs,model$row_upper)
  expect_identical(converted$types,c("C","I","I"))
  expect_false(converted$maximum);expect_identical(converted$offset,0)
  model$var_upper[3] <- 2
  expect_error(.pr_highs_model(model),"zero/one",class="postrank_input_error")
})

test_that("HiGHS controls retain resource seeds and convert risk gap to raw units", {
  problem <- list(objective_units=list(scale=1/3))
  control <- .pr_control(list(time_limit=12,threads=1L,seed=77L,absolute_risk_gap=2e-8,relative_gap=.01,output=FALSE))
  params <- .pr_highs_options(problem,control)
  expect_identical(params$threads,1L);expect_identical(params$time_limit,12)
  expect_identical(params$random_seed,77L);expect_equal(params$mip_abs_gap,6e-8,tolerance=1e-14)
  expect_identical(params$mip_rel_gap,.01);expect_false(params$log_to_console);expect_false(params$output_flag)
  problem$objective_units$scale <- 1
  expect_identical(.pr_highs_options(problem,control)$mip_abs_gap,2e-8)
})

test_that("HiGHS model statuses use exact verified enums and separate incumbent state", {
  expected <- c("unknown",rep("numerical_error",5),"unknown","optimal","infeasible","unknown","unbounded",
    "unknown","unknown","time_limit","unknown","unknown","unknown","unknown","unknown","unknown")
  for(code in 0:19) expect_identical(.pr_highs_status(code,FALSE)$normalized,expected[code+1L])
  for(code in c(11,12,14,16,17,18,19)) expect_identical(.pr_highs_status(code,TRUE)$normalized,"feasible_not_certified")
  expect_identical(.pr_highs_status(13L,TRUE)$normalized,"time_limit")
  for(code in list(NA,7.1,"7","OPTIMAL",c(7,13),7+0i,100L)) expect_identical(.pr_highs_status(code,TRUE)$normalized,"unknown")
  expect_identical(.pr_highs_status(9L,TRUE)$normalized,"unknown")
})

test_that("HiGHS default vectors are not treated as incumbent without feasible info", {
  raw <- list(primal_solution=c(0,0),objective_value=0,status=13L,status_message="Time limit reached",
    info=list(valid=TRUE,primal_solution_status="None",mip_dual_bound=-3,mip_gap=Inf))
  out <- .pr_highs_raw_result(raw,list(name="highs"),elapsed=.02)
  expect_false(out$has_incumbent);expect_null(out$primal)
  expect_true(is.na(out$raw_objective));expect_true(is.na(out$relative_gap))
  expect_identical(out$raw_lower_bound,-3);expect_identical(out$status_normalized,"time_limit")
  expect_identical(out$raw$primal_solution,c(0,0))
  raw$info$primal_solution_status <- "Feasible";raw$info$valid <- FALSE
  out <- .pr_highs_raw_result(raw,list(name="highs"))
  expect_false(out$has_incumbent);expect_null(out$primal);expect_true(is.na(out$raw_lower_bound))
  expect_true(length(out$warnings)>0L)
})

test_that("HiGHS feasible incumbent retains actual fields and external timing source", {
  raw <- list(primal_solution=c(1,0),objective_value=-2,status=7L,status_message="Optimal",
    info=list(valid=TRUE,primal_solution_status="Feasible",mip_dual_bound=-2,mip_gap=0,runtime=999))
  out <- .pr_highs_raw_result(raw,list(name="highs"),elapsed=.125)
  expect_true(out$has_incumbent);expect_identical(out$primal,c(1,0))
  expect_identical(out$raw_objective,-2);expect_identical(out$raw_lower_bound,-2)
  expect_identical(out$relative_gap,0);expect_identical(out$runtime,.125)
  expect_match(out$backend$runtime_source,"R elapsed wall time")
  expect_identical(out$status_normalized,"optimal")
  raw$info$mip_dual_bound <- NULL
  missing <- .pr_highs_raw_result(raw,list(name="highs"))
  expect_true(is.na(missing$raw_lower_bound))
  expect_true(is.na(missing$runtime))
})

test_that("HiGHS ambiguous and failed terminations do not donate default lower bounds", {
  for(code in c(0,1,6,8,9,10,15,100)) {
    raw <- list(primal_solution=c(0,0),objective_value=0,status=code,status_message="preserved raw message",
      info=list(valid=TRUE,primal_solution_status="None",mip_dual_bound=0,mip_gap=0))
    out <- .pr_highs_raw_result(raw,list(name="highs"))
    expect_true(is.na(out$raw_lower_bound));expect_null(out$primal)
    expect_identical(out$raw_message,"preserved raw message")
  }
})
