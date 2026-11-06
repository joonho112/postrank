% Please edit documentation in R/theme.R
\name{scale_colour_grade}
\alias{scale_colour_grade}
\alias{scale_color_grade}
\alias{scale_fill_grade}
\title{Keep Grade Colors Consistent Across Views}
\usage{
scale_colour_grade(n_grades = NULL, ...)

scale_color_grade(n_grades = NULL, ...)

scale_fill_grade(n_grades = NULL, ...)
}
\arguments{
\item{n_grades}{Number of grades in the full object, from 1 to 64.
With \code{NULL}, colors follow the discrete levels present in the data;
specify the full count when a displayed subset omits grades.}

\item{...}{Additional arguments passed to \code{\link[ggplot2:discrete_scale]{ggplot2::discrete_scale()}}.
The helper already sets \code{aesthetics}, \code{palette}, \code{drop} and \code{name}, and
sets \code{limits} when \code{n_grades} is supplied; do not pass those arguments again.}
}
\value{
A ggplot2 discrete color or fill scale.
}
\description{
Discrete color and fill scales represent grade membership. The number of
grades in the full report is supplied so that subsets retain the original
grade colors and legend. \code{scale_color_grade()} is the spelling alias of
\code{scale_colour_grade()}; \code{scale_fill_grade()} uses the same palette for fill.
}
\details{
Map grades as discrete labels, for example \code{factor(grade)}. With an explicit
full count, limits are \code{as.character(seq_len(n_grades))} and \code{drop = FALSE}.
Absent grades remain on the scale. The same full count must be used across
views; inferring a count from a displayed subset can assign different colors.
Grade 1 has highest priority. Equal colors indicate shared grade membership,
which withholds comparisons rather than asserting target equality.
}
\examples{
# Grade 2 is absent from the display, but keeps its place in the full scale.
d <- data.frame(entity = c("A", "C"), value = c(2, 1), grade = factor(c(1, 3)))
ggplot2::ggplot(d, ggplot2::aes(value, entity, colour = grade)) +
  ggplot2::geom_point(size = 3) + scale_colour_grade(n_grades = 3) +
  theme_postrank()
}
\seealso{
\code{\link[=postrank_palette]{postrank_palette()}}, \code{\link[=theme_postrank]{theme_postrank()}}
}
\concept{visualization}
