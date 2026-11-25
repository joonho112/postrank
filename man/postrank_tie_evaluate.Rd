% Please edit documentation in R/tie-evaluate.R
\name{postrank_tie_evaluate}
\alias{postrank_tie_evaluate}
\title{Evaluate a Fixed Grading Under Equality-Neutral Loss}
\usage{
postrank_tie_evaluate(grade, pairwise, weights, tau)
}
\arguments{
\item{grade}{Positive integer/numeric vector named in the exact order of
\code{pairwise$entity_ids} (\code{1} = highest priority; occupied labels are
renumbered to \verb{1..G} by \code{\link[=canonical_postrank_grade]{canonical_postrank_grade()}} without changing
pairwise relations).}

\item{pairwise}{A validated \code{postrank_tie_pairwise} object from
\code{\link[=postrank_tie_pairwise]{postrank_tie_pairwise()}}.}

\item{weights}{Non-negative finite numeric vector named by every criterion in
\code{pairwise} and summing to \code{1} (for a single criterion, supply a named
weight of \code{1}; weights are not normalized automatically).}

\item{tau}{Cost of withholding a distinct comparison, a finite scalar with
\verb{0 < tau <= 0.5}.}
}
\value{
A \code{postrank_tie_evaluation} list containing canonical \code{grade}, \code{G},
\code{M = choose(n, 2)}, \code{N}, directed-disclosure matrix \code{x},
\code{disclosure_rate = N / M}, \code{abstention_rate = (M - N) / M}, criterion
counts \code{E} (also \code{Eb}, expected strict wrong-direction errors), \code{D_k}
(expected disclosed-distinct pairs), \code{T_k} (expected total-distinct pairs),
and \code{H_k} (expected withheld-distinct pairs), weighted distinct counts \code{D}
and \code{T}, ratios \code{E_over_M}, \code{E_over_N}, \code{E_over_D}, \code{D_k_over_T_k}, and
\code{D_over_T} (also \code{distinct_disclosure_rate}; ratios with zero denominator
are \code{NA_real_}), \code{criterion_risk}, \code{criterion_baseline}, \code{weighted_risk}
and \code{primary_risk}, \code{all_withhold_risk} and \code{R0}, \code{weighted_raw_objective}
and \code{raw_Z}, \code{guard_satisfied}, \code{guard_classes}, \code{guard}, and \code{settings}.
}
\description{
\code{postrank_tie_evaluate()} computes posterior expected equality-neutral loss,
distinct-pair counts, and error ratios for a fixed grading without running a
solver. Under equality-neutral loss, ordering a pair incurs loss only when
the targets are strictly reversed (\code{theta_i < theta_j}), and leaving a pair
in the same grade costs \code{tau} only when the targets are distinct
(\code{theta_i != theta_j}), so exact equality (\code{theta_i = theta_j}) has zero loss
under either decision. Placing two entities in the same grade still leaves
them unordered rather than claiming their targets are equal.
}
\details{
Criterion risk is \code{(E + tau * H_k) / M}, and the all-withheld risk is
\code{R0 = tau * T / M} (smaller than \code{tau} whenever positive equality probability
is present on an active criterion). Weighted risk equals \code{R0 + raw_Z / M}
with \code{raw_Z = sum(weights * E) - tau * D}, and is summed directly from
\code{pairwise$b} and \code{pairwise$d} independently of any sparse MIP model. For an
all-withheld single-grade grading (\code{G = 1}), \code{N} and every \code{D_k} are \code{0},
\code{primary_risk} equals \code{R0}, and \code{E_over_N} and \code{E_over_D} are \code{NA_real_}.

Reported ratios (\code{E_over_N}, \code{E_over_D}, \code{D_over_T}) are ratios of posterior
expected counts under the supplied posterior rather than expectations of
per-draw ratios. \code{guard_satisfied} records whether \code{grade} keeps each
active-profile equality class (\code{guard$groups}) in one grade; unlike
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}, \code{postrank_tie_evaluate()} also evaluates gradings
that split an equality class for comparison and does not check \code{G_max}
feasibility (use \code{\link[=validate_postrank_tie_solution]{validate_postrank_tie_solution()}} to check solver
candidates). Ordinary \code{\link[=postrank_evaluate]{postrank_evaluate()}} retains its zero-equality
weak-error loss.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
path <- system.file("examples", "synthetic-tie-aware.json", package = "postrank")
pw <- postrank_tie_pairwise(read_postrank_tie_draws(path))
weights <- c(S = 0.6, C = 0.4)
ev <- postrank_tie_evaluate(
  c(A = 3L, B = 3L, C = 2L, D = 1L),
  pw,
  weights,
  tau = 0.25
)
ev[c("primary_risk", "R0", "N", "D", "T", "guard_satisfied")]

held <- postrank_tie_evaluate(
  c(A = 1L, B = 1L, C = 1L, D = 1L),
  pw,
  weights,
  tau = 0.25
)
held[c("primary_risk", "E_over_N", "E_over_D")]
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_tie_problem]{postrank_tie_problem()}}, \code{\link[=postrank_tie_solve]{postrank_tie_solve()}},
\code{\link[=validate_postrank_tie_solution]{validate_postrank_tie_solution()}}, \code{\link[=postrank_tie_capabilities]{postrank_tie_capabilities()}},
\code{vignette("m4-ties-and-withholding", package = "postrank")}
}
\concept{tie-aware}
