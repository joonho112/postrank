% Please edit documentation in R/compare.R
\name{postrank_compare}
\alias{postrank_compare}
\title{Compare Grading Rules on One Posterior and Loss}
\usage{
postrank_compare(
  x,
  ...,
  baselines = c("expected_rank", "composite"),
  means = NULL
)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis} with a validated grade.}

\item{...}{Further \code{postrank_baseline} or \code{postrank_fit} objects, or named
integer grade vectors (named arguments set the method label).}

\item{baselines}{Built-in baselines to add: any of \code{"expected_rank"} and
\code{"composite"}; \code{character()} for none.}

\item{means}{Optional \verb{n x K} posterior mean matrix for the composite.}
}
\value{
A \code{postrank_comparison} object. Its \code{table} includes method, risk,
disclosure, grade count, status, bounds, criterion error profiles,
\code{family_feasible} and \code{feasibility_reason}; \code{grades}, \code{relation_codes} and
\code{relations} use the same unique method IDs. \code{grades} is an entity-by-method
integer matrix and \code{relation_codes} an entity-by-entity-by-method array;
no-action columns are \code{NA}. \code{relations} has one row per non-reference
method, with \code{n_same}, \code{n_new_disclosed}, \code{n_new_withheld}, \code{n_reversed}
and \code{agreement} (the unchanged fraction of all unordered pairs).
\code{reference}, bound \code{settings}, \code{input_identity}, \code{schema_version},
\code{provenance} and \code{warnings} complete the object. Select table columns by
name rather than relying on their positions.

\code{reason} explains an unavailable action; \code{feasibility_reason} explains an
evaluated action outside the declared family. They are separate fields.
Duplicate method labels receive collision-free suffixes shared by all
result components. Use the returned IDs instead of predicting a suffix.
Older saved comparisons without feasibility metadata remain displayable,
with the absence of these records indicated. Checking constraints requires
recreating the comparison; displays do not calculate missing metadata.
}
\description{
Alternative reports are evaluated under a common reference posterior and
loss, and changes in their pairwise relations are recorded. By default,
score-order baselines with optimal cuts are also calculated. With \code{baselines = character()}, evaluation is restricted to the reference and supplied
actions, without optimization of cuts.
}
\details{
The common grade of \code{x} is labelled \code{"joint"}. Built-in
baselines use the same coefficients and policy: expected rank +
optimal cuts and posterior-mean composite + optimal cuts (\code{scales = 1},
\code{centers = 0}), plus any baselines, fits or named grade vectors supplied
through \code{...}. Every action is evaluated under the reference settings, and
relation changes are read from the reference to the compared action.

Each row retains its status and scope: the joint row records solver status,
bounds and gap; an optimal-cuts baseline has \code{status = "optimal"} with its restricted
optimality scope; quantile and supplied-action rows have status \code{"evaluated"}. Baseline
rows have no full-family bound (\code{NA}). A supplied fit without a validated
grade stays as a status row with \code{NA} action metrics and reason
\code{"no_validated_incumbent"}; an impossible requested baseline is
\code{"not_comparable"} with its error code as reason. A supplied fit or baseline
must match the reference policy and input identity. A named grade vector
carries no such policy record and is explicitly evaluated under the
reference loss, even if it was originally chosen for another objective.

A supplied grade may be evaluated even when it is outside the reference
action family. \code{table$family_feasible} records grade-cap, exact-grade and
error-budget feasibility, with codes in \code{feasibility_reason}; no-action
rows have \code{NA}. All rows use the reference fit's recorded feasibility
tolerance for the raw budget residual \code{E_k - q_k * N}. This tolerance is
stored as \code{provenance$family_feasibility_tolerance} (the usual validator
default is used only if the reference receipt lacks it). Grade counts are
checked exactly. This is a numerical check, not a certificate. Outside-family
actions retain their risk and relations, and are marked in print and figures;
they do not support claims about minima over the same feasible family.

Composite scores need posterior means: an explicit \code{means} matrix, the input
of a \code{postrank_analysis}, or the stored means of typed coefficients. A fit
built from empirical pairwise coefficients alone has no means; requesting
the composite baseline then raises \code{missing_posterior_means}.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  fit <- postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25,
    G_max = 3L, backend = "highs", fragility = FALSE)
  cmp <- postrank_compare(fit)
  cmp$table[, c("method", "risk", "disclosure_rate", "G", "status")]
}
}
\seealso{
\code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_sensitivity]{postrank_sensitivity()}}
}
\concept{baselines}
