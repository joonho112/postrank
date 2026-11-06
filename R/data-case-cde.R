#' Chronic Absence in a Small California School Example
#'
#' A one-criterion teaching example using 12 schools from a frozen 2026
#' California School Dashboard chronic-absence analysis. Larger target values
#' mean lower chronic-absence probability: \eqn{\theta=-p}. The target uses
#' proportion units. Source attribution and documented transformations are
#' retained in the object and the installed DATA-NOTICE.
#'
#' @format A named list with five elements:
#' \describe{
#'   \item{input}{A validated \code{postrank_probabilities} input for 12
#'     schools and one criterion, with genuine posterior means and fixed
#'     90% equal-tail marginal intervals for the same oriented target.}
#'   \item{units}{12 rows in input order: school CDS IDs as character strings,
#'     chronic-absence numerators, eligible denominators, observed proportions,
#'     and the two selection strata. Counts are local source observations,
#'     not posterior estimates.}
#'   \item{alternatives}{\code{order_32} and \code{order_64} are supported
#'     inputs calculated with more quadrature nodes per prior bin. They use
#'     the same posterior law, observations and supplied marginal summaries.}
#'   \item{reference}{Settings and three fixed teaching actions, their risk
#'     evaluations, compact continuous posterior parameters, separate upstream
#'     and constructor corrections, quadrature diagnostics, and archived
#'     statewide summary rows. These are archive records rather than current
#'     native fits.}
#'   \item{provenance}{Source-relative filenames and SHA-256 hashes, dates,
#'     selection rule, model conditioning, target direction, citation and
#'     historical source-review records. No raw CDE download is bundled.}
#' }
#' @details The source frame contains 5,834 elementary-type, non-DASS,
#' ALL-student schools with usable chronic-absence counts and denominators
#' at least 30; charter schools remain eligible. It is not all California
#' schools. The teaching selection takes one school from each of four
#' observed-rate rank groups crossed with three denominator rank groups.
#' Within a cell, the lower middle school ordered by observed rate,
#' denominator and CDS ID is selected. The subset is deliberately spread,
#' not a representative statewide sample. Input order follows the rate group
#' and then the denominator group.
#'
#' The empirical Bayes prior G was estimated on the full source frame and
#' remains fixed for this subset. Uncertainty is conditional on that estimated
#' G; uncertainty in estimating G is not propagated. The prior is uniform
#' within 161 continuous bins. Within a bin the posterior is a truncated
#' Beta(y+1,n-y+1) density, weighted by that school's posterior bin mass.
#' It is neither a uniform posterior within bins nor a set of bin-center
#' atoms. Independent school posteriors given G have zero equality probability.
#'
#' The primary comparison probabilities use 16 Gauss-Legendre nodes per bin.
#' Stored refinements use 32 and 64 nodes. Source integration retains raw
#' probabilities before correcting values outside \eqn{[0,1]} by at most 64 machine
#' epsilons. The public input then applies a separate symmetric
#' reverse-complement correction with tolerance 1e-6. Neither a small correction
#' nor agreement between refinement orders is a certified integration-error
#' bound. No posterior draws or Monte Carlo diagnostics are claimed.
#'
#' The supplied target mean is \eqn{-E[p]}. Its 90% interval is
#' \eqn{[-q_{.95}(p), -q_{.05}(p)]}; the negative direction reverses the endpoints.
#' Request \code{level = .9} to use these intervals in \code{postrank()} or
#' \code{postrank_report_card()}. Other interval levels cannot be recovered
#' from the supplied summaries. The retained intervals are marginal,
#' not simultaneous.
#'
#' The three sample actions withhold all comparisons or use fixed observed-rate
#' and posterior-mean tertiles. They have no optimization guarantee. Archived
#' statewide rows describe fixed-order contiguous cuts and other baselines.
#' Optimal cuts conditional on a declared order are not an unrestricted
#' statewide optimum; their independent-pair relaxation lower bound has a
#' separate scope. These posterior-conditioned risks do not provide external
#' validation. Current-probability comparisons do not reproduce Dashboard
#' Status-plus-Change colors or establish causal effects. Suspension is a
#' separate extension and is not included here.
#'
#' The asset contains selected public-source IDs/counts and author-derived
#' numerical results, not CDE raw files or logos. The original source attribution
#' and historical preparation records remain in the provenance. The installed
#' DATA-NOTICE describes the current distribution scope. No Creative Commons
#' or package-code license is substituted for the CDE source conditions.
#' @source California Department of Education, 2026 California School
#' Dashboard chronic absenteeism data, academic year 2025--26.
#' \url{https://www.cde.ca.gov/ta/ac/cm/chronicdatafiles.asp}.
#' Source copyright statement:
#' \url{https://www.cde.ca.gov/re/di/cr/index.asp} (accessed 2026-10-30).
#' Model, numerical integration and teaching selection by the case-study
#' authors. No CDE endorsement is implied.
#' @seealso `vignette("a2-cde-accountability", package = "postrank")`,
#'   [postrank_probabilities()], [postrank_report_card()]
#' @examples
#' x <- pr_case_cde
#' x$units
#' postrank_posterior_means(x$input, level = .9)
#' ev <- postrank_evaluate(x$reference$actions$posterior_mean_tertiles,
#'   x$input, tau = .2, weights = x$reference$settings$weights)
#' ev[c("G", "N", "M", "primary_risk")]
#' x$reference$statewide$metrics[c("method", "N", "E", "risk")]
#' @keywords datasets
#' @concept data
"pr_case_cde"
