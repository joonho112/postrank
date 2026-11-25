% Please edit documentation in R/draws-builder.R
\name{postrank_draws_from_array}
\alias{postrank_draws_from_array}
\title{Build a Posterior Input from a Joint Array}
\usage{
postrank_draws_from_array(
  values,
  regime = c("iid", "mcmc"),
  chains = NULL,
  targets,
  context,
  provenance,
  origin,
  identification_note,
  tie_justification,
  joint_generation,
  sampling_provenance,
  warmup_per_chain = NULL,
  thin = NULL
)
}
\arguments{
\item{values}{Numeric \verb{S x n x K} array (draws x entities x criteria) with
entity (2nd axis) and criterion (3rd axis) \code{dimnames}. Keep the third axis
\verb{S x n x 1} when \code{K = 1}. Larger values must already mean higher priority;
this function does not negate criteria. Draw names on the 1st axis are
generated (\code{"draw_000001"}, ...) when absent.}

\item{regime}{\code{"iid"} (the default) or \code{"mcmc"}.}

\item{chains}{Number of original MCMC chains when \code{regime = "mcmc"}
(required; \code{S} must be divisible by \code{chains}, with rows ordered chain by
chain). Leave \code{NULL} when \code{regime = "iid"}.}

\item{targets}{One record per criterion, as a data frame or a list of named
lists. Required fields are \code{criterion_id}, \code{estimand},
\code{entity_population}, \code{time_reference} and \code{units}. Optional
\code{source_transform} defaults to \code{"identity"} and \code{identification_basis}
defaults to \code{identification_note}.}

\item{context}{Named list with \code{cohort_id}, \code{data_version},
\code{data_conditioning} and \code{model_summary}.}

\item{provenance}{Named list with \code{producer}, \code{artifact_id} and
\code{construction_note}. Optional \code{artifact_hash} defaults to the SHA-256 of
\code{values}, and \code{created_at} defaults to the current UTC timestamp.}

\item{origin}{Named list with \code{source_id}, \code{fit_id}, \code{model_id},
\code{source_format} and \code{source_artifact}. Optional \code{source_hash} defaults to
the SHA-256 of \code{values}.}

\item{identification_note}{One non-empty string explaining why each target
is identified.}

\item{tie_justification}{One non-empty string explaining why distinct
entities have zero probability of exact equality on each criterion.
Observed ties in \code{values} still stop the call.}

\item{joint_generation}{One non-empty string explaining how each draw holds
all entities and criteria together, preserving model dependence.}

\item{sampling_provenance}{One non-empty string describing how the retained
draws were produced.}

\item{warmup_per_chain}{Number of warmup iterations removed per chain before
the retained draws when \code{regime = "mcmc"} (\code{0L} if none; leave \code{NULL} when
\code{regime = "iid"}).}

\item{thin}{Iteration spacing between retained draws when \code{regime = "mcmc"}
(\code{1L} if unthinned; leave \code{NULL} when \code{regime = "iid"}).}
}
\value{
A validated \code{postrank_draws} object storing \code{values}, ordered
\code{entity_ids} and \code{criterion_ids}, the supplied descriptions, generated
draw indices and variable mappings, and a \code{validation} record.
}
\description{
\code{postrank_draws_from_array()} builds a \code{postrank_draws} object from a
numeric \verb{S x n x K} array of joint posterior draws and its eight required
descriptions, generating draw IDs, variable mappings, MCMC chain histories
and array SHA-256 hashes before validating with \code{\link[=as_postrank_draws]{as_postrank_draws()}}. Most
users can call \code{\link[=postrank_draws]{postrank_draws()}} with \code{\link[=postrank_describe]{postrank_describe()}} instead.
}
\details{
When \code{regime = "mcmc"}, \code{chains}, \code{warmup_per_chain} and \code{thin} are all
required, and retained iteration numbers within each chain are recorded as
\code{warmup_per_chain + thin * seq_len(S / chains)}. For irregular chain lengths
or custom iteration numbers, pass full \code{applied-0.1} metadata to
\code{\link[=as_postrank_draws]{as_postrank_draws()}} or \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}; do not split one MCMC
chain into artificial chains.

\code{postrank_draws_from_array()} checks that all required strings are present
and non-empty, whereas \code{\link[=postrank_declarations]{postrank_declarations()}} and the array route of
\code{\link[=postrank_draws]{postrank_draws()}} also reject generic placeholder words such as \code{"TBD"}.
Validation checks structure and presence of descriptions, not scientific
identification, jointness or MCMC convergence, and generated SHA-256 hashes
identify the in-memory \code{values} array rather than an external file.

To negate lower-is-higher criteria automatically, use the \code{orientation}
argument of \code{\link[=postrank_draws]{postrank_draws()}}. For posteriors with positive probability of
exact ties, use \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}.
}
\examples{
# Rebuild the bundled two-criterion IID toy array from its stored fields:
x <- postrank_toy
b <- x$joint_draws
draws <- postrank_draws_from_array(b$tensor$values, regime = "iid",
  targets = x$targets, context = x$context, provenance = x$provenance,
  origin = b$origin, identification_note = x$identification$note,
  tie_justification = x$tie_policy$justification,
  joint_generation = b$cross_criterion_joint_provenance,
  sampling_provenance = b$sampling$sampling_provenance)
identical(draws$joint_draws$tensor$values, b$tensor$values)
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_describe]{postrank_describe()}},
\code{\link[=postrank_declarations]{postrank_declarations()}}, \code{\link[=as_postrank_draws]{as_postrank_draws()}}
}
\concept{input}
