% Please edit documentation in R/draws-class.R
\name{as_postrank_draws}
\alias{as_postrank_draws}
\title{Prepare a Fully Described Posterior Input}
\usage{
as_postrank_draws(x)
}
\arguments{
\item{x}{A complete \code{applied-0.1} named list, or an existing
\code{postrank_draws} object to revalidate.}
}
\value{
A \code{postrank_draws} object storing the input fields in their
declared order, \code{input_schema_version} (\code{"applied-0.1"}), \code{schema_version}
(\code{"0.1.0"}), and a \code{validation} record from \code{\link[=validate_postrank_draws]{validate_postrank_draws()}}.
Invalid input stops with the first reported issue (\code{code}, \code{path} and
\code{message}).
}
\description{
\code{as_postrank_draws()} validates a complete \code{applied-0.1} posterior input
list (or revalidates an existing \code{postrank_draws} object) and returns a
\code{postrank_draws} object. Use it when constructing separate criterion-wise
draw blocks, an exact finite posterior law, or custom MCMC draw histories;
for an ordinary numeric array of joint draws, \code{\link[=postrank_draws]{postrank_draws()}} with
\code{\link[=postrank_describe]{postrank_describe()}} is simpler.
}
\details{
Three posterior forms are accepted:
\itemize{
\item \code{joint_draws}: equal-weight IID or MCMC draws in an \verb{S x n x K} array
(keeping \verb{S x n x 1} when \code{K = 1}), with MCMC chain IDs, iteration numbers
and warmup/thinning history;
\item \code{criterion_blocks}: separate equal-weight \verb{S_k x n} matrices per
criterion, preserving joint entity states within each criterion without
specifying dependence across criteria;
\item \code{finite_law}: an exact discrete posterior listing every positive-mass
state with safe-integer target values and positive integer probability
numerators summing to a common denominator (not a Monte Carlo sample;
evaluating it with \code{\link[=postrank_pairwise]{postrank_pairwise()}} requires the optional \code{gmp}
package).
}

Values must already be oriented so that larger values mean higher priority.
Distinct entities must have zero probability of exact equality within each
criterion, and observed ties stop the call; for posteriors with positive
probability on ties, use \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}. Required descriptions
are checked for structure and non-empty text without the placeholder-word
list of \code{\link[=postrank_declarations]{postrank_declarations()}}.
}
\examples{
# Build a complete synthetic two-criterion input list from the bundled script:
generator <- new.env()
sys.source(system.file("examples", "make-synthetic-input.R",
  package = "postrank"), envir = generator)
input_list <- generator$make_postrank_synthetic_input()
draws <- as_postrank_draws(input_list)
draws$criterion_ids
dim(draws$joint_draws$tensor$values)
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_describe]{postrank_describe()}}, \code{\link[=read_postrank_draws]{read_postrank_draws()}},
\code{\link[=validate_postrank_draws]{validate_postrank_draws()}},
\code{vignette("m3-posterior-inputs", package = "postrank")}
}
\concept{input}
