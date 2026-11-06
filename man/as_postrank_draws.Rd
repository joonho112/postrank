% Please edit documentation in R/draws-class.R
\name{as_postrank_draws}
\alias{as_postrank_draws}
\title{Prepare a Fully Described Posterior Input}
\usage{
as_postrank_draws(x)
}
\arguments{
\item{x}{A canonical \code{applied-0.1} named-list payload, or an existing
\code{postrank_draws} to revalidate.}
}
\value{
A \code{postrank_draws} object containing the supplied values in their
declared order and a \code{validation} record. Invalid input raises a
structured error containing its code, path and message.
}
\description{
A complete posterior description is validated and prepared for directional
comparisons. This constructor accepts the full producer-supplied metadata,
including an exact finite law or separate criterion-wise blocks. For a
numeric joint array, \code{\link[=postrank_draws]{postrank_draws()}} constructs the metadata from
explicit scientific declarations.
}
\details{
The supported forms are joint equal-weight IID or MCMC draws
(\code{joint_draws}), separate equal-weight criterion blocks (\code{criterion_blocks}),
and a complete exact finite posterior (\code{finite_law}). Every form records
entity/criterion IDs, target definitions, context, identification, the
zero-equality policy and provenance. Joint arrays retain all three axes,
including \verb{S x n x 1} for a single criterion. Values must already be oriented
so that larger means higher priority.

MCMC inputs retain original chain IDs, iteration numbers, warmup and
selection history. Criterion-wise blocks preserve joint entity states within
each criterion without specifying dependence across criteria. An exact
finite law specifies every positive-mass state, safe-integer target values
and positive integer mass numerators summing to a common denominator. Such a
law describes the complete posterior rather than a Monte Carlo sample; its
evaluation requires the optional \code{gmp} package.

The ordinary input domain assumes zero probability of within-criterion
equality between distinct entities and rejects observed ties. Recover
unrounded continuous values or use \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}} for genuine
equality mass. Validation checks the structure and presence of declarations;
it cannot verify their scientific truth or convergence. The extra
placeholder checks of \code{\link[=postrank_declarations]{postrank_declarations()}} are not applied here.
See \code{\link[=validate_postrank_draws]{validate_postrank_draws()}} for the separate check flags.
}
\examples{
# The bundled generator supplies a complete two-criterion canonical input.
# source() only defines this synthetic generator; it does not fit a model.
generator <- new.env()
sys.source(system.file("examples", "make-synthetic-input.R",
  package = "postrank"), envir = generator)
payload <- generator$make_postrank_synthetic_input()
draws <- as_postrank_draws(payload)
draws$criterion_ids
dim(draws$joint_draws$tensor$values)
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=read_postrank_draws]{read_postrank_draws()}},
\code{\link[=validate_postrank_draws]{validate_postrank_draws()}},
\code{vignette("m3-posterior-inputs", package = "postrank")}
}
\concept{input}
