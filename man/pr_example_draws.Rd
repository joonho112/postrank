% Please edit documentation in R/data.R
\docType{data}
\name{pr_example_draws}
\alias{pr_example_draws}
\title{An Additional Three-Criterion Example with 4000 IID Draws}
\format{
A \code{postrank_draws} object whose \code{joint_draws$tensor$values} is a
4000 x 30 x 3 array (draw, entity \code{site001}-\code{site030}, criterion
\code{poverty}, \code{frl}, \code{snap}); the remaining fields follow the legacy schema.
}
\source{
\code{data-raw/make-pr-example-law.R} (law stage, seed 20261023) and
\code{data-raw/make-pr-example-draws.R} (draw stage, seed 20261024); the frozen
law and configuration are \code{data-raw/pr-example-law.json} and
\code{data-raw/pr-example-config.json}.
}
\usage{
pr_example_draws
}
\description{
A validated joint \code{postrank_draws} object with all eight scientific
declarations. A synthetic dataset was generated from a Gaussian model
(K = 3, latent covariance \verb{.4 I + .6 s s'} with \verb{s = (1, 1, -1)}, cyclic
precision groups of ten sites) and passed through the
known-Gaussian posterior; the resulting law (30 x 3 means, 3 x 3 x 30
covariances) was frozen and 4000 IID draws were generated from it once
(seed 20261024). The criteria are named \code{poverty}, \code{frl} and \code{snap} for
illustration only; the values are synthetic latent needs, not real measures.
The same law is shipped as \link{pr_example_gaussian}.
}
\details{
The \code{snap} criterion is negatively related to the other two criteria,
and the posteriors are imprecise. Under the illustrative policy
\code{weights = c(poverty = .5, frl = .25, snap = .25)}, \code{G_max = 4}, the validated
incumbent at \code{tau = .25} is the all-withheld grading (every comparison withheld, risk
\code{tau}), and at \code{tau = .35} it discloses about 63\% of the pairs in four
grades. Both results are provided as cached results for the vignettes.
}
\examples{
dim(pr_example_draws$joint_draws$tensor$values)
pr_example_draws$criterion_ids
}
\concept{data}
\keyword{datasets}
