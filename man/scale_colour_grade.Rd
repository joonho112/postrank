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
\item{n_grades}{Integer number of grades in the full grading (\code{1} to \code{64}),
or \code{NULL} (the default) to size the palette from the discrete levels
present in the plotted data.}

\item{...}{Additional arguments passed to \code{\link[ggplot2:discrete_scale]{ggplot2::discrete_scale()}}. Do not
pass \code{aesthetics}, \code{palette}, \code{drop}, \code{name}, or (when \code{n_grades} is
supplied) \code{limits}, which are set by the scale helper.}
}
\value{
A \code{ggplot2} discrete color or fill scale.
}
\description{
\code{scale_colour_grade()}, \code{scale_color_grade()}, and \code{scale_fill_grade()}
construct discrete \code{ggplot2} color and fill scales for grade membership using
\code{\link[=postrank_palette]{postrank_palette()}}. Passing the full report's grade count \code{n_grades} keeps
grade colors and legend entries identical when plotting a subset of entities
that omits one or more grades.
}
\details{
Map grades as discrete values such as \code{factor(grade)}. When \code{n_grades} is
supplied, the scale fixes \code{limits = as.character(seq_len(n_grades))} and
\code{drop = FALSE} so missing grades retain their slot on the color ramp. Grade
\code{1} has highest priority; shared color indicates shared grade membership
(withheld ordering, not equal targets).
}
\examples{
d <- data.frame(entity = c("A", "C"), value = c(2, 1), grade = factor(c(1, 3)))
ggplot2::ggplot(d, ggplot2::aes(value, entity, colour = grade)) +
  ggplot2::geom_point(size = 3) +
  scale_colour_grade(n_grades = 3) +
  theme_postrank()
}
\seealso{
\code{\link[=postrank_palette]{postrank_palette()}}, \code{\link[=theme_postrank]{theme_postrank()}}
}
\concept{visualization}
