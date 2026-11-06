# Packaged-test copy of the posterior-only synthetic-law adapter.
# Source: checks/exact-fixture-adapter.R (local project, MIT); SHA256 d7800dd77106c76b1b9b58e640c08bdf1e29fa785325e89e6af31fd5c2bcfa64
# Kept self-contained so package tests do not require excluded repository tools.
# Explicit development-only posterior adapter for the unchanged six book laws.
# It neither imports the oracle implementations nor evaluates risk. Decision
# settings remain outside the posterior payload. Metadata describes the actual
# synthetic fixture artifact and never impersonates an empirical fitted model.
pr_fixture_payload <- function(case, fixture_path = NULL) {
  if (is.null(fixture_path)) {
    candidates <- c(file.path("tests", "fixtures", "exact", "core-cases.json"),
                    file.path("..", "fixtures", "exact", "core-cases.json"))
    found <- candidates[file.exists(candidates)]
    if (!length(found)) stop("Supply an existing core-cases.json fixture_path", call. = FALSE)
    fixture_path <- found[[1L]]
  }
  fixture <- jsonlite::read_json(fixture_path, simplifyVector = FALSE)
  if (!identical(fixture$schema, "p1-applied-tiny-oracle-v1")) stop("Unsupported book fixture schema", call. = FALSE)
  positions <- which(vapply(fixture$cases, function(z) identical(z$id, case$id), logical(1L)))
  if (length(positions) != 1L || !identical(case, fixture$cases[[positions]]))
    stop("case must match one complete case in the supplied source fixture", call. = FALSE)
  fixture_hash <- digest::digest(file = fixture_path, algo = "sha256")
  entity_ids <- unlist(case$entity_ids, use.names = FALSE)
  criterion_ids <- unlist(case$criterion_ids, use.names = FALSE)
  states <- lapply(seq_along(case$states), function(s) {
    source <- case$states[[s]]
    theta <- do.call(rbind, lapply(source$theta, unlist, use.names = FALSE))
    dimnames(theta) <- list(entity = entity_ids, criterion = criterion_ids)
    list(state_id = paste0(case$id, "-state-", s), mass_numerator = source$mass, theta = theta)
  })
  list(schema_version = "applied-0.1", input_kind = "exact_finite_posterior", dependence_mode = "joint_model",
    requested_functional = "expected_rank_loss", entity_ids = entity_ids, criterion_ids = criterion_ids,
    targets = lapply(criterion_ids, function(k) list(criterion_id = k,
      estimand = paste("Synthetic target coordinate", k, "of explicit finite-law case", case$id),
      entity_population = paste("Fixed synthetic fixture entities in", case$id), time_reference = "Synthetic finite-law definition",
      units = "Fixture target units", source_transform = "identity; larger supplied integer means higher priority",
      identification_basis = "Explicit entity and criterion coordinate labels in finite-law states", orientation = "higher_priority")),
    context = list(cohort_id = paste0("book-fixture-", case$id), data_version = fixture_hash,
      data_conditioning = "Explicitly defined synthetic finite law; no empirical posterior fit or Monte Carlo approximation",
      model_summary = case$description),
    identification = list(status = "identified_declared", note = "Fixture defines labeled entity target states directly"),
    tie_policy = list(rule = "pairwise_tie_free", declared = TRUE,
      justification = "Explicit positive-mass fixture states are distinct within each criterion; constructor checks every state",
      observed_tie_action = "reject_and_review"),
    provenance = list(producer = "postrank development exact-fixture adapter", artifact_id = paste0(basename(fixture_path), "#", case$id),
      artifact_hash = fixture_hash, construction_note = paste("Posterior-only mapping of explicit book finite law", case$id,
        "from", normalizePath(fixture_path), "; decision settings are retained separately in source fixture"),
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    finite_law = list(denominator = case$denominator, value_representation = "safe_integer", states = states,
      law_definition = paste("Positive integer state masses and targets of case", case$id, "in source fixture SHA-256", fixture_hash),
      not_empirical_posterior_relabeling = TRUE))
}
