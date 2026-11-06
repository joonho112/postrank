% Please edit documentation in R/postrank-analysis.R
\name{postrank}
\alias{postrank}
\title{Choose Posterior Grades and Prepare Their Summaries}
\usage{
postrank(
  x,
  weights = NULL,
  tau = 0.25,
  G_max = 4L,
  ...,
  settings = NULL,
  backend = NULL,
  control = postrank_control(),
  report_card = TRUE,
  fragility = TRUE,
  crossfit = FALSE,
  diagnostics = FALSE,
  level = 0.9
)
}
\arguments{
\item{x}{A validated \code{postrank_draws}, Gaussian/mixture
\code{postrank_coefficients}, or \code{\link[=postrank_probabilities]{postrank_probabilities()}} object.}

\item{weights, tau, G_max}{Decision choices when \code{settings} is not given.
Weights are nonnegative and sum to one, without automatic normalization;
names identify criteria, or unnamed values follow criterion order.
This one-call function supplies weight 1 when it is omitted for one
criterion. The withholding cost satisfies \verb{0 < tau <= 0.5}.
An oversized \code{G_max} is capped at the number of entities.}

\item{...}{Optional \code{q}, \code{exact_G}, \code{objective}, \code{minimax_criteria} and
\code{minimax_refine}, as described in \code{\link[=postrank_settings]{postrank_settings()}}. These modes are
input-dependent: Gaussian/mixture coefficients and supplied probabilities
support only weighted at-most-G problems through this function.}

\item{settings}{A \code{\link[=postrank_settings]{postrank_settings()}} object instead of separate decision
arguments. Explicitly supplying both is a \code{settings_conflict} error.}

\item{backend}{\code{NULL}, \code{"gurobi"} or \code{"highs"}. An explicit choice takes precedence;
otherwise \code{getOption("postrank.backend")} is used, then Gurobi if unset.
Choose HiGHS explicitly for that backend. There is no automatic fallback
after an unavailable, failed or timed-out backend.}

\item{control}{A \code{\link[=postrank_control]{postrank_control()}} object or a named control list.}

\item{report_card, fragility, crossfit, diagnostics}{Logical requests for
additional summaries. Report cards and Monte Carlo fragility are requested
by default; cross-fitting and diagnostics are off by default. See Details
for the input requirements and extra computation.}

\item{level}{Central posterior interval level for a report card, in \verb{(0, 1)}.
Supplied marginal intervals have a fixed level; request that same level.}
}
\value{
A \code{postrank_analysis} list with \code{input}, \code{pairwise}, \code{settings},
\code{control}, \code{problem} and the main \code{fit}. \code{evaluation} is the fixed-action
evaluation of its validated grade. \code{report_card}, \code{fragility}, \code{crossfit}
and \code{diagnostics} contain prepared summaries or \code{NULL}.

Each entry of \code{extras} records \code{requested}, \code{supported}, \code{available},
\code{reason} and \code{condition}, which describe the availability of that component. \code{backend},
\code{timings}, \code{provenance} and \code{warnings} describe the run. \code{metadata} contains
declaration/capability summaries and prepared display data; \code{schema_version}
identifies the analysis structure. Common results are extracted through
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_risk]{get_risk()}}, \code{\link[=get_profile]{get_profile()}} and \link{postrank_tables}.
}
\description{
Entities are assigned to ordered groups by balancing expected
wrong-direction loss against the cost of withholding comparisons under a
supplied posterior. Grade 1 has highest priority. A shared grade withholds
the comparison between the corresponding entities without asserting equality
of their latent targets.
}
\details{
The function prepares pairwise probabilities, constructs and solves the main
problem, and returns the resulting grades, loss and supported summaries. A
posterior representation is supplied externally; the function does not fit a
statistical model. An omitted weight is set to one for a single criterion,
whereas weights must be specified for several criteria. \code{G_max} bounds the
number of grades from above and does not require that the bound be attained.

A time limit can leave a validated grade, or no grade at all.
Without a validated candidate, the fit's status, any usable lower bound
and warnings are retained, while evaluation and grade-dependent extras
are \code{NULL} with reason \code{"no_validated_incumbent"}. A valid report that
withholds every comparison is different: it has one grade and risk tau.
Read the fit's bounds and gap as well as its status; see \code{\link[=postrank_solve]{postrank_solve()}}.

A report card requires marginal posterior intervals, so supplied
probabilities without these summaries permit optimization but cannot produce
a report card. Monte Carlo fragility and cross-fitting require joint
equal-weight IID or MCMC draws; cross-fitting entails two additional
optimizations. For typed coefficients, diagnostics concern conditional
expected risk through \code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}}. Target draws and
simulation diagnostics are unavailable from probability-only inputs.

If an extra fails unexpectedly, a valid main fit is retained, the extra
records \code{reason = "extra_error"} and its condition, and a warning is added.
Core input, backend and solve failures still stop the call. Requested
intervals must be compatible with the source before analysis proceeds.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
    control = postrank_control(time_limit = 10), fragility = FALSE)
  get_grades(one)
  get_risk(one)
}
}
\seealso{
\code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_control]{postrank_control()}}, \code{\link[=postrank_solve]{postrank_solve()}},
\code{\link[=postrank_report_card]{postrank_report_card()}}, \code{\link[=get_risk]{get_risk()}}
}
\concept{decision}
