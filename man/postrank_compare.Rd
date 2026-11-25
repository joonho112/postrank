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
\item{x}{Reference \code{postrank_fit} or \code{postrank_analysis} object with a
checked grading (\code{incumbent_validated = TRUE}).}

\item{...}{Additional \code{postrank_baseline}, \code{postrank_fit} or
\code{postrank_analysis} objects (which must match \code{x}'s input identity and
loss settings), or positive integer grade vectors named by \code{entity_ids}.
Argument names set the method labels.}

\item{baselines}{Character vector of built-in optimal-cut baselines to
include: subset of \code{c("expected_rank", "composite")} (both by default), or
\code{character()} for none.}

\item{means}{Optional \verb{n x K} matrix of posterior means for the
\code{"composite"} baseline when \code{x} is a \code{postrank_fit} built from a bare
\code{postrank_pairwise} object (otherwise \code{missing_posterior_means} is raised).}
}
\value{
A \code{postrank_comparison} object containing:
\itemize{
\item \code{reference}: \code{"joint"};
\item \code{table}: one row per method with \code{method}, \code{risk} (primary loss), \code{N},
\code{disclosure_rate}, \code{G}, \code{status}, \code{optimality_scope}, \code{reason},
\code{risk_lower_bound}, \code{risk_absolute_gap}, \verb{E_over_N_<k>}, \verb{E_over_M_<k>},
\code{family_feasible} and \code{feasibility_reason};
\item \code{relations}: one row per non-reference method with \code{n_same},
\code{n_new_disclosed}, \code{n_new_withheld}, \code{n_reversed} (summing to \code{M}) and
\code{agreement} (\code{n_same / M});
\item \code{grades} (\verb{n x methods} integer matrix) and \code{relation_codes}
(\verb{n x n x methods} array);
\item \code{settings}, \code{input_identity}, \code{schema_version}, \code{provenance} and
\code{warnings}.
}
}
\description{
\code{postrank_compare()} evaluates alternative gradings under the same posterior
probabilities and loss settings as a reference fit or analysis \code{x} (labeled
\code{"joint"}), and counts how many pairwise orderings change relative to
\code{"joint"}. By default it adds optimal-cut baselines on expected rank and on
the posterior-mean composite; no external optimization solver is called.
}
\details{
Built-in \code{"expected_rank"} and \code{"composite"} (\code{scales = 1}, \code{centers = 0})
baselines call \code{\link[=postrank_cuts]{postrank_cuts()}} with \code{rule = "optimal"}; if \code{x} uses
settings that \code{\link[=postrank_cuts]{postrank_cuts()}} does not optimize (such as \code{q} or
\code{"minimax"}), the built-in row is recorded with \code{status = "not_comparable"}
and \code{reason} giving the error code rather than stopping.

Supplied grade vectors are evaluated under \code{x}'s loss even if they violate
\code{G_max}, \code{exact_G} or \code{q} (checked within \code{family_feasibility_tolerance}).
\code{table$family_feasible} (\code{TRUE}/\code{FALSE}/\code{NA}) and \code{feasibility_reason} flag
rows outside \code{x}'s constraint family, whereas \code{reason} explains rows with no
grading (\code{NA} loss). Duplicate method labels receive unique \verb{_2}, \verb{_3}, ...
suffixes across all components.
}
\examples{
toy <- postrank_example("toy_analysis")
cmp <- postrank_compare(toy)
cmp$table[, c("method", "risk", "disclosure_rate", "G", "status")]
cmp$relations
}
\seealso{
\code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_plot_compare]{postrank_plot_compare()}},
\code{\link[=postrank_sensitivity]{postrank_sensitivity()}}
}
\concept{baselines}
