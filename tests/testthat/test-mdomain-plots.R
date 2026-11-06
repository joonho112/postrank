md_plot_fixture <- function() {
  x <- md_test_input()
  g <- matrix(c(1L,1L,2L,2L,1L,1L),3,2,
    dimnames=list(x$unit_ids,x$domain_ids))
  postrank_mdomain_evaluate(x,g,postrank_mdomain_decision(t=NULL))
}
test_that("one public plotting route retains the card, IDs and numeric data", {
  skip_if_not_installed("gmp")
  x <- md_plot_fixture()
  for (view in c("grades","cells","pair")) {
    chosen <- if(view=="pair") c("A","C") else NULL
    p <- postrank_plot_mdomain(x,view,units=chosen)
    expect_s3_class(p,"ggplot")
    expect_silent(ggplot2::ggplot_build(p))
    meta <- attr(p,"postrank_mdomain")
    expect_identical(meta$view,view)
    expect_true(meta$uses_stored_card)
    expect_identical(meta$original_pairs,3)
    expect_identical(meta$domain_ids,c("need","cost"))
    expect_true(is.data.frame(p$data))
  }
  expect_identical(postrank_mdomain_grades(x),x$grades)
})
test_that("labels and selections retain original identities and full-report scope", {
  skip_if_not_installed("gmp")
  x <- md_plot_fixture()
  labels <- c(A="A long preschool site name",B="Another preschool",C="Community center")
  p <- postrank_plot_mdomain(x,"grades",units=c("C","A"),domains="cost",
    unit_labels=labels,domain_labels=c(need="Student need",cost="Community need"),
    base_size=10,title="Selected sites")
  meta <- attr(p,"postrank_mdomain")
  expect_identical(meta$unit_ids,c("C","A"))
  expect_identical(meta$domain_ids,"cost")
  expect_match(meta$caption,"original|full",ignore.case=TRUE)
  expect_silent(ggplot2::ggplot_build(p))
  expect_error(postrank_plot_mdomain(x,view="other"),class="postrank_mdomain_error")
  expect_error(postrank_plot_mdomain(x,"grades",invented=TRUE),class="postrank_mdomain_error")
  expect_error(postrank_plot_mdomain(x,"grades",12),class="postrank_mdomain_error")
  expect_error(postrank_plot_mdomain(x,"grades",base_size=NA_real_),class="postrank_mdomain_error")
  expect_error(postrank_plot_mdomain(x,"grades",unit_labels=c(Z="Unknown")),class="postrank_mdomain_error")
})
test_that("plot dispatch and rendering do not compute, sample or need optional arithmetic", {
  skip_if_not_installed("gmp")
  x <- md_plot_fixture()
  forbidden <- function(...) stop("Computation called during plotting")
  local_mocked_bindings(.md_require_gmp=forbidden,.md_validate_input=forbidden,
    .md_validate_evaluation=forbidden,p2_evaluate_joint=forbidden,
    p2_evaluate_expected=forbidden,p2_solve_candidates=forbidden)
  had_seed <- exists(".Random.seed",.GlobalEnv,inherits=FALSE)
  before <- if(had_seed) get(".Random.seed",.GlobalEnv) else NULL
  for(view in c("grades","cells","pair")) {
    p <- postrank_plot_mdomain(x,view,units=if(view=="pair") c("A","B") else NULL)
    expect_silent(ggplot2::ggplot_build(p))
  }
  expect_identical(exists(".Random.seed",.GlobalEnv,inherits=FALSE),had_seed)
  if(had_seed) expect_identical(get(".Random.seed",.GlobalEnv),before)
})
