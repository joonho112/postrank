# postrank_settings(): ordered schema, validation and the settings/loose conflict rule.
st_pw <- function() postrank_pairwise(read_postrank_draws(system.file("examples", "synthetic-iid.json",
  package = "postrank", mustWork = TRUE)))

test_that("postrank_settings has the documented ordered fields and defaults", {
  s <- postrank_settings(c(need_A = .6, need_B = .4))
  expect_s3_class(s, "postrank_settings")
  expect_identical(names(s), c("weights", "tau", "G_max", "q", "exact_G", "objective", "minimax_criteria",
    "minimax_refine", "label", "weight_sum_tolerance", "schema_version", "provenance", "warnings"))
  expect_identical(s$tau, .25); expect_identical(s$G_max, 4L); expect_null(s$q); expect_null(s$exact_G)
  expect_identical(s$objective, "weighted"); expect_identical(s$minimax_refine, "weighted")
  expect_identical(s$weight_sum_tolerance, 1e-12)
  expect_true(.pr_validate_settings(s))
})

test_that("settings validation mirrors the legacy policy rules", {
  expect_error(postrank_settings(), "weights")
  expect_error(postrank_settings(c(a = .5, b = .4)), "sum to one")
  expect_error(postrank_settings(c(a = -.5, b = 1.5)), "nonnegative")
  expect_error(postrank_settings(c(a = 1), tau = 0), "tau")
  expect_error(postrank_settings(c(a = 1), tau = .6), "tau")
  expect_error(postrank_settings(c(a = 1), G_max = 0), "safe integers")
  expect_error(postrank_settings(c(a = 1), G_max = 2.5), "safe integers")
  expect_error(postrank_settings(c(a = 1), G_max = 3L, exact_G = 4L), "exact_G")
  expect_error(postrank_settings(c(a = 1), q = c(a = 1.2)), "q must")
  expect_error(postrank_settings(c(a = 1), minimax_criteria = "a"), "minimax")
  expect_error(postrank_settings(c(a = 1), label = ""), "label")
  expect_silent(postrank_settings(c(a = .5, b = .5), objective = "minimax", minimax_criteria = "a"))
  expect_silent(postrank_settings(c(.5, .5)))
})

test_that("typed settings build the same problem identity as the loose call", {
  pw <- st_pw(); w <- c(need_A = .6, need_B = .4)
  loose <- postrank_problem(pw, w, .25, 3L)
  typed <- postrank_problem(pw, settings = postrank_settings(w, .25, 3L, label = "display only"))
  expect_identical(typed$problem_identity, loose$problem_identity)
  expect_identical(typed$settings, loose$settings)
  positional <- postrank_problem(pw, settings = postrank_settings(c(.6, .4), .25, 3L))
  expect_identical(positional$problem_identity, loose$problem_identity)
  mm_loose <- postrank_problem(pw, w, .25, 3L, "minimax", minimax_refine = "none")
  mm_typed <- postrank_problem(pw, settings = postrank_settings(w, .25, 3L, objective = "minimax", minimax_refine = "none"))
  expect_identical(mm_typed$problem_identity, mm_loose$problem_identity)
  # Positional legacy call keeps its meaning (T-api-02).
  expect_identical(postrank_problem(pw, w, .25, 3L, "minimax")$settings$objective, "minimax")
})

test_that("typed settings cap G_max at n; loose calls keep the legacy rejection", {
  pw <- st_pw(); w <- c(need_A = .6, need_B = .4)
  typed <- postrank_problem(pw, settings = postrank_settings(w, .25, 9L))
  expect_identical(typed$settings$G_max, 3L)
  b <- .pr_settings_bind(postrank_settings(w, .25, 9L), pw)
  expect_identical(b$settings$provenance$requested_G_max, 9L)
  expect_identical(b$settings$provenance$resolved_G_max, 3L)
  expect_match(b$settings$warnings, "capped")
  expect_error(postrank_problem(pw, w, .25, 9L), "G_max cannot exceed")
  expect_error(postrank_problem(pw, settings = postrank_settings(w, .25, 9L, exact_G = 5L)), "exact_G")
})

test_that("explicitly supplied loose arguments with settings raise settings_conflict", {
  pw <- st_pw(); w <- c(need_A = .6, need_B = .4); s <- postrank_settings(w, .25, 3L)
  for (call in list(quote(postrank_problem(pw, w, settings = s)),
                    quote(postrank_problem(pw, tau = .25, settings = s)),
                    quote(postrank_problem(pw, objective = "weighted", settings = s)),
                    quote(postrank_problem(pw, q = NULL, settings = s)),
                    quote(postrank_evaluate(c("001" = 1L, "site-B" = 2L, "site C" = 2L), pw, tau = .25, settings = s)),
                    quote(postrank_frontier(pw, weights = w, tau = .3, settings = s)))) {
    e <- tryCatch(eval(call), error = identity)
    expect_s3_class(e, "postrank_input_error"); expect_identical(e$code, "settings_conflict")
  }
  expect_silent(postrank_problem(pw, settings = s))
})

test_that("evaluate with typed settings equals the loose evaluation", {
  pw <- st_pw(); w <- c(need_A = .6, need_B = .4); g <- c("001" = 1L, "site-B" = 2L, "site C" = 2L)
  expect_identical(postrank_evaluate(g, pw, settings = postrank_settings(w, .3, 3L)), postrank_evaluate(g, pw, w, .3))
})

test_that("frontier requires a tau grid or a complete q-grid with a base tau", {
  pw <- st_pw(); w <- c(need_A = .6, need_B = .4)
  e <- tryCatch(postrank_frontier(pw, w, G_max = 3L), error = identity)
  expect_identical(e$code, "invalid_frontier")
  e <- tryCatch(postrank_frontier(pw, settings = postrank_settings(w, .25, 3L)), error = identity)
  expect_identical(e$code, "invalid_frontier")
  local_mocked_bindings(.pr_frontier_core = function(pairwise, weights, tau, ...) list(tau = tau, weights = weights))
  out <- postrank_frontier(pw, settings = postrank_settings(w, .3, 3L), q_criterion = "need_A", q_grid = c(.1, .2))
  expect_identical(out$tau, .3)
  out <- postrank_frontier(pw, tau = c(.1, .2), settings = postrank_settings(w, .3, 3L))
  expect_identical(out$tau, c(.1, .2))
})
