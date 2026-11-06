krw_direct_risk <- function(grade, e, weights, tau) {
  loss <- errors <- setNames(numeric(length(weights)), names(weights)); N <- 0L
  for (i in seq_len(length(grade) - 1L)) for (j in seq.int(i + 1L, length(grade))) {
    if (grade[i] == grade[j]) loss <- loss + tau else {
      wrong <- if (grade[i] < grade[j]) e[i, j, ] else e[j, i, ]
      loss <- loss + wrong; errors <- errors + wrong; N <- N + 1L
    }
  }
  list(risk = sum(weights * loss) / choose(length(grade), 2L), E = errors, N = N)
}

test_that("KRW keeps all 97 firms, signed cell targets and matching 90% summaries", {
  z <- pr_case_krw
  expect_identical(names(z), c("input", "units", "alternatives", "reference", "provenance"))
  expect_identical(names(z$alternatives), c("race", "gender", "absolute_gender"))
  expect_identical(dim(z$input$e), c(97L, 97L, 2L))
  expect_identical(z$input$criterion_ids, c("race_signed", "gender_signed"))
  expect_identical(z$units$entity_id, z$input$entity_ids)
  expect_identical(nrow(z$units), 97L)
  expect_identical(anyDuplicated(z$units$entity_id), 0L)
  for (x in c(list(z$input), z$alternatives)) {
    expect_true(validate_postrank_probabilities(x))
    expect_identical(x$entity_ids, z$input$entity_ids)
    expect_true(x$zero_ties)
    expect_identical(x$margin, 0)
    expect_identical(x$event, "directional_error")
    expect_identical(x$source$kind, "numerical_integration")
    expect_identical(x$correction$method, "none")
    expect_identical(x$summaries$level, .9)
    expect_true(x$summaries$same_targets)
    expect_true(all(x$summaries$lower <= x$summaries$upper))
    expect_true(all(is.na(x$sample_sizes)))
    expect_null(x$joint_draws)
  }
  expect_equal(z$alternatives$race$e, z$input$e[, , "race_signed", drop = FALSE])
  expect_equal(z$alternatives$gender$e, z$input$e[, , "gender_signed", drop = FALSE])
  expect_identical(z$alternatives$absolute_gender$criterion_ids, c("race_signed", "gender_absolute"))
  expect_equal(z$alternatives$absolute_gender$e[, , 1L], z$input$e[, , 1L])
  expect_true(all(z$alternatives$absolute_gender$summaries$lower[, 2L] >= 0))
  expect_false(identical(z$alternatives$absolute_gender$e[, , 2L], z$input$e[, , 2L]))
  expect_match(z$provenance$posterior_law, "midpoints", fixed = TRUE)
  expect_match(z$provenance$selection_rule, "no subsetting or hyperparameter refit", fixed = TRUE)
})

test_that("KRW archive Pi, atom ties and lambda cards remain separate references", {
  z <- pr_case_krw; a <- z$reference$archive_pi
  for (k in 1:2) {
    raw <- a$raw[, , k]; plotting <- a$plotting[, , k]
    expect_equal(plotting[upper.tri(plotting)], raw[upper.tri(raw)])
    expect_equal(plotting[lower.tri(plotting)], (1 - t(raw))[lower.tri(raw)])
    expect_equal(unname(diag(plotting)), rep(.5, 97L))
    expect_gt(max(abs((1 - plotting) - z$input$e[, , k]), na.rm = TRUE), 1e-4)
  }
  expect_gt(a$literal_race_max_equality_mass, 1e-4)
  expect_match(a$grade_generator_convention, "1e-7", fixed = TRUE)
  k <- z$reference$single_criterion
  expect_equal(k$lambda, .25); expect_equal(k$tau, .25 / 1.25)
  expect_equal(k$archive_metrics$policy_tau, c(.2, .2))
  expect_identical(k$archive_metrics$grade_sizes, c("2/81/14", "1/3/89/4"))
  expect_equal(k$archive_metrics$N, c(1324, 731))
  expect_equal(k$archive_metrics$M, c(4656, 4656))
  expect_equal(z$reference$signed_core$settings$tau, .25)
  expect_identical(z$reference$certification_scope$total_unique_problems, 236L)
  expect_identical(z$reference$certification_scope$solver_and_coefficient_gate_passed, 8L)
  expect_identical(z$reference$certification_scope$validated_independent_reference, 1L)
  expect_identical(z$reference$certification_scope$not_run, 227L)
})

test_that("all-pair archived KRW actions match independent cell-law risk sums", {
  z <- pr_case_krw
  for (name in c("race", "gender")) {
    x <- z$alternatives[[name]]; g <- z$reference$single_criterion$grade[[name]]
    w <- setNames(1, x$criterion_ids)
    expected <- krw_direct_risk(g, x$e, w, .2)
    ev <- postrank_evaluate(g, x, w, .2)
    expect_equal(ev$weighted_risk, expected$risk, tolerance = 1e-12)
    expect_equal(ev$E, expected$E, tolerance = 1e-10)
    expect_equal(ev$N, expected$N)
    expect_equal(z$reference$single_criterion$cell_metrics[[name]]$risk, expected$risk, tolerance = 1e-12)
  }
  for (name in c("signed_core", "absolute_sensitivity")) {
    ref <- z$reference[[name]]
    x <- if (name == "signed_core") z$input else z$alternatives$absolute_gender
    s <- ref$settings
    expect_identical(names(ref$grade), x$entity_ids)
    expected <- krw_direct_risk(ref$grade, x$e, s$weights, s$tau)
    old <- krw_direct_risk(ref$grade, ref$archive_reference_e, s$weights, s$tau)
    ev <- postrank_evaluate(ref$grade, x, s$weights, s$tau)
    expect_equal(ev$weighted_risk, expected$risk, tolerance = 1e-12)
    expect_equal(ev$E, expected$E, tolerance = 1e-10)
    expect_equal(ev$N, expected$N)
    expect_equal(ref$cell_metrics$risk, expected$risk, tolerance = 1e-12)
    expect_equal(ref$archive_metrics$risk, old$risk, tolerance = 1e-12)
    row <- if (name == "signed_core") 1L else 2L
    expect_lte(abs(expected$risk - old$risk),
      z$reference$law_differences$equal_weight_uniform_risk_difference_bound[row] + 1e-12)
    expect_identical(ref$archive_status, "solver_and_coefficient_gate_passed")
    expect_match(ref$interpretation, "not a new solve or exact optimality", fixed = TRUE)
    expect_false(inherits(ref, "postrank_fit"))
  }
})

krw_small_inputs <- function() {
  lapply(c(list(signed = pr_case_krw$input), pr_case_krw$alternatives[c("race", "gender")]), function(x) {
    postrank_probabilities(x$e[1:3, 1:3, , drop = FALSE], event = "directional_error",
      zero_ties = TRUE, margin = 0, source = x$source, targets = x$targets)
  })
}
krw_three_actions <- function(ids) {
  grid <- as.matrix(expand.grid(rep(list(1:3), 3L)))
  keep <- apply(grid, 1L, function(g) identical(sort(unique(g)), seq_len(max(g))))
  lapply(which(keep), function(i) setNames(as.integer(grid[i, ]), ids))
}

test_that("KRW first-three K1 and K2 fixed-action losses agree over all 13 ordered partitions", {
  for (x in krw_small_inputs()) {
    actions <- krw_three_actions(x$entity_ids)
    expect_length(actions, 13L)
    w <- setNames(rep(1 / length(x$criterion_ids), length(x$criterion_ids)), x$criterion_ids)
    for (g in actions) {
      expected <- krw_direct_risk(g, x$e, w, .25)
      ev <- postrank_evaluate(g, x, w, .25)
      expect_equal(ev$weighted_risk, expected$risk, tolerance = 1e-13)
      expect_equal(ev$N, expected$N)
    }
  }
})

test_that("tiny native KRW solves attain the independent ordered-partition oracle", {
  skip_if_not_installed("highs")
  for (x in krw_small_inputs()) {
    w <- setNames(rep(1 / length(x$criterion_ids), length(x$criterion_ids)), x$criterion_ids)
    actions <- krw_three_actions(x$entity_ids)
    expected <- vapply(actions, function(g) krw_direct_risk(g, x$e, w, .25)$risk, 0)
    p <- postrank_problem(x, weights = w, tau = .25, G_max = 3L)
    fit <- postrank_solve(p, backend = "highs", control = postrank_control(
      time_limit = 5, threads = 1L, strategy = "label_mip", verbose = FALSE))
    expect_true(fit$incumbent_validated)
    expect_equal(krw_direct_risk(fit$grade, x$e, w, .25)$risk, min(expected), tolerance = 1e-10)
    expect_equal(fit$objective$risk_upper_bound, min(expected), tolerance = 1e-10)
  }
})

test_that("KRW source conditions and compact provenance do not become unrestricted data", {
  z <- pr_case_krw; p <- z$provenance
  expect_identical(p$rights$license, "CC-BY-NC")
  expect_identical(p$rights$license_version, "unspecified in source README")
  expect_identical(p$rights$preserved_notice, "The data are licensed under a Creative Commons/CC-BY-NC license.")
  expect_false(p$rights$external_release_cleared)
  expect_match(p$rights$inclusion_decision, "Local noncommercial teaching candidate", fixed = TRUE)
  expect_match(p$attribution, "No endorsement is implied", fixed = TRUE)
  expect_identical(p$source_urls[["dataset"]], "https://doi.org/10.3886/E198284V1")
  expect_true(all(grepl("^[0-9a-f]{64}$", p$source_files$sha256)))
  expect_true(all(grepl("^[0-9a-f]{64}$", p$archive_files$sha256)))
  expect_equal(p$grid_hashes$nodes, c(1000, 1000))
  expect_equal(p$grid_hashes$entities, c(97, 97))
  expect_null(z$input$grids)
  expect_null(z$input$cell_laws)
  unsafe <- function(x) {
    if (is.environment(x) || is.function(x) || is.call(x)) return(TRUE)
    if (is.character(x)) return(any(grepl("/Users/|/home/", x, fixed = FALSE)))
    if (is.list(x)) return(any(vapply(x, unsafe, TRUE)))
    FALSE
  }
  expect_false(unsafe(z))
  path <- pr_source_path("data", "pr_case_krw.rda")
  if (file.exists(path)) expect_lte(file.size(path), 500000)
})
