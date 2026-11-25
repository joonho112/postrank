# postrank_describe() is a flat front end to postrank_declarations().
desc_args <- function(...) utils::modifyList(list(
  estimand = c(need = "Latent site need in a specified standard normal law"),
  population = "Three fictional sites A, B and C", time = "Static illustration; no observation period",
  units = "Illustrative standardized need units", data = "No observations; the law is specified directly",
  model = "Independent standard normal coordinates", identification = "The law directly defines each site's target.",
  joint = "Each draw holds one value for every site and criterion.",
  sampling = "64 independent draws from rnorm() after set.seed(901); no warmup or thinning.",
  ties = "Independent continuous coordinates are equal with probability zero.", software = "Base R rnorm()",
  source = "The array values created in this test", label = "normal-need", data_version = "1",
  format = "R double array of dimension 64 x 3 x 1"), list(...))
direct <- function(a, ids = names(a$estimand)) postrank_declarations(
  targets = data.frame(criterion_id = ids, estimand = unname(a$estimand[ids]),
    entity_population = if (length(a$population) == 1L) rep(a$population, length(ids)) else unname(a$population[ids]),
    time_reference = if (length(a$time) == 1L) rep(a$time, length(ids)) else unname(a$time[ids]),
    units = if (length(a$units) == 1L) rep(a$units, length(ids)) else unname(a$units[ids]), stringsAsFactors = FALSE),
  context = list(cohort_id = a$label, data_version = a$data_version, data_conditioning = a$data, model_summary = a$model),
  provenance = list(producer = a$software, artifact_id = a$label, construction_note = a$sampling),
  origin = list(source_id = a$label, fit_id = a$label, model_id = a$label, source_format = a$format, source_artifact = a$source),
  identification_note = a$identification, tie_justification = a$ties, joint_generation = a$joint, sampling_provenance = a$sampling)

test_that("one criterion gives the same object as postrank_declarations()", {
  a <- desc_args()
  expect_identical(do.call(postrank_describe, a), direct(a))
  expect_s3_class(do.call(postrank_describe, a), "postrank_declarations")
})

test_that("several criteria recycle shared fields and accept per-criterion fields", {
  a <- desc_args(estimand = c(need = "Latent need", cost = "Latent cost"),
    units = c(cost = "Illustrative cost units", need = "Illustrative need units"))
  d <- do.call(postrank_describe, a)
  expect_identical(d, direct(a))
  expect_identical(d$targets$criterion_id, c("need", "cost"))
  expect_identical(d$targets$units, c("Illustrative need units", "Illustrative cost units"))
  bad <- tryCatch(do.call(postrank_describe, desc_args(estimand = c(need = "x", cost = "y"), units = c("a", "b"))), error = identity)
  expect_identical(bad$code, "invalid_description")
  bad <- tryCatch(do.call(postrank_describe, desc_args(estimand = c(need = "x", cost = "y"), units = c(need = "a"))), error = identity)
  expect_identical(bad$code, "invalid_description")
  bad <- tryCatch(do.call(postrank_describe, desc_args(estimand = c("x"))), error = identity)
  expect_identical(bad$code, "invalid_description")
})

test_that("the format is read from values unless given", {
  set.seed(901)
  values <- array(rnorm(64 * 3), c(64, 3, 1), dimnames = list(NULL, c("A", "B", "C"), "need"))
  a <- desc_args(); a$format <- NULL
  d <- do.call(postrank_describe, c(a, list(values = values)))
  expect_identical(d$origin$source_format, "R double array of dimension 64 x 3 x 1")
  d2 <- do.call(postrank_describe, c(a, list(values = values, format = "CmdStan CSV files")))
  expect_identical(d2$origin$source_format, "CmdStan CSV files")
  err <- tryCatch(do.call(postrank_describe, a), error = identity)
  expect_identical(err$code, "missing_declarations")
  expect_match(conditionMessage(err), "format (or values)", fixed = TRUE)
  err <- tryCatch(do.call(postrank_describe, c(a, list(values = values[, , 1]))), error = identity)
  expect_identical(err$code, "invalid_description")
  draws <- postrank_draws(values, regime = "iid", declarations = d)
  expect_identical(draws$criterion_ids, "need")
})

test_that("missing descriptions are named and placeholders are still rejected", {
  a <- desc_args(); a$ties <- NULL; a$joint <- NULL
  err <- tryCatch(do.call(postrank_describe, a), error = identity)
  expect_identical(err$code, "missing_declarations")
  expect_match(conditionMessage(err), "joint, ties", fixed = TRUE)
  a <- desc_args(); a["data"] <- list(NULL)
  err <- tryCatch(do.call(postrank_describe, a), error = identity)
  expect_identical(err$code, "missing_declarations")
  expect_match(conditionMessage(err), "data", fixed = TRUE)
  err <- tryCatch(do.call(postrank_describe, desc_args(ties = "TBD")), error = identity)
  expect_identical(err$code, "placeholder_declaration")
  err <- tryCatch(do.call(postrank_describe, desc_args(label = "unknown")), error = identity)
  expect_identical(err$code, "placeholder_declaration")
})
