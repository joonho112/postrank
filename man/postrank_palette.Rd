% Please edit documentation in R/theme.R
\name{postrank_palette}
\alias{postrank_palette}
\title{Choose Colors for Grades and Pair Relations}
\usage{
postrank_palette(n, which = c("grade", "relation", "change", "sequential"))
}
\arguments{
\item{n}{Integer number of grades from \code{1} to \code{64} when \code{which = "grade"}.
Ignored (and may be omitted) for the other palettes.}

\item{which}{Palette to return: \code{"grade"} (the default), \code{"relation"},
\code{"change"}, or \code{"sequential"}.}
}
\value{
A character vector of R color specifications (hexadecimal strings and,
for neutral states, R gray names):
\itemize{
\item \code{"grade"}: named \code{"1"} through \code{as.character(n)}.
\item \code{"relation"}: named \code{"above"}, \code{"withheld"}, and \code{"below"}.
\item \code{"change"}: named \code{"unchanged"}, \code{"newly disclosed"},
\code{"newly withheld"}, and \code{"reversed"}.
\item \code{"sequential"}: unnamed seven-stop light-to-dark blue ramp.
}
}
\description{
\code{postrank_palette()} returns the color vectors used in \code{postrank} figures for
grades, pair relations, relation changes, and directional-error
probabilities. Grade colors run from dark blue (\code{"#153653"}) for the
highest-priority grade \code{1} to lighter blue-teal (\code{"#4F879E"}) for larger
grade numbers.
}
\details{
For \code{which = "grade"}, sRGB channels are linearly interpolated from
\code{"#153653"} to \code{"#4F879E"} (\code{"#153653"} when \code{n = 1}), giving strictly
increasing luminance with grade number and at least 3:1 contrast against
white across \verb{1..64}. Values of \code{n} outside \verb{1..64} stop with an error;
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}} switches to neutral dark gray above 64 grades.

In \code{"relation"}, \code{"above"} (\code{"#0072B2"}) and \code{"below"} (\code{"#E69F00"}) use
Okabe-Ito colors and \code{"withheld"} uses \code{"grey80"}. In \code{"change"},
\code{"unchanged"} (\code{"grey92"}, covering pairs ordered the same way or withheld in
both gradings) is light gray, \code{"newly withheld"} (\code{"#999999"}) is medium
gray, \code{"newly disclosed"} is \code{"#0072B2"}, and \code{"reversed"} is \code{"#D55E00"}.
\code{"sequential"} runs from \code{"#EFF3FF"} to \code{"#084594"} for probability heat
maps.
}
\examples{
postrank_palette(1)
postrank_palette(4)
postrank_palette(which = "relation")
postrank_palette(which = "change")
}
\seealso{
\code{\link[=scale_colour_grade]{scale_colour_grade()}}, \code{\link[=theme_postrank]{theme_postrank()}},
\code{\link[=postrank_plot_relations]{postrank_plot_relations()}}
}
\concept{visualization}
