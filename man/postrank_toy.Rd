% Please edit documentation in R/data.R
\docType{data}
\name{postrank_toy}
\alias{postrank_toy}
\title{A Small Sample of 32 IID Posterior Draws}
\format{
A \code{postrank_draws} object with S = 32, n = 3, K = 2 (the canonical
\code{applied-0.1} joint equal-weight payload plus its validation receipt).
}
\source{
\code{data-raw/make-postrank-toy.R}, which calls
\code{make_postrank_synthetic_input()} from \code{inst/examples/make-synthetic-input.R}
(seed 20261019).
}
\usage{
postrank_toy
}
\description{
A validated \code{postrank_draws} object contains 32 IID draws of three
entities identified by \code{001}, \code{site-B} and \verb{site C}, on two criteria (\code{need_A}, \code{need_B})
from an explicitly specified independent normal toy law. It is identical to
\code{read_postrank_draws(system.file("examples", "synthetic-iid.json", package = "postrank"))}. The values constitute a finite IID sample rather than a
complete exact finite posterior law. The introductory one-criterion and
two-criterion examples are provided by \link{pr_tutorial}.
}
\examples{
postrank_toy$entity_ids
dim(postrank_toy$joint_draws$tensor$values)
}
\concept{data}
\keyword{datasets}
