% Please edit documentation in R/posterior-summaries.R
\name{postrank_posterior_means}
\alias{postrank_posterior_means}
\title{Posterior Means and Intervals per Entity and Criterion}
\usage{
postrank_posterior_means(x, level = NULL)
}
\arguments{
\item{x}{A \code{postrank_draws}, \code{postrank_coefficients}, or
\code{postrank_probabilities} object with supplied marginal summaries.}

\item{level}{\code{NULL} for means only, or a central interval level in \verb{(0, 1)}.
A probability input with retained intervals supports only its supplied
level; \code{NULL} can still request its supplied means without intervals.}
}
\value{
An \verb{n x K} numeric matrix with dimnames \code{entity} and \code{criterion};
when \code{level} is given it carries attributes \code{lower}, \code{upper}, \code{level} and
\code{interval_source}.
}
\description{
Marginal posterior means are returned as a matrix. When \code{level} is supplied,
central equal-tail intervals are added for the same oriented targets. These
are marginal target summaries rather than simultaneous bands or intervals
for grade numbers.
}
\details{
Draw inputs use equal-weight means and
\code{stats::quantile(type = 7)}; an exact finite law uses probability-weighted
means and the generalized inverse \eqn{Q(p) = \inf\{x : F(x) \ge p\}};
Gaussian coefficients use their stored means and analytic quantiles; a
shared-state mixture uses its stored means and a bracketed root of the
marginal mixture CDF in standardized coordinates. Mixture endpoints are
checked against their CDF with absolute probability tolerance \code{1e-10};
a numerically unrepresentable endpoint raises \code{posterior_quantile_failure}.
Stored mixture weights are never changed. Means and quantiles are computed separately, so a
mean may lie outside its central interval for a skewed law. A pairwise
error array alone does not determine posterior means, so \code{postrank_pairwise}
objects are not accepted. Inputs from \code{\link[=postrank_probabilities]{postrank_probabilities()}} can return
explicitly supplied marginal summaries. Those values are not inferred from
the probabilities, and their fixed interval level cannot be changed.
}
\examples{
m <- postrank_posterior_means(postrank_toy, level = .9)
m
attr(m, "lower")
}
\seealso{
\code{\link[=postrank_report_card]{postrank_report_card()}}
}
\concept{baselines}
