% Please edit documentation in R/postrank-package.R
\docType{package}
\name{postrank-package}
\alias{postrank-package}
\title{postrank: Posterior Ranking with Integer Grades}
\description{
Posterior information on one or several criteria is used to assign an
integer grade to each entity under a declared loss. For several criteria,
the original P1 entry points assign one common grade. Multidomain P2
entry points retain a separate grade for each domain. The input is an existing posterior
representation, supplied as draws, supported analytic laws or previously
calculated comparison probabilities, together with scientific declarations
and numerical qualifications. The package does not fit a statistical model.
}
\section{Interpretation of grades}{

Grade 1 is the highest-priority block; larger targets mean higher priority,
and only the order and equality of grade labels matter. A shared grade
withholds the comparison of its members and asserts no equality of the
entities. The procedure seeks a grade minimizing the declared weighted
wrong-direction loss plus the withholding cost \code{tau}, and reports the
validated incumbent with the solver's bound and gap; withholding every
comparison, with risk \code{tau}, is a legitimate action.
}

\section{Package functions}{

\tabular{ll}{
Input \tab \code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_declarations]{postrank_declarations()}}, \code{\link[=read_postrank_draws]{read_postrank_draws()}} and the strict constructors \cr
Coefficients \tab \code{\link[=postrank_pairwise]{postrank_pairwise()}}, \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}, \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}, \code{\link[=postrank_probabilities]{postrank_probabilities()}} \cr
Settings and control \tab \code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_control]{postrank_control()}} \cr
Decision \tab \code{\link[=postrank]{postrank()}}, \code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}} \cr
Baselines and comparison \tab \code{\link[=postrank_expected_rank]{postrank_expected_rank()}}, \code{\link[=postrank_composite]{postrank_composite()}}, \code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_compare]{postrank_compare()}} \cr
Side outputs and grids \tab \code{\link[=postrank_commonality_cost]{postrank_commonality_cost()}}, \code{\link[=postrank_frontier]{postrank_frontier()}}, \code{\link[=postrank_sensitivity]{postrank_sensitivity()}} \cr
Diagnostics \tab \code{\link[=postrank_crossfit]{postrank_crossfit()}}, \code{\link[=postrank_mc_fragility]{postrank_mc_fragility()}}, \code{\link[=postrank_diagnose]{postrank_diagnose()}} \cr
Reporting \tab \code{\link[=postrank_report_card]{postrank_report_card()}}, \code{\link[=postrank_report]{postrank_report()}}, \code{\link[=get_grades]{get_grades()}} and the console formatters \cr
Visualization \tab the seven \verb{postrank_plot_*()} figures, \code{\link[=theme_postrank]{theme_postrank()}}, \code{\link[=postrank_palette]{postrank_palette()}} \cr
Reference calculations \tab \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}} and the conditional guarantee helpers
}
}

\section{Getting started}{

\link{pr_tutorial} provides the same six fictional sites with one or two
criteria in \code{vignette("a1-getting-started", package = "postrank")}.
The Applied guides present empirical cases and the Methods guides describe the
loss, information requirements, optimization and numerical uncertainty.
Stored-result views need no optimizer. A fresh solve uses an explicitly
selected backend, the \code{postrank.backend} option, or Gurobi in that order.
HiGHS is an explicit alternative; there is no silent backend fallback.
}

\section{Multidomain profiles}{

\code{\link{postrank_mdomain_input}} retains identified unit-by-domain
states and declared target laws. A named grade matrix reports a separate
order in each domain; a shared domain grade withholds direction.
\code{\link{postrank_mdomain_decision}} specifies additive losses and
mean or direct joint-event guards. \code{\link{postrank_mdomain_evaluate}}
evaluates a fixed matrix; \code{\link{postrank_mdomain_family}} and
\code{\link{postrank_mdomain_solve}} select within a complete declared
candidate bank. This bank is the stated scope of optimality.
\code{\link{postrank_mdomain_grades}} extracts verified grades,
\code{\link{postrank_mdomain_assess}} distinguishes finite-law, conditional
iid and descriptive MCMC routes, and \code{\link{postrank_plot_mdomain}}
displays three stored-card views. Profile computation uses optional
\pkg{gmp} arithmetic and requires no MIP backend. Scientific sampling and
proper-law declarations are retained, not independently established.
See \code{vignette("mdomain-quickstart", package = "postrank")} and
\code{vignette("mdomain-decisions", package = "postrank")}.
}

\section{Genuine target ties}{

The separate \code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}} domain makes equality neutral
in both wrong-direction and withheld-comparison loss. It supports guarded
weighted at-most-G label-MIP problems through distinct \verb{postrank_tie_*}
entry points. Its all-withhold risk is R0, which can be below tau.
Ordinary constructors retain their tie-free interpretation.
}

\section{Case-study data}{

The three case-study inputs are adapted from public sources and retain
source-specific conditions, separate from the package code license. The CDE
input preserves source attribution, KRW retains its source CC-BY-NC notice
with the license version unspecified, and Alabama retains CC BY 4.0
attribution. Details are given in the data help pages and the installed
DATA-NOTICE.
}

\section{Citation}{

\code{citation("postrank")} returns the package, its theory book and the
report-card method of Kline, Rose and Walters (2024), in that order.
The book is \emph{Decisions from noisy multidimensional indicators: Theory,
evidence, and posterior grading} (Version 1.0.0),
\doi{10.5281/zenodo.23790260}. The method reference is \emph{A discrimination
report card}, American Economic Review, 114(8), 2472-2525,
\doi{10.1257/aer.20230700}.
}

\examples{
pr_tutorial$one
postrank_expected_rank(pr_tutorial$one)
pr_tutorial$two
}
\seealso{
\link{postrank_options}, \link{pr_tutorial},
\code{vignette("a1-getting-started", package = "postrank")}
}
\author{
\strong{Maintainer}: JoonHo Lee \email{jlee296@ua.edu} (\href{https://orcid.org/0009-0006-4019-8703}{ORCID}) [copyright holder]

Authors:
\itemize{
  \item JoonHo Lee \email{jlee296@ua.edu} (\href{https://orcid.org/0009-0006-4019-8703}{ORCID}) [copyright holder]
}

}
\keyword{internal}
