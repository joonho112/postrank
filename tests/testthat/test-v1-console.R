vc_analysis <- function(K = 2L) {
  draws <- as_postrank_draws(pr_test_payload(K = K))
  w <- setNames(rep(1/K, K), draws$criterion_ids)
  postrank(draws, weights = w, G_max = 3L, backend = "highs", fragility = FALSE)
}
vc_text <- function(x, ...) gsub("[[:space:]]+", " ", paste(format(x, tier = 2, ...), collapse = " "))

test_that("core console explains the result and summary keeps technical records opt-in", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  a <- vc_analysis(); before <- serialize(a, NULL)
  text <- vc_text(a)
  expect_match(text, "3 entities in 2 grades")
  expect_match(text, "2 criteria")
  expect_match(text, "Disclosed 2 of 3 pairs")
  expect_match(text, "withheld 1")
  expect_match(text, "Posterior loss")
  s <- summary(a)
  expect_named(s, c("object_class", "schema_version", "headline", "provenance", "declarations", "settings",
    "identities", "warnings", "interpretation"))
  expect_identical(s$identities$input, a$fit$input_identity)
  plain <- vc_text(s)
  expect_match(plain, "Criterion results")
  expect_match(plain, "Error / disclosed")
  expect_match(plain, "all unordered pairs")
  expect_match(plain, "Tau is a loss cost, not an error-rate limit", fixed = TRUE)
  expect_match(plain, "Monte Carlo fragility: not requested", fixed = TRUE)
  expect_false(grepl(a$fit$input_identity, plain, fixed = TRUE))
  expect_false(grepl("Technical provenance:|Technical identities:", plain))
  detailed <- format(summary(a, details = TRUE), width = 120, tier = 2)
  expect_true(any(grepl("Technical identities:", detailed, fixed = TRUE)))
  expect_true(any(grepl(a$fit$input_identity, detailed, fixed = TRUE)))
  expect_identical(format(s, details = TRUE, width = 120, tier = 2), detailed)
  expect_identical(serialize(a, NULL), before)
  expect_error(summary(a, details = NA), "details must")
})

test_that("core views preserve K=1, all-withheld and unavailable grades", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(setNames(rep(1L, 3L), c("001", "site-B", "site C"))))
  # Use the canonical toy IDs for the fixed mocked grade.
  a <- postrank(postrank_toy, weights = c(need_A=.6, need_B=.4), G_max=3L, backend="highs", fragility=FALSE)
  text <- vc_text(a)
  expect_match(text, "all comparisons withheld")
  expect_match(text, "NA (N = 0)", fixed=TRUE)
  expect_match(text, "withheld 3")
  expect_match(text, "not an error-free ranking", fixed=TRUE)
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  one <- vc_analysis(K=1L)
  expect_match(vc_text(one), "One criterion: need1", fixed=TRUE)
  expect_identical(one$settings$weights, c(need1=1))
  local_mocked_bindings(.pr_solve_core = pr_mock_solver(NULL, status="time_limit", lower=-.3))
  none <- vc_analysis()
  expect_match(vc_text(none), "No validated grades")
  expect_match(vc_text(none), "Time limit reached")
  expect_match(vc_text(none), "Lower bound: 0.1500", fixed=TRUE)
  expect_false(grepl("Posterior loss: 0", vc_text(none), fixed=TRUE))
  expect_match(vc_text(summary(none)), "Error / disclosed")
  expect_match(vc_text(summary(none)), "unavailable without validated grades")
})

test_that("formatters and summaries are bounded pure stored-value views", {
  local_mocked_bindings(.pr_solve_core = pr_mock_solver())
  a <- vc_analysis(); fit <- a$fit; s <- summary(a)
  local_mocked_bindings(.pr_solve_core=function(...) stop("must not solve"),
    .pr_evaluate_core=function(...) stop("must not evaluate"),
    .pr_posterior_summaries=function(...) stop("must not calculate intervals"))
  for (width in c(40L, 80L, 120L)) {
    for (object in list(a, fit, s, summary(a, details=TRUE))) {
      lines <- format(object, width=width, tier=2)
      expect_true(all(nchar(lines, type="width") <= width))
      expect_identical(cli::ansi_strip(format(object, width=width, tier=1)), lines)
    }
    expect_identical(format(a,width=width,tier=2), format_postrank_analysis_cli(a,width=width,tier=2))
    expect_identical(format(fit,width=width,tier=2), format_postrank_fit_cli(fit,width=width,tier=2))
    expect_identical(format(s,width=width,tier=2), format_postrank_summary_cli(s,width=width,tier=2))
  }
  captured <- utils::capture.output(value <- withVisible(print(s, width=40, tier=2, details=TRUE)))
  expect_identical(captured, format(s,width=40,tier=2,details=TRUE))
  expect_false(value$visible)
  expect_identical(value$value,s)
})

test_that("comparison and setting views explain what their losses can be compared against", {
  comparison <- pr_cached("comparison_30x3_tau35")
  frontier <- pr_cached("frontier_30x3")
  common <- pr_cached("commonality_30x3_tau35")
  expect_match(vc_text(comparison), "weights and withholding cost are held fixed")
  expect_match(vc_text(frontier), "Changing tau changes the loss")
  expect_match(vc_text(frontier), "do not rank methods by losses")
  expect_match(vc_text(common), "same withholding cost and grade limit")
  expect_match(vc_text(common), "solver lower bound")
  for (width in c(40L,80L,120L)) for (object in list(comparison,frontier,common,
      postrank_settings(c(need=1),tau=.2,G_max=3L),postrank_control())) {
    lines <- format(object,width=width,tier=2)
    expect_true(all(nchar(lines,type="width")<=width))
    expect_identical(cli::ansi_strip(format(object,width=width,tier=1)),lines)
    cls <- class(object)[1L]
    formatter <- get(paste0("format_postrank_",.pr_formatter_of[[cls]],"_cli"))
    expect_identical(lines,formatter(object,width=width,tier=2))
  }
  expect_match(vc_text(postrank_settings(c(need=1),tau=.2,G_max=3L)),"Tau prices a withheld comparison")
  ctrl <- postrank_control(); ctrl$verbose <- NULL
  expect_match(vc_text(ctrl),"inherit option (quiet by default)",fixed=TRUE)
  ctrl$verbose <- FALSE
  expect_match(vc_text(ctrl),"Progress messages: off",fixed=TRUE)
  # Large tables respect the caller's requested preview size.
  lines <- format(comparison,width=40,tier=2,n_head=1L)
  expect_match(paste(lines,collapse=" "),"Showing 1 of")
})

test_that("probability and diagnostic views do not invent samples or numerical guarantees", {
  p <- matrix(c(NA,.2,.8,NA),2,dimnames=list(c("A","B"),c("A","B")))
  x <- postrank_probabilities(p,"higher_priority",TRUE,0,
    list(kind="analytic_reference",description="A declared two-entity comparison",conditioning="Fixed supplied law"),
    c(need="An oriented continuous score"),criterion="need")
  text <- vc_text(x)
  expect_match(text,"One criterion: need")
  expect_match(text,"no target draws or sample sizes are inferred")
  expect_match(text,"Marginal means and intervals were not supplied")
  expect_false(grepl("NA draws|0 draws",text))
  expect_match(vc_text(summary(x)),"Fixed supplied law")
  expect_identical(format(x,tier=2),format_postrank_pairwise_cli(x,tier=2))
  design <- list(sample_sizes_fixed_before_sampling=TRUE,alpha_fixed_before_sampling=TRUE,adaptive_stopping=FALSE,
    planned_sample_sizes=c(need_A=32L,need_B=32L),declaration_note="Fixed toy sample sizes.")
  bounds <- postrank_iid_bounds(postrank_toy,.05,c(need_A=.025,need_B=.025),design)
  expect_match(vc_text(bounds),"MCMC effective sample size cannot replace the draw count")
  expect_match(vc_text(bounds),"not a numerical certificate")
  expect_match(vc_text(summary(bounds,details=TRUE)),"sample_sizes_fixed_before_sampling")
  for(width in c(40L,80L,120L)) for(object in list(x,summary(x),bounds,summary(bounds),postrank_toy,pr_example_gaussian))
    expect_true(all(nchar(format(object,width=width,tier=2),type="width")<=width))
})

vc_tie_objects <- function() {
  values <- array(0,c(2L,2L,1L)); values[2L,,1L] <- c(1,0)
  draws <- as_postrank_tie_draws(pr_tie_fixture(values,c(1L,1L)))
  pw <- postrank_tie_pairwise(draws)
  problem <- postrank_tie_problem(pw,c(need1=1),.25,2L)
  grade <- setNames(c(1L,1L),pw$entity_ids)
  primal <- .pr_tie_primal(problem,grade)
  raw <- list(primal=primal,raw_status="MOCK",raw_message="stored fixture",status_normalized="optimal",
    termination_reason="fixture",has_incumbent=TRUE,raw_objective=0,raw_lower_bound=0,relative_gap=0,
    runtime=0,backend=list(name="mock"),engine=list(strategy="label_mip"),raw=list(),warnings=character())
  fit <- .pr_tie_normalize_solver_result(problem,raw,.pr_control())
  list(draws=draws,pairwise=pw,problem=problem,fit=fit,evaluation=fit$evaluation,solution_validation=fit$solution_validation)
}

test_that("tie-aware views preserve R0, distinct-pair denominators and their separate classes", {
  skip_if_not_installed("gmp")
  objs <- vc_tie_objects()
  expect_equal(objs$fit$evaluation$R0,.125)
  expect_match(vc_text(objs$fit),"R0 need not equal tau")
  expect_match(vc_text(objs$fit),"0.1250")
  expect_match(vc_text(objs$fit),"Error / distinct")
  expect_match(vc_text(objs$fit),"zero denominator remains NA")
  expect_match(vc_text(objs$problem),"minimax are unsupported")
  for (x in objs) for(width in c(40L,80L,120L)) {
    expect_true(all(nchar(format(x,width=width,tier=2),type="width")<=width))
    expect_identical(cli::ansi_strip(format(x,width=width,tier=1)),format(x,width=width,tier=2))
    expect_s3_class(summary(x),"postrank_summary")
    expect_true(all(nchar(format(summary(x),width=width,tier=2),type="width")<=width))
    expect_match(format(x,width=width,tier=2)[1L],"^<postrank_tie_")
  }
  v <- NULL; invisible(utils::capture.output(v <- withVisible(print(objs$fit))))
  expect_false(v$visible); expect_identical(v$value,objs$fit)
})

test_that("uncertified and missing-bound views retain the validated action distinction", {
  local_mocked_bindings(.pr_solve_core=pr_mock_solver(lower=-.6))
  wide <- vc_analysis()
  expect_identical(wide$fit$status$normalized,"feasible_not_certified")
  expect_match(vc_text(wide),"optimality not established")
  expect_match(vc_text(wide),"upper bound")
  expect_match(vc_text(summary(wide)),"lower bound: 0.0500",fixed=TRUE)
  local_mocked_bindings(.pr_solve_core=pr_mock_solver(lower=NA_real_))
  missing <- vc_analysis()
  expect_true(missing$fit$incumbent_validated)
  expect_match(vc_text(missing),"no usable lower bound")
  expect_false(grepl("No validated grades",vc_text(missing),fixed=TRUE))
})
