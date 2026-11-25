% Please edit documentation in R/mdomain-decision.R
\name{postrank_mdomain_decision}
\alias{postrank_mdomain_decision}
\title{Specify Loss and Error Controls for Multidomain Grading}
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
\item{weights}{Domain weights (non-negative with positive total), or \code{NULL}
(the default) for exact equal weights \code{1 / D} on every domain. Named
vectors must match the input's domain order. Rational strings (such as
\code{c("3/5", "2/5")} or \code{c("0.6", "0.4")}) must sum to \code{1} exactly; numeric
weights within \code{1e-12} of \code{1} are normalized in exact stored-binary
rational arithmetic when bound to an input. Zero weights are allowed and
keep protection rows on that domain active.}

\item{tau}{Withholding cost in \verb{(0, 1/2]}, as a scalar or domain-ordered
vector (default \code{"1/10"}).}

\item{scope}{\code{"all_pairs"} (the default), or a named list of symmetric
\verb{n x n} binary (\code{0}/\code{1} or logical) matrices with zero diagonals (when
named, row and column names must match input unit order).}

\item{q}{Optional expected wrong-direction error cap (\code{E / N <= q}) in
\verb{[0, 1]}, as a scalar or domain-ordered vector. \code{NULL} (the default) omits
expected-error constraints unless \code{expected} is supplied.}

\item{t}{Threshold in \verb{[0, 1]} for strict scoped FDP exceedance events
\code{F / N > t}, as a scalar or domain-ordered vector (default \code{"0"}, so any
wrong-direction error \code{F >= 1} counts as an exceedance). Set \code{t = NULL} to
disable convenience joint constraints.}

\item{alpha}{Upper bound in \verb{[0, 1]} on the probability of the union of all
active \code{F / N > t} events across domains and scopes (default \code{"1/20"}).}

\item{expected}{Optional data frame with columns \code{domain_id}, \code{scope_id}, and
\code{q}, overriding \code{q}. Pass a zero-row data frame to disable expected-error
constraints when using a custom \code{scope} catalog.}

\item{joint}{Optional data frame with columns \code{domain_id}, \code{scope_id}, and
\code{t}, overriding \code{t}. Pass a zero-row data frame to disable joint FDP
constraints when using a custom \code{scope} catalog.}
}
\value{
A \code{postrank_mdomain_decision} list storing the validated policy
parameters and exact-rational \code{receipts}.
}
\description{
\code{postrank_mdomain_decision()} builds a decision specification setting domain
weights, withholding costs \code{tau}, pair scopes, expected-error budgets \code{q},
and joint false-discovery-proportion (FDP) exceedance thresholds \code{t} and
\code{alpha} for multidomain profile grading. Domain IDs, unit IDs, and scope
dimensions are checked again when the specification is matched to a
\code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} object. Grade \code{1} is the highest priority within
each domain, and equal grades leave a pair unordered. Requires optional
package \code{gmp}.
}
\details{
Policy numbers (\code{weights}, \code{tau}, \code{q}, \code{t}, \code{alpha}) accept fraction or
decimal strings (\code{"1/10"}, \code{"0.05"}), \code{gmp::bigq} rationals, or finite R
\code{numeric} values. String fractions and decimals keep their exact rational
value, whereas R \code{numeric} values keep their exact IEEE-754 binary floating
value (for instance, numeric \code{0.1} is not \code{1/10}), so strings are recommended
whenever exact decimal or fractional thresholds are intended.

Convenience arguments \code{q} and \code{t} expand to one row per domain on the
full-pair scope (\code{"full"}). If \code{scope} is a custom list of masks that omits a
full-pair mask, supply \code{expected} and \code{joint} explicitly (or zero-row data
frames to disable them).
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
dec <- postrank_mdomain_decision(tau = "1/4", t = "1/10", alpha = "1/20")
dec
summary(dec)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}}, \code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}},
\code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}}, \code{\link[=postrank_mdomain_assess]{postrank_mdomain_assess()}}
}
\concept{multidomain}
