% Please edit documentation in R/settings.R
\name{postrank_settings}
\alias{postrank_settings}
\title{Choose the Loss and Allowed Grade Reports}
\usage{
postrank_settings(
  weights,
  tau = 0.25,
  G_max = 4L,
  q = NULL,
  exact_G = NULL,
  objective = c("weighted", "minimax"),
  minimax_criteria = NULL,
  minimax_refine = c("weighted", "none"),
  label = NULL
)
}
\arguments{
\item{weights}{Nonnegative finite criterion weights summing to one within
\code{1e-12}; no automatic normalization is performed. Names identify criteria.
Unnamed weights are matched in criterion order when used with an input.
This constructor always requires weights, including weight 1 for one criterion.}

\item{tau}{Cost of a withheld comparison, \verb{0 < tau <= 0.5}.}

\item{G_max}{Positive integer upper bound on occupied grades. Fewer grades
are allowed unless \code{exact_G} is supplied.}

\item{q}{\code{NULL} or a uniquely criterion-named vector of budgets in \verb{[0, 1]}.
Each included criterion requires \code{E_k <= q_k * N}, including criteria with
zero objective weight. At N=0 the count constraint holds, while \code{E_k/N}
is undefined. These are expected-error budgets, not simultaneous guarantees.}

\item{exact_G}{\code{NULL} or the required number of nonempty grades, at most
\code{G_max}. This requirement is never relaxed to fit the input.}

\item{objective}{\code{"weighted"} (default) minimizes the weighted average of
criterion risks; \code{"minimax"} minimizes the largest selected criterion risk.}

\item{minimax_criteria}{\code{NULL} (all criteria) or criterion IDs included in
the minimax objective. Only allowed with \code{objective = "minimax"}.}

\item{minimax_refine}{\code{"weighted"} (default) refines a minimax solution using
the original weighted risk; \code{"none"} keeps the first-stage action.
See \code{\link[=postrank_solve]{postrank_solve()}} for additional zero-weight refinement and its
numerical qualifications. Ignored for weighted problems.}

\item{label}{Optional short display label for grids and figures.}
}
\value{
A \code{postrank_settings} named list with the policy arguments,
\code{label}, \code{weight_sum_tolerance}, \code{schema_version}, \code{provenance} and \code{warnings}.
}
\description{
The settings specify criterion weights, the withholding cost, the maximum
number of grades and optional error budgets or an exact grade count for
\code{\link[=postrank]{postrank()}} or \code{\link[=postrank_problem]{postrank_problem()}}. They define the decision problem
without fitting a posterior or selecting grades. Computation limits are
specified separately by \code{\link[=postrank_control]{postrank_control()}}.
}
\details{
When settings are used with an input, named weights must cover its
criteria and \code{q} must name known criteria. \code{G_max} is capped at the number
of entities, with the requested and resolved caps recorded in the bound
copy's provenance. \code{exact_G} cannot exceed the entity count.

Ordinary draw and exact finite-law pairwise inputs support validated
combinations of weighted/minimax objectives, error budgets and exact
grade counts. Problems built by \code{\link[=postrank_problem]{postrank_problem()}} or \code{\link[=postrank]{postrank()}} from
Gaussian/mixture coefficients or supplied probabilities currently support
weighted at-most-G settings only. Constructing settings
alone does not establish that a particular input supports them.
Display labels and provenance do not alter the decision problem.
}
\examples{
one <- postrank_settings(weights = c(score_A = 1), tau = .2, G_max = 3L)
one$tau
protected <- postrank_settings(weights = c(need_A = .6, need_B = .4),
  tau = .25, G_max = 3L, q = c(need_B = .3))
protected$q
}
\seealso{
\code{\link[=postrank_control]{postrank_control()}}, \code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank]{postrank()}}
}
\concept{settings}
