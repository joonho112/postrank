pr_envelope_fixture <- function(q=c(need1=.5),exact_G=NULL) {
  x <- pr_test_payload(S=1L,n=2L,K=2L)
  # Both criteria rank entity 001 above 002: forward empirical error is zero.
  for(k in 1:2)x$joint_draws$tensor$values[1,,k] <- c(2,1)
  d <- as_postrank_draws(x)
  bounds <- postrank_iid_bounds(d,alpha=.05,alpha_by_criterion=c(need1=.025,need2=.025),
    design=list(sample_sizes_fixed_before_sampling=TRUE,alpha_fixed_before_sampling=TRUE,
      adaptive_stopping=FALSE,planned_sample_sizes=c(need1=1,need2=1),
      declaration_note="Explicit synthetic fixed-S IID design for envelope unit tests."))
  p <- postrank_problem(postrank_pairwise(d),c(need1=.2,need2=.8),.25,2L,q=q,exact_G=exact_G)
  list(draws=d,bounds=bounds,problem=p,envelopes=postrank_protection_envelopes(p,bounds))
}
pr_envelope_primal <- function(problem,grade=c(1,1)) {
  x <- numeric(length(problem$model$objective));x[problem$index$labels] <- grade
  x[problem$index$pairs] <- as.numeric(grade[problem$index$pair_i]<grade[problem$index$pair_j])
  if(!is.null(problem$index$assignment))x[problem$index$assignment[cbind(seq_along(grade),grade)]] <- 1
  x
}
pr_envelope_fit <- function(problem,control,grade=c(1,1),status="feasible_not_certified",
                            lower=.1,incumbent=TRUE,objective_shift=0) {
  primal <- pr_envelope_primal(problem,grade)
  raw <- list(primal=if(incumbent)primal else NULL,raw_status=paste0("EXPLICIT_TEST_MOCK_",status),
    raw_message="Solver-free mock for envelope unit tests",status_normalized=status,termination_reason="mock",
    has_incumbent=incumbent,raw_objective=if(incumbent)sum(problem$model$objective*primal)+objective_shift else NA_real_,
    raw_lower_bound=if(is.finite(lower))(lower-problem$objective_units$offset)/problem$objective_units$scale else NA_real_,
    relative_gap=NA_real_,runtime=0,backend=list(name="highs_test_mock",options=list(random_seed=control$seed)),
    raw=list(mock=TRUE),warnings=character())
  .pr_normalize_solver_result(problem,raw,control)
}

testthat::test_that("signed envelope thresholds are unclipped while public q and input remain unchanged",{
  a <- pr_envelope_fixture(q=c(need1=0,need2=1));p <- a$problem;before <- .pr_identity(p)
  e <- a$envelopes
  testthat::expect_s3_class(e,"postrank_protection_envelopes")
  testthat::expect_identical(e$public_problem,p)
  testthat::expect_identical(e$public_q,c(need1=0,need2=1))
  testthat::expect_identical(e$thresholds$inner,c(need1=-1,need2=0))
  testthat::expect_identical(e$thresholds$outer,c(need1=1,need2=2))
  for(mode in c("inner","outer")) {
    branch <- e[[paste0(mode,"_problem")]]
    testthat::expect_identical(branch$settings$q,p$settings$q)
    testthat::expect_identical(branch$input_identity,p$input_identity)
    testthat::expect_identical(branch$protection_envelope$coefficient_bound_identity,a$bounds$bound_identity)
    testthat::expect_identical(.pr_problem_q_thresholds(branch),e$thresholds[[mode]])
    testthat::expect_false(identical(branch$problem_identity,p$problem_identity))
  }
  testthat::expect_identical(.pr_identity(p),before)
  testthat::expect_false(e$numerically_verified)
  testthat::expect_false(e$guarantee_issued)
  testthat::expect_error(postrank_problem(p$pairwise,p$settings$weights,.25,2,q=c(need1=-1)),"in \\[0,1\\]")
  testthat::expect_error(postrank_problem(p$pairwise,p$settings$weights,.25,2,q=c(need1=2)),"in \\[0,1\\]")
})
testthat::test_that("envelope rows are literal signed coefficients and preserve exact-G encoding",{
  a <- pr_envelope_fixture(exact_G=2L);e <- a$envelopes;p <- a$problem
  for(mode in c("inner","outer")) {
    branch <- e[[paste0(mode,"_problem")]];threshold <- e$thresholds[[mode]][["need1"]]
    row <- match("protection_1",branch$model$row_names)
    expected <- p$pairwise$e[,,1][cbind(branch$index$pair_i,branch$index$pair_j)]-threshold
    testthat::expect_equal(as.numeric(branch$model$A[row,branch$index$pairs]),as.numeric(expected))
    testthat::expect_identical(branch$index$assignment,p$index$assignment)
    testthat::expect_identical(branch$model$objective,p$model$objective)
    testthat::expect_identical(branch$objective_units,p$objective_units)
    testthat::expect_identical(branch$settings$G_max,2L)
    testthat::expect_identical(branch$settings$exact_G,2L)
  }
  # All three weak orders are independently reconstructed as primal vectors.
  grades <- list(c(1,1),c(1,2),c(2,1))
  valid <- function(problem)vapply(grades,function(g)validate_postrank_solution(problem,pr_envelope_primal(problem,g))$valid,logical(1))
  basic <- pr_envelope_fixture()$envelopes
  testthat::expect_identical(valid(basic$inner_problem),c(TRUE,FALSE,FALSE))
  testthat::expect_identical(valid(basic$outer_problem),c(TRUE,TRUE,TRUE))
  testthat::expect_identical(valid(e$inner_problem),c(FALSE,FALSE,FALSE))
  testthat::expect_identical(valid(e$outer_problem),c(FALSE,TRUE,TRUE))
  public_forward <- validate_postrank_solution(p,pr_envelope_primal(p,c(1,2)))
  inner_forward <- validate_postrank_solution(e$inner_problem,pr_envelope_primal(e$inner_problem,c(1,2)))
  testthat::expect_true(public_forward$valid)
  testthat::expect_false(inner_forward$valid)
  # Deliberately remove the linear row in an explicit test-only malformed model:
  # the independent grade reconstruction must still use the signed threshold.
  malformed <- e$inner_problem
  malformed$model$A[match("protection_1",malformed$model$row_names),] <- 0
  malformed$problem_identity <- NULL;malformed$problem_identity <- .pr_identity(malformed)
  reconstructed <- validate_postrank_solution(malformed,pr_envelope_primal(malformed,c(1,2)))
  testthat::expect_true("protection_violation"%in%vapply(reconstructed$issues,`[[`,character(1),"code"))
})
testthat::test_that("envelopes reject missing budgets, minimax, stale bounds, mismatched inputs and nesting",{
  a <- pr_envelope_fixture();p <- a$problem
  no_q <- postrank_problem(p$pairwise,p$settings$weights,.25,2)
  mm <- postrank_problem(p$pairwise,p$settings$weights,.25,2,objective="minimax",q=c(need1=.5))
  testthat::expect_error(postrank_protection_envelopes(no_q,a$bounds),"require public q")
  testthat::expect_error(postrank_protection_envelopes(mm,a$bounds),"weighted risk only")
  b <- a$bounds;b$epsilon[1] <- 0
  testthat::expect_error(postrank_protection_envelopes(p,b),"changed after")
  other <- pr_test_payload(S=1L,n=2L,K=2L);other$context$data_version <- "another-input"
  op <- postrank_problem(postrank_pairwise(other),p$settings$weights,.25,2,q=c(need1=.5))
  testthat::expect_error(postrank_protection_envelopes(op,a$bounds),"different input identity")
  testthat::expect_error(postrank_protection_envelopes(a$envelopes$inner_problem,a$bounds),"original public problem")
  altered <- a$envelopes;altered$thresholds$inner[1] <- 0
  testthat::expect_error(.pr_validate_protection_envelopes(altered),"changed after")
})
testthat::test_that("E5 uses inner feasible upper and whole outer lower with every weighted epsilon",{
  a <- pr_envelope_fixture();order <- character()
  solver <- function(problem,backend,control) {
    mode <- problem$protection_envelope$mode;order <<- c(order,mode)
    pr_envelope_fit(problem,control,lower=if(mode=="inner").25 else .1)
  }
  z <- .pr_run_protection_analysis(a$envelopes,"highs",list(seed=17L),solver)
  testthat::expect_identical(order,c("inner","outer"))
  testthat::expect_equal(z$inner_risk_upper,.25)
  testthat::expect_equal(z$outer_whole_problem_risk_lower,.1)
  testthat::expect_equal(z$delta_w,1)
  testthat::expect_equal(z$computed_value,.25-.1+2)
  testthat::expect_true(z$bound_computed)
  testthat::expect_identical(z$status,"diagnostic_only")
  testthat::expect_false(z$numerically_verified)
  testthat::expect_false(z$finite_sample_certificate)
  testthat::expect_false(z$guarantee_issued)
  testthat::expect_identical(z$attempts$inner$actual_seed,17L)
  testthat::expect_identical(z$attempts$outer$actual_backend$name,"highs_test_mock")
  testthat::expect_s3_class(z$inner_fit,"postrank_fit")
  testthat::expect_s3_class(z$outer_fit,"postrank_fit")
  testthat::expect_length(z$reasons,0)
  testthat::expect_equal(z$solve_count,2L)
})
testthat::test_that("infeasible inner and outer timeout without bound are retained with reasoned NA",{
  a <- pr_envelope_fixture(exact_G=2L)
  solver <- function(problem,backend,control)pr_envelope_fit(problem,control,
    status=if(problem$protection_envelope$mode=="inner")"infeasible" else "time_limit",lower=NA_real_,incumbent=FALSE)
  z <- .pr_run_protection_analysis(a$envelopes,"highs",list(),solver)
  testthat::expect_identical(z$status,"not_established")
  testthat::expect_false(z$bound_computed)
  testthat::expect_true(is.na(z$computed_value))
  testthat::expect_true(all(c("inner_infeasible","outer_whole_problem_lower_unavailable")%in%z$reasons))
  testthat::expect_identical(z$inner_fit$status$normalized,"infeasible")
  testthat::expect_identical(z$outer_fit$status$normalized,"time_limit")
  testthat::expect_length(z$attempts,2)
  # Outer TIME_LIMIT with no incumbent can still carry the needed whole bound.
  b <- pr_envelope_fixture()
  timeout <- function(problem,backend,control)pr_envelope_fit(problem,control,
    status=if(problem$protection_envelope$mode=="outer")"time_limit" else "feasible_not_certified",
    incumbent=problem$protection_envelope$mode=="inner")
  out <- .pr_run_protection_analysis(b$envelopes,"highs",list(),timeout)
  testthat::expect_true(out$bound_computed)
  testthat::expect_false(out$outer_fit$has_incumbent)
  testthat::expect_equal(out$computed_value,2.15)
})
testthat::test_that("analysis attempts both explicit-backend branches after errors without fallback",{
  a <- pr_envelope_fixture();modes <- backends <- character()
  solver <- function(problem,backend,control) {
    modes <<- c(modes,problem$protection_envelope$mode);backends <<- c(backends,backend)
    if(problem$protection_envelope$mode=="inner").pr_stop("Explicit test failure",code="mock_failure")
    warning("Explicit outer test warning")
    pr_envelope_fit(problem,control)
  }
  z <- .pr_run_protection_analysis(a$envelopes,"highs",list(),solver)
  testthat::expect_identical(modes,c("inner","outer"))
  testthat::expect_identical(backends,c("highs","highs"))
  testthat::expect_null(z$inner_fit)
  testthat::expect_s3_class(z$outer_fit,"postrank_fit")
  testthat::expect_identical(z$attempts$inner$error$code,"mock_failure")
  testthat::expect_match(z$attempts$outer$warnings,"Explicit outer test warning")
  testthat::expect_identical(z$reasons,"inner_solve_error")
  testthat::expect_false(z$bound_computed)
  # 0.9.0 migration (Appendix C note 2, D-1): backend = NULL now resolves to the
  # option, then Gurobi, instead of requiring an explicit backend. The resolved name
  # reaches the attempt runner; no other backend is substituted.
  seen <- (function() {
    seen <- character()
    testthat::local_mocked_bindings(.pr_run_protection_analysis = function(envelopes, backend, control, solver) {
      seen <<- c(seen, backend); invisible(NULL) }, .pr_backend_require = function(backend) invisible(list()))
    withr::with_options(list(postrank.backend = NULL), postrank_protection_analysis(a$envelopes))
    withr::with_options(list(postrank.backend = "highs"), postrank_protection_analysis(a$envelopes))
    seen
  })()
  testthat::expect_identical(seen, c("gurobi", "highs"))
  testthat::expect_error(postrank_protection_analysis(a$envelopes, backend = "automatic"), "gurobi")
  testthat::expect_error(.pr_run_protection_analysis(a$envelopes,"automatic",list(),solver),"explicit gurobi or highs")
})
testthat::test_that("known numerical issues and incompatible cross-problem bound do not produce an E5 value",{
  a <- pr_envelope_fixture()
  numerical <- function(problem,backend,control)pr_envelope_fit(problem,control,
    objective_shift=if(problem$protection_envelope$mode=="inner")1 else 0)
  z <- .pr_run_protection_analysis(a$envelopes,"highs",list(),numerical)
  testthat::expect_false(z$bound_computed)
  testthat::expect_identical(z$reasons,"inner_numerical_issue")
  testthat::expect_true(z$inner_fit$incumbent_validated)
  inversion <- function(problem,backend,control) {
    if(problem$protection_envelope$mode=="inner")pr_envelope_fit(problem,control,lower=.1)
    else pr_envelope_fit(problem,control,grade=c(2,1),lower=.3)
  }
  inv <- .pr_run_protection_analysis(a$envelopes,"highs",list(),inversion)
  testthat::expect_identical(inv$reasons,"outer_lower_above_inner_upper")
  testthat::expect_false(inv$bound_computed)
  testthat::expect_true(is.na(inv$computed_value))
  unknown <- function(problem,backend,control)pr_envelope_fit(problem,control,
    status=if(problem$protection_envelope$mode=="outer")"unknown" else "feasible_not_certified")
  unk <- .pr_run_protection_analysis(a$envelopes,"highs",list(),unknown)
  testthat::expect_false(unk$bound_computed)
  testthat::expect_identical(unk$reasons,"outer_whole_problem_lower_not_usable")
})
testthat::test_that("envelope fits are explicitly rejected by stability rebuilding",{
  a <- pr_envelope_fixture();f <- pr_envelope_fit(a$envelopes$inner_problem,.pr_control())
  testthat::expect_error(.pr_prepare_stability(a$draws,f$grade,f$settings,
    list(backend="highs",control=list()),reference_fit=f),"internal protection envelopes are unsupported")
  diagnostics <- postrank_diagnose(a$draws,fit=f)
  report <- postrank_report(f,diagnostics)
  testthat::expect_match(report$protection$status,"diagnostic_inner_envelope_only")
  testthat::expect_match(report$protection$status,"original_public_q_feasibility_and_true_posterior_safety_not_claimed")
})
