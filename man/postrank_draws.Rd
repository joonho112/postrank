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
\item{x}{Posterior draws for \code{n >= 2} entities in one of four forms:
\itemize{
\item a numeric \verb{S x n x K} array (draws x entities x criteria; keep the third
dimension \verb{S x n x 1} when \code{K = 1});
\item a named list of \verb{S_k x n} numeric matrices, one matrix per criterion;
\item a \code{posterior} package object (\code{draws_array}, \code{draws_df} or
\code{draws_matrix});
\item an existing \code{postrank_draws} object to revalidate.
}}

\item{regime}{Sampling regime for a numeric array: \code{"iid"} or \code{"mcmc"}
(required for arrays; leave \code{NULL} for other inputs).}

\item{chains, warmup_per_chain, thin}{MCMC chain layout for a numeric array
when \code{regime = "mcmc"}: the original number of chains (\verb{>= 1}), the number
of warmup iterations removed per chain (\verb{>= 0}), and the thinning interval
between retained iterations (\verb{>= 1}, use \code{1L} when unthinned). All three
are required when \code{regime = "mcmc"}, and array rows must be ordered chain
by chain with \code{S} divisible by \code{chains}. Leave \code{NULL} when \code{regime = "iid"}.}

\item{entity_ids, criterion_ids}{Character vectors naming the 2nd (entity)
and 3rd (criterion) axes of a numeric array. Required when the
corresponding axis of \code{dimnames(x)} is \code{NULL}; optional when \code{dimnames(x)}
already names those axes (if both are given, they must match).}

\item{orientation}{Priority direction of the supplied values. \code{"higher"}
(the default) means larger values already indicate higher priority (toward
grade 1). For numeric arrays only, a character vector named by criterion
may set \code{"higher"} or \code{"lower"}; criteria set to \code{"lower"} are negated
once (\code{-x[, , k]}) and record that sign flip in \code{targets}. Unlisted
criteria stay \code{"higher"}.}

\item{declarations}{Description of the targets and sampling for a numeric
array, from \code{\link[=postrank_describe]{postrank_describe()}} or \code{\link[=postrank_declarations]{postrank_declarations()}} (or a named
list with those eight fields).}

\item{variables}{Variable-mapping records for \code{posterior} objects; see
\code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.}

\item{metadata}{Complete posterior-input metadata list (in \code{postrank}'s
\code{"applied-0.1"} input format) for matrix-list or \code{posterior} inputs; see
\code{\link[=as_postrank_draws]{as_postrank_draws()}} and \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.}

\item{source_coordinates}{Records mapping each draw row ("slot") to its
iteration and chain position in a \code{posterior} object; see
\code{\link[=as_postrank_posterior]{as_postrank_posterior()}}.}
}
\value{
A validated \code{postrank_draws} object storing the oriented draw
values, ordered \code{entity_ids} and \code{criterion_ids}, target and source
descriptions, sampling history, and a \code{validation} record.
}
\description{
\code{postrank_draws()} prepares posterior draws from your model for \code{\link[=postrank]{postrank()}}
or \code{\link[=postrank_pairwise]{postrank_pairwise()}}, checking the values, entity and criterion labels,
sampling layout, and target descriptions. Within each criterion, every draw
must hold values for all compared entities together.
}
\details{
\strong{Numeric arrays.} Most analyses supply an \verb{S x n x K} numeric array with
\code{declarations} built by \code{\link[=postrank_describe]{postrank_describe()}} (or \code{\link[=postrank_declarations]{postrank_declarations()}}).
If a raw criterion has lower values at higher priority (such as an error rate
or cost) and has not yet been negated, pass \code{orientation = c(cost = "lower")}.
If you already negated the values before calling \code{postrank_draws()}, keep
\code{orientation = "higher"} so they are not negated a second time.

\strong{Criterion-wise matrix lists.} When criteria come from separate models or
separate MCMC runs (possibly with different draw counts \code{S_k}), pass a named
list of \verb{S_k x n} matrices together with \code{metadata} setting
\code{dependence_mode = "criterionwise_expected_only"} and one \code{criterion_blocks}
entry per criterion (\code{criterion_id}, \code{origin}, \code{sampling}, \code{draw_index} and
\code{variable_map}; \code{postrank_draws()} inserts \code{matrix}). Each row is joint
across entities within its criterion, while aligning rows across separate
matrices does not create a cross-criterion joint posterior or recover
composite-score or simultaneous-event probabilities. In \code{\link[=postrank]{postrank()}} and
\code{\link[=postrank_problem]{postrank_problem()}}, criterion-wise inputs support weighted and minimax
objectives, \code{q} budgets and \code{exact_G}, whereas Monte Carlo fragility and
cross-fitting require joint \verb{S x n x K} draws and are unavailable even when
\code{K = 1}.

\strong{\code{posterior} objects and existing \code{postrank_draws}.} Objects from the
optional \code{posterior} package are converted with \code{posterior::as_draws_array()}
and passed to \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}. Existing \code{postrank_draws} objects
are revalidated with \code{\link[=as_postrank_draws]{as_postrank_draws()}}. Matrix-list, \code{posterior} and
existing \code{postrank_draws} inputs must already be oriented so larger values
mean higher priority; passing arguments that belong to another input form
stops with \code{input_metadata_conflict}.

\strong{Exact ties, sampling regimes and scope of checks.} \code{postrank_draws()}
assumes zero probability of exact equality between distinct entities within
any criterion and stops if any draw contains tied entity values on a
criterion. Keep draws at full precision rather than rounding, and do not add
random noise (which changes the posterior). When exact ties have positive
probability, use \code{\link[=as_postrank_tie_draws]{as_postrank_tie_draws()}}. Record the actual sampling
regime: do not relabel MCMC draws as \code{"iid"} or a finite Monte Carlo sample
as an exact finite posterior. Only numeric-array input applies the
placeholder-word list of \code{\link[=postrank_declarations]{postrank_declarations()}}; matrix-list and
\code{posterior} \code{metadata} and revalidated \code{postrank_draws} objects check
structure and non-empty strings. Validation checks structure and presence of
descriptions; it does not verify scientific identification, jointness or
MCMC convergence.
}
\examples{
# Numeric IID array described with postrank_describe():
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))
decl <- postrank_describe(
  estimand = c(need = "Site need in a specified standard normal distribution"),
  population = "Three fictional sites A, B and C",
  time = "Static illustration; no observation period",
  units = "Illustrative standardized need units",
  data = "No observations; the distribution is specified directly",
  model = "Independent standard normal coordinates",
  identification = "The specified distribution defines each site's target.",
  joint = "Each draw holds one value for every site and criterion.",
  sampling = "64 independent draws from rnorm() with seed 901; no warmup or thinning.",
  ties = "Independent continuous normal coordinates are equal with probability zero.",
  software = "Base R rnorm()",
  source = "The array values created in this example",
  label = "normal-need", data_version = "1", values = values)
iid_draws <- postrank_draws(values, regime = "iid", declarations = decl)
iid_draws$entity_ids

# Bundled 4-chain MCMC array (512 retained iterations per chain, no warmup):
mcmc_draws <- postrank_draws(pr_toy_mcmc, regime = "mcmc",
  chains = 4L, warmup_per_chain = 0L, thin = 1L,
  declarations = attr(pr_toy_mcmc, "law")$declarations)
mcmc_draws$criterion_ids
mcmc_draws$validation$valid
}
\seealso{
\code{\link[=postrank_describe]{postrank_describe()}}, \code{\link[=postrank_declarations]{postrank_declarations()}},
\code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}}, \code{\link[=as_postrank_draws]{as_postrank_draws()}},
\code{\link[=as_postrank_posterior]{as_postrank_posterior()}},
\code{vignette("a5-your-posterior-results", package = "postrank")}
}
\concept{input}
