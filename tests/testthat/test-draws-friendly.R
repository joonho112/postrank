# T-api-03 / T-api-04: postrank_draws() is bookkeeping over the strict constructors.
df_values <- function(S = 40L) {
  v <- array(0, c(S, 4L, 2L), dimnames = list(NULL, c("A", "B", "C", "D"), c("need1", "need2")))
  for (s in seq_len(S)) for (k in 1:2) v[s, , k] <- c(4, 3, 2, 1) + sin(s * (1:4) + k) / 3 + s / 1e4
  v
}
df_decl_args <- function() list(
  targets = data.frame(criterion_id = c("need1", "need2"), estimand = "Synthetic latent need",
    entity_population = "Four synthetic sites", time_reference = "Fixture year", units = "standardized units"),
  context = list(cohort_id = "fixture", data_version = "1", data_conditioning = "Deterministic synthetic values",
    model_summary = "Deterministic test pattern, not a fitted posterior"),
  provenance = list(producer = "postrank tests", artifact_id = "friendly-fixture",
    construction_note = "Deterministic fixture", created_at = "2026-10-25T00:00:00Z"),
  origin = list(source_id = "fixture", fit_id = "none", model_id = "deterministic",
    source_format = "R array", source_artifact = "tests/testthat/test-draws-friendly.R"),
  identification_note = "Targets are the fixture coordinates themselves.",
  tie_justification = "The deterministic pattern has distinct site values within each draw.",
  joint_generation = "Each slice is one synthetic joint state of all sites and criteria.",
  sampling_provenance = "Deterministic synthetic values; not posterior sampling.")
df_decl <- function() do.call(postrank_declarations, df_decl_args())

test_that("postrank_declarations keeps the eight fields in order and rejects gaps", {
  d <- df_decl()
  expect_s3_class(d, "postrank_declarations")
  expect_identical(names(d), c("targets", "context", "provenance", "origin", "identification_note",
    "tie_justification", "joint_generation", "sampling_provenance"))
  a <- df_decl_args(); a$tie_justification <- NULL
  e <- tryCatch(do.call(postrank_declarations, a), error = identity)
  expect_identical(e$code, "missing_declarations"); expect_match(conditionMessage(e), "tie_justification")
  a <- df_decl_args(); a$sampling_provenance <- "unknown"
  e <- tryCatch(do.call(postrank_declarations, a), error = identity)
  expect_identical(e$code, "placeholder_declaration")
  a <- df_decl_args(); a$targets$estimand <- "TBD"
  expect_error(do.call(postrank_declarations, a), "placeholder")
  a <- df_decl_args(); a$context$model_summary <- NULL
  expect_error(do.call(postrank_declarations, a), "context")
  a <- df_decl_args(); a$joint_generation <- NULL
  expect_error(do.call(postrank_declarations, c(a, list(joint_generation = NULL))), "NULL scientific declarations")
})

test_that("friendly and strict array constructors give identical objects (fixed created_at)", {
  v <- df_values(); a <- df_decl_args()
  strict <- do.call(postrank_draws_from_array, c(list(values = v, regime = "iid"), a))
  friendly <- postrank_draws(v, regime = "iid", declarations = df_decl())
  expect_identical(friendly, strict)
  expect_identical(friendly$validation$input_identity, strict$validation$input_identity)
  # A plain list with exactly the eight fields is accepted and normalized.
  expect_identical(postrank_draws(v, regime = "iid", declarations = a), strict)
  # No receipt or cache fields are added.
  expect_identical(names(friendly), names(strict))
  expect_identical(names(friendly$validation), names(strict$validation))
})

test_that("MCMC layout is declared, never assumed", {
  v <- df_values(); a <- df_decl_args()
  strict <- do.call(postrank_draws_from_array, c(list(values = v, regime = "mcmc", chains = 2L,
    warmup_per_chain = 100L, thin = 1L), a))
  friendly <- postrank_draws(v, regime = "mcmc", chains = 2L, warmup_per_chain = 100L, thin = 1L, declarations = df_decl())
  expect_identical(friendly, strict)
  expect_error(postrank_draws(v, regime = "mcmc", chains = 2L, warmup_per_chain = 100L, declarations = df_decl()), "thin")
  expect_error(postrank_draws(v, regime = "iid", chains = 2L, declarations = df_decl()), "IID")
  e <- tryCatch(postrank_draws(v, declarations = df_decl()), error = identity)
  expect_identical(e$code, "missing_regime")
  e <- tryCatch(postrank_draws(v, regime = "iid"), error = identity)
  expect_identical(e$code, "missing_declarations")
})

test_that("IDs come from dimnames or explicit overrides that do not contradict them", {
  v <- df_values(); dn <- dimnames(v); dimnames(v) <- NULL
  x <- postrank_draws(v, regime = "iid", entity_ids = dn[[2]], criterion_ids = dn[[3]], declarations = df_decl())
  expect_identical(x$entity_ids, dn[[2]]); expect_identical(x$criterion_ids, dn[[3]])
  e <- tryCatch(postrank_draws(df_values(), regime = "iid", entity_ids = c("W", "X", "Y", "Z"), declarations = df_decl()),
    error = identity)
  expect_identical(e$code, "input_metadata_conflict")
})

test_that("orientation = lower negates once and records the transform (T-api-04)", {
  v <- df_values(); a <- df_decl_args()
  oriented <- postrank_draws(v, regime = "iid", orientation = c(need2 = "lower"), declarations = df_decl())
  manual <- v; manual[, , "need2"] <- -manual[, , "need2"]
  strict <- do.call(postrank_draws_from_array, c(list(values = manual, regime = "iid"), a))
  expect_identical(oriented$joint_draws$tensor$values, strict$joint_draws$tensor$values)
  expect_identical(postrank_pairwise(oriented)$e, postrank_pairwise(strict)$e)
  tr <- vapply(oriented$targets, function(t) t$source_transform, "")
  expect_identical(tr[[1]], "identity")
  expect_match(tr[[2]], "^identity; then negated once")
  expect_false(identical(oriented$validation$input_identity, strict$validation$input_identity))
  expect_false("orientation_transform" %in% names(oriented$provenance))
  expect_error(postrank_draws(v, regime = "iid", orientation = c(need3 = "lower"), declarations = df_decl()), "orientation")
  expect_error(postrank_draws(v, regime = "iid", orientation = c(need2 = "down"), declarations = df_decl()), "orientation")
})

test_that("route conflicts raise input_metadata_conflict", {
  v <- df_values(); x <- postrank_draws(v, regime = "iid", declarations = df_decl())
  expect_identical(postrank_draws(x), x)
  for (call in list(quote(postrank_draws(x, regime = "iid")), quote(postrank_draws(x, declarations = df_decl())),
                    quote(postrank_draws(v, regime = "iid", declarations = df_decl(), metadata = list())),
                    quote(postrank_draws(x, orientation = c(need1 = "lower"))))) {
    e <- tryCatch(eval(call), error = identity)
    expect_identical(e$code, "input_metadata_conflict")
  }
  expect_error(postrank_draws("not draws"), "array")
})

test_that("a named matrix list with complete criterionwise metadata matches the strict path", {
  full <- pr_test_criterionwise()
  strict <- as_postrank_draws(full)
  mats <- lapply(full$criterion_blocks, function(b) b$matrix$values)
  names(mats) <- vapply(full$criterion_blocks, function(b) b$criterion_id, "")
  meta <- full; for (b in seq_along(meta$criterion_blocks)) meta$criterion_blocks[[b]]$matrix <- NULL
  friendly <- postrank_draws(mats, metadata = meta)
  expect_identical(friendly, strict)
  expect_identical(vapply(friendly$criterion_blocks, function(b) b$matrix$shape$S, 1), c(4, 5))
  e <- tryCatch(postrank_draws(mats, metadata = meta, regime = "iid"), error = identity)
  expect_identical(e$code, "input_metadata_conflict")
  expect_error(postrank_draws(mats), "criterionwise metadata")
  bad <- mats; names(bad)[1] <- "other"
  expect_error(postrank_draws(bad, metadata = meta), "criterion_ids")
})

test_that("posterior draws route maps through as_postrank_posterior", {
  skip_if_not_installed("posterior")
  metadata <- pr_test_payload(S = 4L, n = 3L, K = 2L, regime = "iid")
  expected <- metadata$joint_draws$tensor$values; map <- metadata$joint_draws$variable_map
  vars <- vapply(map, `[[`, "", "source_target_variable_id")
  src <- array(NA_real_, c(4L, 1L, length(vars)), dimnames = list(iteration = as.character(1:4), chain = "1", variable = vars))
  coords <- lapply(1:4, function(s) list(slot_id = dimnames(expected)$draw[[s]], iteration_index = s, chain_index = 1L))
  for (s in 1:4) for (m in seq_along(map)) src[s, 1, vars[m]] <- expected[s, match(map[[m]]$entity_id, metadata$entity_ids),
    match(map[[m]]$criterion_id, metadata$criterion_ids)]
  metadata$joint_draws$origin$source_hash <- strrep("a", 64L); metadata$joint_draws$tensor$values <- NULL
  da <- posterior::as_draws_array(src)
  direct <- as_postrank_posterior(da, map, metadata, coords)
  friendly <- postrank_draws(da, variables = map, metadata = metadata, source_coordinates = coords)
  expect_identical(friendly, direct)
  expect_identical(postrank_draws(posterior::as_draws_df(da), variables = map, metadata = metadata,
    source_coordinates = coords)$joint_draws$tensor$values, direct$joint_draws$tensor$values)
  e <- tryCatch(postrank_draws(da, regime = "iid", variables = map, metadata = metadata, source_coordinates = coords),
    error = identity)
  expect_identical(e$code, "input_metadata_conflict")
  e <- tryCatch(postrank_draws(da, metadata = metadata), error = identity)
  expect_identical(e$code, "missing_metadata")
})
