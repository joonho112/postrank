% Please edit documentation in R/mdomain-evaluate.R
\name{postrank_mdomain_grades}
\alias{postrank_mdomain_grades}
\title{Extract Verified Multidomain Grades}
\usage{
postrank_mdomain_grades(x)
}
\arguments{
\item{x}{A \code{postrank_mdomain_evaluation} or \code{postrank_mdomain_fit} (for a
\code{postrank_mdomain_assessment}, pass \code{x$evaluation}).}
}
\value{
A named \verb{n x D} integer matrix of grades (\code{1} = highest priority
within each domain) in \code{x}'s original unit and domain order.
}
\description{
\code{postrank_mdomain_grades()} revalidates a \code{postrank_mdomain_evaluation} or
\code{postrank_mdomain_fit} and returns its canonical \verb{n x D} integer grade
matrix. Requires optional package \code{gmp}.
}
\details{
Revalidates \code{x}'s input and \code{validated_result_hash} before returning
\code{x$grades}, stopping with an error if \code{x} was modified after evaluation or
candidate selection. Never searches candidates or recomputes posterior
quantities.
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
postrank_mdomain_grades(ev)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}}, \code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}},
\code{\link[=postrank_plot_mdomain]{postrank_plot_mdomain()}}
}
\concept{multidomain}
