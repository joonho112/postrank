% Please edit documentation in R/tie-input.R
\name{as_postrank_tie_draws}
\alias{as_postrank_tie_draws}
\title{Prepare Posterior Inputs with Positive Equality Probability}
\usage{
as_postrank_tie_draws(x)
}
\arguments{
\item{x}{A plain named \code{list} following the \code{"tie-aware-input-0.1"} structure
(joint equal-weight IID or MCMC draws, or a complete exact finite law), or
an unmodified \code{postrank_tie_draws} object.}
}
\value{
A \code{postrank_tie_draws} list keeping target values, entity and
criterion IDs, sampling history, criterion equality partitions, \code{validation}
flags, and \code{input_identity} (a SHA-256 content hash used to detect later
edits). Does not inherit from \code{postrank_draws}.
}
\description{
\code{as_postrank_tie_draws()} builds and checks a posterior input for \emph{tie-aware
mode}, the separate \verb{postrank_tie_*} workflow for posteriors in which two
distinct entities can be exactly equal with positive probability. Tie-aware
mode uses \emph{equality-neutral loss}, under which true target equality
(\code{theta_i = theta_j}) has zero loss whether the pair is ordered or placed in
the same grade. Placing two entities in the same grade still leaves them
unordered (withholds ordering) rather than claiming their targets are equal.
}
\details{
Target values must already be oriented so larger values mean higher priority
(\code{orientation = "higher_priority"} on every criterion). Required top-level
fields are \code{schema_version = "tie-aware-input-0.1"}, \code{input_kind},
\code{dependence_mode = "joint_model"},
\code{requested_functional = "expected_rank_loss"}, \code{entity_ids}, \code{criterion_ids},
\code{targets}, \code{context}, \code{identification} (\code{status = "identified_declared"}),
\code{tie_policy} (\code{rule = "equality_neutral"}, \code{declared = TRUE}, non-empty
\code{justification}, and
\code{observed_tie_action = "accept_declared_exact_equality"}), \code{provenance},
\code{equality}, and one of \code{joint_draws} or \code{finite_law}. Criterion-wise draw
blocks, unequal draw weights, and variational approximations are rejected.

The \code{equality} list carries \code{basis}, a non-empty \code{justification}, and
\code{criterion_classes} (a criterion-named list of character vectors assigning a
non-blank class label to every entity):
\itemize{
\item For \code{input_kind = "equal_weight_draws"}, \code{joint_draws} holds an
\verb{S x n x K} array (retaining the third dimension when \code{K = 1}), and
\code{equality$basis} must be \code{"structural_declared"}. Entities sharing a
class label on criterion \code{k} must have identical values in every retained
draw (\code{==}, with no tolerance or jitter). Coincident ties in finitely
many Monte Carlo draws are never used to merge structural classes, while
every retained numerical tie contributes to empirical equality
probability. Do not pass rounded continuous draws here; re-export them at
full precision for \code{\link[=postrank_draws]{postrank_draws()}}.
\item For \code{input_kind = "exact_finite_posterior"}, \code{finite_law} lists all
positive-mass states with safe-integer \code{theta} (\verb{n x K}) and positive
safe-integer \code{mass_numerator} values summing to \code{denominator} (at most
\code{2^53 - 1}, verified with optional package \code{gmp}), plus
\code{not_empirical_posterior_relabeling = TRUE}. Here \code{equality$basis} must
be \code{"exact_finite_law"}; set \code{criterion_classes = NULL} to derive the
partition from equality across all states (any supplied partition must
define the same equivalence relation).
}

Integer values are stored as \code{double} so JSON round-trips preserve exact
storage. Structural checks do not verify model specification, MCMC
convergence, or scientific equality claims, and do not issue a numerical
certificate. Mutating a \code{postrank_tie_draws} object after creation causes
revalidation to stop with an error.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
states <- lapply(c(0, 1, 2), function(a) {
  matrix(c(a, 1), 2, 1, dimnames = list(entity = c("A", "B"), criterion = "score"))
})
masses <- c(1L, 4L, 5L)
payload <- list(
  schema_version = "tie-aware-input-0.1",
  input_kind = "exact_finite_posterior",
  dependence_mode = "joint_model",
  requested_functional = "expected_rank_loss",
  entity_ids = c("A", "B"),
  criterion_ids = "score",
  targets = list(list(
    criterion_id = "score", estimand = "Specified latent score",
    entity_population = "Two fictional sites A and B",
    time_reference = "Static mathematical example", units = "Score units",
    source_transform = "identity", identification_basis = "Complete stated law",
    orientation = "higher_priority"
  )),
  context = list(
    cohort_id = "two-site-score", data_version = "1",
    data_conditioning = "Directly specified three-state law",
    model_summary = "B is 1; A is 0, 1, or 2 with masses 1/10, 4/10, 5/10"
  ),
  identification = list(
    status = "identified_declared",
    note = "Coordinates defined directly by the finite law"
  ),
  tie_policy = list(
    rule = "equality_neutral", declared = TRUE,
    justification = "State A = B = 1 has equality probability 4/10",
    observed_tie_action = "accept_declared_exact_equality"
  ),
  provenance = list(
    producer = "Help-page finite-law example",
    artifact_id = "two-site-three-state-law",
    artifact_hash = digest::digest(list(states, masses), algo = "sha256"),
    construction_note = "Complete law without sampling or rounding",
    created_at = format(Sys.time(), "\%Y-\%m-\%dT\%H:\%M:\%SZ", tz = "UTC")
  ),
  equality = list(
    basis = "exact_finite_law",
    justification = "Compare all positive-mass states",
    criterion_classes = NULL
  ),
  finite_law = list(
    denominator = sum(masses), value_representation = "safe_integer",
    states = lapply(seq_along(states), function(s) {
      list(state_id = paste0("state-", s), mass_numerator = masses[s], theta = states[[s]])
    }),
    law_definition = "B is 1; A is 0, 1, or 2 with masses 1/10, 4/10, 5/10",
    not_empirical_posterior_relabeling = TRUE
  )
)
one <- as_postrank_tie_draws(payload)
postrank_tie_pairwise(one)$t["A", "B", "score"]

two <- read_postrank_tie_draws(
  system.file("examples", "synthetic-tie-aware.json", package = "postrank")
)
two$equality$criterion_classes
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=validate_postrank_tie_draws]{validate_postrank_tie_draws()}}, \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}},
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}},
\code{vignette("m4-ties-and-withholding", package = "postrank")}
}
\concept{tie-aware}
