# Independent statewise losses: no production coefficients, evaluator, model
# objective or canonicalizer are used to construct the expected values.
pr_v1_state_losses <- function(values, masses, grade, weights, tau) {
  result <- c(weak = 0, neutral = 0, krw = 0, disclosed_equality = 0,
              withheld_equality = 0)
  n <- dim(values)[2L]
  lambda <- tau / (1 - tau)
  for (s in seq_len(dim(values)[1L])) {
    for (i in seq_len(n - 1L)) for (j in seq.int(i + 1L, n)) {
      held <- grade[i] == grade[j]
      ahead <- if (grade[i] < grade[j]) i else j
      behind <- if (ahead == i) j else i
      for (k in seq_along(weights)) {
        delta <- values[s, ahead, k] - values[s, behind, k]
        weight <- masses[s] * weights[k]
        if (held) {
          result["weak"] <- result["weak"] + weight * tau
          result["neutral"] <- result["neutral"] + weight * tau * (delta != 0)
          result["withheld_equality"] <- result["withheld_equality"] + weight * (delta == 0)
        } else {
          result["weak"] <- result["weak"] + weight * (delta <= 0)
          result["neutral"] <- result["neutral"] + weight * (delta < 0)
          result["krw"] <- result["krw"] + weight * ((delta < 0) - lambda * (delta > 0))
          result["disclosed_equality"] <- result["disclosed_equality"] + weight * (delta == 0)
        }
      }
    }
  }
  result / (sum(masses) * choose(n, 2))
}

pr_v1_finite_input <- function(values, masses) {
  x <- pr_test_payload(S = dim(values)[1L], n = dim(values)[2L], K = dim(values)[3L])
  x$joint_draws <- NULL
  x$input_kind <- "exact_finite_posterior"
  x$provenance$artifact_hash <- digest::digest(list(values, masses), algo = "sha256")
  x$finite_law <- list(denominator = sum(masses), value_representation = "safe_integer",
    states = lapply(seq_along(masses), function(s) list(state_id = paste0("state-", s),
      mass_numerator = masses[s], theta = matrix(values[s, , ], length(x$entity_ids),
        length(x$criterion_ids), dimnames = list(entity = x$entity_ids, criterion = x$criterion_ids)))),
    law_definition = "Explicit finite law over integer target vectors for independent loss checks.",
    not_empirical_posterior_relabeling = TRUE)
  x
}

test_that("K1 finite laws preserve KRW risks and complete minimizer sets on matched domains", {
  skip_if_not_installed("gmp")
  for (n in 2:4) {
    actions <- pr_tie_all_actions(n, n)
    expect_length(actions, c(3L, 13L, 75L)[n - 1L])
    strict <- Filter(function(g) max(g) == n, actions)
    values <- array(unlist(lapply(seq_len(n), function(i)
      vapply(strict, function(g) g[i], integer(1L)))), c(length(strict), n, 1L))
    domains <- list(all = seq_along(actions),
      capped_two = which(vapply(actions, max, integer(1L)) <= 2L),
      exactly_two = which(vapply(actions, max, integer(1L)) == 2L),
      fixed_order = which(vapply(actions, function(g) all(diff(g) >= 0), logical(1L))))
    for (balanced in c(FALSE, TRUE)) {
      masses <- if (balanced) rep(1L, length(strict)) else 1L + seq_along(strict) %% 4L
      pw <- postrank_pairwise(as_postrank_draws(pr_v1_finite_input(values, masses)))
      for (tau in c(.1, .2, .4, .5)) {
        expected <- vapply(actions, function(g)
          pr_v1_state_losses(values, masses, g, 1, tau), numeric(5L))
        risks <- vapply(actions, function(g) postrank_evaluate(setNames(g, pw$entity_ids),
          pw, c(need1 = 1), tau)$weighted_risk, numeric(1L))
        expect_equal(unname(risks), unname(expected["weak", ]), tolerance = 1e-13)
        expect_equal(unname(risks), unname(tau + (1 - tau) * expected["krw", ]), tolerance = 1e-13)
        for (indices in domains) {
          package_minima <- indices[abs(risks[indices] - min(risks[indices])) < 1e-12]
          krw <- expected["krw", indices]
          krw_minima <- indices[abs(krw - min(krw)) < 1e-12]
          expect_identical(package_minima, krw_minima)
        }
        if (balanced && tau == .5) expect_true(all(abs(risks - .5) < 1e-13))
      }
      expect_error(postrank_evaluate(setNames(actions[[1L]], pw$entity_ids), pw,
        c(need1 = 1), 0), "0 < tau")
    }
  }
})

test_that("two-criterion finite risks and zero-tie reductions match independent state losses", {
  skip_if_not_installed("gmp")
  for (n in 2:4) {
    values <- array(0, c(n, n, 2L))
    for (s in seq_len(n)) {
      values[s, , 1L] <- (seq_len(n) + s - 2L) %% n
      values[s, , 2L] <- rev(values[s, , 1L])
    }
    masses <- seq_len(n)
    pw <- postrank_pairwise(as_postrank_draws(pr_v1_finite_input(values, masses)))
    neutral <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(values, masses)))
    weights <- c(need1 = .35, need2 = .65)
    actions <- pr_tie_all_actions(n, n)
    for (tau in c(.2, .5)) {
      expected <- vapply(actions, function(g)
        pr_v1_state_losses(values, masses, g, weights, tau)["weak"], numeric(1L))
      weak_risks <- neutral_risks <- numeric(length(actions))
      for (i in seq_along(actions)) {
        grade <- setNames(actions[[i]], pw$entity_ids)
        weak_risks[i] <- postrank_evaluate(grade, pw, weights, tau)$weighted_risk
        neutral_risks[i] <- postrank_tie_evaluate(grade, neutral, weights, tau)$weighted_risk
      }
      expect_equal(weak_risks, expected, tolerance = 1e-13)
      expect_equal(neutral_risks, expected, tolerance = 1e-13)
    }
  }
})

test_that("positive target ties require the weak KRW correction and change the neutral baseline", {
  skip_if_not_installed("gmp")
  values <- array(c(1L, 2L, 1L, 0L, 0L, 0L), c(2L, 3L, 1L))
  masses <- c(2L, 3L)
  pw <- postrank_tie_pairwise(as_postrank_tie_draws(pr_tie_fixture(values, masses)))
  actions <- pr_tie_all_actions(3L, 3L)
  for (tau in c(.2, .5)) {
    expected <- vapply(actions, function(g)
      pr_v1_state_losses(values, masses, g, 1, tau), numeric(5L))
    actual <- vapply(actions, function(g) postrank_tie_evaluate(setNames(g, pw$entity_ids),
      pw, c(need1 = 1), tau)$weighted_risk, numeric(1L))
    expect_equal(actual, unname(expected["neutral", ]), tolerance = 1e-13)
    expect_equal(unname(expected["weak", ]),
      unname(tau + (1 - tau) * (expected["krw", ] + expected["disclosed_equality", ])),
      tolerance = 1e-13)
    expect_equal(unname(expected["weak", ] - expected["neutral", ]),
      unname(expected["disclosed_equality", ] + tau * expected["withheld_equality", ]),
      tolerance = 1e-13)
    hold <- postrank_tie_evaluate(setNames(rep(1L, 3L), pw$entity_ids), pw, c(need1 = 1), tau)
    expect_equal(hold$R0, 2 * tau / 3, tolerance = 1e-13)
    expect_true(is.na(hold$E_over_N))
    expect_true(is.na(hold$E_over_D))
    expect_lt(hold$R0, tau)
  }
})
