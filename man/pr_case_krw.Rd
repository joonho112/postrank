% Please edit documentation in R/data-case-krw.R
\docType{data}
\name{pr_case_krw}
\alias{pr_case_krw}
\title{Race and Gender Contact Gaps at 97 Employers}
\format{
A named list with five elements:
\describe{
\item{input}{A \code{postrank_probabilities} object with a \verb{97 x 97 x 2}
directional-error array and matching \verb{97 x 2} posterior means and 90\%
equal-tail intervals.}
\item{units}{Data frame of 97 rows in input order: \code{entity_id}, \code{firm_id},
\code{firm_name}, \code{industry}, \code{race_estimate}, \code{race_se}, \code{gender_estimate}
and \code{gender_se} (direct log-contact-gap estimates and standard errors,
not posterior means or standard deviations).}
\item{alternatives}{Named list of \code{postrank_probabilities} inputs:
single-criterion \code{race} and \code{gender}, and two-criterion \code{absolute_gender}
(replacing \code{gender_signed} with \verb{|gender_signed|} folded across zero).}
\item{reference}{KRW single-criterion report cards (\code{single_criterion}),
companion two-criterion common-grading references (\code{signed_core} and
\code{absolute_sensitivity}), cell-law and archive-matrix loss summaries, raw
and plotting \code{Pi} arrays, and summary counts of solved specification-grid
cells.}
\item{provenance}{Source filenames and SHA-256 hashes, posterior cell-law
construction, attribution and the source CC-BY-NC rights notice.}
}
}
\source{
Kline, Patrick, Evan K. Rose and Christopher R. Walters (2024),
\emph{Replication Data for: A Discrimination Report Card} (titled \emph{Data and Code
for: A Discrimination Report Card} on openICPSR), American Economic
Association / ICPSR deposit E198284V1, \doi{10.3886/E198284V1}. Midpoint
cell-law probabilities and compact extraction by \code{data-raw/make-pr-case-krw.R}
(no endorsement by the original authors is implied).
}
\usage{
pr_case_krw
}
\description{
\code{pr_case_krw} is a two-criterion case-study dataset for 97 U.S. employers
adapted from the replication archive of Kline, Rose and Walters (2024),
\emph{A Discrimination Report Card}. Its primary input compares all 97 firms on
signed race and gender callback-gap targets: larger \code{race_signed} means a
larger white-name callback advantage (\code{log(p_white) - log(p_black)}), and
larger \code{gender_signed} means a larger male-name callback advantage
(\code{log(p_male) - log(p_female)}, signed rather than folded in magnitude).
}
\details{
\strong{Posterior cell law.} Pairwise probabilities and marginal summaries treat
each firm's posterior mass on the replication grid as uniform over
continuous cells between adjacent grid midpoints (with nonnegative support on
the lowest race cell), holding the archive's empirical-Bayes prior fixed
without refitting or normal approximation. Pass \code{level = 0.90} when
requesting a report card in \code{\link[=postrank]{postrank()}} or \code{\link[=postrank_report_card]{postrank_report_card()}}. No
posterior draws or cross-criterion joint distribution are stored.

\strong{Reference settings.} Kline, Rose and Walters (2024) report
single-criterion report cards (\code{single_criterion}) at benchmark preference
parameter \code{lambda = 0.25} (\code{tau = 0.20}) allowing up to \code{97} grades (\code{3}
occupied grades on race and \code{4} on gender without industry controls). The
two-criterion common gradings (\code{signed_core} and
\code{postrank_example("case_krw_signed97")}) are \code{postrank} companion analyses
using \code{tau = 0.25}, equal weights \verb{(0.5, 0.5)} and \code{G_max = 4}. Stored
reference actions are evaluated under the midpoint-cell law (not a new solve
or exact optimality claim over alternative laws) and describe the historical
correspondence experiment rather than current firm practices.

\strong{Source license.} The replication archive README states: \code{"The data are licensed under a Creative Commons/CC-BY-NC license."} without naming a
license version. \code{pr_case_krw} and dependent stored results retain that
noncommercial CC-BY-NC condition separately from the package's MIT code
license (\code{provenance$rights} retains historical preparation records, while
the installed \code{DATA-NOTICE.md} states the current public distribution scope).
}
\examples{
dim(pr_case_krw$input$e)
pr_case_krw$reference$single_criterion$archive_metrics

x <- pr_case_krw$input
g <- pr_case_krw$reference$signed_core$grade
postrank_evaluate(g, x, weights = c(race_signed = 0.5,
  gender_signed = 0.5), tau = 0.25)$weighted_risk
}
\seealso{
\code{\link[=postrank_example]{postrank_example()}}, \code{\link[=postrank_probabilities]{postrank_probabilities()}},
\code{\link[=postrank_report_card]{postrank_report_card()}},
\code{vignette("a3-krw-race-gender", package = "postrank")}
}
\concept{data}
\keyword{datasets}
