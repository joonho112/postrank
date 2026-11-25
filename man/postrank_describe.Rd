% Please edit documentation in R/describe.R
\name{postrank_describe}
\alias{postrank_describe}
\title{Describe Posterior Draws in Plain Arguments}
\usage{
postrank_describe(
  estimand,
  population,
  time,
  units,
  data,
  model,
  identification,
  joint,
  sampling,
  ties,
  software,
  source,
  label,
  data_version,
  values = NULL,
  format = NULL
)
}
\arguments{
\item{estimand}{What each criterion measures, as a character vector with one element per
criterion, named by criterion. The names are the criterion names of the draws (the third
dimension of the array given to \code{\link[=postrank_draws]{postrank_draws()}}).}

\item{population, time, units}{The entities the criteria refer to, the time period, and the units.
Give one unnamed string to use for every criterion, or a character vector that names every
criterion once.}

\item{data}{What the posterior is conditioned on, for example which data were used.}

\item{model}{A short summary of the statistical model.}

\item{identification}{Why each entity's target is identified by the model.}

\item{joint}{How each draw represents all entities and criteria together.}

\item{sampling}{How the draws were produced: algorithm, number of draws, warmup and thinning.}

\item{ties}{Why distinct entities have zero probability of exactly equal values.}

\item{software}{The software that produced the draws, for example \code{"Stan 2.36 via cmdstanr"}.}

\item{source}{Which file or object holds the draws.}

\item{label}{A short identifier for this posterior. It is used for all the identifiers that postrank
stores with the draws.}

\item{data_version}{A version label for the data, such as a release date.}

\item{values}{Optional: the numeric array of draws (draws x entities x criteria). If given, its
type and dimensions are recorded as the format of the source.}

\item{format}{The format of the source, for example \code{"CmdStan CSV files"}. Give it when the draws
came from files or from another program; \code{values} only records that they are an R array. If both
are given, \code{format} is used.}
}
\value{
A \code{postrank_declarations} object, the same as \code{\link[=postrank_declarations]{postrank_declarations()}} returns.
}
\description{
\code{postrank_describe()} builds the description that \code{\link[=postrank_draws]{postrank_draws()}} needs for a numeric array of
posterior draws: what each criterion measures, for which entities and period, what the posterior
is conditioned on, how the draws were produced, and why exact ties between entities have
probability zero. Each statement is an ordinary argument instead of an entry in a nested list. The
function passes them to \code{\link[=postrank_declarations]{postrank_declarations()}}, which checks them as usual, so the result is
the same object that a direct call to \code{\link[=postrank_declarations]{postrank_declarations()}} gives.
}
\details{
Every statement is written by you; \code{postrank_describe()} does not fill in anything about your model
or data. It fills in only the identifiers, which are all set to \code{label}, and, if you give \code{values},
the type and dimensions of that array.

Errors from the checks in \code{\link[=postrank_declarations]{postrank_declarations()}} name the fields of the full form. This
table shows which argument fills which field:\tabular{ll}{
   Argument \tab Field of \code{\link[=postrank_declarations]{postrank_declarations()}} \cr
   \code{estimand}, \code{population}, \code{time}, \code{units} \tab \code{targets}: \code{estimand}, \code{entity_population}, \code{time_reference}, \code{units} (\code{criterion_id} = the names of \code{estimand}) \cr
   \code{data}, \code{model}, \code{data_version} \tab \code{context}: \code{data_conditioning}, \code{model_summary}, \code{data_version} \cr
   \code{software}, \code{sampling} \tab \code{provenance}: \code{producer}, \code{construction_note} \cr
   \code{format} or \code{values}, \code{source} \tab \code{origin}: \code{source_format}, \code{source_artifact} \cr
   \code{label} \tab \code{context$cohort_id}, \code{provenance$artifact_id}, \code{origin$source_id}, \code{origin$fit_id}, \code{origin$model_id} \cr
   \code{identification}, \code{ties}, \code{joint}, \code{sampling} \tab \code{identification_note}, \code{tie_justification}, \code{joint_generation}, \code{sampling_provenance} \cr
}


\code{sampling} fills both \code{construction_note} and \code{sampling_provenance}, and \code{label} fills all five
identifiers. Scientific descriptions and \code{label} reject placeholder words such as \code{"TBD"},
\code{"unknown"}, and \code{"none"}. Criterion names and \code{data_version} must be non-empty strings
and are exempt from the placeholder-word check. For example, use \code{data_version = "none"}
when the data have no version. Priority direction is set in
\code{\link[=postrank_draws]{postrank_draws()}} via \code{orientation} (for example \code{orientation = c(rate = "lower")}), not in
\code{postrank_describe()}. Use \code{\link[=postrank_declarations]{postrank_declarations()}} when the five identifiers must differ, for
example when there is no model fit and \code{fit_id} should say \code{"none"}, or when you need to record
that the draws were transformed (a \code{source_transform} entry in \code{targets}).
}
\examples{
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))
decl <- postrank_describe(
  estimand = c(need = "Latent site need in a specified standard normal law"),
  population = "Three fictional sites A, B and C",
  time = "Static illustration; no observation period",
  units = "Illustrative standardized need units",
  data = "No observations; the law is specified directly",
  model = "Independent standard normal coordinates",
  identification = "The law directly defines each site's target.",
  joint = "Each draw holds one value for every site and criterion.",
  sampling = "64 independent draws from rnorm() after set.seed(901); no warmup or thinning.",
  ties = "Independent continuous coordinates are equal with probability zero.",
  software = "Base R rnorm()",
  source = "The array values created in this example",
  label = "normal-need", data_version = "1", values = values)
draws <- postrank_draws(values, regime = "iid", declarations = decl)
draws$criterion_ids
}
\seealso{
\code{\link[=postrank_declarations]{postrank_declarations()}} for the full form; \code{\link[=postrank_draws]{postrank_draws()}}.
}
\concept{input}
