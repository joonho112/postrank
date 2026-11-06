test_that("the labeled user route preserves the finite law and audit limits", {
  skip_if_not_installed("gmp")
  x <- md_test_input()
  expect_s3_class(x,"postrank_mdomain_input")
  expect_s3_class(x,"p2_profile_input")
  expect_identical(x$unit_ids,c("A","B","C"))
  expect_identical(x$domain_ids,c("need","cost"))
  expect_identical(x$payloads$joint$values,md_test_array())
  expect_identical(x$payloads$joint$state_ids,c("s1","s2","s3","s4"))
  expect_identical(as.character(x$payloads$joint$weights_exact),rep("1/4",4L))
  expect_true(x$capabilities$direct_joint)
  expect_false(x$capabilities$numerical_guarantee)
  expect_true(length(x$missing_metadata)>0L)
  expect_null(x$provenance$seed)
  expect_match(x$missing_metadata[["provenance.seed"]],"Not supplied")
  expect_identical(postrank_mdomain_input(x),x)
  expect_identical(postrank_mdomain_input(x$original_spec)$payloads,x$payloads)
})

test_that("IDs, orientation and scientific declarations are explicit", {
  skip_if_not_installed("gmp")
  call <- function(values=md_test_array(),targets=md_test_targets(),provenance=md_test_provenance(),...)
    postrank_mdomain_input(values,targets=targets,provenance=provenance,
      representation="exact_finite_law",masses=rep("1/4",4L),...)
  a <- md_test_array(); dimnames(a)[[2L]] <- c("A","A","C")
  e <- tryCatch(call(a),error=identity)
  expect_s3_class(e,"postrank_mdomain_error");expect_identical(e$field,"unit_ids")
  a <- md_test_array();dimnames(a)[[1L]] <- c("s1","s1","s3","s4")
  expect_error(call(a),class="postrank_mdomain_error")
  a <- md_test_array();dimnames(a) <- NULL
  expect_error(call(a),class="postrank_mdomain_error")
  t <- md_test_targets();t <- t[c("cost","need")]
  expect_error(call(targets=t),"domain order")
  t <- md_test_targets();t$need$orientation <- "smaller_is_higher"
  expect_error(call(targets=t),"oriented")
  t <- md_test_targets();t$need$equality_provenance <- NULL
  expect_error(call(targets=t),"equality_provenance")
  p <- md_test_provenance();p$proper_law <- NULL
  expect_error(call(provenance=p),"proper_law")
  p <- md_test_provenance();p$joint_generation <- NULL
  expect_error(call(provenance=p),"joint_generation")
  p <- md_test_provenance();p$sampling_assumptions <- NULL
  expect_error(call(provenance=p),"finite_support_origin")
  t <- md_test_targets();t$need$equality_classes <- c(A="same",B="same",C="C")
  expect_error(call(targets=t),"Structural equality")
})

test_that("exact masses and original state mapping are checked without reordering", {
  skip_if_not_installed("gmp")
  call <- function(masses=rep("1/4",4L),state_origin=NULL)
    postrank_mdomain_input(md_test_array(),targets=md_test_targets(),provenance=md_test_provenance(),
      representation="exact_finite_law",masses=masses,state_origin=state_origin)
  expect_error(call(c("1/4","1/4","1/4","1/5")),"sum exactly")
  expect_error(call(c("1/4","1/4","1/4","-1/4")),"nonnegative")
  expect_error(call(setNames(rep("1/4",4L),c("s2","s1","s3","s4"))),"state IDs")
  origin <- data.frame(source_index=c(14,11,20,27),chain_id=rep(NA_character_,4),
    iteration_id=rep(NA_real_,4),state_id=c("s2","s1","s3","s4"))
  expect_error(call(state_origin=origin),"state IDs")
  origin$state_id <- c("s1","s2","s3","s4")
  expect_identical(call(state_origin=origin)$payloads$joint$state_origin,origin)
  x <- md_test_input();x$payloads$joint$values[1,1,1] <- 100
  expect_error(postrank_mdomain_input(x),class="postrank_mdomain_error")
  x <- md_test_input();x$original_spec$payloads[[1]]$values[1,1,1] <- 100
  expect_error(postrank_mdomain_input(x),"payload hash")
})

test_that("MCMC states retain original chain and iteration coordinates", {
  skip_if_not_installed("gmp")
  a <- md_test_array();p <- md_test_provenance()
  p$sampling_assumptions <- list(sampler="Specified test sequence; no real sampler was run.",
    chain_details="Two test chains with irregular retained iteration gaps.",target_assertion="Specified fictional target law.")
  origin <- data.frame(source_index=c(8L,12L,19L,25L),chain_id=c("c2","c1","c2","c1"),
    iteration_id=c(3L,7L,9L,15L),state_id=dimnames(a)[[1L]])
  call <- function(o=origin) postrank_mdomain_input(a,targets=md_test_targets(),provenance=p,
    representation="mcmc_equal_weight_draws",state_origin=o)
  expect_error(call(NULL),"original source")
  x <- call()
  expect_identical(x$payloads$joint$state_origin,origin)
  expect_identical(x$payloads$joint$retention$retained_original_indices,origin$source_index)
  expect_match(x$payloads$joint$receipt$sampling_status,"no_iid_or_finite_certificate")
  bad <- origin;bad$iteration_id[c(1,3)] <- c(3L,3L)
  expect_error(call(bad),"Duplicate known iteration")
  bad <- origin;bad$chain_id[1] <- NA_character_
  expect_error(call(bad),"must be known")
})

test_that("separate vectors and probability summaries never gain coupling", {
  skip_if_not_installed("gmp")
  a <- md_test_array()
  v <- setNames(lapply(seq_len(2L),function(d) a[,,d]),c("need","cost"))
  x <- postrank_mdomain_input(v,targets=md_test_targets(),provenance=md_test_provenance(),
    representation="exact_finite_law",masses=list(need=rep("1/4",4L),cost=rep("1/4",4L)))
  expect_false(x$capabilities$direct_joint)
  expect_identical(x$coupling_status,"unknown_cross_domain")
  expect_silent(.md_require_capability(x,"expected"))
  expect_silent(.md_require_capability(x,"joint","need"))
  expect_error(.md_require_capability(x,"joint",c("need","cost")),class="postrank_mdomain_error")
  expect_error(.md_require_capability(x,"bundle",c("need","cost")),"no coupling")
  bad <- v;bad$cost <- bad$cost[,c(2,1,3)]
  expect_error(postrank_mdomain_input(bad,targets=md_test_targets(),provenance=md_test_provenance(),
    representation="iid_equal_weight_draws"),"unit order")
  for(encoding in c("two_strict","strict_plus_equality")) {
    summary <- postrank_mdomain_input(md_test_summary_spec(encoding))
    expect_true(summary$capabilities$expected_additive)
    expect_false(summary$capabilities$direct_joint)
    expect_identical(summary$capabilities$within_domain_tails,character())
    expect_error(.md_require_capability(summary,"within_domain","need"),"capability")
  }
  spec <- md_test_summary_spec();spec$pair_summary$encoding <- "strict_only"
  expect_error(postrank_mdomain_input(spec),"encoding")
})

test_that("existing validated draw formats adapt losslessly and honestly", {
  skip_if_not_installed("gmp")
  p <- list(input_id="existing-p1-input",law_id="producer-declared-law",proper_law=TRUE)
  for(payload in list(pr_test_payload(),pr_test_payload(regime="mcmc"),pr_test_criterionwise(),pr_test_exact())) {
    old <- as_postrank_draws(payload)
    x <- postrank_mdomain_input(old,provenance=p)
    expect_identical(x$unit_ids,old$entity_ids)
    expect_identical(x$domain_ids,old$criterion_ids)
    expect_identical(x$adapter$source_input,.pr_payload(old))
    expect_identical(x$intended_law$conditioning_info,old$context$data_conditioning)
    expect_identical(x$target_spec[[1L]]$original_target,old$targets[[1L]])
    expect_identical(x$capabilities$direct_joint,old$dependence_mode=="joint_model")
    expect_silent(.md_validate_input(x))
    if(!is.null(old$joint_draws)) {
      expect_identical(x$payloads$joint$values,old$joint_draws$tensor$values)
      expect_identical(x$payloads$joint$state_origin$original_draw_id,
        vapply(old$joint_draws$draw_index,`[[`,character(1),"original_draw_id"))
    }
  }
  old <- as_postrank_draws(pr_test_payload())
  expect_error(postrank_mdomain_input(old),"additionally require")
  old$joint_draws$tensor$values[1,1,1] <- NA_real_
  expect_error(postrank_mdomain_input(old,provenance=p),class="postrank_mdomain_error")
})


test_that("P1 adaptation rejects replacement of source-bound declarations", {
  skip_if_not_installed("gmp")
  base <- list(input_id="adapter-conflict",law_id="declared-law",proper_law=TRUE)
  for (payload in list(pr_test_payload(), pr_test_payload(regime="mcmc"),
      pr_test_criterionwise(), pr_test_exact())) {
    old <- as_postrank_draws(payload)
    original <- postrank_mdomain_input(old, provenance=base)
    conflicting <- list(producer="Other producer", model_version="Other model",
      conditioning_info="Other conditioning", conditioning_data_id="Other data",
      source_hash=strrep("f",64))
    for (field in names(conflicting)) {
      supplied <- base; supplied[field] <- conflicting[field]
      expect_error(postrank_mdomain_input(old, provenance=supplied),
        "conflicts with the validated source", class="postrank_mdomain_error")
    }
    field <- if (old$dependence_mode == "joint_model") "joint_generation" else "within_domain_joint"
    supplied <- base; supplied[[field]] <- "Other joint mechanism"
    expect_error(postrank_mdomain_input(old, provenance=supplied),
      class="postrank_mdomain_error")
    supplied <- base
    first <- original$payloads[[1L]]
    if (length(original$payloads) == 1L) {
      supplied$sampling_assumptions <- first$sampling_assumptions
      supplied$sampling_assumptions[[names(first$sampling_assumptions)[1L]]] <- "Other mechanism"
    } else {
      supplied$sampling_assumptions <- lapply(original$payloads, `[[`, "sampling_assumptions")
      key <- names(supplied$sampling_assumptions[[1L]])[1L]
      supplied$sampling_assumptions[[1L]][[key]] <- "Other mechanism"
    }
    expect_error(postrank_mdomain_input(old, provenance=supplied),
      class="postrank_mdomain_error")
    supplied <- base
    supplied$retention <- if (length(original$payloads) == 1L)
      list(note="Supplementary analyst note") else
      setNames(lapply(old$criterion_ids, function(d) list(note="Supplementary analyst note")), old$criterion_ids)
    supplemented <- postrank_mdomain_input(old, provenance=supplied)
    expect_identical(supplemented$adapter$source_input, original$adapter$source_input)
    expect_identical(supplemented$intended_law, original$intended_law)
  }
})
