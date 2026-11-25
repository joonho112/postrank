% Please edit documentation in R/data.R
\docType{data}
\name{postrank_toy}
\alias{postrank_toy}
\title{A Small Sample of 32 IID Posterior Draws}
\format{
A \code{postrank_draws} object with S = 32, n = 3, K = 2 (\code{applied-0.1}
joint equal-weight draws and its \code{validation} record).
}
\source{
Built by \code{data-raw/make-postrank-toy.R} using
\code{make_postrank_synthetic_input()} in \code{inst/examples/make-synthetic-input.R}
(seed \code{20261019}).
}
\usage{
postrank_toy
}
\description{
\code{postrank_toy} is a synthetic \code{postrank_draws} dataset containing 32
independent (IID) draws for three fictional entities (\code{001}, \code{site-B} and
\verb{site C}) on two criteria (\code{need_A} and \code{need_B}), simulated from a specified
independent normal distribution. It equals the input read by
\code{read_postrank_draws(system.file("examples", "synthetic-iid.json", package = "postrank"))},
and represents a finite IID sample rather than an exact discrete posterior
law. For the introductory tutorial dataset, see \link{pr_tutorial}.
}
\examples{
postrank_toy$entity_ids
dim(postrank_toy$joint_draws$tensor$values)
}
\seealso{
\link{pr_tutorial}, \code{\link[=postrank_example]{postrank_example()}}, \code{\link[=read_postrank_draws]{read_postrank_draws()}}
}
\concept{data}
\keyword{datasets}
