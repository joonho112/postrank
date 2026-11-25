% Please edit documentation in R/mdomain-solve.R
\name{postrank_mdomain_solve}
\alias{postrank_mdomain_solve}
\title{Select a Multidomain Grade Profile from a Candidate Family}
\usage{
postrank_mdomain_solve(input, family, decision = NULL, max_actions = 100000L)
}
\arguments{
\item{input}{The validated \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} object used to build
\code{family}.}

\item{family}{A \code{\link[=postrank_mdomain_family]{postrank_mdomain_family()}} object built on \code{input}.}

\item{decision}{A \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} specification, or \code{NULL} (the
default) to use the default specification from \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}}.}

\item{max_actions}{Positive integer cap (\code{100000L} by default) on the exact
Cartesian product size. If \code{family} has more than \code{max_actions} profiles,
\code{postrank_mdomain_solve()} stops with an error before enumeration rather
than truncating the search.}
}
\value{
A \code{postrank_mdomain_fit} list containing \code{grades} (selected \verb{n x D}
integer grade matrix), \code{evaluation} (\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}} output
for \code{selected_id}), \code{candidate_table} (one row per examined profile),
\code{optimizer_ids}, \code{optimizer_count}, \code{selected_id}, \code{solution}, \code{input},
\code{family}, \code{decision} (matched to \code{input}), \code{status}, \code{search_scope},
\code{assurance}, and \code{receipts} (validation and hash records).
}
\description{
\code{postrank_mdomain_solve()} evaluates every grade profile in the Cartesian
product of a \code{\link[=postrank_mdomain_family]{postrank_mdomain_family()}} and selects the feasible profile(s)
minimizing domain-weighted expected loss subject to expected-error budgets
and direct joint false-discovery-proportion (FDP) exceedance limits. Every
tied minimizer in the candidate set is retained. Requires optional package
\code{gmp} and runs no external MIP solver.
}
\details{
When multiple feasible candidates tie for the minimum loss, \code{optimizer_ids}
lists all of them (\code{status$optimum = "tied"}) and \code{selected_id} picks the
first in lexicographic order of the renumbered (\verb{1..K_d}) grade columns
without adding a secondary tie-breaking objective.

Optimality holds only within the declared candidate family
(\code{status$optimality = "candidate_restricted"}); examining the entire
Cartesian product of \code{family} does not establish optimality over all possible
multidomain grade matrices or unrestricted ordered partitions. Exact rational
(\code{gmp}) arithmetic over finite draws evaluates their empirical distribution
without rounding error rather than certifying feasibility or optimality under
an intended continuous posterior. If an active joint constraint requires
cross-domain coupling that \code{input} does not supply, the call stops with a
capability error rather than pairing separate domain rows.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
dec <- postrank_mdomain_decision(tau = "1/4", t = "1/2", alpha = "1/5")
fam <- postrank_mdomain_family(
  inp,
  order = "posterior_mean",
  cuts = list(need_A = 1:2, need_B = 1:2),
  max_grades = 3L
)
fit <- postrank_mdomain_solve(inp, fam, decision = dec)
fit
postrank_mdomain_grades(fit)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_family]{postrank_mdomain_family()}}, \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}},
\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}}, \code{\link[=postrank_mdomain_grades]{postrank_mdomain_grades()}}
}
\concept{multidomain}
