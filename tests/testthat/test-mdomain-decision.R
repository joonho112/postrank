# Decision binding only consumes identified dimensions and the external spec ID.
# These small metadata objects isolate decision tests from posterior adapters.
md_decision_metadata <- function() {
  structure(list(n=3L, D=2L, unit_ids=c("A", "B", "C"),
                 domain_ids=c("need", "cost"), decision_spec_hash="designed-policy-id"),
            class=c("p2_profile_input", "list"))
}

test_that("multidomain decision defaults bind exact full-pair joint guards", {
  skip_if_not_installed("gmp")
  input <- md_decision_metadata()
  recipe <- postrank_mdomain_decision()
  expect_s3_class(recipe, "postrank_mdomain_decision")
  expect_identical(recipe$tau, "1/10")
  expect_null(recipe$q)
  expect_identical(recipe$t, "0")
  expect_identical(recipe$alpha, "1/20")
  bound <- .md_bind_decision(input, recipe)
  expect_s3_class(bound, "p2_profile_decision")
  expect_identical(as.character(bound$weights_exact), rep("1/2", 2L))
  expect_identical(as.character(bound$tau_exact), rep("1/10", 2L))
  expect_identical(as.character(bound$alpha_exact), "1/20")
  expect_identical(as.character(bound$joint_t_exact), c("0", "0"))
  expect_identical(bound$joint$domain_id, input$domain_ids)
  expect_identical(bound$joint$scope_id, rep("full", 2L))
  expect_identical(nrow(bound$expected), 0L)
  expect_equal(bound$M, 3, tolerance=0)
  expect_identical(unname(diag(bound$scopes$full)), rep(0L, 3L))
  expect_identical(dimnames(bound$scopes$full), list(input$unit_ids, input$unit_ids))
  expect_true(bound$receipts$joint_protection_enabled)
  expect_true(bound$receipts$public_recipe$bound_from_exact_fields)
})

test_that("scoped masks and explicit protection rows retain order and exact thresholds", {
  skip_if_not_installed("gmp")
  input <- md_decision_metadata()
  ab <- matrix(0L, 3, 3, dimnames=list(input$unit_ids, input$unit_ids))
  ab[1,2] <- ab[2,1] <- 1L
  empty <- ab * 0L
  expected <- data.frame(domain_id=c("cost", "need"), scope_id=c("empty", "ab"),
                         q=c("1/7", "0"))
  joint <- data.frame(domain_id="need", scope_id="ab", t="1/3")
  recipe <- postrank_mdomain_decision(scope=list(ab=ab, empty=empty),
    q="1", t="1", expected=expected, joint=joint)
  bound <- .md_bind_decision(input, recipe)
  expect_identical(names(bound$scopes), c("ab", "empty"))
  expect_identical(bound$expected$domain_id, c("cost", "need"))
  expect_identical(bound$expected$scope_id, c("empty", "ab"))
  expect_identical(as.character(bound$expected_q_exact), c("1/7", "0"))
  expect_identical(as.character(bound$joint_t_exact), "1/3")
  expect_identical(recipe$expected$q, c("1/7", "0"))
  expect_identical(recipe$joint$t, "1/3")
  expect_equal(sum(bound$scopes$ab)/2, 1, tolerance=0)
  expect_equal(sum(bound$scopes$empty), 0, tolerance=0)
  expect_equal(bound$M, 3, tolerance=0)
  expect_error(.md_bind_decision(input,
    postrank_mdomain_decision(scope=list(ab=ab))), "full-pair mask",
    class="postrank_mdomain_error")
  expect_error(.md_bind_decision(input,
    postrank_mdomain_decision(scope=list(ab=ab), q="1/2", t=NULL)),
    "full-pair mask", class="postrank_mdomain_error")
})

test_that("convenience rows use a full mask and explicit empty rows disable guards", {
  skip_if_not_installed("gmp")
  input <- md_decision_metadata()
  full <- matrix(1L, 3, 3); diag(full) <- 0L
  bound <- .md_bind_decision(input, postrank_mdomain_decision(
    scope=list(everyone=full), q=c(need="1/4", cost="3/4"), t="1/2"))
  expect_identical(bound$expected$scope_id, c("everyone", "everyone"))
  expect_identical(bound$joint$scope_id, c("everyone", "everyone"))
  expect_identical(as.character(bound$expected_q_exact), c("1/4", "3/4"))
  disabled <- .md_bind_decision(input,
    postrank_mdomain_decision(q="1", expected=data.frame(), joint=data.frame()))
  expect_identical(nrow(disabled$expected), 0L)
  expect_identical(nrow(disabled$joint), 0L)
  expect_false(disabled$receipts$joint_protection_enabled)
  null_t <- .md_bind_decision(input, postrank_mdomain_decision(t=NULL))
  expect_identical(nrow(null_t$joint), 0L)
  no_scopes <- .md_bind_decision(input,
    postrank_mdomain_decision(scope=list(), expected=data.frame(), joint=data.frame()))
  expect_length(no_scopes$scopes, 0L)
  expect_identical(nrow(no_scopes$joint), 0L)
})

test_that("decision thresholds preserve exact boundary semantics", {
  skip_if_not_installed("gmp")
  input <- md_decision_metadata()
  exact <- .md_bind_decision(input,
    postrank_mdomain_decision(tau="1/2", q="0", t="1/3", alpha="0"))
  expect_identical(as.character(exact$tau_exact), c("1/2", "1/2"))
  expect_identical(as.character(exact$alpha_exact), "0")
  expect_identical(as.character(p2_integer_cutoff(as.character(exact$joint_t_exact[1]), 3)), "2")
  binary <- postrank_mdomain_decision(t=1/3, alpha=0.1)
  expect_identical(binary$t, as.character(gmp::as.bigq(1/3)))
  expect_identical(binary$alpha, as.character(gmp::as.bigq(0.1)))
  expect_false(identical(binary$t, "1/3"))
  expect_identical(as.character(p2_integer_cutoff(binary$t, 3)), "1")
  upper <- .md_bind_decision(input, postrank_mdomain_decision(t="1", alpha="1"))
  expect_identical(as.character(upper$alpha_exact), "1")
  expect_identical(as.character(p2_integer_cutoff(as.character(upper$joint_t_exact[1]), 3)), "4")
  for (args in list(list(tau="0"), list(tau="1/2+1"), list(tau="0.50001"),
                    list(q="-1/100"), list(t="1.0001"), list(alpha="-1"),
                    list(alpha=c("0", "1")))) {
    expect_error(do.call(postrank_mdomain_decision, args), class="postrank_mdomain_error")
  }
})

test_that("weights use core normalization and do not remove zero-weight guards", {
  skip_if_not_installed("gmp")
  input <- md_decision_metadata()
  raw <- c(need=.3, cost=.7 + 2e-13)
  bound <- .md_bind_decision(input, postrank_mdomain_decision(weights=raw))
  exact_raw <- gmp::as.bigq(raw)
  expect_true(all(bound$weights_exact == exact_raw/sum(exact_raw)))
  expect_true(bound$receipts$weights$normalization_performed)
  zero <- .md_bind_decision(input,
    postrank_mdomain_decision(weights=c(need="1", cost="0"), q="1/2"))
  expect_identical(as.character(zero$weights_exact), c("1", "0"))
  expect_identical(zero$joint$domain_id, input$domain_ids)
  expect_identical(zero$expected$domain_id, input$domain_ids)
  expect_error(.md_bind_decision(input,
    postrank_mdomain_decision(weights=c("1/3", "1/3"))), "sum exactly",
    class="postrank_mdomain_error")
  expect_error(.md_bind_decision(input,
    postrank_mdomain_decision(weights=c(cost=.5, need=.5))), "domain order",
    class="postrank_mdomain_error")
  expect_error(.md_bind_decision(input,
    postrank_mdomain_decision(tau=c(cost="1/10", need="1/10"))), "domain order",
    class="postrank_mdomain_error")
})

test_that("decision binding rejects identity errors and mutated recipes", {
  skip_if_not_installed("gmp")
  input <- md_decision_metadata()
  mask <- matrix(1L, 3, 3); diag(mask) <- 0L
  dimnames(mask) <- list(rev(input$unit_ids), rev(input$unit_ids))
  expect_error(.md_bind_decision(input,
    postrank_mdomain_decision(scope=list(full=mask))), "original unit order",
    class="postrank_mdomain_error")
  rows <- data.frame(domain_id="missing", scope_id="full", t="0")
  expect_error(.md_bind_decision(input, postrank_mdomain_decision(joint=rows)),
    "unknown domain/scope", class="postrank_mdomain_error")
  duplicate <- data.frame(domain_id=rep("need", 2), scope_id=rep("full", 2), t=c("0", "1"))
  expect_error(postrank_mdomain_decision(joint=duplicate), "Duplicate",
    class="postrank_mdomain_error")
  mutated <- postrank_mdomain_decision(); mutated$t <- "2"
  expect_error(.md_bind_decision(input, mutated), class="postrank_mdomain_error")
  mutated <- postrank_mdomain_decision(); mutated$alpha <- NULL
  expect_error(.md_bind_decision(input, mutated), "missing required fields",
    class="postrank_mdomain_error")
  err <- tryCatch(postrank_mdomain_decision(tau="0"), error=identity)
  expect_s3_class(err, "postrank_mdomain_error")
  expect_identical(err$code, "mdomain_decision_invalid")
  expect_identical(err$field, "tau")
})


test_that("decision summaries show stored binary weights as their exact rationals", {
  skip_if_not_installed("gmp")
  weights <- c(need=.1, cost=.9)
  d <- postrank_mdomain_decision(weights=weights)
  expected <- as.character(gmp::as.bigq(weights))
  names(expected) <- names(weights)
  expect_identical(d$weights, weights)
  expect_identical(d$receipts$weights_supplied_exact, expected)
  before <- summary(d)
  expect_identical(before$parameters$exact_value[before$parameters$parameter == "weights"],
    unname(expected))
  boom <- function(...) stop("display must use saved strings")
  local_mocked_bindings(p2_decision_numbers=boom, .md_require_gmp=boom,
    .md_bind_decision=boom, postrank_mdomain_evaluate=boom)
  expect_identical(summary(d), before)
  expect_output(print(summary(d)), "Multidomain decision summary")
})
