md_family_test_input <- function(n=3L, D=2L, units=paste0("u", seq_len(n))) {
  domains <- paste0("d", seq_len(D))
  a <- array(rep(seq_len(n), D), c(1L, n, D),
    dimnames=list(state="specified-state", unit=units, domain=domains))
  targets <- setNames(lapply(domains, function(d) list(definition=paste("Fictional", d),
    units="illustrative units", orientation="larger_is_higher", transformations=list(),
    equality_classes=setNames(units, units),
    equality_provenance="Distinct coordinates of an independently specified finite law.")), domains)
  p <- md_test_provenance()
  p$input_id <- "family-independent-fixture"
  p$law_id <- "family-independent-finite-law"
  p$joint_generation <- "The single complete state and mass one specify the entire fictional law."
  p$sampling_assumptions <- list(finite_support_origin="One explicitly specified state has mass one.")
  postrank_mdomain_input(a, targets=targets, provenance=p,
    representation="exact_finite_law", masses="1")
}

test_that("candidate banks preserve all-withheld, canonical columns and identities", {
  skip_if_not_installed("gmp")
  x <- md_test_input()
  default <- postrank_mdomain_family(x)
  expect_s3_class(default, "postrank_mdomain_family")
  expect_s3_class(default$family, "p2_candidate_family")
  expect_identical(default$family$column_counts, c(need=1L, cost=1L))
  expect_identical(default$family$product_size_exact, "1")
  expect_identical(.md_validate_family(x, default), default$family)
  expect_identical(default$family_hash, default$family$family_hash)
  expect_identical(default$source_input_hash, p2_hash(x$original_spec))
  seeds <- list(need=list(first=c(A=-10,B=-10,C=5), same=c(A=1,B=1,C=2),
    withheld=c(A=90,B=90,C=90)), cost=list(reverse=c(A=3,B=2,C=1)))
  f <- postrank_mdomain_family(x, columns=seeds)
  expect_identical(f$family$column_counts, c(need=2L, cost=2L))
  expect_identical(f$family$product_size_exact, "4")
  b <- f$family$banks$need
  expect_identical(unname(b$columns), rbind(c(1L,1L,1L), c(1L,1L,2L)))
  expect_identical(b$receipts$duplicate_columns_removed, 2L)
  expect_true(all(vapply(f$family$banks, function(b) sum(b$metadata$all_withheld)==1L, logical(1))))
  fewer <- postrank_mdomain_family(x, columns=list(need=seeds$need[1L], cost=seeds$cost))
  expect_identical(fewer$family$banks$need$candidate_ids, b$candidate_ids)
  expect_identical(f$receipts$preflight$need$count_exact, "2")
  expect_false(f$receipts$cartesian_product_materialized)
  expect_false(f$receipts$numerical_guarantee)
  expect_false(f$provenance$need$fixed_universe_claim)
})

test_that("orders, cuts, grade caps and seed overlaps have exact deduplicated counts", {
  skip_if_not_installed("gmp")
  x <- md_test_input()
  ordering <- list(need=c("A","B","C"), cost=c("C","B","A"))
  cuts <- list(need=1:2, cost=1:2)
  seed <- list(need=list(overlap=c(A=1,B=1,C=2), outside=c(A=2,B=1,C=1)), cost=list())
  f <- postrank_mdomain_family(x, columns=seed, order=ordering, cuts=cuts,
    max_grades=c(need=2L,cost=2L), max_actions=12L)
  expect_identical(f$family$column_counts, c(need=4L,cost=3L))
  expect_identical(f$family$product_size_exact, "12")
  expect_identical(f$receipts$preflight$need$ordered_count_exact, "3")
  expect_identical(f$receipts$preflight$need$external_columns_outside_ordered_bank, 1L)
  expect_true(all(f$family$banks$need$metadata$K <= 2L))
  no_cuts <- postrank_mdomain_family(x, order=ordering)
  expect_identical(no_cuts$family$product_size_exact, "1")
  no_grades <- postrank_mdomain_family(x, order=ordering, cuts=cuts, max_grades=1L)
  expect_identical(no_grades$family$product_size_exact, "1")
  expect_error(postrank_mdomain_family(x, cuts=cuts), "explicit order", class="postrank_mdomain_error")
  expect_error(postrank_mdomain_family(x, order="guess"), class="postrank_mdomain_error")
  expect_error(postrank_mdomain_family(x, order=ordering, cuts=list(need=c(1L,1L),cost=integer())),
    "distinct integers", class="postrank_mdomain_error")
  expect_error(postrank_mdomain_family(x, order=ordering, cuts=list(need=3L,cost=integer())),
    "distinct integers", class="postrank_mdomain_error")
  expect_error(postrank_mdomain_family(x, columns=list(need=list(c(A=1,B=2,C=3)),cost=list()),
    max_grades=2L), "grade cap exceeded", class="postrank_mdomain_error")
})

test_that("the same structural guards apply to every domain independent of loss weights", {
  skip_if_not_installed("gmp")
  a <- md_test_array(); a[,"B","cost"] <- a[,"A","cost"]
  targets <- md_test_targets()
  targets$cost$equality_classes <- c(A="same", B="same", C="other")
  x <- postrank_mdomain_input(a, targets=targets, provenance=md_test_provenance(),
    representation="exact_finite_law", masses=rep("1/4",4L))
  ordering <- list(need=c("A","B","C"),cost=c("A","C","B"))
  f <- postrank_mdomain_family(x, order=ordering, cuts=list(need=1:2,cost=1:2))
  expect_identical(f$family$banks$cost$identity_blocked_cut_positions, 1:2)
  expect_identical(f$family$column_counts, c(need=4L,cost=1L))
  decision <- .md_bind_decision(x, postrank_mdomain_decision(weights=c(need="1",cost="0"), t=NULL))
  expect_identical(as.character(decision$weights_exact), c("1","0"))
  expect_true(all(f$family$banks$cost$columns[,"A"] == f$family$banks$cost$columns[,"B"]))
  expect_error(postrank_mdomain_family(x,
    columns=list(need=list(),cost=list(c(A=1,B=2,C=3)))), "equality guard violated in domain cost",
    class="postrank_mdomain_error")
})

test_that("hard bank and exact product limits fail before any native bank allocation", {
  skip_if_not_installed("gmp")
  bank_calls <- 0L
  testthat::local_mocked_bindings(p2_build_domain_bank=function(...) {
    bank_calls <<- bank_calls+1L
    stop("unexpected native bank construction")
  })
  x <- md_family_test_input(n=70L,D=1L)
  e <- tryCatch(postrank_mdomain_family(x, order=list(d1=x$unit_ids),
    cuts=list(d1=seq_len(69L))), error=identity)
  expect_s3_class(e,"postrank_mdomain_error")
  expect_identical(e$code,"mdomain_family_cap")
  expect_identical(e$requested,"590295810358705651712")
  expect_identical(e$available,"1000")
  expect_match(conditionMessage(e),"no allocation or truncation")
  x <- md_family_test_input(n=2L,D=60L)
  columns <- setNames(rep(list(list(c(u1=1,u2=2),c(u1=2,u2=1))),60L), x$domain_ids)
  e <- tryCatch(postrank_mdomain_family(x,columns=columns,max_actions=.Machine$integer.max),error=identity)
  expect_s3_class(e,"postrank_mdomain_error")
  expect_identical(e$code,"mdomain_family_cap")
  expect_identical(e$field,"max_actions")
  expect_identical(e$requested,"42391158275216203514294433201")
  expect_match(conditionMessage(e),"no banks or Cartesian actions")
  x <- md_test_input()
  e <- tryCatch(postrank_mdomain_family(x,
    columns=list(need=rep(list(c(A=1,B=1,C=1)),1001L),cost=list())),error=identity)
  expect_identical(e$code,"mdomain_family_cap")
  expect_identical(e$requested,"1001")
  expect_identical(bank_calls,0L)
})

test_that("product preflight accounts for duplicate supplied and generated columns", {
  skip_if_not_installed("gmp")
  x <- md_test_input()
  seeds <- list(need=list(c(A=1,B=1,C=2),c(A=3,B=3,C=4)),
    cost=list(c(A=1,B=1,C=2),c(A=3,B=3,C=4)))
  f <- postrank_mdomain_family(x,columns=seeds,max_actions=4L)
  expect_identical(f$family$product_size_exact,"4")
  e <- tryCatch(postrank_mdomain_family(x,columns=seeds,max_actions=3L),error=identity)
  expect_identical(e$code,"mdomain_family_cap")
  expect_identical(e$requested,"4")
  expect_identical(e$available,"3")
})

test_that("family identities and frozen source input are revalidated", {
  skip_if_not_installed("gmp")
  x <- md_test_input()
  expect_error(postrank_mdomain_family(x,columns=list(cost=list(),need=list())),
    "input domain order",class="postrank_mdomain_error")
  for (g in list(c(1,2,3), c(B=1,A=2,C=3), c(A=1,B=2,unknown=3)))
    expect_error(postrank_mdomain_family(x,columns=list(need=list(g),cost=list())),
      "input unit order",class="postrank_mdomain_error")
  f <- postrank_mdomain_family(x)
  changed <- x; changed$payloads$joint$values[1,1,1] <- 100
  e <- tryCatch(.md_validate_family(changed,f),error=identity)
  expect_identical(e$code,"mdomain_input_mutated")
  a <- md_test_array()[,c("B","A","C"),,drop=FALSE]
  targets <- md_test_targets()
  targets <- lapply(targets,function(z) {z$equality_classes <- z$equality_classes[c("B","A","C")];z})
  reordered <- postrank_mdomain_input(a,targets=targets,provenance=md_test_provenance(),
    representation="exact_finite_law",masses=rep("1/4",4L))
  e <- tryCatch(.md_validate_family(reordered,f),error=identity)
  expect_identical(e$code,"mdomain_family_source")
  source <- x$original_spec; source$input_id <- "another-input"
  other <- postrank_mdomain_input(source)
  expect_error(.md_validate_family(other,f),"same unchanged construction input",class="postrank_mdomain_error")
  changed <- f; changed$family$banks$need$columns[1,1] <- 2L
  e <- tryCatch(.md_validate_family(x,changed),error=identity)
  expect_identical(e$code,"mdomain_family_mutated")
  changed <- f; changed$provenance$need$construction_method <- "edited"
  expect_error(.md_validate_family(x,changed),"receipts have changed",class="postrank_mdomain_error")
  expect_error(.md_validate_family(x,f$family),"prepare the candidate family",class="postrank_mdomain_error")
  expect_identical(.md_validate_family(x,f)$family_hash,f$family_hash)
})

test_that("explicit posterior mean order records actual construction states and stable ID ties", {
  skip_if_not_installed("gmp")
  x <- md_test_input()
  f <- postrank_mdomain_family(x,order="posterior_mean",cuts=list(need=1:2,cost=1:2))
  expect_identical(f$family$banks$need$order,c("A","B","C"))
  expect_identical(f$family$banks$cost$order,c("A","B","C"))
  expect_identical(f$provenance$need$posterior_means_exact,c(A="9/4",B="2",C="7/4"))
  expect_identical(f$provenance$need$construction_draw_ids,x$payloads$joint$state_ids)
  expect_identical(f$provenance$cost$construction_state_ids,x$payloads$joint$state_ids)
  expect_identical(f$provenance$need$construction_state_origin,x$payloads$joint$state_origin)
  expect_identical(f$provenance$need$sample_adaptive,
    c(order=TRUE,seeds=FALSE,cut_positions=FALSE,configuration=FALSE))
  expect_true(f$provenance$cost$depends_on_y)
  expect_false(f$provenance$need$fixed_universe_claim)
  expect_true(f$receipts$sample_adaptive_order)
  a <- md_test_array(); a[,,1L] <- 1; a[,,2L] <- 1
  a <- a[,c("C","A","B"),,drop=FALSE]
  targets <- lapply(md_test_targets(),function(z) {
    z$equality_classes <- z$equality_classes[c("C","A","B")];z})
  tied <- postrank_mdomain_input(a,targets=targets,provenance=md_test_provenance(),
    representation="exact_finite_law",masses=rep("1/4",4L))
  f <- postrank_mdomain_family(tied,order="posterior_mean")
  expect_identical(f$family$banks$need$order,c("A","B","C"))
  expect_identical(f$family$product_size_exact,"1")
  summary <- postrank_mdomain_input(md_test_summary_spec())
  e <- tryCatch(postrank_mdomain_family(summary,order="posterior_mean"),error=identity)
  expect_identical(e$code,"mdomain_capability")
  expect_identical(postrank_mdomain_family(summary)$family$product_size_exact,"1")
})
