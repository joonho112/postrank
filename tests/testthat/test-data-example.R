# T-doc-10 / T-doc-12 (example part): the sealed typed fixtures validate, agree with each
# other and leave the caller's RNG state untouched.
test_that("postrank_toy equals the shipped JSON fixture in full core payload and identity", {
  json <- read_postrank_draws(system.file("examples", "synthetic-iid.json", package = "postrank", mustWork = TRUE))
  expect_identical(postrank_toy, json)
  expect_identical(postrank_toy$validation$input_identity, json$validation$input_identity)
})

test_that("pr_example_draws is a complete strict S = 4000 joint IID input", {
  x <- pr_example_draws
  expect_s3_class(x, "postrank_draws")
  expect_identical(dim(x$joint_draws$tensor$values), c(4000L, 30L, 3L))
  expect_identical(x$entity_ids, sprintf("site%03d", 1:30))
  expect_identical(x$criterion_ids, c("poverty", "frl", "snap"))
  expect_identical(x$joint_draws$sampling$regime, "iid")
  expect_true(validate_postrank_draws(x)$valid)
  for (f in c("identification", "tie_policy", "provenance", "context"))
    expect_false(is.null(x[[f]]), info = f)
  expect_match(x$tie_policy$justification, "continuous")
  expect_match(x$joint_draws$sampling$sampling_provenance, "seed 20261024")
  expect_identical(x$provenance$created_at, "2026-10-24T00:00:00Z")
})

test_that("draw frequencies agree with the analytic Gaussian coefficients (T-doc-10 band)", {
  pw <- postrank_pairwise(pr_example_draws)
  expect_identical(dimnames(pw$e)[[1]], dimnames(pr_example_gaussian$e)[[1]])
  expect_lte(max(abs(pw$e - pr_example_gaussian$e), na.rm = TRUE), 5 * sqrt(.25 / 4000))
  expect_true(validate_postrank_coefficients(pr_example_gaussian, recompute = TRUE))
  expect_identical(rownames(pr_example_gaussian$means), pr_example_draws$entity_ids)
  expect_identical(pr_example_gaussian$provenance$input_payload_sha256, pr_example_draws$joint_draws$origin$source_hash)
})

test_that("loading the bundled data does not touch the caller's RNG state", {
  set.seed(42); before <- .Random.seed
  e <- new.env(); utils::data("pr_example_draws", "pr_example_gaussian", "pr_toy_mcmc", package = "postrank", envir = e)
  expect_identical(.Random.seed, before)
})
