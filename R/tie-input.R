# Separate opt-in domain. No legacy payload, class, default or identity is changed.
.pr_tie_utf8 <- function(x) {
  .pr_assert(!any(Encoding(x) == "bytes"),
    "byte-encoded strings cannot be represented as declared Unicode text", "invalid_tie_text")
  out <- tryCatch(enc2utf8(x), error = function(e)
    .pr_abort("text cannot be represented as UTF-8 without loss", "invalid_tie_text"))
  .pr_assert(all(is.na(out) | validUTF8(out)),
    "text cannot be represented as UTF-8 without loss", "invalid_tie_text")
  out
}

# Normalize encodings, never Unicode composition or code points. Attributes are
# traversed too: entity/criterion names and array dimnames belong to the seal.
.pr_tie_text_content <- function(x) {
  attrs <- attributes(x)
  if (is.character(x)) x <- .pr_tie_utf8(x)
  else if (is.list(x)) x <- lapply(x, .pr_tie_text_content)
  if (!is.null(attrs)) {
    attrs <- lapply(attrs, .pr_tie_text_content)
    names(attrs) <- .pr_tie_utf8(names(attrs))
    attributes(x) <- attrs
  }
  x
}

.pr_tie_sort_content <- function(x) {
  if (is.list(x) && !is.data.frame(x)) {
    attrs <- attributes(x)
    if (!is.null(names(x))) {
      x <- x[sort(names(x), method = "radix")]
      attrs$names <- names(x)
    }
    x <- lapply(x, .pr_tie_sort_content)
    attributes(x) <- attrs
  }
  x
}

.pr_tie_canonical <- function(x) .pr_tie_sort_content(.pr_tie_text_content(x))

# Callers remove only their own seal before passing semantic content here.
.pr_tie_identity <- function(x, domain) {
  .pr_string(domain, "$.identity_domain")
  digest::digest(list(domain = domain, content = .pr_tie_canonical(x)),
    algo = "sha256", serialize = TRUE, serializeVersion = 2)
}

.pr_tie_numeric_payload <- function(x) {
  if (is.integer(x)) { storage.mode(x) <- "double"; return(x) }
  if (is.list(x)) x <- lapply(x, .pr_tie_numeric_payload)
  x
}

.pr_tie_check_storage <- function(x, path = "$") {
  allowed <- if (is.list(x)) "names" else c("names", "dim", "dimnames")
  .pr_assert(all(names(attributes(x)) %in% allowed),
    "canonical payload has unsupported hidden attributes or classes", "invalid_tie_input", path)
  if (is.character(x)) .pr_tie_utf8(x)
  if (is.list(x)) for (i in seq_along(x))
    .pr_tie_check_storage(x[[i]], paste0(path, "[", i, "]"))
  invisible(TRUE)
}

.pr_tie_input_validation <- function() list(structure_checked = TRUE,
  declared_class_values_checked = TRUE, source_values_checked = FALSE,
  jointness_verified = FALSE, convergence_verified = FALSE,
  scientific_equality_verified = FALSE, finite_sample_certificate = FALSE,
  numerical_certification = FALSE)

.pr_tie_input_payload <- function(x) {
  if (inherits(x, "postrank_tie_draws")) {
    x <- unclass(x); x[c("input_identity", "validation")] <- NULL
  }
  x
}

.pr_tie_validate_exact <- function(x) {
  law <- x$finite_law; path <- "$.finite_law"
  .pr_fields(law, c("denominator", "value_representation", "states", "law_definition",
    "not_empirical_posterior_relabeling"), path = path)
  .pr_assert(identical(law$value_representation, "safe_integer"),
    "exact-law targets require safe_integer representation", path = path)
  .pr_assert(is.numeric(law$denominator) && is.null(dim(law$denominator)) &&
    length(law$denominator) == 1L, "denominator must be a scalar safe integer", path = path)
  .pr_safe_integer(law$denominator, TRUE, paste0(path, ".denominator"))
  .pr_string(law$law_definition, paste0(path, ".law_definition"))
  .pr_assert(identical(law$not_empirical_posterior_relabeling, TRUE),
    "exact law requires an explicit nonempirical declaration", "empirical_relabeling", path)
  .pr_records(law$states, paste0(path, ".states"))
  .pr_assert(length(law$states) > 0L, "finite law needs positive-mass states", path = path)
  .pr_assert(requireNamespace("gmp", quietly = TRUE),
    "exact finite-law validation requires optional package gmp", "missing_dependency", path)
  total <- gmp::as.bigz(0); maximum <- gmp::as.bigz("9007199254740991")
  ids <- character(length(law$states))
  for (s in seq_along(law$states)) {
    z <- law$states[[s]]; loc <- paste0(path, ".states[", s, "]")
    .pr_fields(z, c("state_id", "mass_numerator", "theta"), path = loc)
    .pr_string(z$state_id, paste0(loc, ".state_id")); ids[s] <- z$state_id
    .pr_assert(is.numeric(z$mass_numerator) && is.null(dim(z$mass_numerator)) &&
      length(z$mass_numerator) == 1L, "state mass must be scalar", path = loc)
    .pr_safe_integer(z$mass_numerator, TRUE, paste0(loc, ".mass_numerator"))
    total <- total + .pr_big_integer(z$mass_numerator)
    .pr_assert(total <= maximum, "exact mass sum exceeds safe-integer range", "unsafe_integer", loc)
    theta <- z$theta
    .pr_assert(is.numeric(theta) && is.matrix(theta) &&
      identical(dim(theta), c(length(x$entity_ids), length(x$criterion_ids))),
      "each exact state must retain an n by K numeric matrix", "invalid_shape", loc)
    .pr_safe_integer(theta, path = paste0(loc, ".theta"))
    .pr_assert(identical(dimnames(theta), list(entity = x$entity_ids, criterion = x$criterion_ids)),
      "exact state axes differ from declared order", "invalid_id", loc)
  }
  .pr_ids(ids, path = paste0(path, ".states.state_id"))
  .pr_assert(total == .pr_big_integer(law$denominator),
    "state masses do not sum exactly to denominator", "invalid_exact_mass", path)
  invisible(TRUE)
}

.pr_tie_source_matrices <- function(x) {
  ids <- x$entity_ids; ks <- x$criterion_ids
  out <- lapply(seq_along(ks), function(k) {
    if (identical(x$input_kind, "equal_weight_draws")) {
      a <- x$joint_draws$tensor$values
      matrix(a[, , k, drop = FALSE], nrow = dim(a)[1L], ncol = length(ids),
        dimnames = list(draw = dimnames(a)$draw, entity = ids))
    } else {
      a <- do.call(rbind, lapply(x$finite_law$states, function(s) s$theta[, k]))
      dimnames(a) <- list(state = vapply(x$finite_law$states, `[[`, character(1L), "state_id"), entity = ids)
      a
    }
  })
  names(out) <- ks; out
}

.pr_tie_exact_classes <- function(matrices, ids) {
  lapply(matrices, function(a) {
    labels <- character(length(ids))
    for (i in seq_along(ids)) {
      same <- which(vapply(seq_len(i), function(j) all(a[, i] == a[, j]), logical(1L)))
      labels[i] <- ids[same[1L]]
    }
    stats::setNames(labels, ids)
  })
}

.pr_tie_partition <- function(classes, ids, ks) {
  .pr_fields(classes, ks, path = "$.equality.criterion_classes")
  classes <- classes[ks]
  for (k in ks) {
    z <- classes[[k]]; path <- paste0("$.equality.criterion_classes.", k)
    .pr_assert(is.character(z) && is.null(dim(z)) && length(z) == length(ids) &&
      !anyNA(z) && all(grepl("(*UCP)\\S", z, perl = TRUE)) &&
      !is.null(names(z)) && !anyNA(names(z)) && !anyDuplicated(names(z)) && setequal(names(z), ids),
      "each criterion needs one nonblank class label per named entity", "invalid_equality_partition", path)
    classes[[k]] <- z[ids]
  }
  classes
}

.pr_tie_equality <- function(x) {
  z <- x$equality
  .pr_fields(z, c("basis", "justification", "criterion_classes"), path = "$.equality")
  .pr_string(z$justification, "$.equality.justification")
  exact <- identical(x$input_kind, "exact_finite_posterior")
  required_basis <- if (exact) "exact_finite_law" else "structural_declared"
  .pr_assert(identical(z$basis, required_basis),
    paste("equality basis must be", required_basis), "invalid_equality_basis", "$.equality.basis")
  matrices <- .pr_tie_source_matrices(x)
  if (exact) {
    derived <- .pr_tie_exact_classes(matrices, x$entity_ids)
    if (!is.null(z$criterion_classes)) {
      supplied <- .pr_tie_partition(z$criterion_classes, x$entity_ids, x$criterion_ids)
      for (k in x$criterion_ids) .pr_assert(identical(outer(supplied[[k]], supplied[[k]], `==`),
        outer(derived[[k]], derived[[k]], `==`)),
        "supplied exact-law partition differs from equality across all positive-mass states",
        "invalid_equality_partition", paste0("$.equality.criterion_classes.", k))
    }
    z$criterion_classes <- derived
  } else {
    z$criterion_classes <- .pr_tie_partition(z$criterion_classes, x$entity_ids, x$criterion_ids)
    for (k in x$criterion_ids) for (group in unique(z$criterion_classes[[k]])) {
      members <- which(z$criterion_classes[[k]] == group)
      if (length(members) > 1L) for (i in members[-1L])
        .pr_assert(all(matrices[[k]][, i] == matrices[[k]][, members[1L]]),
          "declared equal-class entities differ in a retained draw; no tolerance or jitter is used",
          "declared_equality_violated", paste0("$.equality.criterion_classes.", k))
    }
  }
  z
}

.pr_tie_validate_payload <- function(x) {
  .pr_tie_check_storage(x)
  fields <- c("schema_version", "input_kind", "dependence_mode", "requested_functional", "entity_ids",
    "criterion_ids", "targets", "context", "identification", "tie_policy", "provenance", "equality")
  .pr_fields(x, fields, c(fields, "joint_draws", "finite_law"))
  .pr_assert(identical(x$schema_version, "tie-aware-input-0.1"),
    "expected explicit tie-aware-input-0.1 schema", "unsupported_version")
  .pr_assert(identical(x$dependence_mode, "joint_model"),
    "tie-aware input currently requires joint_model", "unsupported_tie_input")
  .pr_assert(identical(x$requested_functional, "expected_rank_loss"),
    "only expected_rank_loss is supported", "unsupported_functional")
  .pr_ids(x$entity_ids, 2L, "$.entity_ids"); .pr_ids(x$criterion_ids, 1L, "$.criterion_ids")
  .pr_records(x$targets, "$.targets")
  .pr_assert(length(x$targets) == length(x$criterion_ids), "one target record is required per criterion")
  target_fields <- c("criterion_id", "estimand", "entity_population", "time_reference", "units",
    "source_transform", "identification_basis", "orientation")
  for (k in seq_along(x$targets)) {
    z <- x$targets[[k]]; path <- paste0("$.targets[", k, "]")
    .pr_fields(z, target_fields, path = path)
    for (f in target_fields) .pr_string(z[[f]], paste0(path, ".", f))
    .pr_assert(identical(z$orientation, "higher_priority"), "targets must be oriented higher_priority", path = path)
  }
  target_ids <- vapply(x$targets, `[[`, character(1L), "criterion_id")
  .pr_ids(target_ids)
  .pr_assert(setequal(target_ids, x$criterion_ids), "targets must cover each criterion exactly once")
  .pr_fields(x$context, c("cohort_id", "data_version", "data_conditioning", "model_summary"), path = "$.context")
  for (f in names(x$context)) .pr_string(x$context[[f]], paste0("$.context.", f))
  .pr_fields(x$identification, c("status", "note"), path = "$.identification")
  .pr_assert(identical(x$identification$status, "identified_declared"),
    "unresolved target identification", "unresolved_identification")
  .pr_string(x$identification$note, "$.identification.note")
  .pr_fields(x$tie_policy, c("rule", "declared", "justification", "observed_tie_action"), path = "$.tie_policy")
  .pr_assert(identical(x$tie_policy$rule, "equality_neutral") && identical(x$tie_policy$declared, TRUE) &&
    identical(x$tie_policy$observed_tie_action, "accept_declared_exact_equality"),
    "explicit equality-neutral genuine-tie declaration is required", "invalid_tie_policy", "$.tie_policy")
  .pr_string(x$tie_policy$justification, "$.tie_policy.justification")
  .pr_fields(x$provenance, c("producer", "artifact_id", "artifact_hash", "construction_note", "created_at"), path = "$.provenance")
  for (f in names(x$provenance)) .pr_string(x$provenance[[f]], paste0("$.provenance.", f))
  branches <- intersect(c("joint_draws", "finite_law"), names(x))
  .pr_assert(length(branches) == 1L, "exactly one joint input branch is required")
  if (identical(x$input_kind, "equal_weight_draws")) {
    .pr_assert(identical(branches, "joint_draws"), "equal-weight inputs require joint_draws")
    b <- x$joint_draws; path <- "$.joint_draws"
    .pr_fields(b, c("tensor", "origin", "sampling", "draw_index", "variable_map", "cross_criterion_joint_provenance"), path = path)
    .pr_validate_numeric_axes(b$tensor, c("draw", "entity", "criterion"),
      list(draw = NULL, entity = x$entity_ids, criterion = x$criterion_ids), paste0(path, ".tensor"))
    .pr_string(b$cross_criterion_joint_provenance, paste0(path, ".cross_criterion_joint_provenance"))
    .pr_validate_origin_map(b, x$entity_ids, x$criterion_ids, path)
    .pr_validate_history(b, b$tensor$shape$S, b$tensor$dimnames$draw, path)
  } else if (identical(x$input_kind, "exact_finite_posterior")) {
    .pr_assert(identical(branches, "finite_law"), "exact inputs require finite_law")
    .pr_tie_validate_exact(x)
  } else .pr_abort("unsupported tie-aware input kind", "unsupported_tie_input")
  invisible(TRUE)
}

#' Prepare Posterior Inputs with Genuine Equality Mass
#'
#' The constructor prepares a posterior law that permits exact equality between
#' distinct entities. The separate equality-neutral analysis uses strict
#' directional errors and assigns zero withholding loss at true equality. A
#' shared grade denotes a withheld comparison without asserting that the
#' targets are equal.
#'
#' @param x A complete `tie-aware-input-0.1` named-list payload or an unchanged
#'   `postrank_tie_draws` object. Supported inputs are joint equal-weight IID
#'   or MCMC draws, or a complete exact finite law.
#' @return A `postrank_tie_draws` object retaining the target values, IDs,
#'   source histories and equality classes, with an identity for detecting
#'   subsequent changes. It does not inherit from `postrank_draws`.
#' @details
#' Values must already be oriented so that larger means higher priority.
#' Joint draws retain a `S x n x K` array, including `S x n x 1` for one
#' criterion. Target, context, identification, provenance and joint-state
#' records follow the corresponding ordinary input structure. The input
#' must explicitly set `tie_policy$rule = "equality_neutral"`,
#' `declared = TRUE` and
#' `observed_tie_action = "accept_declared_exact_equality"`.
#'
#' The `equality` record contains `basis`, a substantive `justification`, and
#' `criterion_classes`, a criterion-named list of character class labels named
#' by every entity. For IID/MCMC draws, `basis = "structural_declared"` requires
#' classes justified by the producing model. Every declared within-class
#' equality is checked in every retained draw. Coincident Monte Carlo values
#' do not establish almost-sure equality and are never used to infer classes.
#'
#' For `basis = "exact_finite_law"`, the complete positive-mass states determine
#' the equality partition. Set `criterion_classes = NULL` to derive it;
#' a supplied partition must describe the same relation. State targets and
#' mass numerators must be safe integers, with positive masses summing to a
#' common denominator; the optional `gmp` package is required. These states
#' define the entire law, not an empirical sample relabeled as exact.
#'
#' All numerical equality is exact. Each retained numeric tie is treated as
#' genuine equality, even if it occurs outside a structurally equal class.
#' Recover full-precision exports of rounded continuous draws before using
#' this route. No tolerance, jitter, rounding or entity removal is performed.
#' Integer storage is normalized losslessly to double storage for JSON
#' round-trips. Criterion-wise, weighted approximate and variational inputs
#' are unsupported. Metadata checks cannot establish scientific equality,
#' jointness, stationarity or convergence; they do not supply an uncertainty
#' certificate. Changed objects fail revalidation; the constructor does not
#' assign them a new content identity.
#' @seealso [validate_postrank_tie_draws()], [postrank_tie_pairwise()],
#'   [read_postrank_tie_draws()],
#'   `vignette("m4-ties-and-withholding", package = "postrank")`
#' @concept tie-aware
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   # K = 1: B is always 1; A is 0, 1 or 2 with probabilities .1, .4, .5.
#'   states <- lapply(c(0, 1, 2), function(a)
#'     matrix(c(a, 1), 2, 1,
#'       dimnames = list(entity = c("A", "B"), criterion = "score")))
#'   masses <- c(1L, 4L, 5L)
#'   payload <- list(
#'     schema_version = "tie-aware-input-0.1",
#'     input_kind = "exact_finite_posterior", dependence_mode = "joint_model",
#'     requested_functional = "expected_rank_loss",
#'     entity_ids = c("A", "B"), criterion_ids = "score",
#'     targets = list(list(criterion_id = "score", estimand = "Specified latent score",
#'       entity_population = "Two fictional sites A and B",
#'       time_reference = "Static mathematical example", units = "Score units",
#'       source_transform = "identity", identification_basis = "Complete stated law",
#'       orientation = "higher_priority")),
#'     context = list(cohort_id = "two-site-score", data_version = "1",
#'       data_conditioning = "No observations; a directly specified law",
#'       model_summary = "B is 1; A is 0, 1 or 2 with masses 1/10, 4/10, 5/10"),
#'     identification = list(status = "identified_declared",
#'       note = "Labeled coordinates are defined directly by the law"),
#'     tie_policy = list(rule = "equality_neutral", declared = TRUE,
#'       justification = "The state A = B = 1 has genuine equality mass 4/10",
#'       observed_tie_action = "accept_declared_exact_equality"),
#'     provenance = list(producer = "Help-page finite-law example",
#'       artifact_id = "two-site-three-state-law",
#'       artifact_hash = digest::digest(list(states, masses), algo = "sha256"),
#'       construction_note = "Complete law; no sampling or rounding",
#'       created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
#'     equality = list(basis = "exact_finite_law",
#'       justification = "Compare all positive-mass states", criterion_classes = NULL),
#'     finite_law = list(denominator = sum(masses), value_representation = "safe_integer",
#'       states = lapply(seq_along(states), function(s)
#'         list(state_id = paste0("state-", s), mass_numerator = masses[s], theta = states[[s]])),
#'       law_definition = "B is 1; A is 0, 1 or 2 with masses 1/10, 4/10, 5/10",
#'       not_empirical_posterior_relabeling = TRUE))
#'   one <- as_postrank_tie_draws(payload)
#'   postrank_tie_pairwise(one)$t["A", "B", "score"] # 0.4 equality probability
#'
#'   # K = 2: the bundled complete law retains its own source and declarations.
#'   two <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
#'     package = "postrank"))
#'   two$criterion_ids
#'   two$equality$criterion_classes
#' }
#' @export
as_postrank_tie_draws <- function(x) {
  if (inherits(x, "postrank_tie_draws")) { validate_postrank_tie_draws(x); return(x) }
  .pr_assert(is.list(x) && identical(class(x), "list"), "expected a new canonical tie-aware payload", "invalid_tie_input")
  .pr_tie_check_storage(x)
  x <- .pr_tie_text_content(x)
  .pr_tie_validate_payload(x)
  x <- .pr_tie_numeric_payload(x)
  x$equality <- .pr_tie_equality(x)
  x$input_identity <- .pr_tie_identity(x, "postrank-tie-input-v1")
  x$validation <- .pr_tie_input_validation()
  class(x) <- c("postrank_tie_draws", "list")
  validate_postrank_tie_draws(x); x
}

#' Check an Equality-Neutral Posterior Input
#'
#' The validator checks numerical values, declared equality classes and
#' sampling history for a tie-aware analysis. It also detects changes
#' introduced after the object was constructed by [as_postrank_tie_draws()].
#'
#' @param x A `postrank_tie_draws` from [as_postrank_tie_draws()].
#' @return Invisible `TRUE` on success. Invalid or changed input raises a
#'   structured error; unlike [validate_postrank_draws()], this function does
#'   not return a record with `valid = FALSE`.
#' @details
#' Checks cover ordered axes, required source descriptions, sampling history,
#' exact within-class equality and the object's content identity. Scientific
#' equality classes for Monte Carlo draws remain declarations about the model;
#' their agreement with finitely many draws is not proof of almost-sure
#' equality. Complete finite laws determine equality from all positive-mass
#' states. Validation does not establish scientific provenance, jointness,
#' stationarity or convergence. Ordinary `postrank_draws` inputs are not
#' accepted, and reusing the constructor does not silently accept mutations.
#' @seealso [as_postrank_tie_draws()], [read_postrank_tie_draws()]
#' @concept tie-aware
#' @examples
#' if (requireNamespace("gmp", quietly = TRUE)) {
#'   input <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
#'     package = "postrank"))
#'   valid <- validate_postrank_tie_draws(input)
#'   valid
#'   input$equality$criterion_classes
#' }
#' @export
validate_postrank_tie_draws <- function(x) {
  .pr_assert(identical(class(x), c("postrank_tie_draws", "list")),
    "expected separate postrank_tie_draws class", "invalid_tie_input")
  .pr_assert(identical(x$validation, .pr_tie_input_validation()),
    "unsupported input validation claims", "invalid_tie_input")
  payload <- .pr_tie_input_payload(x)
  .pr_tie_validate_payload(payload)
  .pr_assert(identical(payload$equality, .pr_tie_equality(payload)),
    "equality partition is not the normalized source partition", "invalid_equality_partition")
  .pr_assert(is.character(x$input_identity) && length(x$input_identity) == 1L &&
    identical(x$input_identity, .pr_tie_identity(payload, "postrank-tie-input-v1")),
    "tie-aware input changed after construction", "stale_tie_input_identity")
  invisible(TRUE)
}
