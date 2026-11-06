% Please edit documentation in R/sensitivity.R
\name{postrank_settings_grid}
\alias{postrank_settings_grid}
\title{Build a One-at-a-Time or Full Settings Grid}
\usage{
postrank_settings_grid(
  base,
  tau = NULL,
  G_max = NULL,
  weights = NULL,
  q = NULL,
  design = c("one_at_a_time", "full")
)
}
\arguments{
\item{base}{A \code{\link[=postrank_settings]{postrank_settings()}} object.}

\item{tau}{Optional numeric vector of tau values.}

\item{G_max}{Optional integer vector of grade caps.}

\item{weights}{Optional named list of weight profiles (named numeric
vectors); the unique nonblank list names label the rows.}

\item{q}{Optional uniquely criterion-named list of numeric error-budget
vectors.}

\item{design}{\code{"one_at_a_time"} (default) or \code{"full"}.}
}
\value{
A data frame with \code{setting_id}, \code{label}, \code{tau}, \code{G_max}, \code{exact_G},
\code{objective}, \code{minimax_refine}, \verb{w_<k>}, \verb{q_<k>}, \code{is_reference} and the
\code{settings} list-column.
}
\description{
Settings are constructed for \code{\link[=postrank_sensitivity]{postrank_sensitivity()}} without optimization.
The default \code{design = "one_at_a_time"} varies each supplied axis separately
around \code{base}, flags the base row with \code{is_reference = TRUE}, and removes
rows equal to the base or to each other. With \code{design = "full"}, the
Cartesian grid is constructed and the row equal to \code{base} is flagged as the
reference. The complete \code{\link[=postrank_settings]{postrank_settings()}} object in the \code{settings}
list-column defines each row; the scalar columns provide its displayed
summary.
}
\details{
Profile names such as \code{base} are ordinary display labels, not reserved keys.
Different policies receive distinct labels; a colliding user label is
suffixed with its setting ID. Invalid fractional grade caps are refused.
}
\examples{
base <- postrank_settings(c(need_A = .6, need_B = .4), tau = .25, G_max = 3L)
g <- postrank_settings_grid(base, tau = c(.1, .35), G_max = 2L)
g[, c("setting_id", "label", "tau", "G_max", "is_reference")]
}
\seealso{
\code{\link[=postrank_sensitivity]{postrank_sensitivity()}}
}
\concept{grids}
