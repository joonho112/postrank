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
\item{x}{Pairwise comparison probabilities (\code{postrank_pairwise},
\code{postrank_coefficients} or \code{\link[=postrank_probabilities]{postrank_probabilities()}}), or a
\code{postrank_analysis} whose \code{pairwise} component is reused.}

\item{grid}{A \code{\link[=postrank_settings_grid]{postrank_settings_grid()}} data frame or a non-empty list of
\code{\link[=postrank_settings]{postrank_settings()}} objects.}

\item{backend}{Solver to use, \code{"gurobi"} or \code{"highs"}; \code{NULL} uses
\code{getOption("postrank.backend")}, or \code{"gurobi"} if unset.}

\item{control}{Solver controls from \code{\link[=postrank_control]{postrank_control()}} or a named list.}

\item{reference}{Optional \code{setting_id} of the reference row (defaults to the
row with \code{is_reference = TRUE}, or row 1).}

\item{keep_fits}{Logical; whether to retain all \code{postrank_fit} objects in
\code{fits} (defaults to \code{TRUE} when at most 25 rows remain after binding).}
}
\value{
A \code{postrank_sensitivity} list containing \code{grid}, bound \code{settings},
\code{fits} (\code{NULL} when \code{keep_fits = FALSE}), \code{grades} (\verb{n x L} integer
matrix), \code{table} (loss, \code{N}, \code{disclosure_rate}, \code{G}, \code{status}, \code{reason},
bounds, gap and \verb{E_over_N_<k>}), \code{changes} (\code{n_same}, \code{n_new_disclosed},
\code{n_new_withheld}, \code{n_reversed} and \code{change_fraction} relative to
\code{reference_id}), \code{reference_id}, \code{backend}, \code{control}, \code{schema_version},
\code{provenance} and \code{warnings}.
}
\description{
\code{postrank_sensitivity()} solves one grading problem per setting in \code{grid} on
the same pairwise comparison probabilities, and summarizes how grades,
ordered pair counts and pairwise relations change relative to a reference
row.
}
\details{
Solving requires an optimization solver: install the free \code{highs} package
(\code{install.packages("highs")}) and use \code{backend = "highs"} or
\code{options(postrank.backend = "highs")}, or provide a licensed Gurobi
installation (the default). \code{postrank} never switches solvers on its own.

Because changing \code{tau} or \code{weights} changes the loss definition itself,
compare rows by their grades, ordered pair counts and \code{changes} rather than
ranking settings by their \code{risk} numbers. If capping \code{G_max} at the entity
count makes two grid rows identical, duplicates are dropped with a warning.
Rows that finish without a checked grading record \code{NA} loss and \code{changes}
with \code{reason = "no_validated_incumbent"}.
}
\examples{
# Inspect a stored sensitivity grid without running a solver:
sens0 <- postrank_example("tutorial_sensitivity")
sens0$table[, c("setting_id", "risk", "N", "G", "status")]
sens0$changes
\dontshow{if (requireNamespace("highs", quietly = TRUE)) withAutoprint(\{ # examplesIf}
# Solve a two-row grid directly with the optional highs package:
pw <- postrank_pairwise(postrank_toy)
base <- postrank_settings(c(need_A = 0.6, need_B = 0.4), tau = 0.25, G_max = 3L)
sens <- postrank_sensitivity(pw, postrank_settings_grid(base, tau = 0.4),
  backend = "highs", control = postrank_control(time_limit = 10))
sens$table[, c("setting_id", "risk", "N", "G", "status")]
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_settings_grid]{postrank_settings_grid()}}, \code{\link[=postrank_frontier]{postrank_frontier()}},
\code{\link[=postrank_example]{postrank_example()}}
}
\concept{grids}
