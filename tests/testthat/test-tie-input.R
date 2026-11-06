# New-domain input/aggregation tests. Existing 0.9 fixtures are never rewritten.
pr_tie_input_payload <- function(exact = FALSE, regime = "iid") {
  x <- if (exact) pr_test_exact() else pr_test_payload(regime = regime)
  x$schema_version <- "tie-aware-input-0.1"
  x$tie_policy <- list(rule = "equality_neutral", declared = TRUE,
    justification = "Exact equality in this explicit synthetic fixture is genuine.",
    observed_tie_action = "accept_declared_exact_equality")
  x$equality <- list(basis = if (exact) "exact_finite_law" else "structural_declared",
    justification = "Explicit synthetic equality structure, not empirical inference.",
    criterion_classes = if (exact) NULL else stats::setNames(lapply(x$criterion_ids,
      function(k) stats::setNames(x$entity_ids, x$entity_ids)), x$criterion_ids))
  x
}

testthat::test_that("new input domains preserve declarations and reject stale source values", {
  x <- pr_tie_input_payload(regime = "mcmc")
  x$joint_draws$tensor$values[, 2, 1] <- x$joint_draws$tensor$values[, 1, 1]
  x$equality$criterion_classes$need1[2] <- x$equality$criterion_classes$need1[1]
  source <- as_postrank_tie_draws(x)
  testthat::expect_identical(class(source), c("postrank_tie_draws", "list"))
  testthat::expect_false(inherits(source, "postrank_draws"))
  testthat::expect_true(validate_postrank_tie_draws(source))
  testthat::expect_equal(source$joint_draws$draw_index, x$joint_draws$draw_index)
  testthat::expect_equal(source$joint_draws$sampling$chain_history, x$joint_draws$sampling$chain_history)
  testthat::expect_false(source$validation$scientific_equality_verified)
  bad <- source; bad$provenance$construction_note <- "Changed source declaration"
  testthat::expect_error(validate_postrank_tie_draws(bad), "changed after construction")
  testthat::expect_error(as_postrank_tie_draws(bad), "changed after construction")
  bad <- x; bad$joint_draws$tensor$values[1, 2, 1] <- bad$joint_draws$tensor$values[1, 2, 1] + 1e-15
  testthat::expect_error(as_postrank_tie_draws(bad), "declared equal-class")
})

testthat::test_that("Monte Carlo coincidences never create structural equality classes", {
  x <- pr_tie_input_payload()
  x$joint_draws$tensor$values[, 2, ] <- x$joint_draws$tensor$values[, 1, ]
  pw <- postrank_tie_pairwise(x)
  testthat::expect_true(all(pw$t[1, 2, ] == 1))
  testthat::expect_identical(pw$equality$criterion_classes, x$equality$criterion_classes)
  testthat::expect_false(pw$equality$evidence$monte_carlo_coincidences_used_to_merge_classes)
  testthat::expect_false(inherits(pw, "postrank_pairwise"))
  testthat::expect_false("e" %in% names(pw))
  for (invalid in c("schema", "policy", "partition", "criterionwise")) {
    bad <- x
    if (invalid == "schema") bad$schema_version <- "applied-0.1"
    if (invalid == "policy") bad$tie_policy$observed_tie_action <- "reject_and_review"
    if (invalid == "partition") bad$equality$criterion_classes <- NULL
    if (invalid == "criterionwise") bad$dependence_mode <- "criterionwise_expected_only"
    testthat::expect_error(as_postrank_tie_draws(bad))
  }
})

testthat::test_that("blocked strict/tie/discordance probabilities match direct states", {
  x <- pr_tie_input_payload()
  v <- x$joint_draws$tensor$values
  v[1, 2, 1] <- v[1, 1, 1]; v[2, 3, 2] <- v[2, 1, 2]
  x$joint_draws$tensor$values <- v
  reference <- postrank_tie_pairwise(x, "reference")
  for (block in c(1L, 2L, 128L)) {
    pw <- postrank_tie_pairwise(x, "blocks", block)
    for (field in c("b", "t", "d")) testthat::expect_identical(pw[[field]], reference[[field]])
    testthat::expect_true(validate_postrank_tie_pairwise(pw))
  }
  for (k in seq_len(dim(v)[3])) for (i in seq_len(dim(v)[2])) for (j in seq_len(dim(v)[2])) if (i != j) {
    testthat::expect_equal(reference$b[i, j, k], mean(v[, i, k] < v[, j, k]))
    testthat::expect_equal(reference$t[i, j, k], mean(v[, i, k] == v[, j, k]))
    testthat::expect_equal(reference$d[i, j, k], mean(v[, i, k] != v[, j, k]))
    testthat::expect_equal(reference$b[i, j, k] + reference$b[j, i, k], reference$d[i, j, k])
  }
  bad <- reference; bad$b[1, 2, 1] <- bad$b[1, 2, 1] + .01
  testthat::expect_error(validate_postrank_tie_pairwise(bad))
  bad <- reference; bad$equality$evidence$scientific_equality_verified <- TRUE
  testthat::expect_error(validate_postrank_tie_pairwise(bad), "equality evidence")
  testthat::expect_error(postrank_tie_pairwise(x, block_size = 0))
})

testthat::test_that("exact equality uses every positive-mass state and preserves rational counts", {
  testthat::skip_if_not_installed("gmp")
  x <- pr_tie_input_payload(exact = TRUE)
  for (s in seq_along(x$finite_law$states)) x$finite_law$states[[s]]$theta[2, 1] <- x$finite_law$states[[s]]$theta[1, 1]
  source <- as_postrank_tie_draws(x)
  testthat::expect_identical(unname(source$equality$criterion_classes$need1), c("001", "001", "003"))
  pw <- postrank_tie_pairwise(source)
  testthat::expect_equal(pw$t[1, 2, 1], 1)
  testthat::expect_equal(pw$b[1, 2, 1], 0)
  testthat::expect_equal(pw$d[1, 2, 1], 0)
  testthat::expect_identical(pw$exact$numerators$t[1, 2, 1], "3")
  testthat::expect_identical(pw$exact$rationals$t[1, 2, 1], "1")
  testthat::expect_true(all(is.na(pw$sample_sizes)))
  testthat::expect_true(all(pw$sampling_regimes == "exact_law"))
  wrong <- x; wrong$equality$criterion_classes <- stats::setNames(lapply(x$criterion_ids,
    function(k) stats::setNames(rep("one", 3), x$entity_ids)), x$criterion_ids)
  testthat::expect_error(as_postrank_tie_draws(wrong), "differs from equality")
  partial <- x; partial$finite_law$states[[2]]$theta[2, 1] <- partial$finite_law$states[[2]]$theta[2, 1] + 1
  testthat::expect_false(as_postrank_tie_draws(partial)$equality$criterion_classes$need1[1] ==
    as_postrank_tie_draws(partial)$equality$criterion_classes$need1[2])
  unsafe <- x; unsafe$finite_law$states[[1]]$mass_numerator <- 0
  testthat::expect_error(as_postrank_tie_draws(unsafe), "safe integers")
})

testthat::test_that("separate JSON round trips retain source identities and opaque class names", {
  inputs <- list(pr_tie_input_payload())
  if (requireNamespace("gmp", quietly = TRUE)) inputs[[2]] <- pr_tie_input_payload(exact = TRUE)
  for (input in inputs) {
    source <- as_postrank_tie_draws(input)
    path <- tempfile(fileext = ".json")
    on.exit(unlink(path), add = TRUE)
    write_postrank_tie_draws(source, path)
    back <- read_postrank_tie_draws(path)
    testthat::expect_identical(back$input_identity, source$input_identity)
    testthat::expect_identical(postrank_tie_pairwise(back)$b, postrank_tie_pairwise(source)$b)
    testthat::expect_error(write_postrank_tie_draws(source, path), "already exists")
    text <- readLines(path, warn = FALSE)
    text[1] <- '{"schema_version":"tie-aware-input-0.1",'
    writeLines(text, path)
    testthat::expect_error(read_postrank_tie_draws(path), "duplicate")
  }
})

testthat::test_that("new JSON numeric decoding preserves the complete finite-double boundary", {
  x <- pr_tie_input_payload()
  smallest <- .Machine$double.xmin * .Machine$double.eps
  boundary <- c(.Machine$double.xmax, -.Machine$double.xmax,
    .Machine$double.xmax - 2^971, .Machine$double.xmin, -.Machine$double.xmin,
    smallest, -smallest, .Machine$double.xmin - smallest,
    1, 1 + .Machine$double.eps, 1 - .Machine$double.eps / 2, 0, -0.0)
  testthat::expect_true(all(is.finite(boundary)))
  testthat::expect_gt(smallest, 0)
  x$joint_draws$tensor$values[] <- rep(boundary, length.out = length(x$joint_draws$tensor$values))
  source <- as_postrank_tie_draws(x)
  path <- tempfile(fileext = ".json"); on.exit(unlink(path), add = TRUE)
  testthat::expect_silent(write_postrank_tie_draws(source, path))
  back <- read_postrank_tie_draws(path)
  before <- source$joint_draws$tensor$values; after <- back$joint_draws$tensor$values
  testthat::expect_identical(after, before)
  testthat::expect_identical(writeBin(as.vector(after), raw(), size = 8L, endian = "little"),
    writeBin(as.vector(before), raw(), size = 8L, endian = "little"))
  testthat::expect_identical(back$input_identity, source$input_identity)
  testthat::expect_identical(postrank_tie_pairwise(back)$pairwise_identity,
    postrank_tie_pairwise(source)$pairwise_identity)
  testthat::expect_silent(.pr_tie_json_scan("1.7976931348623157e+308"))
  testthat::expect_silent(.pr_tie_json_scan("4.9406564584124654e-324"))
})

testthat::test_that("new boundary decoder retains strict lexical safeguards", {
  for (token in c("1e309", "-1e309", "1e-9999", "-1e-9999", "01", "+1", "NaN", "Infinity"))
    testthat::expect_error(.pr_tie_json_scan(token), class = "postrank_input_error")
  testthat::expect_error(.pr_tie_json_scan('{"a":1,"\\u0061":2}'), "duplicate object key")
  for (token in c("9007199254740992", "9007199254740991.1", "1e9999", "1e-9999")) {
    text <- paste0('{"finite_law":{"denominator":', token, '}}')
    error <- tryCatch(.pr_tie_json_scan(text), error = identity)
    testthat::expect_s3_class(error, "postrank_input_error")
    testthat::expect_identical(error$code, "unsafe_integer")
  }
})

testthat::test_that("new-domain text encodings normalize values and named axes without changing code points", {
  x <- pr_tie_input_payload()
  x$context$model_summary <- "caf\u00e9"
  x$context$data_conditioning <- "e\u0301"
  latin <- function(z) {
    attrs <- attributes(z)
    if (is.character(z)) {
      z[z == "001"] <- "caf\u00e9"
      z[z == "need1"] <- "crit\u00e8re"
      z[z == "slot1"] <- "tir\u00e9"
      # The decomposed text is deliberately left UTF-8: there is no Latin-1
      # representation, and new-domain normalization must never compose it.
      keep <- z == "e\u0301"
      z[!keep] <- iconv(z[!keep], from = "UTF-8", to = "latin1", sub = NA)
      Encoding(z[!keep]) <- "latin1"
    } else if (is.list(z)) z <- lapply(z, latin)
    if (!is.null(attrs)) {
      attrs <- lapply(attrs, latin)
      names(attrs) <- enc2utf8(names(attrs))
      attributes(z) <- attrs
    }
    z
  }
  x <- latin(x)
  source <- as_postrank_tie_draws(x)
  testthat::expect_identical(Encoding(source$context$model_summary), "UTF-8")
  testthat::expect_identical(source$context$data_conditioning, "e\u0301")
  testthat::expect_identical(Encoding(source$entity_ids[1]), "UTF-8")
  testthat::expect_identical(Encoding(names(source$equality$criterion_classes)[1]), "UTF-8")
  testthat::expect_identical(Encoding(dimnames(source$joint_draws$tensor$values)$entity[1]), "UTF-8")
  path <- tempfile(fileext = ".json"); on.exit(unlink(path), add = TRUE)
  write_postrank_tie_draws(source, path)
  back <- read_postrank_tie_draws(path)
  testthat::expect_identical(back$input_identity, source$input_identity)
  testthat::expect_identical(back$joint_draws$tensor$values, source$joint_draws$tensor$values)
  testthat::expect_identical(back$equality$criterion_classes, source$equality$criterion_classes)
  testthat::expect_identical(postrank_tie_pairwise(back)$pairwise_identity,
    postrank_tie_pairwise(source)$pairwise_identity)
  bad <- pr_tie_input_payload()
  bytes <- rawToChar(as.raw(255)); Encoding(bytes) <- "bytes"
  bad$context$model_summary <- bytes
  testthat::expect_error(as_postrank_tie_draws(bad), "byte-encoded|UTF-8")
})
