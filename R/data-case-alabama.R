#' Historical Economic Opportunity in 67 Alabama Counties
#'
#' A compact example combining income and incarceration outcomes for children
#' born in 1978--1983, at parent income percentile 25, with race and gender
#' pooled. Income ranks use household incomes from 2014--2015; incarceration
#' is measured on April 1, 2010. The example favors higher income and lower
#' incarceration. It describes historical conditional outcomes, not current
#' county conditions or the causal effect of a policy.
#'
#' @format A named list with five elements:
#' \describe{
#'   \item{input}{A validated \code{postrank_probabilities} input for all 67
#'     counties and both criteria, from selected numerical pool A. It includes
#'     genuine marginal posterior means and fixed 95% equal-tail intervals.}
#'   \item{units}{67 rows in input order, with county IDs and names, published
#'     estimates and standard errors, oriented point scales, and source fields.
#'     The published population count is descriptive; it is not a binomial
#'     denominator for the fitted model.}
#'   \item{alternatives}{\code{pool_B} supplies probabilities from a separate
#'     numerical run; \code{income} and \code{incarceration} are one-criterion
#'     inputs from pool A. All retain their same-target marginal summaries.}
#'   \item{reference}{Archived settings, seven grade vectors, A/B evaluations,
#'     single-criterion solver results, commonality comparisons, and numerical
#'     precision information. These were computed with postrank 0.9.0 and
#'     HiGHS 1.12.0.3; they are not fresh fits by the installed package.}
#'   \item{provenance}{Source-relative filenames and hashes, outcome dates,
#'     directions, model conditioning, attribution and CC BY 4.0 notice.}
#' }
#' @details The two criteria were fitted separately using the published
#' conditional estimates and total standard errors, with Gaussian observation
#' models and logistic-normal partial pooling. Their comparison probabilities
#' support additive expected loss; they do not supply a joint posterior across
#' criteria. The retained probabilities are Monte Carlo estimates, including
#' observed zeros and ones, not exact posterior-certainty statements.
#'
#' A and B use the same observations and model. They are separate numerical
#' pools, not independent observational replications. Pool A uses 16,000
#' retained draws per criterion and pool B uses 8,000 in the source study;
#' those draws are not included here and the supplied inputs do not claim
#' retained samples or newly computed diagnostics. B failed the source's
#' sensitive-pair MCSE target of .005 in 486 directional criterion rows
#' (maximum .00586708). Its fixed-action risk precision was assessed separately.
#' The archived MCSEs came from the original chains; they cannot be recalculated
#' from these probability summaries. Constant-trace pair MCSE is unavailable.
#'
#' The archived common grades use weights .5/.5, withholding cost .20, and
#' at most five grades. Their grade vector equals the expected-rank cut
#' baseline B3 in this example. B3 optimizes within a fixed score order; the
#' common optimization's lower bound has a different scope. Numerical solver
#' gaps do not measure Monte Carlo error or posterior uncertainty.
#'
#' To use the supplied marginal intervals in \code{postrank()} or
#' \code{postrank_report_card()}, request \code{level = .95}; intervals at
#' other levels cannot be recovered from the stored summaries. A negative
#' incarceration target has higher priority when original incarceration is
#' lower. This direction differs from the source project's later policy-v2
#' needs analysis, which is not included.
#' @source Raj Chetty, John Friedman, Nathaniel Hendren, Maggie R. Jones and
#' Sonya R. Porter (2022), \emph{Replication Data for: The Opportunity Atlas:
#' Mapping the Childhood Roots of Social Mobility}, Harvard Dataverse V1.0,
#' \doi{10.7910/DVN/NKCQM1}. Source: Opportunity Insights and U.S. Census Bureau.
#' Selected CSV: \url{https://opportunityinsights.org/wp-content/uploads/2018/10/county_outcomes_simple.csv}.
#' Observations and documented derivatives are available under
#' \href{https://creativecommons.org/licenses/by/4.0/}{CC BY 4.0}.
#' Changes include Alabama filtering, county identifiers and names, point
#' scales, incarceration orientation, separate M1 posterior summaries, and
#' compact package inputs. Attribution and earlier change notices are retained
#' in \code{provenance$rights}. No endorsement is implied.
#' @seealso `vignette("a4-alabama-opportunity", package = "postrank")`,
#'   [postrank_probabilities()], [postrank_report_card()]
#' @examples
#' x <- pr_case_alabama
#' x$units[c("entity_id", "county_name", "income_estimate_points",
#'           "incarceration_estimate_points")]
#' postrank_posterior_means(x$input, level = .95)[1:3, ]
#' ev <- postrank_evaluate(x$reference$actions$P, x$input,
#'   weights = c(income = .5, incarceration = .5), tau = .2)
#' ev[c("G", "N", "M", "primary_risk")]
#' @keywords datasets
#' @concept data
"pr_case_alabama"
