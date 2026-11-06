% Please edit documentation in R/theme.R
\name{theme_postrank}
\alias{theme_postrank}
\title{Use the postrank Figure Theme}
\usage{
theme_postrank(base_size = 11, base_family = "")
}
\arguments{
\item{base_size}{Base font size in points; default 11.}

\item{base_family}{Font family passed to ggplot2; the default \code{""} uses
the graphics device's default family.}
}
\value{
A ggplot2 \code{theme} that can be added to a plot.
}
\description{
The theme specifies the typography and white background used in postrank
figures. It extends \code{\link[ggplot2:theme_minimal]{ggplot2::theme_minimal()}} with a light horizontal grid,
axis lines, a left-aligned bold title and a bottom legend.
}
\details{
White plot and panel backgrounds preserve the contrast of the grade
palette. The theme affects presentation only: grades, entity order and
plotted values are retained. Additional ggplot2 theme settings can be
applied subsequently to modify individual figures.
}
\examples{
# A prepared one-criterion probability matrix, with larger text.
p <- postrank_plot_pairwise(pr_tutorial$one)
p + theme_postrank(base_size = 12)
}
\seealso{
\code{\link[=postrank_palette]{postrank_palette()}}, \code{\link[=scale_colour_grade]{scale_colour_grade()}}
}
\concept{visualization}
