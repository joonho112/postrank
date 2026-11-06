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

\item{show}{\code{"E_over_N"} for expected errors per disclosed pair;
\code{"E_over_M"} for expected errors per all unordered pairs; or \code{"risk"}
for criterion risk, including the cost of withholding.}

\item{budgets}{Logical; show available error-budget ticks for
\code{show = "E_over_N"}.}

\item{...}{Unused.}

\item{criterion_labels}{Optional partial named character vector mapping
raw criterion IDs to display names. Text is wrapped; IDs and numerical
plot data remain unchanged. Supply this argument by name.}
}
\value{
A \code{ggplot} object. Without a validated incumbent, it is a status
panel. When \code{N = 0}, the \code{E_over_N} view explains that the ratio is
undefined and omits the corresponding point.
}
\description{
The figure displays criterion-specific expected directional-error rates or
risks for the stored grading. Each criterion is represented by one point.
Point area indicates a positive criterion weight; zero-weight criteria are
retained as small hollow points.
}
\details{
\code{E_k} is the stored expected number of wrong-direction comparisons on
criterion \code{k}, \code{N} counts disclosed pairs, and \code{M = choose(n, 2)} counts
all unordered pairs. These are posterior expectations for the selected
action, not observed error counts. Withholding is not a claim of equality.

For \code{E_over_N}, a declared budget \code{q_k} appears as a tick connected to its
criterion's point. For \code{risk}, a dashed line marks \code{tau}, the ordinary
all-withheld risk. In minimax mode, orange rings identify criteria attaining
the largest criterion risk. All axes begin at zero. The figure reads the
stored evaluation without selecting a new grade or recomputing its risk.
}
\examples{
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
postrank_plot_profile(one)
two <- load_or_compute("tutorial_two")
postrank_plot_profile(two, show = "E_over_M",
  criterion_labels = c(score_A = "Score A", score_B = "Score B"))
}
\seealso{
\code{\link[=get_profile]{get_profile()}}, \code{\link[=postrank_plot_data]{postrank_plot_data()}}, \code{\link[=postrank_plot_frontier]{postrank_plot_frontier()}}
}
\concept{visualization}
