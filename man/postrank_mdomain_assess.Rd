% Please edit documentation in R/mdomain-assess.R
\name{postrank_mdomain_assess}
\alias{postrank_mdomain_assess}
\title{Assess a Fixed Multidomain Grade Profile}
\usage{
postrank_mdomain_assess(
  input,
  grades,
  decision = NULL,
  method = c("mcmc", "iid", "exact"),
  design = NULL,
  beta = "1/20",
  ...
)
}
\arguments{
\item{input}{The \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} object to assess. Its
\code{representation} must match \code{method} (\code{"mcmc"} requires
\code{"mcmc_equal_weight_draws"}, \code{"iid"} requires joint
\code{"iid_equal_weight_draws"}, and \code{"exact"} requires \code{"exact_finite_law"};
inputs are never relabeled across representations).}

\item{grades}{Either an \verb{n x D} numeric grade matrix named in \code{input}'s exact
unit and domain order, or a stored \code{postrank_mdomain_evaluation} or
feasible validated \code{postrank_mdomain_fit} (\code{feasible_for_represented_measure = TRUE}) whose \code{unit_ids}, \code{domain_ids} (in original order), and saved
\code{validation_spec_hashes} (\code{report}, \code{decision}, and \code{target_law}) match
\code{input}.}

\item{decision}{A \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} specification, or \code{NULL}
(uses the stored card's decision when \code{grades} is an evaluation or fit, or
the defaults of \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} when \code{grades} is a matrix).
When \code{grades} is a stored evaluation or fit, any non-\code{NULL} \code{decision} must
match the exact same decision hash as the stored card (or stop with
\code{mdomain_frozen_event_mismatch}).}

\item{method}{Assessment method: \code{"mcmc"} (the default), \code{"iid"}, or
\code{"exact"}.}

\item{design}{For \code{method = "iid"} (whenever joint protection is active, the
union event is not analytically zero, and \code{alpha < 1}), a named list
recording the validation design fixed before generating validation draws
(see Details). For \code{"mcmc"} and \code{"exact"}, \code{NULL} or an optional named list
of user metadata retained unchanged.}

\item{beta}{Monte Carlo Type-I error budget in \verb{(0, 1)} for the exact
binomial tail test when \code{method = "iid"} (default \code{"1/20"}, separate from
the decision's exceedance limit \code{alpha}). Accepts fraction or finite
decimal strings (such as \code{"1/20"} or \code{"0.05"}, without scientific
notation), \code{gmp::bigq} scalars, or finite numeric scalars; pass exact
strings or \code{gmp::bigq} rather than floating-point doubles so \code{beta} matches
\code{design$beta_exact} (\code{0.05} converts to its IEEE-754 binary rational rather
than \code{"1/20"}).}

\item{...}{Named options for the chosen \code{method}: all methods accept
\code{keep_traces = TRUE}; \code{"mcmc"} accepts \code{batch_size = 50L} and
\code{run_id = input$input_id}; \code{"iid"} accepts exact-binomial workload caps
\code{max_S = 10000L}, \code{max_bits = 1000000L}, and \code{max_work = 50000000}. Other
names stop with an error.}
}
\value{
A \code{postrank_mdomain_assessment} list containing \code{input}, \code{evaluation}
(\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}} on \code{input}), \code{native} (the underlying IID
count-bound record, MCMC diagnostic, or finite-law evaluation), \code{method},
\code{status}, \code{grades}, \code{decision} (matched to \code{input}), \code{spec_hashes},
\code{design}, \code{risk}, \code{risk_exact}, \code{J}, \code{J_exact}, \code{joint_certificate},
\code{certificate_scope}, \code{assurance}, and \code{receipts}. Any \code{joint_certificate}
applies only to the specified joint false-discovery-proportion (\code{FDP})
exceedance event; expected-error (\code{q}) budgets, profile optimality,
external sampling claims, and model calibration are not certified.
}
\description{
\code{postrank_mdomain_assess()} evaluates a fixed multidomain grade profile on
\code{input} using one of three explicitly chosen methods: descriptive MCMC batch
diagnostics (\code{method = "mcmc"}), conditional fixed-sample IID binomial
testing (\code{method = "iid"}), or complete finite-law evaluation
(\code{method = "exact"}). It reports domain-weighted expected loss (\code{risk}) and
the joint exceedance probability \code{J} (the probability under the supplied
states that at least one protected \verb{(domain, scope)} pair has realized false
discovery proportion \code{FDP = F / N}, wrong-direction pairs divided by ordered
pairs in that scope, strictly exceeding its threshold \code{t}). Requires optional
package \code{gmp} and runs no MIP solver.
}
\details{
The three methods differ in what they compute and assume:
\itemize{
\item \strong{Conditional fixed-sample IID (\code{method = "iid"})}: Before
generating or inspecting validation draws, fix the candidate report card
on separate exploration draws and save
\code{card$receipts$validation_spec_hashes} (\code{report}, \code{decision}, and
\code{target_law}, which exclude draw rows). Supply \code{design} with:
\code{spec_hashes} equal to that three-element list; \code{beta_exact} equal to the
reduced fraction string for \code{beta} (such as \code{"1/20"}); six \code{TRUE} flags
(\code{iid_whole_states}, \code{independent_of_exploration},
\code{frozen_before_validation}, \code{fixed_sample_size}, \code{no_validation_reuse},
\code{no_optional_stopping}); five non-blank strings (\code{iid_mechanism},
\code{independence_justification}, \code{exploration_history_id},
\code{frozen_record_id}, \code{validation_batch_id}); \code{fixed_S} matching the
validation draw count \code{S}; \code{validation_state_ids} matching the validation
state IDs in order; and \code{exploration_state_ids} (unique character vector,
possibly \code{character()}, disjoint from \code{validation_state_ids}).

\if{html}{\out{<div class="sourceCode">}}\preformatted{Given `v` observed joint-event violations out of `S` coupled validation
draws, the method tests \eqn{H_0: J > \alpha} against
\eqn{H_1: J \le \alpha} at Monte Carlo Type-I error level `beta`, setting
`joint_certificate = TRUE` and
`status = "certified_conditional_on_declared_iid_independence"` when the
exact `gmp` rational binomial lower tail
\eqn{\Pr(\mathrm{Binomial}(S, \alpha) \le v)} is at most `beta`
(`upper_display` is an approximate \eqn{1 - \beta} one-sided upper bound
on `J` for display only). Hash and disjoint-ID checks verify internal
consistency only and cannot prove prior fixation or independence;
non-acceptance returns `"inconclusive"`, which does not prove
`J > alpha`. Analytically zero union events (`"analytic_zero_event"`) and
`alpha = 1` (`"trivial_alpha_one"`) set `joint_certificate = TRUE`
without requiring `design`, while disabled joint protection sets
`status = "joint_protection_disabled"` and `joint_certificate = FALSE`.
}\if{html}{\out{</div>}}

\item \strong{Descriptive MCMC (\code{method = "mcmc"})}: Computes empirical hit
counts, zero-hit runs, and fixed-size batch summaries (retaining any
final partial batch) in supplied chain order. \code{joint_certificate} is
always \code{FALSE} (\code{diagnostics_not_certificate = TRUE}): batch summaries do
not imply independent replicates, IID/binomial inference, MCMC
convergence, or held-out validation, and zero observed hits do not
establish \code{J = 0} unless the event is analytically impossible (such as
\code{N = 0}).
\item \strong{Declared finite law (\code{method = "exact"})}: Evaluates \code{grades}
across all states of an \code{"exact_finite_law"} input
(\code{status = "evaluated_declared_finite_law"}). Floating-point state masses
are summed in floating-point arithmetic rather than converted to exact
rationals (reported in \code{evaluation$status$arithmetic}).
\code{joint_certificate} records whether \code{J <= alpha} under that declared
finite law, which is not a numerical guarantee about an underlying
continuous posterior if discretized states or floating-point masses were
used.
}
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
targets <- list(need = list(
  definition = "Priority score", units = "score",
  orientation = "larger_is_higher", equality_classes = c(A = "A", B = "B"),
  equality_provenance = "No structural tie."
))
mk <- function(ids, rev_pair) {
  array(c(ifelse(rev_pair, 1, 2), ifelse(rev_pair, 2, 1)),
    c(length(ids), 2L, 1L), dimnames = list(ids, c("A", "B"), "need"))
}
G <- matrix(1:2, 2L, 1L, dimnames = list(c("A", "B"), "need"))
d <- postrank_mdomain_decision(alpha = "1/10")

# 1. Complete declared finite law:
fin <- postrank_mdomain_input(mk(c("s1", "s2"), c(FALSE, TRUE)),
  targets = targets, representation = "exact_finite_law",
  masses = c("99/100", "1/100"),
  provenance = list(input_id = "fin", law_id = "two-state", proper_law = TRUE,
    joint_generation = "Two-state joint law.",
    sampling_assumptions = list(finite_support_origin = "Complete two-state law.")))
postrank_mdomain_assess(fin, G, decision = d, method = "exact")

# 2. Conditional fixed-S IID validation after freezing card hashes:
exp_in <- postrank_mdomain_input(mk(c("e1", "e2"), c(FALSE, FALSE)),
  targets = targets, representation = "iid_equal_weight_draws",
  provenance = list(input_id = "exp", law_id = "iid-law", proper_law = TRUE,
    joint_generation = "Independent whole states."))
card <- postrank_mdomain_evaluate(exp_in, G, d)
S <- 59L
val_ids <- paste0("v", seq_len(S))
set.seed(120)
val_in <- postrank_mdomain_input(mk(val_ids, stats::runif(S) < 0.01),
  targets = targets, representation = "iid_equal_weight_draws",
  provenance = list(input_id = "val", law_id = "iid-law", proper_law = TRUE,
    joint_generation = "Independent whole states."))
design <- list(
  spec_hashes = card$receipts$validation_spec_hashes, beta_exact = "1/20",
  fixed_S = S, iid_whole_states = TRUE, independent_of_exploration = TRUE,
  frozen_before_validation = TRUE, fixed_sample_size = TRUE,
  no_validation_reuse = TRUE, no_optional_stopping = TRUE,
  iid_mechanism = "Independent Bernoulli draws.",
  independence_justification = "Fresh RNG draws after freezing card.",
  exploration_history_id = "exp-1", frozen_record_id = "frz-59",
  validation_batch_id = "val-1", exploration_state_ids = c("e1", "e2"),
  validation_state_ids = val_ids
)
postrank_mdomain_assess(val_in, card, method = "iid", design = design)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}}, \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}},
\code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}}
}
\concept{multidomain}
