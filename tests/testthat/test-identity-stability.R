# T-obj-01 / T-inv-03: sealed fixtures keep their legacy identities; round trips verify;
# core mutations fail or produce a new identity.
gi <- jsonlite::read_json(test_path("fixtures", "golden-identities.json"))

test_that("toy, example and coefficient fixtures reproduce the golden identities", {
  pw <- postrank_pairwise(postrank_toy)
  expect_identical(postrank_toy$validation$input_identity, gi$postrank_toy$input_identity)
  expect_identical(pw$pairwise_identity, gi$postrank_toy$pairwise_identity)
  expect_identical(postrank_problem(pw, c(need_A = .6, need_B = .4), .25, 3L)$problem_identity, gi$postrank_toy$problem_identity)
  g <- unlist(gi$postrank_toy$fixed_grade)
  expect_identical(.pr_solution_identity(g, pw$entity_ids)$relation_identity, gi$postrank_toy$relation_identity)
  epw <- postrank_pairwise(pr_example_draws)
  expect_identical(pr_example_draws$validation$input_identity, gi$pr_example_draws$input_identity)
  expect_identical(epw$pairwise_identity, gi$pr_example_draws$pairwise_identity)
  expect_identical(postrank_problem(epw, c(poverty = .5, frl = .25, snap = .25), .25, 4L)$problem_identity,
    gi$pr_example_draws$problem_identity)
  expect_identical(pr_example_gaussian$coefficient_identity, gi$pr_example_gaussian$coefficient_identity)
  expect_identical(postrank_problem(pr_example_gaussian, c(poverty = .5, frl = .25, snap = .25), .25, 4L)$problem_identity,
    gi$pr_example_gaussian$problem_identity)
  # The 9002 shipped example keeps its 0.0.1.9002 identities (T-inv-03).
  expect_identical(gi$postrank_toy$input_identity, "9e7e1006f4d53c1bf75b4bbeb89fdf72c24afc2b24ecfb6832c86acc66692331")
  expect_identical(gi$postrank_toy$problem_identity, "45c5f990202d9df3b60143a186177338ff1c47bc428db7e07c10e3252af37aba")
})

test_that("typed settings and solution relation identities are invariant to display metadata", {
  pw <- postrank_pairwise(postrank_toy); w <- c(need_A = .6, need_B = .4)
  a <- postrank_problem(pw, settings = postrank_settings(w, .25, 3L, label = "A"))
  b <- postrank_problem(pw, settings = postrank_settings(w, .25, 3L, label = "a different display label"))
  expect_identical(a$problem_identity, b$problem_identity)
  expect_identical(a$problem_identity, gi$postrank_toy$problem_identity)
})

test_that("JSON and RDS round trips verify; core mutations are rejected", {
  path <- withr::local_tempfile(fileext = ".json")
  write_postrank_draws(postrank_toy, path)
  back <- read_postrank_draws(path)
  expect_identical(back$validation$input_identity, postrank_toy$validation$input_identity)
  rds <- withr::local_tempfile(fileext = ".rds"); saveRDS(pr_example_gaussian, rds)
  expect_true(validate_postrank_coefficients(readRDS(rds)))
  bad <- postrank_toy; bad$joint_draws$tensor$values[1, 1, 1] <- bad$joint_draws$tensor$values[1, 1, 1] + 1
  # Core content change: either rejected or re-sealed under a newly computed identity.
  rebuilt <- tryCatch(as_postrank_draws(bad), error = function(e) NULL)
  if (!is.null(rebuilt)) expect_false(identical(rebuilt$validation$input_identity, postrank_toy$validation$input_identity))
  expect_false(identical(.pr_identity(.pr_payload(bad)), .pr_identity(.pr_payload(postrank_toy))))
  bad <- pr_example_gaussian; bad$means[1, 1] <- bad$means[1, 1] + 1
  expect_error(validate_postrank_coefficients(bad), class = "postrank_input_error")
  p <- postrank_problem(postrank_pairwise(postrank_toy), c(need_A = .6, need_B = .4), .25, 3L)
  p$settings$tau <- .3
  expect_error(.pr_validate_problem(p))
})
