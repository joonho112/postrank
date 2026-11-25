% Please edit documentation in R/postrank-package.R
\docType{package}
\name{postrank-package}
\alias{postrank-package}
\title{postrank: Posterior Ranking with Integer Grades}
\description{
\code{postrank} assigns an integer grade to each entity (such as a school, an
employer or an area) using posterior information that you supply: posterior
draws, normal or mixture posteriors, or pairwise comparison probabilities.
For one or several criteria, \code{\link[=postrank]{postrank()}} chooses a single common grading
across entities; the multidomain functions (\verb{postrank_mdomain_*}) instead
assign a separate grade in each domain. The package does not fit a
statistical model.
}
\section{How grades work}{

Grade 1 is the highest priority; larger values of each target mean higher
priority, as set when the input was built. Entities in different grades are
reported in that order. Entities in the same grade are left unordered: the
report withholds their comparison rather than claiming they are equal. By
default, grades minimize the posterior expected loss averaged over all entity
pairs, where reporting a pair in the wrong order costs 1 and leaving a pair
unordered costs \code{tau}. Leaving every pair unordered (a single shared grade,
with loss \code{tau}) is a valid result.
}

\section{Getting started}{

Start with \code{vignette("a1-getting-started", package = "postrank")},
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_describe]{postrank_describe()}} and \code{\link[=postrank_example]{postrank_example()}}. Stored example
results from \code{\link[=postrank_example]{postrank_example()}} run without an optimization solver, and
\link{pr_tutorial} holds the six fictional sites used in the introductory guide.

Computing new grades with \code{\link[=postrank]{postrank()}} or \code{\link[=postrank_solve]{postrank_solve()}} requires a
solver. Install the free \code{highs} package (\code{install.packages("highs")}) and
select it with \code{backend = "highs"} or \code{options(postrank.backend = "highs")},
or provide a licensed Gurobi installation (used by default when no solver is
chosen). \code{postrank} never switches solvers on its own.
}

\section{Package functions}{

\tabular{ll}{
Input \tab \code{\link[=postrank_describe]{postrank_describe()}}, \code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_declarations]{postrank_declarations()}}, \code{\link[=read_postrank_draws]{read_postrank_draws()}}, \code{\link[=as_postrank_draws]{as_postrank_draws()}} \cr
Coefficients \tab \code{\link[=postrank_pairwise]{postrank_pairwise()}}, \code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}, \code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}}, \code{\link[=postrank_probabilities]{postrank_probabilities()}} \cr
Settings and control \tab \code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_control]{postrank_control()}}, \link{postrank_options} \cr
Decision \tab \code{\link[=postrank]{postrank()}}, \code{\link[=postrank_problem]{postrank_problem()}}, \code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_evaluate]{postrank_evaluate()}} \cr
Baselines and comparison \tab \code{\link[=postrank_expected_rank]{postrank_expected_rank()}}, \code{\link[=postrank_composite]{postrank_composite()}}, \code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_compare]{postrank_compare()}} \cr
Side outputs and grids \tab \code{\link[=postrank_commonality_cost]{postrank_commonality_cost()}}, \code{\link[=postrank_frontier]{postrank_frontier()}}, \code{\link[=postrank_sensitivity]{postrank_sensitivity()}} \cr
Diagnostics \tab \code{\link[=postrank_crossfit]{postrank_crossfit()}}, \code{\link[=postrank_mc_fragility]{postrank_mc_fragility()}}, \code{\link[=postrank_diagnose]{postrank_diagnose()}} \cr
Reporting and stored examples \tab \code{\link[=postrank_report_card]{postrank_report_card()}}, \code{\link[=postrank_report]{postrank_report()}}, \code{\link[=get_grades]{get_grades()}}, \code{\link[=postrank_example]{postrank_example()}} \cr
Visualization \tab the seven \verb{postrank_plot_*()} functions, \code{\link[=theme_postrank]{theme_postrank()}}, \code{\link[=postrank_palette]{postrank_palette()}} \cr
Reference bounds \tab \code{\link[=postrank_iid_bounds]{postrank_iid_bounds()}} and the conditional envelope functions \cr
Multidomain \tab \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}}, \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}}, \code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}}, \code{\link[=postrank_plot_mdomain]{postrank_plot_mdomain()}}
}
}

\section{Multidomain profiles}{

\code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} represents entity-by-domain posteriors when a
separate grade is reported in each domain rather than one common grade. Within
each domain, a shared grade leaves the pair unordered.
\code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} defines additive domain losses and optional
mean or joint-event constraints. \code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}} evaluates a
given entity-by-domain grade matrix, while \code{\link[=postrank_mdomain_family]{postrank_mdomain_family()}} and
\code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}} choose a matrix from a declared set of candidate
profiles; optimality holds only within that candidate set.
\code{\link[=postrank_mdomain_grades]{postrank_mdomain_grades()}} extracts checked grades,
\code{\link[=postrank_mdomain_assess]{postrank_mdomain_assess()}} reports finite-law, conditional IID or
descriptive MCMC summaries, and \code{\link[=postrank_plot_mdomain]{postrank_plot_mdomain()}} plots the results.
Multidomain calculations need no mixed-integer solver and use exact rational
arithmetic when the optional \code{gmp} package is installed; exact finite-law
arithmetic does not verify the statistical model or intended posterior. See
\code{vignette("mdomain-quickstart", package = "postrank")} and
\code{vignette("mdomain-decisions", package = "postrank")}.
}

\section{Exact ties}{

Ordinary inputs assume that distinct entities have zero probability of being
equal. For posteriors in which exact equality has positive probability, the
\verb{postrank_tie_*} functions (see \code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}}) treat exact
equality as having zero loss whether the pair is ordered or left unordered,
so the single-grade loss \code{R0} can be below \code{tau}.
}

\section{Case-study data}{

The three case-study datasets are adapted from public sources and keep their
source conditions, separate from the package code license: \link{pr_case_cde}
preserves source attribution, \link{pr_case_krw} retains its source CC-BY-NC
notice (license version unspecified in the source), and \link{pr_case_alabama}
retains CC BY 4.0 attribution. See each dataset's help page and the installed
\code{DATA-NOTICE.md} file.
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
one <- postrank_example("tutorial_one")
get_grades(one)
get_risk(one)
postrank_expected_rank(pr_tutorial$one)
}
\seealso{
\code{\link[=postrank]{postrank()}}, \code{\link[=postrank_example]{postrank_example()}}, \code{\link[=postrank_describe]{postrank_describe()}},
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
