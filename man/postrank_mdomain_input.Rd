% Please edit documentation in R/mdomain-input.R
\name{postrank_mdomain_input}
\alias{postrank_mdomain_input}
\title{Prepare Identified Multidomain Posterior States}
\usage{
postrank_mdomain_input(
  x,
  targets = NULL,
  provenance = NULL,
  representation = NULL,
  masses = NULL,
  state_origin = NULL,
  equality_classes = NULL
)
}
\arguments{
\item{x}{A labeled numeric state by unit by domain array; a domain-named
list of labeled state by unit matrices; a complete P2 specification; or
a validated \code{\link[=postrank_draws]{postrank_draws()}} object.}

\item{targets}{Domain-ordered named target records containing \code{definition},
\code{units}, \code{orientation = "larger_is_higher"}, \code{equality_classes}, and
\code{equality_provenance}. \code{transformations} records existing transformations;
its default empty list records that this interface applies none.}

\item{provenance}{A list with \code{input_id}, \code{law_id}, \code{proper_law = TRUE},
and \code{joint_generation} for a joint array or \code{within_domain_joint} for
separate vectors. Optional producer, intended-law, sampling, retention
and audit metadata are retained; absent audit fields have explicit
missing reasons. A complete finite law additionally requires
\code{sampling_assumptions = list(finite_support_origin = "...")} describing
why the supplied support is complete. Draw inputs retain their actual
sampling declarations; missing sampler metadata is marked as missing.
These are producer declarations, not verified facts.}

\item{representation}{Explicit \code{"exact_finite_law"},
\code{"iid_equal_weight_draws"} or \code{"mcmc_equal_weight_draws"}; separate
domains may use a domain-ordered named vector.}

\item{masses}{For finite laws, rational strings or numeric stored values,
or a list with \code{encoding} and \code{values}. Separate inputs use a domain-named
list. Rational masses sum exactly to one; numeric masses use the core's
recorded floating normalization contract.}

\item{state_origin}{Data frame with \code{source_index}, \code{chain_id}, and
\code{iteration_id}, in array state order; required for MCMC. Optional
\code{state_id} must match state labels. Separate inputs use a named list.}

\item{equality_classes}{Optional domain-ordered named list of unit class
labels, equivalent to the corresponding target fields. Equal labels
declare model identities; they are never inferred from observed ties.}
}
\value{
A \code{postrank_mdomain_input} inheriting \code{p2_profile_input}, retaining
\code{original_spec}, validated payloads, capabilities and audit receipts.
}
\description{
Bind explicit unit and domain IDs, target definitions and producer
declarations to states without fitting a model or inventing dependence.
}
\details{
Separate domain vectors support additive expectations and events
within each domain. Matching row labels do not establish cross-domain
coupling. Pair probability summaries are accepted through a complete
specification and require an explicit latent equality convention.
Existing draw inputs are revalidated and adapted with their original
declarations; \code{provenance} must additionally declare \code{input_id}, \code{law_id}
and \code{proper_law = TRUE}. The suggested package \code{gmp} is required.
}
\concept{multidomain}
