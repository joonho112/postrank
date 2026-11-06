#' Race and Gender Contact Gaps at 97 Employers
#'
#' A compact teaching case adapted from Kline, Rose, and Walters' 2024
#' replication archive for *A Discrimination Report Card*. The primary input
#' contains all 97 firms, with signed race and gender contact-gap targets.
#' Larger `race_signed` means a larger white-name contact advantage,
#' `log(p_white) - log(p_black)`; larger `gender_signed` means a larger
#' male-name contact advantage, `log(p_male) - log(p_female)`.
#' Signed gender is not the magnitude of a gap in either direction.
#'
#' The probabilities and marginal summaries describe continuous uniform cells
#' between adjacent retained posterior-grid midpoints. Each cell keeps its
#' posterior mass, and the first race cell has nonnegative support. The
#' empirical-Bayes prior and its fitted parameters remain fixed. There is no
#' refit or Gaussian posterior approximation. The supplied means and central
#' equal-tail intervals describe the same cell law; the interval level is
#' **90%**, so use `level = .9` when requesting a report card. No target draws,
#' Monte Carlo sample size, or cross-criterion joint law are supplied.
#'
#' Single-criterion alternatives retain the same signed targets and firms.
#' The absolute-gender alternative folds the original signed uniform cells,
#' including cells crossing zero, and has its own probabilities and summaries.
#' Raw archive Pi, its explicitly repaired plotting convention, and literal
#' grid atoms are distinct references. They are not substituted for the
#' primary cell-law input, and their numerical qualifications are not inherited
#' by a new calculation.
#'
#' The archived single-criterion cards use lambda = .25, corresponding to
#' tau = .2. The archived common-grade operating point instead uses tau = .25,
#' equal criterion weights and at most four grades. Stored actions are
#' re-evaluated under the cell law without claiming a new optimum. The source
#' research campaign completed 9 of 236 distinct numerical problems; the other
#' 227 were not run. The archive describes the original correspondence
#' experiment, not firms' current behavior or a causal policy comparison.
#'
#' @format A plain list with five elements:
#' \describe{
#'   \item{input}{A validated `postrank_probabilities` object with a
#'     97 x 97 x 2 directional-error array and matching 97 x 2 cell-law means
#'     and 90% interval endpoints.}
#'   \item{units}{A 97-row table in input order: `entity_id`, `firm_id`,
#'     `firm_name`, `industry`, `race_estimate`, `race_se`, `gender_estimate`,
#'     and `gender_se`. Estimates and SEs are on the source log-contact-gap
#'     scale; they are not posterior means or standard deviations.}
#'   \item{alternatives}{Supported probability inputs named `race`, `gender`,
#'     and `absolute_gender`. The first two have K = 1; the last retains signed
#'     race and replaces signed gender with the absolute target.}
#'   \item{reference}{Archived actions, settings and law-labelled metrics;
#'     separate raw and plotting Pi arrays; cell-versus-archive diagnostics;
#'     and the limited source certification counts. These are reference
#'     records rather than current `postrank_fit` objects.}
#'   \item{provenance}{Relative source filenames and SHA-256 hashes, original
#'     grid component hashes, source versions, posterior interpretation,
#'     attribution, rights notice, and the maintainer extraction script.}
#' }
#' @source Kline, Patrick, Evan Rose, and Christopher Walters (2024).
#'   *Data and Code for: A Discrimination Report Card*. American Economic
#'   Association (publisher); ICPSR (distributor).
#'   \doi{10.3886/E198284V1}. Extracted by
#'   `data-raw/make-pr-case-krw.R` from the frozen research case, preserving the
#'   original firm order and fixed posterior parameters. Original grids remain
#'   in the source archive and are not duplicated in this object.
#' @details The source README states: "The data are licensed under a Creative
#'   Commons/CC-BY-NC license." It does not specify a license version. The
#'   compact adaptation retains that noncommercial source notice. These data
#'   conditions are separate from the package code license. The cell-law
#'   interpretation and compact extraction are adaptations by the postrank
#'   case-study maintainers; no endorsement by the original authors is implied.
#' @concept data
#' @seealso `vignette("a3-krw-race-gender", package = "postrank")`,
#'   [postrank_probabilities()], [postrank_report_card()]
#' @examples
#' dim(pr_case_krw$input$e)
#' pr_case_krw$reference$single_criterion$archive_metrics
#' x <- pr_case_krw$input
#' g <- pr_case_krw$reference$signed_core$grade
#' postrank_evaluate(g, x, weights = c(race_signed = .5,
#'   gender_signed = .5), tau = .25)$weighted_risk
"pr_case_krw"
