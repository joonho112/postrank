# Self-contained since 0.9.0: tests call the package namespace directly.
ci_prov<-function()list(producer_id='fixed-identity-test',producer_version='1',posterior_id='literal-no-sampling',input_payload_sha256=strrep('a',64),source_sha256=strrep('b',64),config_sha256=strrep('c',64))
ci_gaussian<-function() {
  m<-matrix(c(-1,1),2,1,dimnames=list(entity=c('A','B'),criterion='k'))
  C<-array(c(1,1),c(1,1,2),dimnames=list(criterion_i='k',criterion_j='k',entity=c('A','B')))
  postrank_gaussian_coefficients(m,C,'entities_given_shared_h',ci_prov())
}
ci_mixture<-function(mcmc=FALSE) {
  g<-ci_gaussian();z<-list(mu=c(k=0),Sigma=matrix(1,1,1,dimnames=list(criterion_i='k',criterion_j='k')),means=g$means,covariance=g$source$covariance)
  z2<-z;z2$mu<-c(k=1);z2$means[,1]<-c(2,-2)
  idx<-if(mcmc)data.frame(state_id=c('s1','s2'),chain_id=c(1L,2L),iteration=c(10L,20L)) else data.frame(state_id=c('s1','s2'))
  postrank_mixture_coefficients(list(s1=z,s2=z2),c(s1=.5,s2=.5),idx,if(mcmc)'hyperparameter_mcmc' else 'fixed_finite_mixture','entities_given_shared_h',ci_prov())
}
testthat::test_that('own-domain identity binds both projections source and metadata',{
  for(x in list(ci_gaussian(),ci_mixture(),ci_mixture(TRUE))) {
    testthat::expect_identical(x$coefficient_identity,x$input_identity);testthat::expect_identical(x$coefficient_identity,x$pairwise_identity)
    testthat::expect_false(identical(x$input_identity,.pr_identity(x)))
    for(key in c('coefficient_identity','input_identity','pairwise_identity')){b<-x;b[[key]]<-strrep('f',64);testthat::expect_error(validate_postrank_coefficients(b),'changed after construction')}
    b<-x;b$means[1,1]<-b$means[1,1]+.1;testthat::expect_error(validate_postrank_coefficients(b))
    b<-x;b$e[1,2,1]<-.3;b$e[2,1,1]<-.7;testthat::expect_error(validate_postrank_coefficients(b),'changed after construction')
    b<-x;b$provenance$config_sha256<-strrep('d',64);testthat::expect_error(validate_postrank_coefficients(b),'changed after construction')
  }
})
testthat::test_that('header order canonicalizes while state order and supplied values remain bound',{
  x<-ci_mixture();b<-x[rev(names(x))];class(b)<-class(x)
  b$source<-b$source[rev(names(b$source))];b$provenance<-b$provenance[rev(names(b$provenance))];b$capabilities<-b$capabilities[rev(names(b$capabilities))]
  testthat::expect_true(validate_postrank_coefficients(b));testthat::expect_identical(.pr_coefficient_identity(b),x$input_identity)
  src<-x$source;index<-src$state_index[2:1,,drop=FALSE]
  y<-postrank_mixture_coefficients(src$components[2:1],src$weights[2:1],index,src$source_regime,src$conditional_independence,x$provenance)
  testthat::expect_equal(y$means,x$means,tolerance=0);testthat::expect_equal(y$e,x$e,tolerance=0);testthat::expect_false(identical(y$input_identity,x$input_identity))
  src$components$s1$mu<-c(k=10)
  y<-postrank_mixture_coefficients(src$components,src$weights,src$state_index,src$source_regime,src$conditional_independence,x$provenance)
  testthat::expect_identical(y$means,x$means);testthat::expect_identical(y$e,x$e);testthat::expect_false(identical(y$input_identity,x$input_identity));testthat::expect_false(y$validation$source_values_checked)
})
testthat::test_that('typed identity does not inherit a caller serialization default',{
  x<-ci_gaussian()
  check<-function(version) {
    old<-options(serializeVersion=version);on.exit(options(old))
    testthat::expect_identical(.pr_coefficient_identity(x),x$input_identity)
    testthat::expect_true(validate_postrank_coefficients(x))
  }
  check(2L);check(3L)
})
testthat::test_that('explicit audit tests mathematical projection separately from immutable byte seal',{
  for(x in list(ci_gaussian(),ci_mixture())) {
    testthat::expect_true(validate_postrank_coefficients(x,recompute=TRUE))
    # Deliberately untrusted new-domain negative artifact, never a public
    # constructor/legacy-draw substitute. Importers also require expected ID.
    b<-x;b$e[1,2,1]<-.3;b$e[2,1,1]<-.7;b<-.pr_coefficient_seal(b)
    testthat::expect_true(validate_postrank_coefficients(b))
    testthat::expect_error(validate_postrank_coefficients(b,recompute=TRUE),'projection')
    b<-x;b$e[1,2,1]<-b$e[1,2,1]+1e-15;b$e[2,1,1]<-b$e[2,1,1]-1e-15
    testthat::expect_error(validate_postrank_coefficients(b),'changed after construction')
    b<-.pr_coefficient_seal(b);testthat::expect_true(validate_postrank_coefficients(b,recompute=TRUE))
  }
})
testthat::test_that('capabilities retain statistical truth and distinguish fixed from MCMC states',{
  g<-ci_gaussian();f<-ci_mixture();m<-ci_mixture(TRUE)
  for(x in list(g,f,m)) {
    caps<-postrank_coefficient_capabilities(x)
    testthat::expect_true(caps$weighted_expected_risk);testthat::expect_true(caps$posterior_means)
    for(key in c('minimax_problem','protection_problem','exact_G_problem','target_state_trace','target_quantiles','exact_rational','formal_numerical_certification'))testthat::expect_false(caps[[key]])
    for(key in setdiff(names(x$validation),'structure_checked'))testthat::expect_false(x$validation[[key]])
  }
  testthat::expect_false(g$capabilities$rb_conditional_risk_trace);testthat::expect_true(f$capabilities$rb_conditional_risk_trace)
  testthat::expect_false(f$capabilities$hyperparameter_mcse_eligible);testthat::expect_true(m$capabilities$hyperparameter_mcse_eligible)
  b<-m;b$source$state_index$iteration[1]<-11L;testthat::expect_error(validate_postrank_coefficients(b),'changed after construction')
})
