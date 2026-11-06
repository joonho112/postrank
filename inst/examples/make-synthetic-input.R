# Newly authored software example. source() only defines the function.
# The generator uses an explicitly specified proper toy Normal law, no fitted
# model or real observations. This is not copied from the upstream book oracle.
make_postrank_synthetic_input <- function() {
  # Fixed before generation, including the illustrative fixed-S IID allocation.
  S <- 32L; seed <- 20261019L; alpha <- .05
  entities <- c("001", "site-B", "site C"); criteria <- c("need_A", "need_B")
  alpha_by_criterion <- stats::setNames(c(.025, .025), criteria)
  target_means <- matrix(c(1, 0, -1, -.6, .8, 0), 3L, 2L,
    dimnames = list(entity = entities, criterion = criteria))
  target_sd <- .6
  existed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  previous <- if (existed) get(".Random.seed", envir = .GlobalEnv, inherits = FALSE) else NULL
  kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(kind))
    if (existed) assign(".Random.seed", previous, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  slots <- sprintf("toy_draw_%03d", seq_len(S))
  values <- array(0, c(S, 3L, 2L), dimnames = list(draw = slots, entity = entities, criterion = criteria))
  for (k in seq_along(criteria)) for (i in seq_along(entities))
    values[, i, k] <- stats::rnorm(S, target_means[i, k], target_sd)
  source_hash <- digest::digest(values, algo = "sha256", serialize = TRUE)
  variable_map <- unlist(lapply(seq_along(criteria), function(k) lapply(seq_along(entities), function(i)
    list(entity_id = entities[i], criterion_id = criteria[k],
      source_target_variable_id = paste0("theta[", i, ",", k, "]"),
      derivation_note = "Direct labeled coordinate from the complete synthetic R array; identity transform."))), recursive = FALSE)
  list(schema_version = "applied-0.1", input_kind = "equal_weight_draws", dependence_mode = "joint_model",
    requested_functional = "expected_rank_loss", entity_ids = entities, criterion_ids = criteria,
    targets = lapply(criteria, function(k) list(criterion_id = k,
      estimand = "Toy latent site need under the explicitly specified independent Normal target law",
      entity_population = "Three labeled synthetic entities", time_reference = "Single fixed software example",
      units = "toy real-valued need units", source_transform = "identity",
      identification_basis = "Direct specified target coordinates; no fitted factor model", orientation = "higher_priority")),
    context = list(cohort_id = "new-authored-toy-normal-example", data_version = "toy-normal-0.1",
      data_conditioning = "No observed dataset: a declared proper toy Normal target distribution used only for software illustration.",
      model_summary = paste0("Independent Normal coordinates, SD .6, fixed means in generator; IID states; S=", S,
        ", seed=", seed, ". Before generation alpha=", alpha, " and allocation=",
        paste(alpha_by_criterion, collapse = ","), " were fixed. This is not empirical evidence about a scientific posterior.")),
    identification = list(status = "identified_declared", note = "The toy law defines every labeled target directly."),
    tie_policy = list(rule = "pairwise_tie_free", declared = TRUE,
      justification = "Continuous independent Normal target coordinates have zero probability of exact pairwise equality; observed ties are still rejected.",
      observed_tie_action = "reject_and_review"),
    provenance = list(producer = "Newly authored postrank synthetic Normal example generator",
      artifact_id = "toy-normal-fixed-S-0.1", artifact_hash = source_hash,
      construction_note = "Complete 32 by 3 by 2 R array from the explicit seed/means/SD in examples/make-synthetic-input.R; original array hash is source_hash. No upstream oracle values reused.",
      created_at = "2026-10-19T00:00:00Z"),
    joint_draws = list(tensor = list(axis_order = c("draw", "entity", "criterion"),
      shape = list(S = S, n = 3L, K = 2L), dimnames = dimnames(values), values = values),
      origin = list(source_id = "toy-normal-full-array-0.1", fit_id = "toy-law-no-fitted-data-0.1",
        model_id = "specified-independent-normal-0.1", source_format = "R array",
        source_artifact = "Fresh complete R array from examples/make-synthetic-input.R",
        source_hash = source_hash, vector_generation_provenance = "Every draw slot stores the entire labeled site/criterion vector from one IID toy state.",
        within_criterion_joint_declared = TRUE),
      sampling = list(regime = "iid", target_distribution = "declared_posterior", equal_weight = TRUE,
        warmup_status = "not_applicable", sampling_provenance = "Fixed-S independent states from a specified proper toy Normal law; not a fitted scientific posterior.",
        chain_history = list()),
      draw_index = lapply(seq_len(S), function(s) list(slot_id = slots[s], original_draw_id = paste0("toy_original_", s),
        chain_id = NULL, iteration = NULL)), variable_map = variable_map,
      cross_criterion_joint_provenance = "Complete synthetic states retain all three entities and both criteria together; no marginal reordering."))
}
