% Please edit documentation in R/mdomain-solve.R
\name{postrank_mdomain_solve}
\alias{postrank_mdomain_solve}
\title{Solve a Declared Multidomain Candidate Family}
\usage{
postrank_mdomain_solve(input, family, decision = NULL, max_actions = 100000L)
}
\arguments{
\item{input}{A \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} object used to construct \code{family}.}

\item{family}{A \code{\link[=postrank_mdomain_family]{postrank_mdomain_family()}} object. Its construction input,
identities, columns, provenance and integrity receipts are revalidated.}

\item{decision}{A \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} recipe, or \code{NULL} for its
documented defaults. The recipe is rebound to the validated input.}

\item{max_actions}{Positive integer maximum size of the declared Cartesian
product. An oversized product raises a typed error before enumeration;
the product is never silently truncated and no incumbent is returned.}
}
\value{
A \code{postrank_mdomain_fit} containing \code{solution}, the complete native
candidate-search record; \code{evaluation}, a validated fixed-card evaluation of
the selected candidate; and \code{input}, \code{family}, bound \code{decision}, named
integer \code{grades}, \code{optimizer_ids}, \code{optimizer_count}, \code{selected_id},
\code{candidate_table}, \code{status}, \code{search_scope} and integrity receipts.
}
\description{
Minimize additive expected loss over the complete Cartesian product of the
declared candidate columns, subject to mean guards and direct joint
protection. Every optimal candidate is retained, including exact ties.
}
\details{
Only primary expected-loss minimization with direct joint union
protection is exposed. The first optimizer in lexicographic canonical grade
order is selected without a secondary objective. The full optimizer set
and all examined candidates remain available in \code{solution}.

Optimality is restricted to the declared candidate family. Examining its
complete product does not establish unrestricted ordered-partition
optimality. Exact rational comparisons and computed approximate comparisons
have distinct statuses; approximate values use no tie tolerance. Arithmetic
on supplied draws concerns their empirical measure and supplies no intended
posterior feasibility certificate. Construction provenance is retained,
including whether the evaluation measure also informed the candidates.
Missing joint information raises an error rather than making a candidate
infeasible or pairing marginal histories.
}
\concept{multidomain}
