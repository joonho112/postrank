% Please edit documentation in R/baselines.R
\name{postrank_composite}
\alias{postrank_composite}
\title{Posterior-Mean Composite Scores with Declared Scales}
\usage{
postrank_composite(means, weights, scales = 1, centers = 0)
}
\arguments{
\item{means}{Finite \verb{n x K} numeric matrix of posterior means with entity
row names and criterion column names (for example from
\code{\link[=postrank_posterior_means]{postrank_posterior_means()}} or \code{coefficients$means}).}

\item{weights}{Nonnegative finite criterion weights \code{a} summing to one within
\code{1e-12}, or \code{NULL} for equal weights \code{1 / K}. Unnamed weights follow column
order; named weights must name every criterion once.}

\item{scales}{Positive finite scale value(s) (default \code{1}): an unnamed scalar
is recycled across criteria, an unnamed length-\code{K} vector follows column
order, and a named vector must name every criterion once.}

\item{centers}{Finite center value(s) (default \code{0}), following the same
name-matching and recycling rules as \code{scales}.}
}
\value{
A numeric vector named by \code{rownames(means)}, carrying attributes
\code{score_method = "composite"}, \code{scales} and \code{centers}.
}
\description{
\code{postrank_composite()} combines entity posterior means across criteria into a
weighted linear score using caller-supplied centers and scales (larger score
= higher priority). Pass the resulting score vector to \code{\link[=postrank_cuts]{postrank_cuts()}} to
partition that order into integer grades.
}
\details{
Entity \code{i}'s composite score is
\eqn{c_i = \sum_k a_k (\bar\theta_{ik} - \mathrm{center}_k) / \mathrm{scale}_k}.
\code{postrank_composite()} does not estimate empirical means or standard
deviations across entities. Ordering entities by \code{c_i} and cutting that order
under per-criterion pairwise loss differs from forming a posterior
distribution of a single composite target; see
\code{vignette("m2-several-criteria", package = "postrank")}.
}
\examples{
m <- postrank_posterior_means(postrank_toy)
postrank_composite(m, c(need_A = 0.6, need_B = 0.4))
}
\seealso{
\code{\link[=postrank_cuts]{postrank_cuts()}}, \code{\link[=postrank_posterior_means]{postrank_posterior_means()}},
\code{\link[=postrank_compare]{postrank_compare()}}
}
\concept{baselines}
