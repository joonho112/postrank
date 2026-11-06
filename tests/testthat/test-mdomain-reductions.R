# These reductions score a fixed, identical common-grade action set. They do
# not claim family membership or compare independently selected optima.
md_reduction_finite_p1 <- function(D=2L) {
  values <- md_test_array()[,,seq_len(D),drop=FALSE]
  spec <- pr_test_payload(S=4L, n=3L, K=D)
  dimnames(values) <- list(state=paste0("state-",seq_len(4L)),
    entity=spec$entity_ids, criterion=spec$criterion_ids)
  numerators <- c(1L,2L,3L,4L)
  spec$input_kind <- "exact_finite_posterior"; spec$joint_draws <- NULL
  spec$provenance$artifact_hash <- digest::digest(list(values,numerators),algo="sha256")
  spec$finite_law <- list(denominator=10L, value_representation="safe_integer",
    states=lapply(seq_len(4L),function(s) list(state_id=dimnames(values)[[1L]][s],
      mass_numerator=numerators[s], theta=matrix(values[s,,],3L,D,
        dimnames=list(entity=spec$entity_ids,criterion=spec$criterion_ids)))),
    law_definition="The four specified integer target states have masses 1/10, 2/10, 3/10 and 4/10.",
    not_empirical_posterior_relabeling=TRUE)
  list(draws=as_postrank_draws(spec), values=values,
    masses=paste0(numerators,"/10"))
}

# An independent statewise weak-error sum, with no production pairwise
# coefficients, evaluator, action canonicalizer or P2 core calls.
md_reduction_exact_counts <- function(values, masses, grades, weights, tau) {
  S <- dim(values)[1L]; n <- dim(values)[2L]; D <- dim(values)[3L]
  F <- matrix(0L,S,D); N <- integer(D)
  for (d in seq_len(D)) for (i in seq_len(n-1L)) for (j in seq.int(i+1L,n)) {
    if (grades[i,d]==grades[j,d]) next
    N[d] <- N[d]+1L
    ahead <- if(grades[i,d]<grades[j,d]) i else j
    behind <- if(ahead==i) j else i
    F[,d] <- F[,d]+as.integer(values[,ahead,d]<=values[,behind,d])
  }
  masses <- gmp::as.bigq(masses); M <- choose(n,2L)
  EF <- lapply(seq_len(D),function(d) sum(masses*gmp::as.bigq(F[,d])))
  risk <- gmp::as.bigq(0)
  for(d in seq_len(D)) risk <- risk+gmp::as.bigq(weights[d])*
    (EF[[d]]+gmp::as.bigq(tau)*(M-N[d]))/M
  list(F=F,N=N,EF=EF,risk=risk,M=M)
}

md_reduction_state_input <- function(values, masses, classes=NULL) {
  units <- dimnames(values)[[2L]]; domains <- dimnames(values)[[3L]]
  targets <- setNames(lapply(domains,function(d) list(
    definition=paste("Specified fictional coordinate",d), units="illustrative units",
    orientation="larger_is_higher",transformations=list(),
    equality_classes=if(is.null(classes)) setNames(units,units) else classes[[d]],
    equality_provenance="Only explicitly supplied model identities are declared by the finite-law design.")),domains)
  postrank_mdomain_input(values,targets=targets,provenance=md_test_provenance(),
    representation="exact_finite_law",masses=masses)
}

test_that("one-domain and common-grade P2 risks reduce to the same P1 weak loss", {
  skip_if_not_installed("gmp")
  # Ordinary P1 inputs require zero latent equality. Positive equality is
  # checked below against its own weak-error oracle, rather than relabeled.
  for(D in 1:2) {
    law <- md_reduction_finite_p1(D)
    input <- postrank_mdomain_input(law$draws,provenance=list(
      input_id=paste0("matched-p1-",D),law_id="specified-four-state-law",proper_law=TRUE))
    pairwise <- postrank_pairwise(law$draws)
    domains <- input$domain_ids
    weights <- setNames(if(D==1L) 1 else c(.25,.75),domains)
    weights_exact <- setNames(if(D==1L) "1" else c("1/4","3/4"),domains)
    decision <- postrank_mdomain_decision(weights=weights_exact,tau="1/4",q="1/2",t=NULL)
    expect_identical(input$unit_ids,pairwise$entity_ids)
    expect_identical(input$domain_ids,pairwise$criterion_ids)
    expect_equal(unname(input$payloads$joint$values),unname(law$values),tolerance=0)
    expect_identical(as.character(input$payloads$joint$weights_exact),
      as.character(gmp::as.bigq(law$masses)))
    # The 13 ordered partitions of three units define the identical supplied
    # common-grade action set, with the same all-pair q protection and tau.
    actions <- pr_tie_all_actions(3L,3L)
    expect_length(actions,13L)
    for(g in actions) {
      grades <- matrix(rep(g,D),3L,D,dimnames=list(input$unit_ids,domains))
      p1 <- postrank_evaluate(setNames(g,input$unit_ids),pairwise,weights,tau=.25)
      p2 <- postrank_mdomain_evaluate(input,grades,decision)
      exact <- md_reduction_exact_counts(law$values,law$masses,grades,weights_exact,"1/4")
      expect_identical(p2$risk_exact,as.character(exact$risk))
      expect_equal(p2$risk,p1$weighted_risk,tolerance=1e-14)
      expect_equal(p2$domain_table$EF,unname(p1$E),tolerance=1e-14)
      expect_identical(p2$domain_table$EF_exact,vapply(exact$EF,as.character,character(1L)))
      expect_equal(p2$domain_table$N,rep(p1$N,D),tolerance=0)
      expect_equal(p2$M,p1$M,tolerance=0)
      expect_identical(p2$mean_feasible,all(p1$E<=.5*p1$N))
      expect_identical(p2$feasible_for_represented_measure,p2$mean_feasible)
      expect_identical(p2$J_exact,"0")
      expect_false(p2$joint_protection_enabled)
      if(p1$N==0) {
        expect_true(all(is.na(p2$domain_table$eFDP)))
        expect_equal(p2$domain_table$eFDP_zero,rep(0,D),tolerance=0)
        expect_identical(p2$risk_exact,"1/4")
      }
    }
  }
})

test_that("positive latent equality is a false strict assertion in the weak loss", {
  skip_if_not_installed("gmp")
  values <- array(0,c(2L,3L,1L),dimnames=list(
    state=c("state-1","state-2"),unit=c("001","002","003"),domain="need1"))
  values[1,,1] <- c(2,2,0); values[2,,1] <- c(3,1,0)
  input <- md_reduction_state_input(values,c("1/3","2/3"))
  grades <- matrix(c(1L,2L,2L),3L,1L,dimnames=list(input$unit_ids,input$domain_ids))
  ev <- postrank_mdomain_evaluate(input,grades,postrank_mdomain_decision(
    tau="1/4",q="1/6",t="1/6",alpha="1/3"))
  exact <- md_reduction_exact_counts(values,c("1/3","2/3"),grades,"1","1/4")
  expect_identical(ev$risk_exact,"7/36")
  expect_identical(ev$risk_exact,as.character(exact$risk))
  expect_identical(ev$domain_table$EF_exact,"1/3")
  expect_identical(ev$domain_table$eFDP_exact,"1/6")
  expect_identical(ev$J_exact,"1/3")
  expect_true(ev$mean_feasible); expect_true(ev$joint_feasible)
  expect_identical(unname(ev$evaluation$expected$traces$need1$full_F),c(1L,0L))
  # The supported P1 positive-equality route explicitly has another loss:
  # equality is neutral. Preserve that distinction, using the same law/IDs.
  neutral_pw <- postrank_tie_pairwise(as_postrank_tie_draws(
    pr_tie_fixture(values,c(1L,2L))))
  neutral <- postrank_tie_evaluate(setNames(grades[,1],input$unit_ids),
    neutral_pw,c(need1=1),tau=.25)
  expect_identical(neutral_pw$entity_ids,input$unit_ids)
  expect_identical(neutral_pw$criterion_ids,input$domain_ids)
  expect_equal(neutral$weighted_risk,1/12,tolerance=1e-14)
  expect_equal(ev$risk-neutral$weighted_risk,1/9,tolerance=1e-14)
  expect_gt(ev$risk,neutral$weighted_risk)
  held <- postrank_mdomain_evaluate(input,grades*0+1L,
    postrank_mdomain_decision(tau="1/4",q="0",t="0",alpha="0"))
  expect_identical(held$risk_exact,"1/4")
  expect_identical(held$domain_table$EF_exact,"0")
  expect_identical(held$J_exact,"0")
  expect_identical(held$status$joint,"analytic_zero")
  # N=2 and cutoff=2 permit a tail event, but this complete law has only
  # F=0 or F=1. Zero evaluated mass differs from an inactive guard.
  zero_mass <- postrank_mdomain_evaluate(input,grades,
    postrank_mdomain_decision(t="1/2",alpha="0"))
  expect_identical(zero_mass$J_exact,"0")
  expect_identical(zero_mass$event_table$cutoff_exact,"2")
  expect_false(zero_mass$event_table$analytically_inactive)
  expect_identical(zero_mass$status$joint,"evaluated")
})

test_that("a zero-weight domain retains expected and joint protection", {
  skip_if_not_installed("gmp")
  values <- md_test_array()[1,,,drop=FALSE]
  values[1,,"need"] <- c(3,2,1); values[1,,"cost"] <- c(1,2,3)
  input <- md_reduction_state_input(values,"1")
  grades <- matrix(rep(1:3,2L),3L,2L,dimnames=list(input$unit_ids,input$domain_ids))
  policy <- postrank_mdomain_decision(weights=c(need="1",cost="0"),
    tau="1/4",q="0",t="0",alpha="0")
  ev <- postrank_mdomain_evaluate(input,grades,policy)
  expect_identical(ev$risk_exact,"0")
  expect_identical(ev$domain_table$EF_exact,c("0","3"))
  expect_identical(ev$domain_table$weighted_loss_exact,c("0","0"))
  expect_identical(ev$expected_constraints$satisfied,c(TRUE,FALSE))
  expect_false(ev$mean_feasible); expect_false(ev$joint_feasible)
  expect_false(ev$feasible_for_represented_measure)
  expect_identical(ev$J_exact,"1")
  expect_identical(ev$event_table$p_exact,c("0","1"))
  only_need <- postrank_mdomain_decision(weights=c(need="1",cost="0"),tau="1/4",
    expected=data.frame(domain_id="need",scope_id="full",q="0"),
    joint=data.frame(domain_id="need",scope_id="full",t="0"),alpha="0")
  unprotected <- postrank_mdomain_evaluate(input,grades,only_need)
  expect_identical(unprotected$risk_exact,ev$risk_exact)
  expect_true(unprotected$feasible_for_represented_measure)
  expect_identical(unprotected$J_exact,"0")
  # Identity guards also apply to a zero-weight coordinate.
  values[1,,"cost"] <- c(1,1,0)
  classes <- list(need=c(A="A",B="B",C="C"),cost=c(A="same",B="same",C="C"))
  identical_input <- md_reduction_state_input(values,"1",classes)
  expect_error(postrank_mdomain_evaluate(identical_input,grades,policy),
    "equality guard",class="postrank_mdomain_error")
})

test_that("separate fits support expectations but refuse active cross-domain coupling", {
  skip_if_not_installed("gmp")
  a <- md_test_array()
  vectors <- setNames(lapply(seq_len(2L),function(d) a[,,d]),c("need","cost"))
  input <- postrank_mdomain_input(vectors,targets=md_test_targets(),provenance=md_test_provenance(),
    representation="exact_finite_law",masses=list(need=rep("1/4",4L),cost=rep("1/4",4L)))
  grades <- matrix(rep(1:3,2L),3L,2L,dimnames=list(input$unit_ids,input$domain_ids))
  decision <- postrank_mdomain_decision(tau="1/4",q="1",t="0",alpha="1/2")
  expected <- postrank_mdomain_evaluate(input,grades,decision,mode="expected")
  expect_identical(expected$risk_exact,"5/12")
  expect_false(expected$joint_evaluated)
  expect_true(is.na(expected$J)); expect_true(is.na(expected$joint_feasible))
  expect_true(is.na(expected$feasible_for_represented_measure))
  err <- tryCatch(postrank_mdomain_evaluate(input,grades,decision),error=identity)
  expect_s3_class(err,"postrank_mdomain_error")
  expect_identical(err$code,"mdomain_capability")
  expect_identical(err$requested$domains,c("need","cost"))
  expect_match(conditionMessage(err),"no coupling")
  # A t=1 row is inactive even with disclosures: only need requires a law.
  one_active <- postrank_mdomain_decision(tau="1/4",q="1",alpha="1/2",
    joint=data.frame(domain_id=c("need","cost"),scope_id="full",t=c("0","1")))
  within <- postrank_mdomain_evaluate(input,grades,one_active)
  expect_identical(within$J_exact,"3/4")
  expect_identical(within$event_table$analytically_inactive,c(FALSE,TRUE))
  expect_identical(within$event_table$inactive_reason,c("","cutoff_exceeds_N"))
  expect_false(within$feasible_for_represented_measure)
  expect_identical(within$status$feasibility,"infeasible_for_represented_measure")
  # Withholding cost also makes its row inactive, irrespective of its weight.
  grades[,"cost"] <- 1L
  held_cost <- postrank_mdomain_evaluate(input,grades,decision)
  expect_identical(held_cost$J_exact,"3/4")
  expect_identical(held_cost$event_table$inactive_reason,c("","no_disclosure"))
  expect_identical(held_cost$evaluation$traces$active_domains,"need")
})

test_that("pair summaries refuse active tails but allow analytic-zero and disabled guards", {
  skip_if_not_installed("gmp")
  input <- postrank_mdomain_input(md_test_summary_spec())
  grades <- matrix(rep(1:3,2L),3L,2L,dimnames=list(input$unit_ids,input$domain_ids))
  active <- postrank_mdomain_decision(joint=data.frame(domain_id="need",scope_id="full",t="0"))
  expected <- postrank_mdomain_evaluate(input,grades,active,mode="expected")
  expect_equal(expected$risk,.5,tolerance=0)
  expect_null(expected$risk_exact)
  expect_false(expected$joint_evaluated)
  expect_error(postrank_mdomain_evaluate(input,grades,active),
    "capability",class="postrank_mdomain_error")
  no_disclosure <- postrank_mdomain_evaluate(input,grades*0+1L,
    postrank_mdomain_decision(tau="1/4",q="0",t="0",alpha="0"))
  expect_equal(no_disclosure$risk,.25,tolerance=0)
  expect_identical(no_disclosure$J_exact,"0")
  expect_identical(no_disclosure$status$joint,"analytic_zero")
  expect_true(no_disclosure$feasible_for_represented_measure)
  at_one <- postrank_mdomain_evaluate(input,grades,
    postrank_mdomain_decision(t="1",alpha="0"))
  expect_identical(at_one$J_exact,"0")
  expect_true(all(at_one$event_table$analytically_inactive))
  disabled <- postrank_mdomain_evaluate(input,grades,
    postrank_mdomain_decision(expected=data.frame(),joint=data.frame()))
  expect_identical(disabled$status$joint,"disabled")
  expect_false(disabled$joint_protection_enabled)
  expect_identical(nrow(disabled$event_table),0L)
  expect_identical(disabled$J_exact,"0")
})

test_that("scoped disclosure counts never replace the original loss denominator", {
  skip_if_not_installed("gmp")
  values <- md_test_array()[,,"need",drop=FALSE]
  input <- md_reduction_state_input(values,rep("1/4",4L))
  grades <- matrix(c(1L,1L,2L),3L,1L,dimnames=list(input$unit_ids,input$domain_ids))
  ab <- matrix(0L,3L,3L,dimnames=list(input$unit_ids,input$unit_ids))
  ab[1,2] <- ab[2,1] <- 1L
  decision <- postrank_mdomain_decision(tau="1/4",scope=list(ab=ab,empty=ab*0L),
    expected=data.frame(domain_id=c("need","need"),scope_id=c("ab","empty"),q="0"),
    joint=data.frame(domain_id=c("need","need"),scope_id=c("ab","empty"),t="0"),alpha="0")
  ev <- postrank_mdomain_evaluate(input,grades,decision)
  expect_equal(ev$M,3,tolerance=0)
  expect_identical(ev$risk_exact,"1/3")
  expect_identical(ev$domain_table$EF_exact,"3/4")
  expect_equal(ev$domain_table$N,2,tolerance=0)
  expect_identical(ev$domain_table$eFDP_exact,"3/8")
  expect_equal(ev$scope_table$N,c(0,0),tolerance=0)
  expect_identical(ev$scope_table$EF_exact,c("0","0"))
  expect_true(all(is.na(ev$scope_table$eFDP)))
  expect_identical(ev$scope_table$eFDP_zero_exact,c("0","0"))
  expect_identical(ev$J_exact,"0")
  expect_true(ev$mean_feasible); expect_true(ev$feasible_for_represented_measure)
  full <- postrank_mdomain_evaluate(input,grades,postrank_mdomain_decision(tau="1/4",t=NULL))
  expect_identical(full$risk_exact,ev$risk_exact)
  # An empty catalog and explicit disabled rows have no scoped denominator.
  disabled <- postrank_mdomain_evaluate(input,grades,postrank_mdomain_decision(
    tau="1/4",scope=list(),expected=data.frame(),joint=data.frame()))
  expect_identical(disabled$risk_exact,ev$risk_exact)
  expect_identical(nrow(disabled$scope_table),0L)
  expect_identical(nrow(disabled$event_table),0L)
  expect_identical(disabled$status$joint,"disabled")
})

test_that("strict FDP thresholds exclude equality at the exact count boundary", {
  skip_if_not_installed("gmp")
  input <- md_reduction_state_input(md_test_array()[,,"need",drop=FALSE],rep("1/4",4L))
  grades <- matrix(1:3,3L,1L,dimnames=list(input$unit_ids,input$domain_ids))
  exact <- postrank_mdomain_evaluate(input,grades,
    postrank_mdomain_decision(t="1/3",alpha="1/4"))
  expect_identical(exact$event_table$cutoff_exact,"2")
  expect_identical(exact$J_exact,"1/4")
  expect_true(exact$joint_feasible)
  expect_identical(unname(exact$evaluation$traces$union_event),c(FALSE,FALSE,FALSE,TRUE))
  below <- postrank_mdomain_evaluate(input,grades,postrank_mdomain_decision(
    t="0.3333333333333333333333333333",alpha="1/4"))
  expect_identical(below$event_table$cutoff_exact,"1")
  expect_identical(below$J_exact,"3/4")
  expect_false(below$joint_feasible)
})
