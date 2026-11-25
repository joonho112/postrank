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
\item{base}{Reference \code{\link[=postrank_settings]{postrank_settings()}} object.}

\item{tau}{Optional numeric vector of \code{tau} values in \verb{(0, 0.5]}.}

\item{G_max}{Optional positive integer vector of maximum grade counts
(non-integers are rejected rather than truncated).}

\item{weights}{Optional named list of criterion weight vectors, with unique
non-blank list names used as row labels.}

\item{q}{Optional list named by criteria in \code{base$weights}, where each
element is a numeric vector of error budgets in \verb{[0, 1]} (\code{NA} is not
allowed).}

\item{design}{\code{"one_at_a_time"} (the default) or \code{"full"}.}
}
\value{
A data frame with columns \code{setting_id}, \code{label}, \code{tau}, \code{G_max},
\code{exact_G}, \code{objective}, \code{minimax_refine}, \verb{w_<k>}, \verb{q_<k>}, \code{is_reference}
and list-column \code{settings} (holding the full \code{postrank_settings} objects).
}
\description{
\code{postrank_settings_grid()} builds a table of \code{\link[=postrank_settings]{postrank_settings()}} rows
around a reference setting \code{base} for \code{\link[=postrank_sensitivity]{postrank_sensitivity()}}, without
running a solver. With \code{design = "one_at_a_time"} (the default), each
supplied axis is varied separately while holding the other axes at \code{base};
with \code{design = "full"}, all combinations of \code{base} and the supplied axis
values are formed. Duplicate policies are removed, and the \code{base} policy sits
in row 1 (\code{setting_id = "S01"}, \code{is_reference = TRUE}).
}
\details{
Each row's optimization settings come from \code{settings[[i]]}; scalar columns
are display summaries checked for agreement by \code{\link[=postrank_sensitivity]{postrank_sensitivity()}}.
Colliding display labels receive a \code{" [<setting_id>]"} suffix.
}
\examples{
base <- postrank_settings(c(need_A = 0.6, need_B = 0.4), tau = 0.25, G_max = 3L)
g <- postrank_settings_grid(base, tau = c(0.1, 0.35), G_max = 2L)
g[, c("setting_id", "label", "tau", "G_max", "is_reference")]
}
\seealso{
\code{\link[=postrank_sensitivity]{postrank_sensitivity()}}, \code{\link[=postrank_settings]{postrank_settings()}}
}
\concept{grids}
