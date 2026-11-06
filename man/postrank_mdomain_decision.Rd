% Please edit documentation in R/mdomain-decision.R
\name{postrank_mdomain_decision}
\alias{postrank_mdomain_decision}
\title{Specify a Multidomain Reporting Decision}
\usage{
postrank_mdomain_decision(
  weights = NULL,
  tau = "1/10",
  scope = "all_pairs",
  q = NULL,
  t = "0",
  alpha = "1/20",
  expected = NULL,
  joint = NULL
)
}
\arguments{
\item{weights}{Domain weights, or \code{NULL} for exactly equal weights. Named
vectors must follow the input's domain order. Numeric weights whose total
is within the core tolerance are normalized using their exact stored binary
values; rational text weights must sum to exactly one. Zero weights are
permitted and do not disable protection rows.}

\item{tau}{Tie loss in \verb{(0, 1/2]}, as a scalar or a domain vector.}

\item{scope}{\code{"all_pairs"}, or a named list of symmetric binary masks with
zero diagonals. Named masks must follow the input's unit order.}

\item{q}{Expected-error guard in \verb{[0, 1]}, as a scalar or domain vector.
\code{NULL} omits these guards.}

\item{t}{Joint exceedance threshold in \verb{[0, 1]}, as a scalar or domain
vector. \code{NULL} disables joint guards. An exceedance is strict, \code{F/N > t}.}

\item{alpha}{Joint-event probability limit in \verb{[0, 1]}.}

\item{expected}{Explicit rows with \code{domain_id}, \code{scope_id}, and \code{q} columns.
These override the convenience \code{q} rows. An empty data frame disables them.}

\item{joint}{Explicit rows with \code{domain_id}, \code{scope_id}, and \code{t} columns.
These override the convenience \code{t} rows. An empty data frame disables them.}
}
\value{
A \code{postrank_mdomain_decision} recipe. Validation does not certify the
scientific or sampling provenance of the input.
}
\description{
Creates a decision recipe. Domain and unit identities, mask dimensions, and
protection rows are checked again when the recipe is bound to an input.
Smaller grade labels report higher priority; a grade tie withholds direction.
}
\details{
Convenience rows use a full-pair mask. A custom mask catalog without
a full-pair mask requires explicit rows, including an empty data frame to
disable a guard. Exact decimal/fraction strings retain their rational value;
numeric values retain their stored binary value. Joint guards default to
\code{t = "0"}, with \code{alpha = "1/20"}; expected guards default to disabled.
}
\concept{multidomain}
