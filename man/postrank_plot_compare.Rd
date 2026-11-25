% Please edit documentation in R/plots-compare.R
\name{postrank_plot_compare}
\alias{postrank_plot_compare}
\title{Plot Grading Rules Evaluated Under the Same Loss}
\usage{
postrank_plot_compare(x, view = c("summary", "relations"), ..., ncol = NULL)
}
\arguments{
\item{x}{A \code{postrank_comparison} from \code{\link[=postrank_compare]{postrank_compare()}}.}

\item{view}{\code{"summary"} (the default) for risk, disclosure, and grade-count
panels, or \code{"relations"} for stacked counts of pairwise relation changes
from \code{x$reference} to each other rule.}

\item{...}{Unused; unnamed extra arguments are ignored. Pass \code{ncol} by name.}

\item{ncol}{Positive integer number of facet columns in \code{view = "summary"},
or \code{NULL} (the default, which uses 3 columns). Use \code{ncol = 1} for narrow
pages. Ignored when \code{view = "relations"}.}
}
\value{
A \code{ggplot} object. Rules without a finite risk (\code{!is.finite(risk)})
keep their y-axis labels, statuses, and reasons in the subtitle while their
points and bars are omitted. When \code{view = "relations"} and no compared rule
has grades, returns an empty status \code{ggplot} stating why.
}
\description{
\code{postrank_plot_compare()} plots stored grading rules from
\code{\link[=postrank_compare]{postrank_compare()}} side by side on risk, disclosure rate (\code{N / M}), and
grade count (\code{G}), or by pairwise relation changes relative to the reference
rule. All risk values come from \code{x}'s shared posterior and loss settings
without solving or evaluating new gradings.
}
\details{
In \code{view = "summary"}, the reference rule (\code{x$reference}) is drawn as a
filled circle and other rules as hollow circles; a vertical tick marks any
stored \code{risk_lower_bound}. Y-axis labels show the rule name, solver status
(\code{"optimal (numerical)"} for full-family optimal solves), optimization scope
(\code{"full family"}, \code{"fixed score order"}, or \code{"supplied action"}), and any
absolute solver risk gap. A score-order baseline searches only contiguous
cuts of its fixed score order rather than all gradings, so it has no
full-family lower bound.

In \code{view = "relations"}, each bar covers all \code{M = choose(n, 2)} unordered
pairs across \code{"unchanged"}, \code{"newly disclosed"}, \code{"newly withheld"}, and
\code{"reversed"} relative to \code{x$reference}; \code{"unchanged"} includes pairs left
unordered by both rules.

Rules recorded with \code{family_feasible == FALSE} (for example, exceeding
\code{G_max} or violating an error budget \code{q_k}) are tagged \code{"[outside family]"}
on the y-axis and listed in the subtitle: their fixed-action risks are
evaluated under the same loss, but they are outside the constrained feasible
set. If \code{family_feasible} is absent from an older comparison object, the
subtitle notes that constraint checks require rebuilding \code{x} with
\code{\link[=postrank_compare]{postrank_compare()}}.
}
\examples{
comparison <- postrank_example("comparison_30x3_tau35")
postrank_plot_compare(comparison, ncol = 1)
postrank_plot_compare(comparison, view = "relations")
}
\seealso{
\code{\link[=postrank_compare]{postrank_compare()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}},
\code{\link[=postrank_plot_data]{postrank_plot_data()}}
}
\concept{visualization}
