# Independent raw-state fixtures/oracle: never read production b/t/d,
# objective coefficients, evaluator or guard builder to compute expectations.
pr_tie_fixture <- function(values, masses = NULL, classes = NULL) {
  stopifnot(length(dim(values)) == 3L)
  dims <- dim(values); S <- dims[1L]; n <- dims[2L]; K <- dims[3L]
  x <- pr_test_payload(S = S, n = n, K = K)
  dimnames(values) <- x$joint_draws$tensor$dimnames
  x$schema_version <- "tie-aware-input-0.1"
  x$tie_policy <- list(rule = "equality_neutral", declared = TRUE,
    justification = "Software fixture declares genuine exact target equality, without rounding or jitter.",
    observed_tie_action = "accept_declared_exact_equality")
  x$provenance$artifact_hash <- digest::digest(list(values, masses), algo = "sha256")
  if (is.null(masses)) {
    x$joint_draws$tensor$values <- values
    if (is.null(classes)) classes <- stats::setNames(lapply(seq_len(K), function(k)
      stats::setNames(paste0("singleton-", seq_len(n)), x$entity_ids)), x$criterion_ids)
    x$equality <- list(basis = "structural_declared",
      justification = "Only supplied structural partitions are declared; sampled coincidences do not establish identity.",
      criterion_classes = classes)
  } else {
    stopifnot(length(masses) == S, all(masses > 0), all(masses == floor(masses)))
    x$input_kind <- "exact_finite_posterior"; x$joint_draws <- NULL
    x$finite_law <- list(denominator = sum(masses), value_representation = "safe_integer",
      states = lapply(seq_len(S), function(s) list(state_id = paste0("state-", s), mass_numerator = masses[s],
        theta = matrix(values[s, , ], n, K, dimnames = list(entity = x$entity_ids, criterion = x$criterion_ids)))),
      law_definition = "All positive-mass states of an explicit finite software law, not empirical relabeling.",
      not_empirical_posterior_relabeling = TRUE)
    x$equality <- list(basis = "exact_finite_law", justification = "Derive equality from every positive-mass law state.",
      criterion_classes = classes)
  }
  x
}

pr_tie_pair_values <- function(bad_S, bad_C = NULL, tie_S = integer(), tie_C = integer(), S = 10L) {
  K <- if (is.null(bad_C)) 1L else 2L; v <- array(0, c(S, 2L, K))
  for (k in seq_len(K)) v[, 1L, k] <- 1
  for (s in bad_S) v[s, , 1L] <- c(0, 1)
  for (s in tie_S) v[s, , 1L] <- c(0, 0)
  if (K == 2L) {
    for (s in bad_C) v[s, , 2L] <- c(0, 1)
    for (s in tie_C) v[s, , 2L] <- c(0, 0)
  }; v
}

pr_tie_state_oracle <- function(values, probabilities, grade, weights, tau) {
  S <- dim(values)[1L]; n <- dim(values)[2L]; K <- dim(values)[3L]
  stopifnot(length(probabilities) == S, abs(sum(probabilities) - 1) < 1e-12)
  loss <- errors <- Dk <- Tk <- numeric(K); state_loss <- numeric(S); N <- 0L
  for (i in seq_len(n - 1L)) for (j in seq.int(i + 1L, n)) {
    held <- grade[i] == grade[j]
    if (!held) N <- N + 1L
    for (s in seq_len(S)) for (k in seq_len(K)) {
      distinct <- values[s, i, k] != values[s, j, k]
      wrong <- if (held) FALSE else if (grade[i] < grade[j]) values[s, i, k] < values[s, j, k] else values[s, j, k] < values[s, i, k]
      cost <- if (held) tau * distinct else as.numeric(wrong)
      loss[k] <- loss[k] + probabilities[s] * cost
      errors[k] <- errors[k] + probabilities[s] * wrong
      Tk[k] <- Tk[k] + probabilities[s] * distinct
      if (!held) Dk[k] <- Dk[k] + probabilities[s] * distinct
      state_loss[s] <- state_loss[s] + weights[k] * cost
    }
  }
  M <- choose(n, 2)
  list(risk = sum(weights * loss) / M, criterion_risk = loss / M, E = errors, D_k = Dk, T_k = Tk,
    D = sum(weights * Dk), T = sum(weights * Tk), N = N, M = M,
    baseline = tau * sum(weights * Tk) / M, state_loss = state_loss / M)
}

# Exhaustive tiny ordered partitions from n-tuples; no production canonicalizer.
pr_tie_all_actions <- function(n, G_max) {
  grid <- as.matrix(expand.grid(rep(list(seq_len(G_max)), n)))
  good <- apply(grid, 1L, function(g) identical(sort(unique(as.integer(g))), seq_len(max(g))))
  lapply(which(good), function(r) as.integer(grid[r, ]))
}
pr_tie_oracle_optimum <- function(values, probabilities, weights, tau, G_max) {
  n <- dim(values)[2L]; active <- which(weights > 0); equal <- matrix(FALSE, n, n)
  for (i in seq_len(n)) for (j in seq_len(n)) equal[i, j] <- all(values[, i, active, drop = FALSE] == values[, j, active, drop = FALSE])
  actions <- pr_tie_all_actions(n, G_max)
  actions <- actions[vapply(actions, function(g) all(!equal | outer(g, g, `==`)), logical(1L))]
  risk <- vapply(actions, function(g) pr_tie_state_oracle(values, probabilities, g, weights, tau)$risk, numeric(1L))
  list(value = min(risk), actions = actions, risks = risk, minimizers = actions[abs(risk - min(risk)) < 1e-12])
}
pr_tie_t11 <- function() {
  v <- array(0, c(2L, 4L, 2L)); v[1L, , 1L] <- c(0, 0, 2, 3); v[2L, , 1L] <- c(0, 0, 2, 1); v[, 4L, 2L] <- 1
  list(values = v, masses = c(3L, 2L), weights = c(need1 = .25, need2 = .75))
}
