# Self-contained since 0.9.0: the independent fixed-action risk oracle is the
# packaged copy in pr_cf_oracle; the solve is mocked with local_mocked_bindings()
# so no native backend can be entered.
cp_ref<-pr_cf_oracle
cp_x<-function(mixture=FALSE) {
  ids<-c('A','B','C');ks<-c('k1','k2')
  m<-matrix(c(2,0,-2,-1,1,0),3,2,dimnames=list(entity=ids,criterion=ks))
  C<-array(rep(diag(2),3),c(2,2,3),dimnames=list(criterion_i=ks,criterion_j=ks,entity=ids))
  p<-list(producer_id='fixed-public-pipeline',producer_version='1',posterior_id='literal-law-not-sampled',input_payload_sha256=strrep('a',64),source_sha256=strrep('b',64),config_sha256=strrep('c',64))
  g<-postrank_gaussian_coefficients(m,C,'entities_given_shared_h',p)
  if(!mixture)return(g)
  z<-list(mu=c(k1=0,k2=0),Sigma=matrix(c(1,0,0,1),2,dimnames=list(criterion_i=ks,criterion_j=ks)),means=m,covariance=C)
  z2<-z;z2$means[,1]<-c(-1,0,1)
  postrank_mixture_coefficients(list(s1=z,s2=z2),c(s1=.25,s2=.75),data.frame(state_id=c('s1','s2')),'fixed_finite_mixture','entities_given_shared_h',p)
}
cp_mock_solve<-function(problem,grade=NULL,lower=NULL,status='optimal') {
  calls<-0L
  testthat::local_mocked_bindings(
    .pr_solve_raw=function(problem,backend,control,strategy,seed_grades=list()) {
      calls<<-calls+1L
      primal<-if(is.null(grade))NULL else .pr_engine_primal(problem,grade)
      objective<-if(is.null(primal))NA_real_ else sum(problem$model$objective*primal)
      list(primal=primal,raw_status='FIXED_MOCK',raw_message='No optimizer called',status_normalized=status,termination_reason='fixed_mock',has_incumbent=!is.null(primal),raw_objective=objective,raw_lower_bound=if(is.null(lower))objective else lower,relative_gap=NA_real_,runtime=0,backend=list(name='fixed_mock_no_native',wrapper_version='fixture',solver_version=NA_character_,options=list()),raw=list(execution_scope='mock',native_solver_called=FALSE),warnings=character(),bound_source='backend_reported_dual_bound')
    },
    # Any accidental backend call fails closed.
    .pr_backend_highs=function(...)stop('native entry forbidden'),
    .pr_backend_gurobi=function(...)stop('native entry forbidden'))
  fit<-postrank_solve(problem,backend='highs',strategy='label_mip',control=list(absolute_risk_gap=1e-6))
  list(fit=fit,mock_calls=calls)
}
testthat::test_that('typed public pairwise and weighted problem retain genuine input identity',{
  for(mixture in c(FALSE,TRUE)) {
    x<-cp_x(mixture);w<-c(k1=.5,k2=.5)
    testthat::expect_identical(postrank_pairwise(x),x)
    testthat::expect_error(postrank_pairwise(x,method='blocks'),'already projected')
    p<-postrank_problem(x,w,.25,3L)
    testthat::expect_identical(p$input_identity,x$coefficient_identity)
    testthat::expect_identical(p$pairwise,x);testthat::expect_identical(p$objective_units,list(raw='weighted_Z',scale=1/3,offset=.25))
    testthat::expect_null(p$pairwise$sample_sizes);testthat::expect_true(.pr_validate_problem(p))
  }
})
testthat::test_that('all fixed tiny actions agree with independent main risk and sparse raw units',{
  for(mixture in c(FALSE,TRUE)) {
    x<-cp_x(mixture);w<-c(k1=.5,k2=.5);p<-postrank_problem(x,w,.25,3L)
    e<-x$e;names(dimnames(e))<-NULL
    grid<-expand.grid(rep(list(1:3),3));relations<-character()
    for(row in seq_len(nrow(grid))) {
      g<-stats::setNames(as.integer(grid[row,]),x$entity_ids)
      evaluated<-postrank_evaluate(g,x,w,.25)
      reference<-cp_ref$main_fixed_action_risk(e,g,w,.25)
      primal<-.pr_engine_primal(p,g);validation<-validate_postrank_solution(p,primal)
      testthat::expect_equal(evaluated$weighted_risk,reference$risk,tolerance=1e-14)
      testthat::expect_identical(evaluated$N,reference$N)
      testthat::expect_true(validation$valid)
      testthat::expect_equal(.25+sum(p$model$objective*primal)/3,reference$risk,tolerance=1e-14)
      relations<-c(relations,paste(evaluated$grade,collapse=':'))
    }
    testthat::expect_length(unique(relations),13L)
  }
})
testthat::test_that('new-type scope rejects unsupported modes without narrowing legacy modes',{
  x<-cp_x();w<-c(k1=.5,k2=.5)
  testthat::expect_error(postrank_problem(x,w,.25,3L,objective='minimax'),'at-most-G')
  testthat::expect_error(postrank_problem(x,w,.25,3L,q=c(k1=.2)),'at-most-G')
  testthat::expect_error(postrank_problem(x,w,.25,3L,exact_G=2L),'at-most-G')
  testthat::expect_error(postrank_evaluate(c(A=1L,B=2L,C=2L),x,w,.25,objective='minimax'),'at-most-G')
  testthat::expect_error(postrank_evaluate(c(A=1L,B=2L,C=2L),x,w,.25,minimax_criteria='k1'),'at-most-G')
  bad<-x;bad$means[1,1]<-4;testthat::expect_error(postrank_problem(bad,w,.25,3L))
  p<-postrank_problem(x,w,.25,3L);p$pairwise<-cp_x(TRUE);testthat::expect_error(.pr_validate_problem(p),'changed after construction')
})
testthat::test_that('public solve fixed mock preserves fit validation risk bounds and raw scope',{
  for(mixture in c(FALSE,TRUE)) {
    x<-cp_x(mixture);w<-c(k1=.5,k2=.5);p<-postrank_problem(x,w,.25,3L);g<-c(A=1L,B=2L,C=3L)
    solved<-cp_mock_solve(p,g);fit<-solved$fit
    testthat::expect_identical(solved$mock_calls,1L);testthat::expect_true(fit$incumbent_validated)
    testthat::expect_identical(fit$input_identity,x$coefficient_identity)
    testthat::expect_equal(fit$objective$primary_action_risk,postrank_evaluate(g,x,w,.25)$weighted_risk,tolerance=0)
    testthat::expect_equal(fit$objective$risk_upper_bound,fit$objective$primary_action_risk,tolerance=0)
    testthat::expect_identical(fit$raw_backend_result$execution_scope,'mock')
    testthat::expect_false(fit$raw_backend_result$native_solver_called);testthat::expect_false(fit$objective$numerical_certification)
    absent<-cp_mock_solve(p,status='time_limit')$fit
    testthat::expect_false(absent$incumbent_validated);testthat::expect_null(absent$grade);testthat::expect_true(is.na(absent$objective$risk_upper_bound))
    badbound<-cp_mock_solve(p,g,lower=10)$fit
    testthat::expect_identical(badbound$status$normalized,'numerical_error');testthat::expect_true(badbound$incumbent_validated)
    testthat::expect_true(is.na(badbound$objective$risk_lower_bound));testthat::expect_true(is.na(badbound$objective$risk_absolute_gap))
  }
})
