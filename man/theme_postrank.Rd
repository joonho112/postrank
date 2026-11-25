% Please edit documentation in R/theme.R
\name{theme_postrank}
\alias{theme_postrank}
\title{Use the postrank Figure Theme}
\usage{
theme_postrank(base_size = 11, base_family = "")
}
\arguments{
\item{base_size}{Base font size in points (\code{11} by default).}

\item{base_family}{Font family passed to \code{ggplot2} (\code{""} by default, using
the graphics device's default family).}
}
\value{
A \code{ggplot2} \code{theme} object that can be added to a plot with \code{+}.
}
\description{
\code{theme_postrank()} returns the \code{ggplot2} theme used across \code{postrank}
figures, extending \code{\link[ggplot2:theme_minimal]{ggplot2::theme_minimal()}} with white backgrounds, a light
horizontal grid, axis lines and ticks, left-aligned bold titles, and a bottom
legend.
}
\details{
White plot and panel backgrounds (\code{"#FFFFFF"}) keep at least 3:1 contrast
with the grade color ramp from \code{\link[=postrank_palette]{postrank_palette()}}. The theme changes
visual styling only and leaves grades, entity order, and plotted data
untouched; add further \code{\link[ggplot2:theme]{ggplot2::theme()}} calls afterward to customize
individual elements.
}
\examples{
p <- postrank_plot_pairwise(pr_tutorial$one)
p + theme_postrank(base_size = 12)
}
\seealso{
\code{\link[=postrank_palette]{postrank_palette()}}, \code{\link[=scale_colour_grade]{scale_colour_grade()}}
}
\concept{visualization}
