% Please edit documentation in R/mdomain-plot.R
\name{postrank_plot_mdomain}
\alias{postrank_plot_mdomain}
\title{Plot a Multidomain Grade Profile}
\usage{
postrank_plot_mdomain(
  x,
  view = c("grades", "cells", "pair"),
  units = NULL,
  domains = NULL,
  ...
)
}
\arguments{
\item{x}{A \code{postrank_mdomain_evaluation} or \code{postrank_mdomain_fit} (for a
\code{postrank_mdomain_assessment}, pass \code{x$evaluation}).}

\item{view}{One of \code{"grades"} (the default), \code{"cells"}, or \code{"pair"}.}

\item{units}{Optional character vector of distinct unit IDs from \code{x} in the
desired display order. Required with exactly two distinct unit IDs when
\code{view = "pair"}.}

\item{domains}{Optional character vector of distinct domain IDs from \code{x} in
the desired display order. Required with one or two domain IDs when
\code{view = "cells"} and \code{x} has more than two domains.}

\item{...}{Optional named display arguments chosen from \code{title} (character
scalar or \code{NULL}), \code{unit_labels} (named character vector keyed by raw unit
IDs), \code{domain_labels} (named character vector keyed by raw domain IDs), and
\code{base_size} (positive finite number, default \code{11}). Passing any other
argument stops with an error.}
}
\value{
A \code{ggplot} object with underlying plot data in \verb{$data} and a
\code{"postrank_mdomain"} attribute containing \code{view}, \code{unit_ids}, \code{domain_ids},
\code{original_units}, \code{original_pairs}, full \code{caption} text, and
\code{uses_stored_card = TRUE}.
}
\description{
\code{postrank_plot_mdomain()} plots a stored multidomain report card as a
unit-by-domain grade table (\code{view = "grades"}), a one- or two-domain cell
occupancy chart (\code{view = "cells"}), or a domain-by-domain directional
comparison of two units (\code{view = "pair"}), without re-evaluating or searching
candidates.
}
\details{
Within each domain, grade \code{1} has highest priority and equal grades leave a
pair unordered rather than claiming equal targets:
\itemize{
\item \code{view = "grades"}: draws a unit-by-domain tile grid labeled with
integer grades (\code{scale_fill_grade()} up to 64 grades); any domain with a
single occupied grade (\code{K_d = 1}) is shaded light gray and marked
\code{"(all withheld)"}.
\item \code{view = "cells"}: counts displayed units in each grade (bar chart for
one domain) or \verb{(grade_x, grade_y)} cell (tile chart with reversed y-axis
for two domains). Cell coordinates locate per-domain grade combinations
without defining a total order across cells, and counts sum over any
domains omitted from \code{domains}.
\item \code{view = "pair"}: compares \code{units[1]} against \code{units[2]} on each
displayed domain, marking \code{"+"} (\code{"Favors <units[1]>"}), \code{"-"}
(\code{"Favors <units[2]>"}), or \code{"0"} (\code{"Direction withheld"}, or
\code{"Same modeled target (direction withheld)"} when the pair shares a
structural equality class on that domain), and notes in the subtitle when
opposite directions appear across domains.
}
Figure captions report the original full-card risk \code{risk} and joint
exceedance probability \code{J} even when a subset of \code{units} or \code{domains} is
displayed.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
G <- matrix(
  c(1L, 1L, 2L, 3L, 1L, 2L),
  nrow = 3L,
  ncol = 2L,
  dimnames = list(inp$unit_ids, inp$domain_ids)
)
ev <- postrank_mdomain_evaluate(inp, G)
postrank_plot_mdomain(ev, view = "grades")
postrank_plot_mdomain(ev, view = "cells", domains = c("need_A", "need_B"))
postrank_plot_mdomain(ev, view = "pair", units = c("001", "site-B"))
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}}, \code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}},
\code{\link[=postrank_mdomain_grades]{postrank_mdomain_grades()}}, \code{\link[=theme_postrank]{theme_postrank()}}
}
\concept{multidomain}
