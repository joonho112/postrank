% Please edit documentation in R/posterior-summaries.R
\name{postrank_posterior_means}
\alias{postrank_posterior_means}
\title{Posterior Means and Intervals per Entity and Criterion}
\usage{
postrank_posterior_means(x, level = NULL)
}
\arguments{
\item{x}{A \code{postrank_draws} object, a \code{postrank_coefficients} object, or a
\code{\link[=postrank_probabilities]{postrank_probabilities()}} object that stores \code{summaries}. Bare
\code{postrank_pairwise} objects do not determine marginal means and are
rejected.}

\item{level}{\code{NULL} (the default, returning means only) or a central interval
level in \verb{(0, 1)}. For a \code{\link[=postrank_probabilities]{postrank_probabilities()}} input with stored
intervals, a non-\code{NULL} \code{level} must equal \code{x$summaries$level}.}
}
\value{
An \verb{n x K} numeric matrix with \code{dimnames} \code{entity} and \code{criterion}.
When \code{level} is non-\code{NULL}, attributes \code{lower}, \code{upper}, \code{level} and
\code{interval_source} (\code{"draws_equal_tail"}, \code{"exact_finite_law"},
\code{"gaussian_analytic"}, \code{"mixture_analytic"} or
\code{"supplied_marginal_summaries"}) are attached.
}
\description{
\code{postrank_posterior_means()} computes an entity-by-criterion matrix of
marginal posterior means, and optionally attaches central equal-tail
posterior intervals at \code{level}. Intervals summarize marginal target
uncertainty one entity and criterion at a time, not simultaneous coverage or
intervals for grade numbers.
}
\details{
Calculation method by input type:
\itemize{
\item IID or MCMC draws: equal-weight column means and \code{stats::quantile(..., type = 7)};
\item exact finite posterior: probability-weighted means and generalized inverse
quantile \eqn{Q(p) = \inf\{x : F(x) \ge p\}};
\item normal posterior coefficients: stored \code{means} and \code{stats::qnorm()};
\item shared-state mixture coefficients: stored \code{means} and bracketed roots of
the marginal mixture CDF verified within probability tolerance \code{1e-10}
(stopping with \code{posterior_quantile_failure} if unrepresentable);
\item precomputed probabilities: stored \code{x$summaries} without recalculation.
}

Because means and quantiles are computed separately, a posterior mean can lie
outside an equal-tail interval under a skewed distribution.
}
\examples{
m <- postrank_posterior_means(postrank_toy, level = 0.90)
m
attr(m, "lower")
}
\seealso{
\code{\link[=postrank_report_card]{postrank_report_card()}}, \code{\link[=postrank_composite]{postrank_composite()}}
}
\concept{baselines}
