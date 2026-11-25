% Please edit documentation in R/postrank-analysis.R
\name{postrank}
\alias{postrank}
\title{Assign Grades to Entities Under Posterior Uncertainty}
\usage{
postrank(
  x,
  weights = NULL,
  tau = 0.25,
  G_max = 4L,
  ...,
  settings = NULL,
  backend = NULL,
  control = postrank_control(),
  report_card = TRUE,
  fragility = TRUE,
  crossfit = FALSE,
  diagnostics = FALSE,
  level = 0.9
)
}
\arguments{
\item{x}{Posterior information for the entities, one of:
\itemize{
\item a \code{postrank_draws} object (see \code{\link[=postrank_draws]{postrank_draws()}} and
\code{\link[=as_postrank_draws]{as_postrank_draws()}});
\item a normal posterior given by means and covariances
(\code{\link[=postrank_gaussian_coefficients]{postrank_gaussian_coefficients()}}) or an average of normal
posteriors over shared states such as hyperparameter draws
(\code{\link[=postrank_mixture_coefficients]{postrank_mixture_coefficients()}});
\item a \code{\link[=postrank_probabilities]{postrank_probabilities()}} object holding comparison probabilities
computed elsewhere.
}}

\item{weights}{Criterion weights: nonnegative numbers that sum to one. They
are not rescaled for you. Name them by criterion (named weights must name
every criterion once, including any with weight 0), or give them in
criterion order. With one criterion, \code{postrank()} sets the weight to 1 if
you leave it out; with several criteria it is required.}

\item{tau}{Cost of leaving a pair unordered, relative to a cost of 1 for a
pair reported in the wrong order. Must satisfy \verb{0 < tau <= 0.5}.}

\item{G_max}{Largest number of grades. Fewer grades are allowed unless
\code{exact_G} is given. A value larger than the number of entities is reduced
to that number, and a note is added to the result's warnings.}

\item{...}{Further settings passed to \code{\link[=postrank_settings]{postrank_settings()}}: \code{q}
(per-criterion upper limits in \verb{[0, 1]} on the expected wrong-order
proportion of ordered pairs, \code{E_k <= q_k * N}), \code{exact_G} (an exact number
of occupied grades), \code{objective} (\code{"minimax"} minimizes the largest
criterion loss instead of the weighted one), \code{minimax_criteria} (subset of
criteria included in the minimax objective) and \code{minimax_refine} (whether
to refine a minimax solution on weighted loss). With normal or mixture
posteriors or supplied probabilities, only the weighted objective without
\code{q}, \code{exact_G} or \code{minimax_criteria} is available; other values are an
error.}

\item{settings}{A \code{\link[=postrank_settings]{postrank_settings()}} object, used instead of \code{weights},
\code{tau}, \code{G_max} and \code{...}. Giving both, even at their default values, is an
error (\code{settings_conflict}).}

\item{backend}{Solver to use, \code{"gurobi"} or \code{"highs"}. If \code{NULL} (the
default), \code{getOption("postrank.backend")} is used, or \code{"gurobi"} if that
option is not set. If the chosen solver is not installed or cannot be
loaded, the call stops with an error. The fit records the overall solver
outcome in \code{fit$status} and stage-specific errors in \code{fit$engine$stages}
(see Details). \code{postrank} never switches to the other solver.}

\item{control}{Solver controls from \code{\link[=postrank_control]{postrank_control()}}, such as the time
limit, number of threads and seed, or a named list of them.}

\item{report_card, fragility, crossfit, diagnostics}{Whether to request extra
summaries. The report card and fragility are requested by default;
cross-fitting and diagnostics are not. Each one is computed only when the
input supports it; Details lists what each needs.
\itemize{
\item Report card: the posterior means and intervals shown with the grades.
\item Fragility: pairs whose wrong-order probability in the likelier direction
is within Monte Carlo noise of \code{tau}. On MCMC draws, only borderline
pairs within \code{0.1} (\code{screen_margin}) of \code{tau} are traced, and an
informational \code{"MCMC screen"} note is added to \code{warnings}.
\item Cross-fitting: grades chosen on one half of the draws and evaluated on
the other half (the model is not refitted).
\item Diagnostics: for IID or MCMC draws, Monte Carlo standard errors (with
R-hat and effective sample size for MCMC draws, from the \code{posterior}
package); for exact finite posteriors and other inputs, see Details.
}}

\item{level}{Level of the central posterior intervals in the report card,
between 0 and 1. If the input comes with its own intervals, use their
level (for 95\% intervals, \code{level = 0.95}) or set \code{report_card = FALSE}.}
}
\value{
A \code{postrank_analysis} object, a list with these components:
\itemize{
\item \code{input}, \code{pairwise}, \code{settings}, \code{control} and \code{problem}: the checked
input, its pairwise probabilities, and the settings, solver controls and
optimization problem that were used.
\item \code{fit}: the solver result (see \code{\link[=postrank_solve]{postrank_solve()}}).
\item \code{evaluation}: loss and error summaries of the chosen grades, or \code{NULL}
when no grading passed postrank's checks.
\item \code{report_card}, \code{fragility}, \code{crossfit} and \code{diagnostics}: the extra
summaries, each \code{NULL} when it was not computed.
\item \code{extras}: for each extra summary, whether it was \code{requested},
\code{supported} and \code{available}, with a \code{reason} and any error \code{condition}.
\item \code{backend}, \code{timings} and \code{warnings}: the solver used, the seconds spent
in each stage, and any warnings.
\item \code{provenance}: how and when the result was made (postrank and R versions,
time, solver and how it was chosen).
\item \code{metadata}: a summary of the input's declarations, which extra summaries
the input supports, and stored display data.
\item \code{schema_version}: the version of this object's layout.
}

Use \code{\link[=get_grades]{get_grades()}}, \code{\link[=get_risk]{get_risk()}}, \code{\link[=get_profile]{get_profile()}}, and \code{\link[=as.data.frame]{as.data.frame()}}
(see \link{postrank_tables}) to extract the usual results, and \code{plot()} or
\code{\link[=postrank_plot_report_card]{postrank_plot_report_card()}} to plot the report card.
}
\description{
\code{postrank()} gives each entity (for example a school, an employer or an
area) an integer grade, using posterior information that you supply: draws,
normal (Gaussian) or mixture posteriors, or comparison probabilities. Grade
1 is the highest priority; larger values of each criterion's target (the
entity quantity estimated on that criterion) mean higher priority, as set
when the input was built. Entities in different grades are reported in that
order. Entities in the same grade are left unordered: the report does not
say which one is higher, and it does not say that they are equal.
}
\details{
By default, the grades are chosen to minimize the posterior expected loss,
averaged over all pairs of entities: a pair reported in the wrong order
costs 1 and a pair left unordered costs \code{tau}. With several criteria, one
common grading is chosen and the criterion losses are combined with
\code{weights}. \code{postrank()} computes the pairwise probabilities, solves the
optimization problem and returns the grades, the loss and optional
summaries. It does not fit a model, so the results are only as good as the
posterior you supply.

postrank needs an optimization solver. HiGHS is free: install the \code{highs}
package and use \code{backend = "highs"} or \code{options(postrank.backend = "highs")}.
The default, Gurobi, is commercial software that needs a license.

\strong{Words in the printed output.} The printed result and \code{\link[=get_risk]{get_risk()}} use the
package's internal terms: "disclosed" pairs are the ordered pairs,
"withheld" pairs are the unordered ones, and "risk" is the loss described
above.

\strong{Solver results.} postrank recomputes the loss of the solver's grading
and checks it before reporting it. The solver also reports a lower bound
(a loss that no grading can beat) and the gap between the returned loss and
that bound; a gap of 0 means that, up to numerical tolerance, no better
grading exists for these probabilities. The status, bound and gap describe
the optimization only, not the uncertainty in the posterior or the adequacy
of the model; see \code{\link[=get_risk]{get_risk()}} and \code{\link[=postrank_solve]{postrank_solve()}}.

\strong{Time limits.} When the solver stops at its time limit, the result may hold
a checked grading, or none. Without one, the result keeps the solver status,
any lower bound and the warnings; \code{evaluation} and the requested extra
summaries are \code{NULL}, with reason \code{"no_validated_incumbent"} (no checked
grading). This differs from a valid grading that leaves every pair
unordered, which has one grade and loss \code{tau}.

\strong{What each extra summary needs.} A report card needs marginal posterior
intervals: supplied probabilities without interval summaries can be graded
but give no report card. Monte Carlo fragility and cross-fitting need joint
equal-weight IID or MCMC draws, in which every draw holds a value for every
entity and criterion; cross-fitting solves two more optimization problems.
For IID or MCMC draws, \code{diagnostics} reports Monte Carlo standard errors
(exact finite posteriors have no Monte Carlo error); for normal or mixture
posteriors it evaluates the expected loss given those posteriors (for
hyperparameter-MCMC MCSEs on mixture posteriors, call
\code{\link[=postrank_coefficient_diagnose]{postrank_coefficient_diagnose()}} directly with \code{chain_history}). Supplied
probabilities have no draws, so fragility, cross-fitting and diagnostics are
not available for them.

\strong{Errors.} Invalid input, invalid settings, an unavailable solver, and
uncaught solver execution errors (such as a missing Gurobi license under
\code{strategy = "label_mip"} or LP setup) stop the call. Solver termination
outcomes, including infeasibility, numerical trouble and time limits, appear
in \code{fit$status}. Without a checked grading, \code{evaluation} is \code{NULL}. For a
caught error in staged search, check \code{fit$engine$stages$lp$status} and its
\code{trace} for LP rounds, or \code{fit$engine$stages$mip$error} and \code{fit$warnings}
for the final MIP. If an extra
summary fails unexpectedly, the main grading is kept, the extra records
\code{reason = "extra_error"} and its condition, and an R warning is signaled and
appended to \code{warnings}. When the input supplies its own intervals, a report
card at another \code{level} is an error, raised before any solving.
}
\examples{
# Read a stored result without running a solver:
stored <- postrank_example("tutorial_one")
get_grades(stored)
get_risk(stored)
\dontshow{if (requireNamespace("highs", quietly = TRUE)) withAutoprint(\{ # examplesIf}
# Solve directly with the optional highs package:
one <- postrank(pr_tutorial$one, tau = 0.2, G_max = 3, backend = "highs",
  control = postrank_control(time_limit = 10), fragility = FALSE)
get_grades(one)
get_risk(one)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_example]{postrank_example()}}, \code{\link[=postrank_settings]{postrank_settings()}}, \code{\link[=postrank_control]{postrank_control()}},
\code{\link[=postrank_solve]{postrank_solve()}}, \code{\link[=postrank_report_card]{postrank_report_card()}}, \code{\link[=get_risk]{get_risk()}}
}
\concept{decision}
