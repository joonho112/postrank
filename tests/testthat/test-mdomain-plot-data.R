md_plot_data_case <- function(empirical=FALSE, approximate=FALSE, expected=FALSE) {
  units <- c("unit-9", "unit-2", "unit-17", "unit-4")
  domains <- c("priority-Z", "zero-domain", "priority-A")
  values <- array(0, c(2L,4L,3L),
    dimnames=list(state=c("state-2","state-8"), unit=units, domain=domains))
  values[,,1L] <- rbind(c(4,3,2,1), c(3,4,2,1))
  values[,,2L] <- rbind(c(2,2,3,1), c(3,3,2,1))
  values[,,3L] <- rbind(c(2,1,4,3), c(1,2,4,3))
  targets <- setNames(lapply(domains, function(d) list(
    definition=paste("Declared fictional", d, "coordinate"), units="illustrative units",
    orientation="larger_is_higher", transformations=list(),
    equality_classes=setNames(if (d == "zero-domain")
      c("shared", "shared", "third", "fourth") else units, units),
    equality_provenance="Only the declared shared class has a modeled identity.")), domains)
  provenance <- list(input_id="plotting-only-fictional-law", law_id="two-listed-states",
    proper_law=TRUE, producer="Independent plotting test generator",
    joint_generation="Each listed row is a complete joint state of all coordinates.",
    within_domain_joint="Every row contains every original unit.",
    sampling_assumptions=if (empirical) list(iid=TRUE) else
      list(finite_support_origin="The two listed states constitute the complete law."))
  input <- postrank_mdomain_input(values, targets=targets, provenance=provenance,
    representation=if (empirical) "iid_equal_weight_draws" else "exact_finite_law",
    masses=if (empirical) NULL else if (approximate)
      list(encoding="float64", values=c(.5,.5)) else c("1/2","1/2"))
  grades <- matrix(c(10,20,70,100, 0,0,0,0, 40,40,10,20), 4L,
    dimnames=list(units,domains))
  decision <- postrank_mdomain_decision(weights=setNames(c("1/2","0","1/2"),domains), t=NULL)
  evaluation <- postrank_mdomain_evaluate(input, grades, decision,
    mode=if (expected) "expected" else "joint")
  list(input=input, decision=decision, evaluation=evaluation)
}

md_plot_data_fit <- function() {
  fixture <- md_plot_data_case()
  columns <- setNames(lapply(fixture$input$domain_ids, function(d)
    list(fixed=setNames(fixture$evaluation$grades[,d],fixture$input$unit_ids))),
    fixture$input$domain_ids)
  family <- postrank_mdomain_family(fixture$input, columns=columns)
  postrank_mdomain_solve(fixture$input, family, fixture$decision)
}

test_that("plot preparation retains original IDs, canonical grades and full-card counts", {
  skip_if_not_installed("gmp")
  result <- md_plot_data_case()$evaluation
  data <- postrank:::.md_plot_prepare(result)
  expect_identical(names(data), c("grades","full_grades","unit_ids","domain_ids",
    "K","long","pair","n_original","M","caption"))
  expect_identical(data$grades, result$grades)
  expect_identical(data$full_grades, result$grades)
  expect_identical(data$unit_ids, c("unit-9","unit-2","unit-17","unit-4"))
  expect_identical(data$domain_ids, c("priority-Z","zero-domain","priority-A"))
  expect_identical(data$K, c(`priority-Z`=4L, `zero-domain`=1L, `priority-A`=3L))
  expect_identical(data$n_original, 4L)
  expect_identical(data$M, 6)
  expect_identical(data$long$unit_id, rep(data$unit_ids,3L))
  expect_identical(data$long$domain_id, rep(data$domain_ids,each=4L))
  expect_identical(data$long$grade, c(1L,2L,3L,4L,1L,1L,1L,1L,3L,3L,1L,2L))
  expect_identical(names(data$pair), c("domain_id","unit_i","unit_j","grade_i",
    "grade_j","sign","direction_label","structural_identity"))
  expect_identical(nrow(data$pair), 0L)
  expect_match(data$caption, "Declared finite law; exact represented-measure arithmetic", fixed=TRUE)
  expect_match(data$caption, "Showing 4/4 original units, 3/3 original domains", fixed=TRUE)
  expect_match(data$caption, "Original full-report risk =", fixed=TRUE)
  expect_match(data$caption, "M = 6", fixed=TRUE)
})

test_that("subsets keep explicit order and unoccupied original grade labels", {
  skip_if_not_installed("gmp")
  result <- md_plot_data_case()$evaluation
  data <- postrank:::.md_plot_prepare(result, units=c("unit-4","unit-9"),
    domains=c("priority-A","priority-Z"))
  expect_identical(data$grades, result$grades[c("unit-4","unit-9"),c("priority-A","priority-Z"),drop=FALSE])
  expect_identical(data$full_grades, result$grades)
  expect_identical(data$K, c(`priority-A`=3L,`priority-Z`=4L))
  expect_identical(data$long$grade, c(2L,3L,4L,1L))
  expect_identical(data$long$unit_id, c("unit-4","unit-9","unit-4","unit-9"))
  expect_identical(data$long$domain_id, c("priority-A","priority-A","priority-Z","priority-Z"))
  expect_identical(data$pair$sign, c(1L,-1L))
  expect_identical(data$pair$direction_label,
    c("unit-4 higher than unit-9","unit-9 higher than unit-4"))
  expect_identical(data$n_original,4L)
  expect_identical(data$M,6)
  expect_match(data$caption,"Showing 2/4 original units, 2/3 original domains",fixed=TRUE)
  expect_match(data$caption,paste0("Original full-report risk = ",result$risk_exact),fixed=TRUE)
  one <- postrank:::.md_plot_prepare(result,units="unit-4",domains="priority-Z")
  expect_identical(dim(one$grades),c(1L,1L))
  expect_identical(one$long$grade,4L)
  expect_identical(one$K,c(`priority-Z`=4L))
})

test_that("declared modeled identity remains distinct from a grade tie and zero weight", {
  skip_if_not_installed("gmp")
  result <- md_plot_data_case()$evaluation
  data <- postrank:::.md_plot_prepare(result,units=c("unit-9","unit-2"),view="pair")
  expect_identical(data$pair$domain_id,result$input$domain_ids)
  expect_identical(data$pair$sign,c(1L,0L,0L))
  expect_identical(data$pair$structural_identity,c(FALSE,TRUE,FALSE))
  expect_identical(data$pair$grade_i,c(1L,1L,3L))
  expect_identical(data$pair$grade_j,c(2L,1L,3L))
  expect_identical(data$pair$direction_label,c("unit-9 higher than unit-2",
    "Direction withheld","Direction withheld"))
  expect_identical(unname(result$decision$weights["zero-domain"]),0)
  zero <- postrank:::.md_plot_prepare(result,domains="zero-domain")
  expect_identical(zero$K,c(`zero-domain`=1L))
  expect_identical(zero$long$grade,rep(1L,4L))
  expect_match(zero$caption,"Ties withhold direction",fixed=TRUE)
})

test_that("display selections require original character IDs and explicit pair units", {
  skip_if_not_installed("gmp")
  result <- md_plot_data_case()$evaluation
  for (bad in list(character(),1:2,c("unit-9","unit-9"),c("unit-9",NA),"unknown",
      factor("unit-9")))
    expect_error(postrank:::.md_plot_prepare(result,units=bad),class="postrank_mdomain_error")
  for (bad in list(character(),1L,c("priority-Z","priority-Z"),"unknown",NA_character_))
    expect_error(postrank:::.md_plot_prepare(result,domains=bad),class="postrank_mdomain_error")
  for (bad in list(NULL,"unit-9",result$input$unit_ids,c("unit-9","unit-9")))
    expect_error(postrank:::.md_plot_prepare(result,units=bad,view="pair"),"distinct")
  expect_error(postrank:::.md_plot_prepare(result,view="cells"),"one or two explicit")
  cells <- postrank:::.md_plot_prepare(result,domains="priority-A",view="cells")
  expect_match(cells$caption,"Cell counts aggregate over unshown domains",fixed=TRUE)
  for (bad in list(NULL,"unknown",c("grades","pair"),NA_character_,1L))
    expect_error(postrank:::.md_plot_prepare(result,view=bad),"view must be")
  assessment <- structure(list(evaluation=result),class=c("postrank_mdomain_assessment","list"))
  expect_error(postrank:::.md_plot_prepare(assessment),"use x\\$evaluation")
  expect_error(postrank:::.md_plot_prepare(result$grades),"stored public")
})

test_that("stored plots need no numerical validators, arithmetic, compute or RNG paths", {
  skip_if_not_installed("gmp")
  result <- md_plot_data_case()$evaluation
  fit <- md_plot_data_fit()
  wanted <- postrank:::.md_plot_prepare(fit)
  boom <- function(...) stop("Optional arithmetic and numerical computation are unavailable")
  local_mocked_bindings(.md_require_gmp=boom,.md_attempt=boom,
    .md_validate_input=boom,.md_validate_fit=boom,.md_validate_evaluation=boom,
    .md_validate_family=boom,.md_bind_decision=boom,.md_action=boom,
    p2_validate_input=boom,p2_validate_action=boom,p2_validate_decision=boom,
    p2_evaluate_expected=boom,p2_evaluate_joint=boom,p2_solve_candidates=boom,
    postrank_mdomain_evaluate=boom,postrank_mdomain_solve=boom)
  withr::local_seed(105L)
  seed <- .Random.seed
  expect_identical(postrank:::.md_plot_prepare(fit),wanted)
  expect_identical(postrank:::.md_plot_prepare(result)$full_grades,result$grades)
  expect_identical(postrank:::.md_plot_prepare(result,units=c("unit-2","unit-9"),view="pair")$pair$sign,
    c(-1L,0L,0L))
  expect_identical(.Random.seed,seed)
})

test_that("evaluation hashes and original ID aliases reject stale or malformed records", {
  skip_if_not_installed("gmp")
  result <- md_plot_data_case()$evaluation
  changes <- list(
    grades=function(x) {x$grades[1L,1L] <- 4L;x},
    risk=function(x) {x$risk <- 0;x},
    identity=function(x) {x$input$equality_classes[[1L]][1L] <- "other";x},
    action=function(x) {x$action$G[1L,1L] <- 4L;x},
    engine=function(x) {x$evaluation$action$G[1L,1L] <- 4L;x},
    input=function(x) {x$input$payloads[[1L]]$values[1L] <- 9;x},
    receipt=function(x) {x$receipts$validated_result_hash <- NULL;x},
    input_class=function(x) {class(x$input) <- "list";x})
  for (name in names(changes)) {
    error <- tryCatch(postrank:::.md_plot_prepare(changes[[name]](result)),error=identity)
    expect_s3_class(error,"postrank_mdomain_error")
    expect_identical(error$code,"mdomain_result_mutated",info=name)
  }
  # Receipt matching does not substitute for verifying the source/grade aliases.
  for (change in list(
      function(x) {x$input$unit_ids <- rev(x$input$unit_ids);x},
      function(x) {x$input$original_spec$domain_ids <- rev(x$input$domain_ids);x},
      function(x) {x$action$domain_ids <- rev(x$input$domain_ids);x},
      function(x) {x$action$K[1L] <- 1L;x},
      function(x) {x$input$original_spec$target_spec[[2L]]$equality_classes[1L] <- "other";x},
      function(x) {x$evaluation$action <- unclass(x$evaluation$action);x},
      function(x) {x$grades <- x$grades * 1;x},
      function(x) {x$input <- 1L;x})) {
    changed <- change(result)
    changed$receipts$validated_result_hash <- postrank:::.md_evaluation_hash(changed)
    expect_error(postrank:::.md_plot_prepare(changed),class="postrank_mdomain_error")
  }
})

test_that("fit preparation binds the public evaluation and selected search record", {
  skip_if_not_installed("gmp")
  fit <- md_plot_data_fit()
  data <- postrank:::.md_plot_prepare(fit,units=c("unit-4","unit-9"),domains="priority-Z")
  expect_identical(data$full_grades,fit$evaluation$grades)
  expect_identical(data$grades,fit$grades[c("unit-4","unit-9"),"priority-Z",drop=FALSE])
  expect_match(data$caption,"Selection restricted to the complete declared candidate family",fixed=TRUE)
  expect_match(data$caption,"unrestricted optimality is not established",fixed=TRUE)
  changes <- list(
    missing_evaluation=function(x) {x$evaluation <- NULL;x},
    missing_solution=function(x) {x$solution <- NULL;x},
    missing_selected_action=function(x) {x$solution$selected_action <- NULL;x},
    selected_grade=function(x) {x$solution$selected_action$G[1L,1L] <- 4L;x},
    selected_id=function(x) {x$solution$selected_id <- "unknown";x},
    selected_ids=function(x) {x$solution$selected_action$unit_ids <- rev(x$input$unit_ids);x},
    record=function(x) {x$solution$candidate_table$risk[1L] <- 42;x},
    action_class=function(x) {class(x$solution$selected_action) <- "list";x},
    solution_class=function(x) {class(x$solution) <- "list";x},
    evaluation_class=function(x) {class(x$evaluation) <- "list";x},
    evaluation_hash=function(x) {x$evaluation$receipts$validated_result_hash <- "changed";x},
    family=function(x) {x$family <- NULL;x},
    input_class=function(x) {class(x$input) <- "list";x})
  for (name in names(changes))
    expect_error(postrank:::.md_plot_prepare(changes[[name]](fit)),
      class="postrank_mdomain_error",info=name)
  for (name in c("missing_evaluation","missing_solution","missing_selected_action", "selected_id", "selected_ids",
      "action_class","solution_class","evaluation_class","evaluation_hash")) {
    changed <- changes[[name]](fit)
    changed$receipts$validated_result_hash <- postrank:::.md_fit_hash(changed)
    expect_error(postrank:::.md_plot_prepare(changed),class="postrank_mdomain_error",info=name)
  }
})

test_that("captions distinguish empirical, approximate and unevaluated quantities", {
  skip_if_not_installed("gmp")
  empirical <- postrank:::.md_plot_prepare(md_plot_data_case(empirical=TRUE)$evaluation)
  expect_match(empirical$caption,"Supplied empirical measure",fixed=TRUE)
  expect_match(empirical$caption,"exact represented-measure arithmetic",fixed=TRUE)
  expect_match(empirical$caption,"no intended posterior feasibility certificate",fixed=TRUE)
  approximate <- postrank:::.md_plot_prepare(md_plot_data_case(approximate=TRUE)$evaluation)
  expect_match(approximate$caption,"Declared finite law; contains approximate arithmetic",fixed=TRUE)
  expected <- postrank:::.md_plot_prepare(md_plot_data_case(expected=TRUE)$evaluation)
  expect_match(expected$caption,"J = not evaluated",fixed=TRUE)
  expect_match(expected$caption,"joint not_evaluated",fixed=TRUE)
})

test_that("plotting accepts supported subclasses and character ID wrappers", {
  skip_if_not_installed("gmp")
  fixture <- md_plot_data_case()
  class(fixture$input) <- c("research_input",class(fixture$input))
  evaluation <- postrank_mdomain_evaluate(fixture$input,fixture$evaluation$grades,fixture$decision)
  class(evaluation) <- c("research_evaluation",class(evaluation))
  data <- postrank:::.md_plot_prepare(evaluation,units=I(c("unit-4","unit-9")),
    domains=I("priority-Z"))
  expect_identical(as.character(data$unit_ids),c("unit-4","unit-9"))
  expect_identical(as.character(data$domain_ids),"priority-Z")
  expect_identical(data$grades,evaluation$grades[c("unit-4","unit-9"),"priority-Z",drop=FALSE])
  expect_identical(data$full_grades,evaluation$grades)
  class(evaluation) <- "list"
  expect_error(postrank:::.md_plot_prepare(evaluation),"stored public")
})
