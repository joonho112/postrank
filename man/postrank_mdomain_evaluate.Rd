% Please edit documentation in R/mdomain-evaluate.R
\name{postrank_mdomain_evaluate}
\alias{postrank_mdomain_evaluate}
\title{Evaluate a Fixed Multidomain Report}
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
\item{input}{A \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} object.}

\item{grades}{A finite numeric unit by domain matrix with both dimensions
named in the input's original order. Smaller labels mean higher priority.
Labels are canonicalized to occupied integer grades without changing order
or ties. A tie withholds a direction; it does not assert latent equality.}

\item{decision}{A \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} recipe, or \code{NULL} for its
documented defaults. The recipe is revalidated and bound to \code{input}.}

\item{mode}{\code{"joint"} evaluates expected quantities and the joint union;
\code{"expected"} evaluates expected quantities only. Expected mode leaves joint
and overall feasibility unknown, including when joint guards are disabled.}

\item{keep_traces}{Retain the evaluated state counts and joint indicators.}
}
\value{
A \code{postrank_mdomain_evaluation} containing the validated input,
action, bound decision, engine evaluation, named integer \code{grades}, risk,
domain and scope tables, constraint tables, status and assurance records.
Exact quantities have companion rational strings. In expected mode \code{J},
\code{joint_feasible}, and \code{feasible_for_represented_measure} are \code{NA}.
}
\description{
Compute additive expected loss and, when requested, the probability of the
union of strict scoped FDP exceedances for a supplied report card.
}
\details{
The loss denominator remains the original number of unordered unit
pairs. Scoped FDP uses the number of directions disclosed in that scope.
The strict event is \code{F/N > t}, represented by the exact integer cutoff
\code{floor(t*N) + 1}; no disclosure makes the event analytically false.
Joint evaluation uses only an actual relevant state law. Separate domain
inputs can evaluate a union with at most one active domain, and any input
can evaluate an analytically inactive union. No cross-domain coupling is
inferred from matching state labels. Arithmetic on draws describes their
empirical measure and does not certify intended posterior feasibility.
}
\concept{multidomain}
