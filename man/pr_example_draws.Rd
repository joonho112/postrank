% Please edit documentation in R/data.R
\docType{data}
\name{pr_example_draws}
\alias{pr_example_draws}
\title{An Additional Three-Criterion Example with 4000 IID Draws}
\format{
A \code{postrank_draws} object whose \code{joint_draws$tensor$values} is a
4000 x 30 x 3 numeric array (draws x entities \code{site001}-\code{site030} x
criteria \code{poverty}, \code{frl}, \code{snap}), together with its target, context and
sampling descriptions and \code{validation} record.
}
\source{
Built by \code{data-raw/make-pr-example-law.R} (posterior parameters, seed
\code{20261023}) and \code{data-raw/make-pr-example-draws.R} (IID draws, seed
\code{20261024}).
}
\usage{
pr_example_draws
}
\description{
\code{pr_example_draws} is a synthetic \code{postrank_draws} dataset for 30 fictional
sites (\code{site001} through \code{site030}) on three criteria (\code{poverty}, \code{frl} and
\code{snap}), carrying all eight scientific declarations. Synthetic observations
were simulated from a three-criterion normal model (latent covariance
\verb{0.4 I + 0.6 s s'} with \verb{s = (1, 1, -1)} and cyclic precision groups of 10
sites, seed \code{20261023}), yielding a conjugate normal posterior from which
4,000 IID draws were sampled once (seed \code{20261024}). The criterion names are
illustrative labels only, not measurements of real sites. The underlying
normal posterior is also provided analytically in \link{pr_example_gaussian}.
}
\details{
Because \code{snap} is negatively correlated with \code{poverty} and \code{frl} and the
posteriors are noisy, under \code{weights = c(poverty = 0.5, frl = 0.25, snap = 0.25)}
and \code{G_max = 4} the chosen grading at \code{tau = 0.25} leaves all pairs
unordered (one shared grade, loss \code{tau}), whereas at \code{tau = 0.35} it orders
about 63\% of pairs across four grades (stored as
\code{postrank_example("analysis_30x3")} and
\code{postrank_example("analysis_30x3_tau35")}).
}
\examples{
dim(pr_example_draws$joint_draws$tensor$values)
pr_example_draws$criterion_ids
}
\seealso{
\link{pr_example_gaussian}, \code{\link[=postrank_example]{postrank_example()}}
}
\concept{data}
\keyword{datasets}
