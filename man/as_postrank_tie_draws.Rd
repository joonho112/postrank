% Please edit documentation in R/tie-input.R
\name{as_postrank_tie_draws}
\alias{as_postrank_tie_draws}
\title{Prepare Posterior Inputs with Genuine Equality Mass}
\usage{
as_postrank_tie_draws(x)
}
\arguments{
\item{x}{A complete \code{tie-aware-input-0.1} named-list payload or an unchanged
\code{postrank_tie_draws} object. Supported inputs are joint equal-weight IID
or MCMC draws, or a complete exact finite law.}
}
\value{
A \code{postrank_tie_draws} object retaining the target values, IDs,
source histories and equality classes, with an identity for detecting
subsequent changes. It does not inherit from \code{postrank_draws}.
}
\description{
The constructor prepares a posterior law that permits exact equality between
distinct entities. The separate equality-neutral analysis uses strict
directional errors and assigns zero withholding loss at true equality. A
shared grade denotes a withheld comparison without asserting that the
targets are equal.
}
\details{
Values must already be oriented so that larger means higher priority.
Joint draws retain a \verb{S x n x K} array, including \verb{S x n x 1} for one
criterion. Target, context, identification, provenance and joint-state
records follow the corresponding ordinary input structure. The input
must explicitly set \code{tie_policy$rule = "equality_neutral"},
\code{declared = TRUE} and
\code{observed_tie_action = "accept_declared_exact_equality"}.

The \code{equality} record contains \code{basis}, a substantive \code{justification}, and
\code{criterion_classes}, a criterion-named list of character class labels named
by every entity. For IID/MCMC draws, \code{basis = "structural_declared"} requires
classes justified by the producing model. Every declared within-class
equality is checked in every retained draw. Coincident Monte Carlo values
do not establish almost-sure equality and are never used to infer classes.

For \code{basis = "exact_finite_law"}, the complete positive-mass states determine
the equality partition. Set \code{criterion_classes = NULL} to derive it;
a supplied partition must describe the same relation. State targets and
mass numerators must be safe integers, with positive masses summing to a
common denominator; the optional \code{gmp} package is required. These states
define the entire law, not an empirical sample relabeled as exact.

All numerical equality is exact. Each retained numeric tie is treated as
genuine equality, even if it occurs outside a structurally equal class.
Recover full-precision exports of rounded continuous draws before using
this route. No tolerance, jitter, rounding or entity removal is performed.
Integer storage is normalized losslessly to double storage for JSON
round-trips. Criterion-wise, weighted approximate and variational inputs
are unsupported. Metadata checks cannot establish scientific equality,
jointness, stationarity or convergence; they do not supply an uncertainty
certificate. Changed objects fail revalidation; the constructor does not
assign them a new content identity.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  # K = 1: B is always 1; A is 0, 1 or 2 with probabilities .1, .4, .5.
  states <- lapply(c(0, 1, 2), function(a)
    matrix(c(a, 1), 2, 1,
      dimnames = list(entity = c("A", "B"), criterion = "score")))
  masses <- c(1L, 4L, 5L)
  payload <- list(
    schema_version = "tie-aware-input-0.1",
    input_kind = "exact_finite_posterior", dependence_mode = "joint_model",
    requested_functional = "expected_rank_loss",
    entity_ids = c("A", "B"), criterion_ids = "score",
    targets = list(list(criterion_id = "score", estimand = "Specified latent score",
      entity_population = "Two fictional sites A and B",
      time_reference = "Static mathematical example", units = "Score units",
      source_transform = "identity", identification_basis = "Complete stated law",
      orientation = "higher_priority")),
    context = list(cohort_id = "two-site-score", data_version = "1",
      data_conditioning = "No observations; a directly specified law",
      model_summary = "B is 1; A is 0, 1 or 2 with masses 1/10, 4/10, 5/10"),
    identification = list(status = "identified_declared",
      note = "Labeled coordinates are defined directly by the law"),
    tie_policy = list(rule = "equality_neutral", declared = TRUE,
      justification = "The state A = B = 1 has genuine equality mass 4/10",
      observed_tie_action = "accept_declared_exact_equality"),
    provenance = list(producer = "Help-page finite-law example",
      artifact_id = "two-site-three-state-law",
      artifact_hash = digest::digest(list(states, masses), algo = "sha256"),
      construction_note = "Complete law; no sampling or rounding",
      created_at = format(Sys.time(), "\%Y-\%m-\%dT\%H:\%M:\%SZ", tz = "UTC")),
    equality = list(basis = "exact_finite_law",
      justification = "Compare all positive-mass states", criterion_classes = NULL),
    finite_law = list(denominator = sum(masses), value_representation = "safe_integer",
      states = lapply(seq_along(states), function(s)
        list(state_id = paste0("state-", s), mass_numerator = masses[s], theta = states[[s]])),
      law_definition = "B is 1; A is 0, 1 or 2 with masses 1/10, 4/10, 5/10",
      not_empirical_posterior_relabeling = TRUE))
  one <- as_postrank_tie_draws(payload)
  postrank_tie_pairwise(one)$t["A", "B", "score"] # 0.4 equality probability

  # K = 2: the bundled complete law retains its own source and declarations.
  two <- read_postrank_tie_draws(system.file("examples", "synthetic-tie-aware.json",
    package = "postrank"))
  two$criterion_ids
  two$equality$criterion_classes
}
}
\seealso{
\code{\link[=validate_postrank_tie_draws]{validate_postrank_tie_draws()}}, \code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}},
\code{\link[=read_postrank_tie_draws]{read_postrank_tie_draws()}},
\code{vignette("m4-ties-and-withholding", package = "postrank")}
}
\concept{tie-aware}
