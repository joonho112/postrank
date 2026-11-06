% Please edit documentation in R/draws-friendly.R
\name{postrank_draws}
\alias{postrank_draws}
\title{Prepare Posterior Draws for One or Several Criteria}
\usage{
postrank_draws(
  x,
  regime = NULL,
  chains = NULL,
  warmup_per_chain = NULL,
  thin = NULL,
  entity_ids = NULL,
  criterion_ids = NULL,
  orientation = "higher",
  declarations = NULL,
  variables = NULL,
  metadata = NULL,
  source_coordinates = NULL
)
}
\arguments{
\item{x}{A numeric \verb{S x n x K} array (draw, entity, criterion), a named list
of \verb{S_k x n} matrices, a \code{posterior} draws object, or a \code{postrank_draws}.
For one criterion retain the third axis: \verb{S x n x 1}.}

\item{regime}{For numeric arrays, \code{"iid"} or \code{"mcmc"}; required.}

\item{chains, warmup_per_chain, thin}{For MCMC arrays, the original number of
chains, number of removed warmup iterations per chain, and retained
iteration spacing. All three are required. Rows must be stored chain by
chain with equal retained lengths; use \code{thin = 1L} for no thinning.
Leave these arguments unset for IID draws.}

\item{entity_ids, criterion_ids}{Optional IDs for numeric array axes without
dimnames. Supplied IDs must agree with any existing dimnames.}

\item{orientation}{\code{"higher"} by default: larger values already mean higher
priority. For numeric arrays, a criterion-named character vector may
instead specify \code{"higher"} or \code{"lower"}; unlisted criteria stay unchanged.}

\item{declarations}{A \code{\link[=postrank_declarations]{postrank_declarations()}} bundle for numeric arrays.}

\item{variables}{For \code{posterior} objects, explicit variable-mapping records
as described in \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.}

\item{metadata}{For matrix lists or \code{posterior} objects, complete canonical
\code{applied-0.1} metadata describing the corresponding input.}

\item{source_coordinates}{For \code{posterior} objects, records mapping retained
slots to source iteration and chain positions; see \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.}
}
\value{
A validated \code{postrank_draws} object retaining entity and criterion
order, target descriptions and sampling history. Numeric array criteria
requested as \code{"lower"} are negated once and that change is recorded.
}
\description{
Posterior output is prepared for \code{\link[=postrank_pairwise]{postrank_pairwise()}} or \code{\link[=postrank]{postrank()}} from
the retained values and their target, source and sampling descriptions. Each
row must retain the joint state of the entities being compared.
}
\details{
The numeric-array route calls \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}} with
the eight required declarations. Larger oriented values indicate higher
priority, and grade 1 therefore denotes the highest-priority group. For a
raw criterion whose preferred direction is lower, \code{orientation = c(rate = "lower")} applies the required negation. A target already supplied as
\code{-rate} instead requires \code{orientation = "higher"}, since a second negation
would reverse the intended direction.

A named matrix list uses \code{dependence_mode = "criterionwise_expected_only"}
and one \code{criterion_blocks} record per criterion in \code{metadata}. Each record
needs \code{criterion_id}, \code{origin}, \code{sampling}, \code{draw_index} and \code{variable_map};
the function inserts its \code{matrix} values. Column order must match entity
IDs and rows must match the declared draw slots. Different draw counts are
allowed. Each row remains joint across entities within a criterion; aligning
rows from separate criteria does not create a cross-criterion joint law.
These inputs support additive criterion-wise expected loss, not recovery
of composite-target or simultaneous-event probabilities.

A \code{posterior::draws_array}, \code{draws_df} or \code{draws_matrix} is converted with
\code{posterior::as_draws_array()} and passed to \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.
Existing \code{postrank_draws} inputs are revalidated. These routes and matrix
lists must already have higher-priority orientation. Arguments belonging to
a different route raise \code{input_metadata_conflict}.

All ordinary draw routes require a scientific zero-equality declaration
and reject observed within-criterion ties. Preserve original precision;
jitter would change the values. Genuine equality mass requires
\code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}. Do not relabel MCMC draws as IID or a finite
Monte Carlo sample as an exact finite posterior.

Only the high-level numeric-array route applies the additional placeholder
checks of \code{\link[=postrank_declarations]{postrank_declarations()}}. Matrix-list and \code{posterior} metadata,
existing objects, direct strict constructors and JSON readers retain their
structural and declaration-presence checks. No route establishes scientific
jointness or convergence from those declarations.
}
\examples{
# The bundled two-criterion Markov-chain toy includes its actual declarations.
# Its four original chains each have 512 retained iterations and no warmup.
# See postrank_declarations() for a complete K = 1 construction example.
draws <- postrank_draws(pr_toy_mcmc, regime = "mcmc",
  chains = 4L, warmup_per_chain = 0L, thin = 1L,
  declarations = attr(pr_toy_mcmc, "law")$declarations)
dim(draws$joint_draws$tensor$values)
draws$joint_draws$draw_index[[513L]] # first iteration of original chain 2
}
\seealso{
\code{\link[=postrank_declarations]{postrank_declarations()}}, \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}},
\code{\link[=as_postrank_draws]{as_postrank_draws()}}, \code{\link[=as_postrank_posterior]{as_postrank_posterior()}},
\code{vignette("a5-your-posterior-results", package = "postrank")}
}
\concept{input}
