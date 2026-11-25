% Please edit documentation in R/plots-profile.R
\name{postrank_plot_profile}
\alias{postrank_plot_profile}
\title{Plot Criterion-Wise Error Rates or Risk}
\usage{
postrank_plot_profile(
  x,
  show = c("E_over_N", "E_over_M", "risk"),
  budgets = TRUE,
  ...,
  criterion_labels = NULL
)
}
\arguments{
\item{x}{A \code{postrank_fit} or \code{postrank_analysis} with a stored evaluation.}

\item{show}{Metric drawn on the horizontal axis: \code{"E_over_N"} (the default)
for expected wrong-direction errors per disclosed pair (\code{E_k / N}),
\code{"E_over_M"} for expected wrong-direction errors per unordered pair
(\code{E_k / M}), or \code{"risk"} for criterion risk \code{R_k} (including the
withholding cost \code{tau} on withheld pairs).}

\item{budgets}{Logical scalar (\code{TRUE} by default). When \code{TRUE} and
\code{show = "E_over_N"}, draws a vertical tick at each declared error budget
\code{q_k} and connects it to that criterion's point.}

\item{...}{Unused; unnamed extra arguments are ignored. Pass
\code{criterion_labels} by name.}

\item{criterion_labels}{Optional named character vector mapping raw criterion
IDs to display labels. Unmapped IDs keep their raw IDs, and labels are
wrapped to 22 characters per line; underlying IDs and numeric values in
\verb{$data} are unchanged.}
}
\value{
A \code{ggplot} object whose \verb{$data} table matches \code{\link[=get_profile]{get_profile()}} with an
added \code{value} column for the selected \code{show} metric. If \code{x} has no checked
grading, returns an empty status \code{ggplot} stating why. When
\code{show = "E_over_N"} and \code{N = 0} (every pair is withheld), returns a blank
\verb{[0, 1]} panel stating that \code{E/N} is undefined rather than plotting zero.
}
\description{
\code{postrank_plot_profile()} plots the posterior expected directional-error rate
or criterion risk for each criterion in a stored grading, with one row per
criterion. In plot text and tables, \code{disclosed} means pairs placed in
different grades (ordered), \code{withheld} means pairs placed in the same grade
(left unordered), and \code{risk} means posterior expected loss.
}
\details{
\code{E_k} is the posterior expected number of wrong-direction comparisons on
criterion \code{k}, \code{N} is the number of disclosed pairs, and \code{M = choose(n, 2)}
is the number of unordered entity pairs. Points for positive-weight criteria
scale in area with \code{weight} (the size legend is omitted when there is only
one criterion); zero-weight criteria with finite values appear as small
hollow circles.

When \code{show = "risk"}, a vertical dashed line marks \code{tau}, the risk of placing
all entities in a single shared grade. When the problem uses
\code{objective = "minimax"}, orange rings mark criteria attaining the maximum
criterion risk (\code{is_minimax_max}). Horizontal axes always start at zero. The
function reads stored evaluation summaries without solving or recomputing
risks.
}
\examples{
one <- postrank_example("tutorial_one")
postrank_plot_profile(one)

two <- postrank_example("tutorial_two")
postrank_plot_profile(
  two,
  show = "E_over_M",
  criterion_labels = c(score_A = "Score A", score_B = "Score B")
)
}
\seealso{
\code{\link[=get_profile]{get_profile()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}}, \code{\link[=postrank_plot_frontier]{postrank_plot_frontier()}}
}
\concept{visualization}
