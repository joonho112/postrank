% Please edit documentation in R/mdomain-input.R
\name{postrank_mdomain_input}
\alias{postrank_mdomain_input}
\title{Prepare Posterior States for Multidomain Grading}
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
\item{x}{One of four inputs:
\itemize{
\item a 3D finite numeric array (\verb{state x unit x domain}) with unique
non-blank dimnames on all three axes (\code{S >= 1}, \code{n >= 2}, \code{D >= 1});
\item a domain-named list of 2D finite numeric matrices (\verb{state x unit})
sharing identical unit column names in the same order;
\item a validated \code{\link[=postrank_draws]{postrank_draws()}} object (adapted with its stored
targets, representation, and draw history; leave \code{targets},
\code{representation}, \code{masses}, \code{state_origin}, and \code{equality_classes} as
\code{NULL});
\item a complete native specification list (\code{!is.null(x$layout)}) or an
existing \code{postrank_mdomain_input} object to revalidate (with all extra
arguments \code{NULL}).
}}

\item{targets}{Named list in exact domain order. Each domain record requires
non-empty strings \code{definition}, \code{units}, and \code{equality_provenance},
\code{orientation = "larger_is_higher"}, character vector \code{equality_classes}
(one non-blank class label per unit in unit order; distinct labels declare
no structural tie), and optional \code{transformations} (defaults to \code{list()}).}

\item{provenance}{Named list requiring non-empty strings \code{input_id} and
\code{law_id}, plus \code{proper_law = TRUE}. Joint 3D arrays also require non-empty
\code{joint_generation}; separate domain matrix lists require
\code{within_domain_joint}. When \code{representation = "exact_finite_law"},
\code{provenance$sampling_assumptions$finite_support_origin} is also required.
Optional source, sampling, and retention fields are kept as supplied, and
omitted optional fields are listed in \code{missing_metadata} rather than filled
in automatically.}

\item{representation}{State representation: \code{"exact_finite_law"},
\code{"iid_equal_weight_draws"}, or \code{"mcmc_equal_weight_draws"} (for separate
domain matrices, may be a domain-ordered named character vector).}

\item{masses}{State masses required when
\code{representation = "exact_finite_law"}: exact rational strings summing to
\code{1} (for example \code{c("1/10", "9/10")}), numeric weights, or
\code{list(encoding = ..., values = ...)}. Separate domain inputs take a
domain-ordered named list.}

\item{state_origin}{Data frame with one row per state and columns
\code{source_index}, \code{chain_id}, and \code{iteration_id} (plus optional \code{state_id}
matching state dimnames). Required without missing values (\code{iteration_id >= 1}) when \code{representation = "mcmc_equal_weight_draws"}. Separate domain
inputs take a domain-ordered named list.}

\item{equality_classes}{Optional domain-ordered named list of unit equality
class vectors (equivalent to supplying \code{equality_classes} inside each
\code{targets} entry). Shared labels declare model-based equality and are never
inferred from observed numerical ties.}
}
\value{
A \code{postrank_mdomain_input} object (inheriting \code{p2_profile_input})
containing \code{unit_ids}, \code{domain_ids}, \code{n}, \code{D}, \code{layout}, \code{representation},
\code{coupling_status}, \code{payloads}, \code{capabilities}, \code{missing_metadata},
\code{original_spec}, and validation \code{receipts}.
}
\description{
\code{postrank_mdomain_input()} binds unit IDs, domain IDs, target definitions,
and source metadata to posterior states for multidomain profile grading,
where each unit receives a separate integer grade on each domain rather than
a single shared grade across criteria. It validates the supplied states and
metadata without fitting a statistical model or inventing cross-domain
dependence. Requires optional package \code{gmp}.
}
\details{
Separate domain matrix lists (\code{layout = "criterionwise_arrays"}) set
\code{coupling_status = "unknown_cross_domain"}: they support additive expected
loss and joint events involving at most one active domain, and matching state
row names across matrices are never treated as coupled joint draws. Adapting
an existing \code{\link[=postrank_draws]{postrank_draws()}} object revalidates it and carries over its
target definitions and sampling metadata once \code{provenance} supplies
\code{input_id}, \code{law_id}, and \code{proper_law = TRUE}. Metadata fields record how
the input was constructed without verifying model specification or MCMC
convergence.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
inp
inp$domain_ids
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}}, \code{\link[=postrank_mdomain_family]{postrank_mdomain_family()}},
\code{\link[=postrank_mdomain_evaluate]{postrank_mdomain_evaluate()}}, \code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}}
}
\concept{multidomain}
