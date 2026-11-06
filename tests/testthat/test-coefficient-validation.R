cf_structure_fixture <- function(mixture=FALSE,mcmc=FALSE) {
  ids<-c('A','B');ks<-c('k1','k2')
  means<-matrix(0,2,2,dimnames=list(entity=ids,criterion=ks))
  C<-array(rep(diag(2),2),c(2,2,2),dimnames=list(criterion_i=ks,criterion_j=ks,entity=ids))
  e<-array(NA_real_,c(2,2,2),dimnames=list(entity_i=ids,entity_j=ids,criterion=ks))
  e[1,2,]<-.5;e[2,1,]<-.5
  source<-list(kind='gaussian_conditional',means=means,covariance=C,conditional_independence='entities_given_shared_h')
  if(mixture) {
    z<-list(mu=stats::setNames(c(0,0),ks),Sigma=matrix(c(1,0,0,1),2,dimnames=list(criterion_i=ks,criterion_j=ks)),means=means,covariance=C)
    index<-if(mcmc)data.frame(state_id=c('s1','s2'),chain_id=c(1L,2L),iteration=c(1L,1L)) else data.frame(state_id=c('s1','s2'))
    source<-list(kind='shared_hyperstate_mixture',components=list(s1=z,s2=z),weights=c(s1=.5,s2=.5),state_index=index,source_regime=if(mcmc)'hyperparameter_mcmc' else 'fixed_finite_mixture',conditional_independence='entities_given_shared_h')
  }
  p<-list(producer_id='fixed-validator-fixture',producer_version='1',posterior_id='literal-law-not-sampled',input_payload_sha256=strrep('a',64),source_sha256=strrep('b',64),config_sha256=strrep('c',64))
  .pr_coefficient_assemble(source,means,e,p)
}
test_that('typed schemas are separate complete objects without fabricated draw counts',{
  for(x in list(cf_structure_fixture(),cf_structure_fixture(TRUE),cf_structure_fixture(TRUE,TRUE))) {
    expect_true(validate_postrank_coefficients(x));expect_identical(class(x),c('postrank_coefficients','list'))
    expect_false(inherits(x,'postrank_draws'));expect_null(x$sample_sizes);expect_null(x$exact)
    expect_identical(x$validation,.pr_cf_validation())
  }
})
test_that('unknown schemas fields classes and hidden attributes reject',{
  x<-cf_structure_fixture()
  for(field in c('schema_version','input_kind')){bad<-x;bad[[field]]<-'unknown';expect_error(validate_postrank_coefficients(bad))}
  bad<-x;bad$extra<-TRUE;expect_error(validate_postrank_coefficients(bad),'unknown fields')
  bad<-x;class(bad)<-c('postrank_draws',class(bad));expect_error(validate_postrank_coefficients(bad),'separate')
  bad<-x;attr(bad$means,'origin')<-'hidden';expect_error(validate_postrank_coefficients(bad),'hidden')
  bad<-x;bad$source$extra<-TRUE;expect_error(validate_postrank_coefficients(bad),'unknown fields')
  bad<-x;attr(bad$provenance,'source_checked')<-TRUE;expect_error(validate_postrank_coefficients(bad),'hidden')
})
test_that('axes probabilities and covariance geometry reject invalid inputs',{
  x<-cf_structure_fixture()
  bad<-x;bad$entity_ids<-c('A','A');expect_error(validate_postrank_coefficients(bad),'IDs')
  bad<-x;dimnames(bad$means)[[1]]<-c('B','A');expect_error(validate_postrank_coefficients(bad),'axes')
  bad<-x;bad$means[1,1]<-Inf;expect_error(validate_postrank_coefficients(bad),'finite')
  for(value in c(0,NaN)) {bad<-x;bad$e[1,1,1]<-value;expect_error(validate_postrank_coefficients(bad),'diagonal')}
  for(value in c(-.1,1.1,Inf,NA_real_)) {bad<-x;bad$e[1,2,1]<-value;expect_error(validate_postrank_coefficients(bad),'probabilities')}
  bad<-x;bad$e[1,2,1]<-.6;expect_error(validate_postrank_coefficients(bad),'complements')
  for(value in c(0,-1)) {bad<-x;bad$source$covariance[1,1,1]<-value;expect_error(validate_postrank_coefficients(bad),'positive definite')}
  bad<-x;bad$source$covariance[1,2,1]<-.2;expect_error(validate_postrank_coefficients(bad),'symmetric')
  bad<-x;bad$source$covariance[,,1]<-matrix(c(1,1+5e-13,1-1e-14,1),2);expect_error(validate_postrank_coefficients(bad),'symmetric')
  bad<-x;bad$source$conditional_independence<-NULL;expect_error(validate_postrank_coefficients(bad),'missing fields')
})
test_that('provenance exact fields and derived capability truth limits are enforced',{
  x<-cf_structure_fixture()
  bad<-x;bad$provenance$input_payload_sha256<-'HASH';expect_error(validate_postrank_coefficients(bad),'SHA256')
  bad<-x;bad$provenance$producer_id<-NULL;expect_error(validate_postrank_coefficients(bad),'missing fields')
  for(key in names(x$capabilities)) {bad<-x;bad$capabilities[[key]]<-!bad$capabilities[[key]];expect_error(validate_postrank_coefficients(bad),'capabilities')}
  for(key in setdiff(names(x$validation),'structure_checked')) {bad<-x;bad$validation[[key]]<-TRUE;expect_error(validate_postrank_coefficients(bad),'verification claim')}
  expect_error(.pr_coefficient_assemble(x$source,x$means,x$e,x$provenance,list(everything=TRUE)))
})
test_that('mixture state and original coordinate structure reject recycling and fabrication',{
  x<-cf_structure_fixture(TRUE)
  bad<-x;names(bad$source$components)<-c('s1','s1');expect_error(validate_postrank_coefficients(bad),'IDs')
  bad<-x;bad$source$weights<-c(s2=.5,s1=.5);expect_error(validate_postrank_coefficients(bad),'weights')
  bad<-x;bad$source$weights<-c(s1=.6,s2=.6);expect_error(validate_postrank_coefficients(bad),'weights')
  bad<-x;bad$source$state_index$chain_id<-c(1L,2L);expect_error(validate_postrank_coefficients(bad),'columns')
  bad<-x;bad$source$components$s1$Sigma[1,1]<-0;expect_error(validate_postrank_coefficients(bad),'positive definite')
  bad<-x;bad$source$components$s1$Sigma[,]<-matrix(c(1,1+5e-13,1-1e-14,1),2);expect_error(validate_postrank_coefficients(bad),'symmetric')
  x<-cf_structure_fixture(TRUE,TRUE)
  bad<-x;bad$source$weights<-c(s1=.25,s2=.75);expect_error(validate_postrank_coefficients(bad),'uniform')
  bad<-x;bad$source$weights<-c(s1=.5+5e-13,s2=.5-5e-13);expect_error(validate_postrank_coefficients(bad),'uniform')
  bad<-x;bad$source$state_index$chain_id<-c(1L,1L);expect_error(validate_postrank_coefficients(bad),'duplicate')
  bad<-x;bad$source$state_index$iteration<-c(0L,1L);expect_error(validate_postrank_coefficients(bad),'safe integers')
  bad<-x;bad$source$state_index<-structure(list(state_id=c('s1','s2'),chain_id=1L,iteration=c(1L,2L)),class='data.frame',row.names=c(1L,2L));expect_error(validate_postrank_coefficients(bad),'exact lengths')
  bad<-x;bad$source$source_regime<-'iid_target_draws';expect_error(validate_postrank_coefficients(bad),'unsupported')
  source<-x$source;source$state_index$chain_id<-c(1,1);source$state_index$iteration<-c(1e15,1e15+1)
  large<-postrank_mixture_coefficients(source$components,source$weights,source$state_index,source$source_regime,source$conditional_independence,x$provenance)
  expect_true(validate_postrank_coefficients(large))
  expect_identical(large$source$state_index$iteration,c(1e15,1e15+1))
  source$state_index$iteration<-c(1e15,1e15)
  expect_error(postrank_mixture_coefficients(source$components,source$weights,source$state_index,source$source_regime,source$conditional_independence,x$provenance),'duplicate')
})
test_that('the initial own-domain seal binds source and output without upgrading truth',{
  x<-cf_structure_fixture()
  bad<-x;bad$e[1,2,1]<-.6;bad$e[2,1,1]<-.4;expect_error(validate_postrank_coefficients(bad),'changed after construction')
  bad<-x;bad$source$covariance[1,1,1]<-2;expect_error(validate_postrank_coefficients(bad),'changed after construction')
  bad<-x;bad$provenance$posterior_id<-'different';expect_error(validate_postrank_coefficients(bad),'changed after construction')
  bad<-x;bad$input_identity<-strrep('0',64);expect_error(validate_postrank_coefficients(bad),'changed after construction')
  reordered<-x[rev(names(x))];class(reordered)<-class(x);expect_true(validate_postrank_coefficients(reordered))
  expect_identical(.pr_coefficient_identity(reordered),x$coefficient_identity)
  expect_error(validate_postrank_coefficients(x,recompute=NA),'logical scalar')
})
