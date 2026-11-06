# T-doc-03: every bundled data object has a topic whose @format lists all of its columns
# in their declared order (tables) or its typed dimensions (typed objects).
pr_rd_text <- function(topic) {
  src <- pr_source_path("man", paste0(topic, ".Rd"))
  rd <- if (file.exists(src)) tools::parse_Rd(src) else tools::Rd_db("postrank", lib.loc = dirname(system.file(package = "postrank")))[[paste0(topic, ".Rd")]]
  expect_false(is.null(rd), info = topic)
  paste(as.character(rd), collapse = "")
}

test_that("the eight data objects are exactly the documented ones", {
  shipped <- sort(utils::data(package = "postrank")$results[, "Item"])
  expect_length(shipped, 8L)
  expect_identical(shipped, sort(c("postrank_toy", "pr_example_draws", "pr_example_gaussian", "pr_toy_mcmc",
    "pr_case_cde", "pr_case_krw", "pr_case_alabama", "pr_tutorial")))
})

test_that("typed objects document their dimensions and declarations", {
  expect_match(pr_rd_text("postrank_toy"), "S = 32, n = 3, K = 2", fixed = TRUE)
  expect_match(pr_rd_text("pr_example_draws"), "4000 x 30 x 3", fixed = TRUE)
  expect_match(pr_rd_text("pr_example_draws"), "eight scientific", fixed = TRUE)
  g <- pr_rd_text("pr_example_gaussian")
  for (s in c("30 x 3", "30 x 30 x 3", "3 x 3 x 30", "entities_given_shared_h")) expect_match(g, s, fixed = TRUE)
  expect_match(pr_rd_text("pr_toy_mcmc"), "2048 x 3 x 2", fixed = TRUE)
  expect_identical(dim(pr_example_draws$joint_draws$tensor$values), c(4000L, 30L, 3L))
  expect_identical(dim(pr_example_gaussian$e), c(30L, 30L, 3L))
  expect_identical(dim(pr_toy_mcmc), c(2048L, 3L, 2L))
})
