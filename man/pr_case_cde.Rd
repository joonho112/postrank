% Please edit documentation in R/data-case-cde.R
\docType{data}
\name{pr_case_cde}
\alias{pr_case_cde}
\title{Chronic Absence in a Small California School Example}
\format{
A named list with five elements:
\describe{
\item{input}{A \code{postrank_probabilities} object for the 12 schools on one
criterion, with marginal posterior means and 90\% equal-tail intervals for
\eqn{\theta = -p}.}
\item{units}{Data frame of 12 rows in input order with columns
\code{entity_id} (14-digit County-District-School CDS codes stored as
character strings to preserve leading zeros), \code{chronic_absent_count},
\code{eligible_count}, \code{observed_rate}, \code{observed_rate_group} and
\code{denominator_group}. Counts are observed school data, not posterior
estimates.}
\item{alternatives}{Alternative \code{postrank_probabilities} inputs \code{order_32}
and \code{order_64}, computed with 32 and 64 Gauss-Legendre nodes per prior
bin under the same posterior and marginal summaries.}
\item{reference}{Settings, three fixed comparison gradings (all-unordered,
observed-rate tertiles and posterior-mean tertiles) with their losses,
piecewise-Beta posterior parameters, quadrature diagnostics, and
archived statewide baseline summaries.}
\item{provenance}{Source filenames and SHA-256 hashes, dates, school
selection rule, model conditioning, target orientation, attribution and
historical preparation-stage review records. Raw CDE download files,
logos, full source tables and statewide pairwise matrices are not
bundled.}
}
}
\source{
California Department of Education, 2026 California School Dashboard
chronic absenteeism data, academic year 2025--26,
\url{https://www.cde.ca.gov/ta/ac/cm/chronicdatafiles.asp}; source
conditions at \url{https://www.cde.ca.gov/re/di/cr/index.asp} (accessed
2026-10-30). Empirical-Bayes model, numerical integration and 12-school
selection by the package author; no CDE endorsement is implied.
}
\usage{
pr_case_cde
}
\description{
\code{pr_case_cde} is a one-criterion case-study dataset for 12 California
elementary schools adapted from 2026 California School Dashboard
chronic-absenteeism counts (academic year 2025--26) and an empirical-Bayes
model. Larger target values mean lower chronic-absence probability:
\eqn{\theta = -p}, measured in proportion units. Source attribution and
documented adaptations are recorded in \code{provenance} and the installed
\code{DATA-NOTICE.md} file.
}
\details{
\strong{School selection.} The statewide frame comprises 5,834 elementary-type
schools outside Dashboard Alternative School Status (non-DASS, including
eligible charter schools) with usable ALL-student chronic-absence counts and
denominators of at least 30. One school was chosen from each cell of 4
observed-rate rank groups crossed with 3 denominator rank groups (the
lower-median row \code{ceiling(m / 2)} within each cell when ordered by observed
rate, denominator and CDS code). This 12-school subset spans rate and size
strata for teaching and is not a representative sample of California
schools.

\strong{Posterior and numerical integration.} A piecewise-uniform empirical-Bayes
prior \code{G} over 161 continuous bins was estimated on the 5,834-school frame
and held fixed; uncertainty in estimating \code{G} is not propagated. Within each
bin, a school's posterior is a truncated \code{Beta(y + 1, n - y + 1)} density
weighted by its posterior bin probability, so independent school posteriors
given \code{G} have zero probability of exact equality. Primary pairwise
probabilities use 16 Gauss-Legendre nodes per bin, clipping raw values that
overshot \verb{[0, 1]} by at most 64 machine epsilons back into \verb{[0, 1]} before
applying symmetric complement correction with \code{tolerance = 1e-6} in
\code{\link[=postrank_probabilities]{postrank_probabilities()}}. Small corrections and agreement across 16, 32
and 64 nodes are diagnostic checks, not certified bounds on integration
error, and no posterior draws are stored.

\strong{Intervals and scope.} Each school's mean is \eqn{-E[p]} and its 90\%
marginal (not simultaneous) interval is \eqn{[-q_{0.95}(p), -q_{0.05}(p)]};
pass \code{level = 0.90} in \code{\link[=postrank]{postrank()}} or \code{\link[=postrank_report_card]{postrank_report_card()}} (other
levels cannot be computed from stored summaries). Archived statewide rows in
\code{reference$statewide$metrics} summarize fixed-order contiguous cuts, an
all-unordered row and matched grade-size baselines rather than an
unrestricted 5,834-school optimization, and their independent-pair
relaxation lower bound has a separate scope. Posterior-conditioned losses do
not provide external validation, and the results do not reproduce California
Dashboard Status-plus-Change colors or estimate causal effects.

\strong{Source conditions.} Only the 12 selected school IDs/counts and
author-derived summaries are included. \code{provenance$rights} retains historical
preparation-stage records, while the installed \code{DATA-NOTICE.md} describes the
current public distribution scope. CDE source conditions apply to \code{pr_case_cde}
and dependent stored results (such as \code{postrank_example("case_cde_12")})
rather than a Creative Commons or MIT code license.
}
\examples{
x <- pr_case_cde
x$units[, c("entity_id", "chronic_absent_count", "eligible_count", "observed_rate")]
postrank_posterior_means(x$input, level = 0.90)

cde_res <- postrank_example("case_cde_12")
get_grades(cde_res)
}
\seealso{
\code{\link[=postrank_example]{postrank_example()}}, \code{\link[=postrank_probabilities]{postrank_probabilities()}},
\code{\link[=postrank_report_card]{postrank_report_card()}},
\code{vignette("a2-cde-accountability", package = "postrank")}
}
\concept{data}
\keyword{datasets}
