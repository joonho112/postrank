# T-obj-03 (sensitivity part) and T-api-08: settings grids, typed row policies, retention of
# no-incumbent rows, and the gap-qualified F1 monotonicity of disclosure in tau.
sv_mock <- function(fail_tau = NULL) function(problem, backend, control, strategy) {
  ids <- problem$pairwise$entity_ids
  bad <- !is.null(fail_tau) && isTRUE(all.equal(problem$settings$tau, fail_tau))
  g <- if (bad) NULL else stats::setNames(c(1L, rep(2L, length(ids) - 1L)), ids)
  primal <- if (is.null(g)) NULL else .pr_engine_primal(problem, g)
  obj <- if (is.null(primal)) NA_real_ else sum(problem$model$objective * primal)
  .pr_normalize_solver_result(problem, list(primal = primal, raw_status = "MOCK", raw_message = "mock",
    status_normalized = if (bad) "time_limit" else "optimal", termination_reason = "mock", has_incumbent = !is.null(primal),
    raw_objective = obj, raw_lower_bound = if (bad) -1 else obj, relative_gap = NA_real_, runtime = 0,
    backend = list(name = backend, wrapper_version = "mock", solver_version = NA_character_, options = list()),
    raw = list(execution_scope = "mock", native_solver_called = FALSE), warnings = character(),
    bound_source = "backend_reported_dual_bound"), .pr_control(control))
}
sw <- c(need_A = .6, need_B = .4)

test_that("one-at-a-time grids keep typed row policies and a flagged reference", {
  base <- postrank_settings(sw, .25, 3L, objective = "minimax", minimax_criteria = "need_A", minimax_refine = "none")
  g <- postrank_settings_grid(base, tau = c(.1, .25, .4), G_max = 2L)
  expect_identical(g$label, c("reference", "tau=0.10", "tau=0.40", "G_max=2"))
  expect_identical(g$is_reference, c(TRUE, FALSE, FALSE, FALSE))
  for (s in g$settings) { expect_identical(s$minimax_criteria, "need_A"); expect_identical(s$minimax_refine, "none") }
  bad <- g; bad$tau[2] <- .2
  local_mocked_bindings(.pr_solve_core = sv_mock())
  e <- tryCatch(postrank_sensitivity(postrank_pairwise(postrank_toy), bad, backend = "highs"), error = identity)
  expect_identical(e$code, "grid_settings_conflict")
  full <- postrank_settings_grid(postrank_settings(sw, .25, 3L), tau = c(.1, .4), G_max = 2L, design = "full")
  expect_identical(nrow(full), 6L); expect_identical(full$label[1], "reference")
})

test_that("rows without an incumbent keep status, reason and bounds, also with keep_fits = FALSE (> 25 rows)", {
  local_mocked_bindings(.pr_solve_core = sv_mock(fail_tau = .3))
  base <- postrank_settings(sw, .25, 3L)
  taus <- seq(.02, .5, length.out = 27)
  taus[13] <- .3
  grid <- postrank_settings_grid(base, tau = taus)
  expect_gt(nrow(grid), 25L)
  s <- postrank_sensitivity(postrank_pairwise(postrank_toy), grid, backend = "highs")
  expect_null(s$fits)
  row <- s$table[abs(s$grid$tau - .3) < 1e-12, ]
  expect_identical(row$status, "time_limit"); expect_identical(row$reason, "no_validated_incumbent")
  expect_true(is.na(row$risk)); expect_false(is.na(row$risk_lower_bound) && is.na(row$bound_source))
  expect_true(is.na(s$changes$n_same[abs(s$grid$tau - .3) < 1e-12]))
  expect_identical(s$backend$name, "highs")
  # G_max values above n are capped and duplicates dropped with a warning.
  g2 <- postrank_settings_grid(base, G_max = c(5L, 9L))
  s2 <- postrank_sensitivity(postrank_pairwise(postrank_toy), g2, backend = "highs")
  expect_lt(nrow(s2$table), nrow(g2)); expect_true(any(grepl("coincide after binding", s2$warnings)))
})

test_that("exact oracle rows obey F1: disclosure is nondecreasing in tau (T-api-08)", {
  for (seed in 1:5) {
    pay <- pr_random_payload(seed, S = 40L, n = 4L, K = 2L)
    pw <- postrank_pairwise(as_postrank_draws(pay)); e <- pw$e; w <- c(.5, .5); names(w) <- pw$criterion_ids
    taus <- c(.1, .2, .3, .4, .5); lo <- hi <- numeric()
    for (t in taus) {
      o <- pr_oracle_solve(e, w, t, 4L)
      best <- o$actions[which(abs(o$values - o$optimum) <= 1e-12)]
      n_best <- vapply(best, function(g) sum(outer(g, g, `<`)), 1)
      lo <- c(lo, min(n_best)); hi <- c(hi, max(n_best))
    }
    # (tau' - tau)(N - N') <= 0 for any optimum N at tau and N' at tau' > tau: every optimum discloses at least as much.
    for (i in seq_along(taus)[-1L]) expect_lte(hi[i - 1L], lo[i])
  }
})

test_that("tier 2: numerical rows satisfy the gap-aware F1 inequality", {
  skip_if_not_installed("highs")
  pw <- postrank_pairwise(pr_example_draws)
  base <- postrank_settings(c(poverty = .5, frl = .25, snap = .25), .35, 4L)
  s <- postrank_sensitivity(pw, postrank_settings_grid(base, tau = c(.25, .45)), backend = "highs",
    control = postrank_control(time_limit = 30))
  t <- s$table; tau <- s$grid$tau; o <- order(tau); t <- t[o, ]; tau <- tau[o]
  # Gap-aware F1: for eps-optimal actions, (tau' - tau)(N - N') <= M (gap + gap'), so disclosure can fall
  # only by the amount the reported gaps allow. Risk is also nondecreasing in tau up to the gaps.
  M <- choose(length(pw$entity_ids), 2)
  # Slacks are justified only by usable bounds: missing, rejected or clamped-only bounds support no claim (T-mode-11).
  usable <- !is.na(t$bound_source) & t$bound_source != "missing" & !grepl("clamped|rejected", t$bound_source)
  for (i in seq_len(nrow(t) - 1L)) if (usable[i] && usable[i + 1L] &&
      all(is.finite(c(t$N[i], t$N[i + 1L], t$risk_absolute_gap[i], t$risk_absolute_gap[i + 1L])))) {
    expect_lte(t$N[i], t$N[i + 1L] + M * (t$risk_absolute_gap[i] + t$risk_absolute_gap[i + 1L]) / (tau[i + 1L] - tau[i]) + 1e-9)
    expect_lte(t$risk[i], t$risk[i + 1L] + t$risk_absolute_gap[i] + 1e-9)
  }
})

test_that("a positive gap alone admits a fall in disclosure: the two-entity counterexample (T-mode-11)", {
  # n = 2, K = 1, e12 = .2500000005: disclosing (1,2) at tau1 = .25 and all-tie at tau2 = .250000001 are each within
  # 5e-10 of their exact minima, below the default 1e-8 gap, yet N falls from 1 to 0.
  e12 <- .2500000005; e21 <- 1 - e12; M <- 1
  risk <- function(N, tau) if (N == 1) min(e12, e21) else tau          # best disclosure versus all-tie
  tau1 <- .25; tau2 <- .250000001
  eps1 <- risk(1, tau1) - min(risk(1, tau1), risk(0, tau1)); eps2 <- risk(0, tau2) - min(risk(1, tau2), risk(0, tau2))
  expect_lt(eps1, 1e-8); expect_lt(eps2, 1e-8); expect_gt(eps1 + eps2, 0)
  # The exact optima obey F1 (all-tie at tau1, disclosure at tau2); the eps-optimal selections reverse it,
  # and only the eps-inequality N2 - N1 >= -(eps1 + eps2) M / (tau2 - tau1) survives.
  exact_N <- function(tau) if (risk(1, tau) < risk(0, tau)) 1 else 0
  expect_lte(exact_N(tau1), exact_N(tau2))
  N1 <- 1; N2 <- 0                                                  # the eps-optimal selections above
  expect_gt(N1, N2)
  expect_gte(N2 - N1, -(eps1 + eps2) * M / (tau2 - tau1) - 1e-12)
  expect_identical(postrank_control()$absolute_risk_gap, 1e-8)
})
