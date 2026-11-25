% Please edit documentation in R/draws-class.R
\name{validate_postrank_draws}
\alias{validate_postrank_draws}
\title{Check a Posterior Input and Inspect Its Validation Results}
\usage{
validate_postrank_draws(x, source = NULL)
}
\arguments{
\item{x}{A \code{postrank_draws} object or an \code{applied-0.1} named list.}

\item{source}{Reserved; leave \code{NULL} (any non-\code{NULL} value stops with
\code{unsupported_source_audit}). To check values against a \code{posterior} package
object, use \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.}
}
\value{
A \code{postrank_validation} list with components:
\itemize{
\item \code{valid}: \code{TRUE} if all R structural and semantic checks passed, \code{FALSE}
otherwise;
\item \code{issues}: empty list when \code{valid} is \code{TRUE}, otherwise a list containing
the error \code{code}, \code{path}, \code{message} and \code{severity};
\item \code{semantic_checks_completed}: check IDs \code{"DC01"} through \code{"DC15"} when
\code{valid} is \code{TRUE}, otherwise \code{character()};
\item \code{eligible_functional}, \code{input_identity}, \code{validator_version},
\code{check_results} and \code{limitations};
\item \code{schema_checked} (\code{FALSE}), \code{source_values_checked},
\code{jointness_verified} (\code{FALSE}) and \code{convergence_verified} (\code{FALSE}).
}
}
\description{
\code{validate_postrank_draws()} checks whether a \code{postrank_draws} object or an
\code{applied-0.1} input list satisfies \code{postrank}'s structural, numeric and
description requirements, returning a report rather than stopping on an
invalid input.
}
\details{
The checks verify axis order, entity and criterion IDs, target and source
descriptions, finite numeric values, absence of within-criterion ties, and
MCMC chain-history consistency. They do not run an external Draft 2020-12
JSON Schema validator (\code{schema_checked} is always \code{FALSE}), and they do not
apply the placeholder-word list of \code{\link[=postrank_declarations]{postrank_declarations()}}.

\code{source_values_checked} is \code{TRUE} only when \code{x} is an unchanged
\code{postrank_draws} object created by \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}, in which case
\code{source_audit} is also retained. \code{valid = TRUE} means the input's structure
and required descriptions are complete; it does not verify scientific
identification, joint sampling or MCMC convergence. For exact-tie inputs,
see \code{\link[=validate_postrank_tie_draws]{validate_postrank_tie_draws()}}, which uses a different return format.
}
\examples{
check <- validate_postrank_draws(postrank_toy)
check$valid
check[c("source_values_checked", "jointness_verified", "convergence_verified")]

# Omit required context to inspect the reported issue without throwing an error:
bad <- postrank_toy
bad$context <- NULL
validate_postrank_draws(bad)$issues
}
\seealso{
\code{\link[=as_postrank_draws]{as_postrank_draws()}}, \code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}
}
\concept{input}
