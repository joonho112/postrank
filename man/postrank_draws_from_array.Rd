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
\item{values}{Numeric \verb{S x n x K} array (draw, entity, criterion) with
entity and criterion dimnames. Keep \code{K = 1} as a third axis. Larger values
must already mean higher priority; this function performs no negation.
Draw names are generated when absent.}

\item{regime}{\code{"iid"} (the default) or \code{"mcmc"}; select the actual regime.}

\item{chains}{For MCMC, the original number of chains. Rows must be stored
chain by chain with equal retained lengths. Leave unset for IID draws.}

\item{targets}{One record per criterion as a list of named lists or a data
frame. Required fields: \code{criterion_id}, \code{estimand}, \code{entity_population},
\code{time_reference}, \code{units}. Optional \code{source_transform} defaults to
\code{"identity"}; \code{identification_basis} defaults to \code{identification_note}.}

\item{context}{Named list with \code{cohort_id}, \code{data_version},
\code{data_conditioning} and \code{model_summary}.}

\item{provenance}{Named list with \code{producer}, \code{artifact_id} and
\code{construction_note}. Optional \code{artifact_hash} defaults to the SHA-256 of
the supplied array; \code{created_at} defaults to the current UTC time.}

\item{origin}{Named list with \code{source_id}, \code{fit_id}, \code{model_id},
\code{source_format} and \code{source_artifact}. Optional \code{source_hash} defaults
to the SHA-256 of the supplied array.}

\item{identification_note}{Why every labeled target is identified.}

\item{tie_justification}{Why exact equality between distinct entities has
probability zero on each criterion. Observed ties are still rejected.}

\item{joint_generation}{How each draw holds one joint state of all entities
and criteria, including their dependence.}

\item{sampling_provenance}{How the retained draws were produced.}

\item{warmup_per_chain}{For MCMC, the number of removed warmup iterations
per chain. Zero declares no removed warmup. Leave unset for IID draws.}

\item{thin}{For MCMC, retained-iteration spacing; use \code{1L} for no thinning.
Leave unset for IID draws.}
}
\value{
A validated \code{postrank_draws} object with the supplied values and
entity/criterion order, plus their declarations and generated bookkeeping.
}
\description{
The builder constructs a posterior input from an already oriented array of
joint draws, together with target definitions, source information and
sampling history. Draw IDs, variable mappings and content hashes are
generated before the input is validated by \code{\link[=as_postrank_draws]{as_postrank_draws()}}.
}
\details{
For MCMC, \code{chains}, \code{warmup_per_chain} and \code{thin} are required declarations,
not estimates. Within each chain, retained iteration numbers are
\code{warmup_per_chain + thin * seq_len(S / chains)}. This regular layout must
match the producer's actual history. Use canonical metadata and
\code{\link[=as_postrank_posterior]{as_postrank_posterior()}} for an explicit source mapping with other histories;
never split a single chain into artificial independent chains.

The eight scientific declarations are required. This strict builder checks
required text and structure; the additional placeholder-text checks apply
to \code{\link[=postrank_declarations]{postrank_declarations()}} and the numeric-array route of \code{\link[=postrank_draws]{postrank_draws()}}.
Neither kind of validation proves scientific jointness, identification,
zero equality probability or convergence. A generated hash identifies the
supplied in-memory array; it does not verify an external source file.

\code{source_transform} describes a transformation already performed. To
negate raw criteria automatically, use \code{\link[=postrank_draws]{postrank_draws()}} with its
\code{orientation} argument. Use \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}} for genuine equality
mass, and \code{\link[=as_postrank_draws]{as_postrank_draws()}} for a completely specified exact finite law.
}
\examples{
# Rebuild the unchanged two-criterion IID toy array with its own records.
# Reuse is appropriate here because the values and specified law are identical.
# For newly generated data, write declarations as in postrank_declarations().
x <- postrank_toy
b <- x$joint_draws
draws <- postrank_draws_from_array(b$tensor$values, regime = "iid",
  targets = x$targets, context = x$context, provenance = x$provenance,
  origin = b$origin, identification_note = x$identification$note,
  tie_justification = x$tie_policy$justification,
  joint_generation = b$cross_criterion_joint_provenance,
  sampling_provenance = b$sampling$sampling_provenance)
identical(draws$joint_draws$tensor$values, b$tensor$values)
# The builder creates bookkeeping; use canonical input to retain custom draw IDs.
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_declarations]{postrank_declarations()}}, \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}
}
\concept{input}
