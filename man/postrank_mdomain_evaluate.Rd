% Please edit documentation in R/mdomain-evaluate.R
\name{postrank_mdomain_evaluate}
\alias{postrank_mdomain_evaluate}
\title{Evaluate a Fixed Multidomain Grade Profile}
\usage{
postrank_mdomain_evaluate(
  input,
  grades,
  decision = NULL,
  mode = c("joint", "expected"),
  keep_traces = TRUE
)
}
\arguments{
\item{input}{A validated \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} object.}

\item{grades}{Finite numeric \verb{n x D} matrix with row and column names in
\code{input}'s exact unit and domain order (\code{1} = highest priority within each
domain). Occupied grade labels on each domain are renumbered to \verb{1..K_d}
without changing pairwise orderings or ties; equal grades leave a pair
unordered without claiming equal targets, and splitting a structural
equality class stops with an error.}

\item{decision}{A \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} specification, or \code{NULL} (the
default) to use the default specification from \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}}.}

\item{mode}{\code{"joint"} (the default, evaluating both expected quantities and
the joint union exceedance probability \code{J}) or \code{"expected"} (evaluating
expected quantities only, leaving \code{J}, \code{joint_feasible}, and
\code{feasible_for_represented_measure} as \code{NA}, even when joint constraints are
disabled).}

\item{keep_traces}{Logical scalar (\code{TRUE} by default). When \code{TRUE}, retains
per-state error counts and joint event indicators in \code{evaluation}.}
}
\value{
A \code{postrank_mdomain_evaluation} list containing \code{input}, \code{action},
\code{decision} (matched to \code{input}), renumbered (\verb{1..K_d}) \verb{n x D} integer
\code{grades}, \code{mode}, \code{M = n * (n - 1) / 2}, \code{risk} and \code{risk_exact}, \code{J} and
\code{J_exact}, \code{domain_table}, \code{scope_table}, \code{expected_constraints},
\code{event_table} (\code{NULL} in \code{"expected"} mode), \code{mean_feasible},
\code{joint_feasible}, \code{feasible_for_represented_measure}, \code{status}, \code{assurance},
and \code{receipts} (validation and hash records, including
\code{validation_spec_hashes} for \code{\link[=postrank_mdomain_assess]{postrank_mdomain_assess()}}).
}
\description{
\code{postrank_mdomain_evaluate()} computes domain-weighted expected loss and,
when \code{mode = "joint"}, the probability of the union of strict scoped
false-discovery-proportion (FDP) exceedances for a fixed multidomain grade
matrix without searching candidates. Requires optional package \code{gmp}.
}
\details{
Expected loss uses the full unordered pair count \code{M = n * (n - 1) / 2} as its
denominator, whereas scoped FDP \code{F / N} uses the number \code{N} of pairs ordered
inside that scope on that domain. Each strict exceedance event \code{F / N > t} is
evaluated via the exact \code{gmp} integer cutoff \code{F >= floor(t * N) + 1}; when
\code{N = 0}, no pairs are ordered in that scope so the event is analytically
false.

Separate domain matrix inputs (\code{layout = "criterionwise_arrays"}) can run
\code{mode = "joint"} only when at most one domain has an active joint event (or
the union event is analytically zero); matching row names across separate
matrices are never paired as coupled joint states. Exact rational (\code{gmp})
arithmetic over finite draws evaluates their empirical distribution without
rounding error rather than certifying feasibility under an intended
continuous posterior.
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
ev
ev$domain_table
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_grades]{postrank_mdomain_grades()}}, \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}},
\code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}}, \code{\link[=postrank_mdomain_assess]{postrank_mdomain_assess()}},
\code{\link[=postrank_plot_mdomain]{postrank_plot_mdomain()}}
}
\concept{multidomain}
