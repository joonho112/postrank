% Please edit documentation in R/sensitivity.R
\name{postrank_sensitivity}
\alias{postrank_sensitivity}
\title{Re-Solve a Decision Problem Over a Settings Grid}
\usage{
postrank_sensitivity(
  x,
  grid,
  backend = NULL,
  control = postrank_control(),
  reference = NULL,
  keep_fits = NULL
)
}
\arguments{
\item{x}{A \code{postrank_pairwise}, \code{postrank_coefficients}, or
\code{postrank_probabilities} object accepted by \code{\link[=postrank_problem]{postrank_problem()}}, or a
\code{postrank_analysis} whose coefficients are reused.}

\item{grid}{A \code{\link[=postrank_settings_grid]{postrank_settings_grid()}} data frame or a list of
\code{\link[=postrank_settings]{postrank_settings()}}.}

\item{backend}{\code{NULL} (option, then Gurobi) or \code{"gurobi"}/\code{"highs"}.}

\item{control}{A \code{\link[=postrank_control]{postrank_control()}} object or bare control list.}

\item{reference}{Optional \code{setting_id} of the reference row (default: the
row flagged \code{is_reference}).}

\item{keep_fits}{Keep every fit (\code{TRUE} by default for at most 25 rows).}
}
\value{
A \code{postrank_sensitivity} list. \code{table} contains action metrics and
solver bounds, \code{changes} counts pair relations newly disclosed, newly
withheld or reversed against the reference, and \code{grades} stores entity
grades by setting. Changes compare relations, not numeric label differences.
\code{grid} and \code{settings} retain the bound policies; \code{fits} holds the full fits
when requested. \code{reference_id}, \code{backend}, \code{control}, \code{schema_version},
\code{provenance} and \code{warnings} record the calculation.
}
\description{
A separate optimization is performed for each distinct policy using the same
posterior coefficients. A working optimizer backend is required.
}
\details{
One problem is solved per grid row using the same coefficients. The
backend is resolved once and recorded. Each row reports risk, disclosure,
grade count, status, bounds and relation changes relative to the reference
row. Rows without a validated grade retain their status, reason and bounds,
with \code{NA} action metrics and changes; they are not replaced by all-withheld
actions. Grade caps exceeding the entity count are reduced when bound to the
input. Rows that coincide only after this reduction are removed with a
warning. Since raw risks are comparable only under a common loss, the table
reports settings separately without ranking them.
}
\examples{
if (requireNamespace("highs", quietly = TRUE)) {
  pw <- postrank_pairwise(postrank_toy)
  base <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
  sens <- postrank_sensitivity(pw, postrank_settings_grid(base, tau = .4), backend = "highs",
    control = postrank_control(time_limit = 10))
  sens$table[, c("risk", "N", "G", "status")]
}
}
\seealso{
\code{\link[=postrank_settings_grid]{postrank_settings_grid()}}, \code{\link[=postrank_frontier]{postrank_frontier()}}
}
\concept{grids}
