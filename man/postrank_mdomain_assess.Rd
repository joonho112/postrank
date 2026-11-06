% Please edit documentation in R/mdomain-assess.R
\name{postrank_mdomain_assess}
\alias{postrank_mdomain_assess}
\title{Assess a Fixed Multidomain Report}
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
\item{input}{The actual \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} law or history to assess.}

\item{grades}{A named unit by domain matrix, a verified
\code{postrank_mdomain_evaluation}, or a successful \code{postrank_mdomain_fit}.
A stored card supplies its fixed grades and decision. Its report, decision
and target-law hashes must match assessment of the actual \code{input}.}

\item{decision}{A \code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}} recipe. \code{NULL} uses the
stored card's decision when \code{grades} is a card or fit, and the documented
default decision for a matrix. A supplied recipe must preserve a stored
card's exact decision contract.}

\item{method}{Explicit assessment route: \code{"mcmc"} requires MCMC payloads;
\code{"iid"} requires a declared joint iid equal-weight input; \code{"exact"}
requires finite-law payloads. Representations are never relabeled.}

\item{design}{For iid assurance, the native frozen validation record
described below. For MCMC or finite-law assessment, an optional caller
record (for example \code{list(role = "assessment_history")}) retained as
supplied. Sampling claims remain producer declarations.}

\item{beta}{Exact numerical error budget in \verb{(0,1)} for the iid count rule,
distinct from the decision's scientific joint-event cap \code{alpha}.}

\item{...}{Named options. All methods accept \code{keep_traces = TRUE}. MCMC
accepts \code{batch_size = 50L} and \code{run_id = input$input_id}. iid accepts
exact-count workload caps \code{max_S = 10000L}, \code{max_bits = 1000000L}, and
\code{max_work = 50000000}. Other options raise a typed error.}
}
\value{
A \code{postrank_mdomain_assessment} containing \code{evaluation}, the public
fixed-card evaluation of the actual input; \code{native}, the unchanged native
iid validation, MCMC diagnostic, or finite-law evaluation; \code{method}, native
\code{status}, \code{grades}, bound \code{decision}, \code{spec_hashes}, retained \code{design},
\code{risk}, \code{risk_exact}, \code{J}, \code{J_exact}, \code{joint_certificate},
\code{certificate_scope}, \code{assurance}, and consistency receipts. The certificate
concerns only the specified joint event. Mean guards, report optimality,
scientific sampling claims and model calibration are not certified.
}
\description{
Evaluate the actual supplied states using complete finite-law support,
conditional fixed-sample iid assurance, or descriptive MCMC diagnostics.
}
\details{
Before collecting or inspecting iid validation states, freeze the
report, decision, target law, sample size and numerical budget. A public
card exposes \code{card$receipts$validation_spec_hashes}, a named list containing
\code{report}, \code{decision}, and \code{target_law} hashes. Set \code{design$spec_hashes} to
that saved list; constructing this record after seeing validation states
does not establish prior freezing.

The iid design is passed unchanged to the native validator. It requires:
\itemize{
\item \code{spec_hashes} matching the frozen three-field list, and
\code{beta_exact}, the canonical rational string matching \code{beta}.
\item \code{iid_whole_states}, \code{independent_of_exploration},
\code{frozen_before_validation}, \code{fixed_sample_size}, \code{no_validation_reuse},
and \code{no_optional_stopping}, each exactly \code{TRUE}.
\item Nonblank strings \code{iid_mechanism}, \code{independence_justification},
\code{exploration_history_id}, \code{frozen_record_id}, and \code{validation_batch_id}.
\item \code{fixed_S}, the predeclared positive numeric integer equal to the
relevant validation trace length; \code{validation_state_ids}, the actual
relevant state IDs in supplied order; and \code{exploration_state_ids}, a
unique character vector disjoint from validation IDs, possibly empty.
}
Input producer selection/validation IDs are also checked when supplied.
Hashes, source records and disjoint IDs check consistency; they do not
prove independence or that freezing occurred before validation. Duplicate
target values are permitted. The strict joint event is evaluated on whole
states, never on randomly paired domain margins. The exact rational
binomial tail decides acceptance; its floating upper bound is display only.
Failure to certify is \code{"inconclusive"}, not a proof of infeasibility.
\code{assurance$numerical_guarantee} and
\code{assurance$conditional_iid_guarantee_available} are true only for an
accepted iid count bound, conditional on the retained declared assumptions;
\code{numerical_guarantee_conditional} and \code{numerical_guarantee_conditions}
identify that scope. \code{fixed_evaluation_numerical_guarantee} retains the
underlying empirical evaluation's separate flag. No unconditional target-law
guarantee or intended-posterior/model-calibration certificate is inferred.
Analytically zero events and \code{alpha = 1} need no sampling certificate;
disabled joint protection supplies no joint certificate.

MCMC output is an empirical diagnostic. Its native record preserves
supplied chain order, hit counts, zero runs and fixed batches, including
final partial batches. No iid/binomial inference, convergence certificate,
independent-replicate claim, or held-out interpretation is inferred.
Observed zero hits differ from a structurally zero event. Finite-law
assessment evaluates all supplied support of the declared law; \code{"exact"}
identifies that route and does not turn floating masses into rational
arithmetic. Rational/approximate arithmetic and producer declarations are
reported separately. Display and summary methods consume stored results.
}
\examples{
if (requireNamespace("gmp", quietly = TRUE)) {
  units <- c("A", "B")
  targets <- list(need = list(definition = "Fictional priority coordinate",
    units = "score", orientation = "larger_is_higher",
    transformations = list(), equality_classes = c(A = "A", B = "B"),
    equality_provenance = "Distinct units have no structural identity."))
  provenance <- list(input_id = "exploration", law_id = "fictional-iid-law",
    proper_law = TRUE, producer = "Independent example generator",
    joint_generation = "Each row is one complete state of both units.",
    sampling_assumptions = list(iid_whole_states = TRUE))
  make_states <- function(ids, reverse = rep(FALSE, length(ids))) {
    x <- array(0, c(length(ids), 2L, 1L),
      dimnames = list(ids, units, "need"))
    x[, 1L, 1L] <- ifelse(reverse, 1, 2)
    x[, 2L, 1L] <- ifelse(reverse, 2, 1)
    x
  }
  exploration_ids <- c("explore-1", "explore-2")
  exploration <- postrank_mdomain_input(make_states(exploration_ids),
    targets = targets, provenance = provenance,
    representation = "iid_equal_weight_draws")
  G <- matrix(1:2, 2L, dimnames = list(units, "need"))
  d <- postrank_mdomain_decision(alpha = "1/10")
  card <- postrank_mdomain_evaluate(exploration, G, d)
  # Record this fixed contract before generating validation states.
  S <- 59L
  validation_ids <- paste0("validate-", seq_len(S))
  design <- list(spec_hashes = card$receipts$validation_spec_hashes,
    beta_exact = "1/20", fixed_S = S,
    iid_whole_states = TRUE, independent_of_exploration = TRUE,
    frozen_before_validation = TRUE, fixed_sample_size = TRUE,
    no_validation_reuse = TRUE, no_optional_stopping = TRUE,
    iid_mechanism = "Independent Bernoulli draws for complete states.",
    independence_justification = "Fresh RNG draws after the fixed record.",
    exploration_history_id = "example-exploration",
    frozen_record_id = "example-fixed-59", validation_batch_id = "example-validation",
    exploration_state_ids = exploration_ids, validation_state_ids = validation_ids)
  set.seed(120)
  validation_states <- make_states(validation_ids, stats::runif(S) < .01)
  provenance$input_id <- "validation"
  validation <- postrank_mdomain_input(validation_states, targets = targets,
    provenance = provenance, representation = "iid_equal_weight_draws")
  assessed <- postrank_mdomain_assess(validation, card, method = "iid", design = design)
  summary(assessed)
  # Complete finite support is assessed through its declared-law route.
  finite_provenance <- provenance
  finite_provenance$sampling_assumptions <- list(
    finite_support_origin = paste("The two listed states and exact masses",
      "define the complete fictional law."))
  finite <- postrank_mdomain_input(make_states(c("law-1", "law-2"), c(FALSE, TRUE)),
    targets = targets, provenance = finite_provenance,
    representation = "exact_finite_law", masses = c("99/100", "1/100"))
  postrank_mdomain_assess(finite, G, decision = d, method = "exact")
}
}
\concept{multidomain}
