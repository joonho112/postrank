% Please edit documentation in R/baselines.R
\name{postrank_composite}
\alias{postrank_composite}
\title{Posterior-Mean Composite Scores with Declared Scales}
\usage{
postrank_composite(means, weights, scales = 1, centers = 0)
}
\arguments{
\item{means}{An \verb{n x K} numeric matrix of posterior means with entity
rownames and criterion colnames (for example from
\code{\link[=postrank_posterior_means]{postrank_posterior_means()}} or \code{coefficients$means}).}

\item{weights}{Nonnegative criterion weights \code{a} summing to one, or \code{NULL}
for equal weights. Names are matched to criterion columns; an unnamed
vector follows column order.}

\item{scales}{Positive scales: an unnamed scalar is recycled, an unnamed
length-K vector follows the columns of \code{means}, and a named vector must
contain every criterion ID exactly once (matched by name).}

\item{centers}{Centers, with the same name-matching and recycling rules
as \code{scales}.}
}
\value{
A named numeric vector (attribute \code{score_method = "composite"}).
}
\description{
Posterior means are combined using declared criterion weights, scales and
centers. Larger scores indicate higher reporting priority. The resulting
deterministic score defines an order; it does not specify a posterior
distribution for the composite or the probability that one uncertain
composite exceeds another.
}
\details{
The score is
\eqn{c_i = \sum_k a_k (\bar\theta_{ik} - \mathrm{center}_k) / \mathrm{scale}_k}.
Scales and centers are supplied by the caller; this function does not
estimate standardization parameters. Ranking these scores and then cutting
their order under criterion-weighted loss is different from grading a
composite target's posterior. See
\code{vignette("m2-several-criteria", package = "postrank")}.
}
\examples{
m <- postrank_posterior_means(postrank_toy)
postrank_composite(m, c(need_A = .6, need_B = .4))
}
\seealso{
\code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_posterior_means]{postrank_posterior_means()}}
}
\concept{baselines}
