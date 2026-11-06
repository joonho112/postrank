% Please edit documentation in R/theme.R
\name{postrank_palette}
\alias{postrank_palette}
\title{Choose Colors for Grades and Pair Relations}
\usage{
postrank_palette(n, which = c("grade", "relation", "change", "sequential"))
}
\arguments{
\item{n}{Number of grades, from 1 to 64, for \code{which = "grade"}.
Ignored for other palettes and may be omitted for them.}

\item{which}{\code{"grade"}, \code{"relation"}, \code{"change"} or \code{"sequential"}.}
}
\value{
A character vector of R color specifications. Grade colors are
named \code{"1"} through \code{"n"}; relation and change colors are named by state.
The seven-stop sequential vector is unnamed. Some state colors use R
gray names rather than hexadecimal notation.
}
\description{
The palettes define the colors used for grades, relations, relation changes
and probabilities. Grade colors progress from dark for the highest-priority
grade 1 to lighter colors for larger grade numbers.
}
\details{
The grade palette interpolates sRGB channels from \verb{#153653} to \verb{#4F879E}.
Across its supported sizes, luminance increases with grade number and
colors retain at least 3:1 contrast against white. For a single grade,
the sole color is \verb{#153653}.

The relation palette names \code{above}, \code{withheld} and \code{below}, with gray for
withholding. The change palette names \code{unchanged}, \verb{newly disclosed},
\verb{newly withheld} and \code{reversed}; unchanged is light gray, newly withheld
is medium gray. Unchanged pairs may be ordered or withheld. The colored
states use selected Okabe-Ito colors. \code{"sequential"} provides a light-to-dark
Blues ramp used for probabilities. A grade palette supports at most 64
grades; the report-card view uses neutral ink and labels beyond that limit.
}
\examples{
postrank_palette(1)
postrank_palette(4)
postrank_palette(which = "relation")
postrank_palette(which = "change")
}
\seealso{
\code{\link[=scale_colour_grade]{scale_colour_grade()}}, \code{\link[=theme_postrank]{theme_postrank()}}, \code{\link[=postrank_plot_relations]{postrank_plot_relations()}}
}
\concept{visualization}
