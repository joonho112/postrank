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
\item{weights}{Criterion weights: nonnegative finite numbers summing to one
within \code{1e-12}. They are never rescaled automatically. Always required by
\code{postrank_settings()}, including weight \code{1} for a single criterion. Names
identify criteria; unnamed weights are matched in criterion order when
combined with an input.}

\item{tau}{Cost of leaving a pair unordered, relative to a cost of 1 for a
wrong-order pair. Must satisfy \verb{0 < tau <= 0.5}.}

\item{G_max}{Largest number of occupied grades, a positive integer. Fewer
grades are allowed unless \code{exact_G} is given.}

\item{q}{\code{NULL} (the default) or a vector of per-criterion expected-error
budgets in \verb{[0, 1]}, uniquely named by criterion. Each named criterion \code{k}
requires \code{E_k <= q_k * N}, where \code{E_k} is the expected number of
wrong-order ordered pairs on criterion \code{k} and \code{N} is the number of
ordered pairs (including criteria with weight 0 in \code{weights}). When
\code{N = 0}, the count constraint \code{0 <= 0} holds while \code{E_k / N} is \code{NA}.
These constrain posterior expected error counts, not simultaneous error
rates.}

\item{exact_G}{\code{NULL} (the default) or a positive integer giving the exact
number of occupied grades required, at most \code{G_max}. Unlike \code{G_max}, this
value is never reduced automatically to fit the number of entities.}

\item{objective}{\code{"weighted"} (the default) minimizes the weighted sum of
criterion losses; \code{"minimax"} minimizes the largest loss among the
selected criteria.}

\item{minimax_criteria}{\code{NULL} (the default, all criteria) or a character
vector of criterion IDs included in the minimax objective. Allowed only
when \code{objective = "minimax"}.}

\item{minimax_refine}{How a minimax solution is refined when
\code{objective = "minimax"}: \code{"weighted"} (the default) minimizes the weighted
loss while keeping the first-stage minimax value, and \code{"none"} keeps the
first-stage grading. Ignored when \code{objective = "weighted"}. See
\code{\link[=postrank_solve]{postrank_solve()}} for additional refinement on zero-weight criteria.}

\item{label}{Optional non-empty string used to label this setting in grids
and figures. Defaults to \code{"tau=<tau>, G_max=<G_max>"}. Does not change the
decision problem.}
}
\value{
A \code{postrank_settings} object, a named list containing:
\itemize{
\item \code{weights}, \code{tau}, \code{G_max}, \code{q}, \code{exact_G}, \code{objective},
\code{minimax_criteria}, \code{minimax_refine} and \code{label}: the validated
settings;
\item \code{weight_sum_tolerance}: \code{1e-12};
\item \code{schema_version}: \code{"1"}, the version of this object's layout;
\item \code{provenance}: package and R versions, creation time, and function name;
\item \code{warnings}: character vector of notes added when the settings are bound
to an input.
}
}
\description{
\code{postrank_settings()} defines the loss function and allowed grade reports
for \code{\link[=postrank]{postrank()}} and \code{\link[=postrank_problem]{postrank_problem()}}: criterion weights, the cost \code{tau}
of leaving a pair unordered, the maximum number of grades \code{G_max}, and
optional per-criterion error budgets \code{q} or an exact grade count \code{exact_G}.
Computation limits are set separately by \code{\link[=postrank_control]{postrank_control()}}.
}
\details{
When settings are combined with an input in \code{\link[=postrank]{postrank()}} or
\code{\link[=postrank_problem]{postrank_problem()}}, named weights must cover all criteria, \code{q} must name
known criteria, and \code{exact_G} cannot exceed the number of entities. If
\code{G_max} exceeds the number of entities, the bound copy reduces \code{G_max} to
that number, records \code{requested_G_max} and \code{resolved_G_max} in
\code{provenance}, and appends a note to \code{warnings}.

Posterior draws and exact finite-law inputs support weighted and minimax
objectives, \code{q} and \code{exact_G}. Normal or mixture posteriors
(\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}, \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}})
and supplied probabilities (\code{\link[=postrank_probabilities]{postrank_probabilities()}}) support only the
weighted objective without \code{q}, \code{exact_G} or \code{minimax_criteria}. Creating
a \code{postrank_settings} object checks the arguments on their own; whether an
input supports them is checked when building or solving the problem.
}
\examples{
one <- postrank_settings(weights = c(score_A = 1), tau = 0.2, G_max = 3L)
one$tau

protected <- postrank_settings(weights = c(need_A = 0.6, need_B = 0.4),
  tau = 0.25, G_max = 3L, q = c(need_B = 0.3))
protected$q
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_control]{postrank_control()}}
}
\concept{settings}
