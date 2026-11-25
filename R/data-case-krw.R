#' Race and Gender Contact Gaps at 97 Employers
#'
#' `pr_case_krw` is a two-criterion case-study dataset for 97 U.S. employers
#' adapted from the replication archive of Kline, Rose and Walters (2024),
#' *A Discrimination Report Card*. Its primary input compares all 97 firms on
#' signed race and gender callback-gap targets: larger `race_signed` means a
#' larger white-name callback advantage (`log(p_white) - log(p_black)`), and
#' larger `gender_signed` means a larger male-name callback advantage
#' (`log(p_male) - log(p_female)`, signed rather than folded in magnitude).
#'
#' @format A named list with five elements:
#' \describe{
#'   \item{input}{A `postrank_probabilities` object with a `97 x 97 x 2`
#'     directional-error array and matching `97 x 2` posterior means and 90%
#'     equal-tail intervals.}
#'   \item{units}{Data frame of 97 rows in input order: `entity_id`, `firm_id`,
#'     `firm_name`, `industry`, `race_estimate`, `race_se`, `gender_estimate`
#'     and `gender_se` (direct log-contact-gap estimates and standard errors,
#'     not posterior means or standard deviations).}
#'   \item{alternatives}{Named list of `postrank_probabilities` inputs:
#'     single-criterion `race` and `gender`, and two-criterion `absolute_gender`
#'     (replacing `gender_signed` with `|gender_signed|` folded across zero).}
#'   \item{reference}{KRW single-criterion report cards (`single_criterion`),
#'     companion two-criterion common-grading references (`signed_core` and
#'     `absolute_sensitivity`), cell-law and archive-matrix loss summaries, raw
#'     and plotting `Pi` arrays, and summary counts of solved specification-grid
#'     cells.}
#'   \item{provenance}{Source filenames and SHA-256 hashes, posterior cell-law
#'     construction, attribution and the source CC-BY-NC rights notice.}
#' }
#' @details
#' **Posterior cell law.** Pairwise probabilities and marginal summaries treat
#' each firm's posterior mass on the replication grid as uniform over
#' continuous cells between adjacent grid midpoints (with nonnegative support on
#' the lowest race cell), holding the archive's empirical-Bayes prior fixed
#' without refitting or normal approximation. Pass `level = 0.90` when
#' requesting a report card in [postrank()] or [postrank_report_card()]. No
#' posterior draws or cross-criterion joint distribution are stored.
#'
#' **Reference settings.** Kline, Rose and Walters (2024) report
#' single-criterion report cards (`single_criterion`) at benchmark preference
#' parameter `lambda = 0.25` (`tau = 0.20`) allowing up to `97` grades (`3`
#' occupied grades on race and `4` on gender without industry controls). The
#' two-criterion common gradings (`signed_core` and
#' `postrank_example("case_krw_signed97")`) are `postrank` companion analyses
#' using `tau = 0.25`, equal weights `(0.5, 0.5)` and `G_max = 4`. Stored
#' reference actions are evaluated under the midpoint-cell law (not a new solve
#' or exact optimality claim over alternative laws) and describe the historical
#' correspondence experiment rather than current firm practices.
#'
#' **Source license.** The replication archive README states: `"The data are
#' licensed under a Creative Commons/CC-BY-NC license."` without naming a
#' license version. `pr_case_krw` and dependent stored results retain that
#' noncommercial CC-BY-NC condition separately from the package's MIT code
#' license (`provenance$rights` retains historical preparation records, while
#' the installed `DATA-NOTICE.md` states the current public distribution scope).
#' @source Kline, Patrick, Evan K. Rose and Christopher R. Walters (2024),
#'   *Replication Data for: A Discrimination Report Card* (titled *Data and Code
#'   for: A Discrimination Report Card* on openICPSR), American Economic
#'   Association / ICPSR deposit E198284V1, \doi{10.3886/E198284V1}. Midpoint
#'   cell-law probabilities and compact extraction by `data-raw/make-pr-case-krw.R`
#'   (no endorsement by the original authors is implied).
#' @seealso [postrank_example()], [postrank_probabilities()],
#'   [postrank_report_card()],
#'   `vignette("a3-krw-race-gender", package = "postrank")`
#' @concept data
#' @examples
#' dim(pr_case_krw$input$e)
#' pr_case_krw$reference$single_criterion$archive_metrics
#'
#' x <- pr_case_krw$input
#' g <- pr_case_krw$reference$signed_core$grade
#' postrank_evaluate(g, x, weights = c(race_signed = 0.5,
#'   gender_signed = 0.5), tau = 0.25)$weighted_risk
"pr_case_krw"
