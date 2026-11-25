#' One or Two Criteria for Six Fictional Sites
#'
#' `pr_tutorial` is a synthetic normal-posterior dataset for six fictional sites
#' (`A` through `F`) on one criterion (`score_A`) or two criteria (`score_A`
#' and `score_B`). All means and standard deviations are specified directly
#' rather than fitted to real data, providing the introductory examples used in
#' `vignette("a1-getting-started", package = "postrank")`.
#'
#' @format A named list with four elements:
#' \describe{
#'   \item{one}{A `postrank_coefficients` object with one criterion (`score_A`)
#'     for sites `A` through `F`.}
#'   \item{two}{A `postrank_coefficients` object for the same six sites on
#'     `score_A` and `score_B`, keeping the exact same marginal distribution for
#'     `score_A` as `one`.}
#'   \item{units}{Data frame of site IDs and display labels in input order.}
#'   \item{law}{List of the specified means, covariance matrices, conditioning
#'     note, priority direction, units and construction metadata.}
#' }
#' @details
#' Each site follows an independent bivariate normal distribution with marginal
#' standard deviations `0.2` and zero within-site correlation between `score_A`
#' and `score_B`. Larger values mean higher priority on both criteria, and
#' distinct sites have zero probability of exact equality.
#'
#' Pairwise comparison probabilities and marginal summaries come analytically
#' from the normal distribution, so `pr_tutorial` contains no posterior draws
#' or Monte Carlo error. Stored grading results for `pr_tutorial$one` and
#' `pr_tutorial$two` are available through `postrank_example("tutorial_one")`
#' and `postrank_example("tutorial_two")`.
#'
#' @source Synthetic normal distribution specified in
#'   `data-raw/pr-tutorial-law.json`; no external data.
#' @examples
#' names(pr_tutorial)
#' pr_tutorial$one
#' postrank_posterior_means(pr_tutorial$one)
#' postrank_posterior_means(pr_tutorial$two)
#' @seealso [postrank_example()], [postrank_gaussian_coefficients()],
#'   [postrank()], `vignette("a1-getting-started", package = "postrank")`
#' @name pr_tutorial
#' @docType data
#' @keywords datasets
#' @concept data
NULL
