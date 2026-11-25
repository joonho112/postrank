% Please edit documentation in R/draws-friendly.R
\name{postrank_declarations}
\alias{postrank_declarations}
\title{Describe the Targets and Source of Posterior Draws}
\usage{
postrank_declarations(
  targets,
  context,
  provenance,
  origin,
  identification_note,
  tie_justification,
  joint_generation,
  sampling_provenance
)
}
\arguments{
\item{targets}{One record per criterion, as a data frame or a list of named
lists. Required string fields are \code{criterion_id}, \code{estimand},
\code{entity_population}, \code{time_reference} and \code{units}; optional string fields
are \code{source_transform} and \code{identification_basis}.}

\item{context}{Named list of non-empty character strings: \code{cohort_id}
(identifier for the compared entity cohort), \code{data_version} (data release
label), \code{data_conditioning} (which observations or assumptions the
posterior conditions on) and \code{model_summary} (short summary of the
statistical model).}

\item{provenance}{Named list of non-empty character strings: \code{producer}
(software or script that created this draw object), \code{artifact_id}
(identifier for the draw object) and \code{construction_note} (how this draw
array or file was assembled from the model output); optional string fields
are \code{artifact_hash} and \code{created_at}.}

\item{origin}{Named list of non-empty character strings: \code{source_id}
(identifier for the upstream posterior source), \code{fit_id} (identifier for
the model fit, or \code{"none"} when there is no fit), \code{model_id} (identifier
for the model specification), \code{source_format} (format of the upstream
output, such as \code{"CmdStan CSV files"} or \code{"R array"}) and
\code{source_artifact} (which file or R object holds the draws); optional
string field \code{source_hash}.}

\item{identification_note}{One string explaining why each criterion's target
is identified by the model.}

\item{tie_justification}{One string explaining why distinct entities have
zero probability of exact equality on each criterion. Continuous marginals
alone do not guarantee this when entity targets are dependent.}

\item{joint_generation}{One string explaining how each draw represents all
entities and criteria together, preserving their dependence under the
model.}

\item{sampling_provenance}{One string describing the sampling algorithm,
chain count, warmup removal and thinning used to generate the retained
draws (whereas \code{provenance$construction_note} describes how the array or
file was extracted or packaged).}
}
\value{
A \code{postrank_declarations} object, a named list containing these
eight fields in order.
}
\description{
\code{postrank_declarations()} collects the eight required descriptions of a
posterior-draws input for \code{\link[=postrank_draws]{postrank_draws()}}: what each criterion measures,
the data and model context, the software and source that produced the draws,
and why target identification, joint sampling and zero exact-tie probability
hold. Its components can also be passed separately to
\code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}}.
}
\details{
For most numeric arrays, \code{\link[=postrank_describe]{postrank_describe()}} is shorter: it takes each
statement as a plain argument, fills all five identifiers from one \code{label},
and calls \code{postrank_declarations()}. Use \code{postrank_declarations()} directly
when the five identifiers (\code{cohort_id}, \code{artifact_id}, \code{source_id}, \code{fit_id},
\code{model_id}) or the two sampling notes (\code{construction_note} and
\code{sampling_provenance}) need to differ, or when you want to record an existing
\code{source_transform} or \code{identification_basis} in \code{targets}. Every descriptive
statement must be written by you; nothing is inferred or filled in
automatically.

All eight arguments are required and non-\code{NULL}. Every required string field
except \code{targets$criterion_id}, \code{origin$fit_id} and \code{context$data_version} is
checked against generic placeholders such as \code{"unknown"}, \code{"TBD"}, \code{"TODO"},
\code{"NA"}, \code{"none"}, \code{"..."}, \code{"missing"} or \code{"not declared"} (error code
\code{placeholder_declaration}), so \code{cohort_id}, \code{artifact_id}, \code{source_id} and
\code{model_id} must also be real labels rather than \code{"none"}. Optional subfields
(\code{source_transform}, \code{identification_basis}, \code{artifact_hash}, \code{created_at},
\code{source_hash}) are checked when passed to \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}}.
Lower-level constructors (\code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}},
\code{\link[=as_postrank_draws]{as_postrank_draws()}}, \code{\link[=as_postrank_posterior]{as_postrank_posterior()}}, \code{\link[=read_postrank_draws]{read_postrank_draws()}})
check that required strings are non-empty without applying this placeholder
list.

Checking a \code{postrank_declarations} object verifies that required fields are
present and non-placeholder; it does not verify scientific identification,
joint sampling, zero tie probability or MCMC convergence. In \code{targets},
\code{source_transform} records a transformation that was already applied before
calling \code{postrank}; sign reversal of lower-is-higher criteria is performed
separately by the \code{orientation} argument of \code{\link[=postrank_draws]{postrank_draws()}}.
}
\examples{
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))

# Short form via postrank_describe() (calls postrank_declarations()):
decl <- postrank_describe(
  estimand = c(need = "Latent site need in a specified standard normal law"),
  population = "Three fictional sites A, B and C",
  time = "Static illustration; no observation period",
  units = "Illustrative standardized need units",
  data = "No observations; the law is specified directly",
  model = "Independent standard normal coordinates",
  identification = "The law directly defines each site's target.",
  joint = "Each draw holds one value for every site and criterion.",
  sampling = "64 independent draws from rnorm() with seed 901; no warmup or thinning.",
  ties = "Independent continuous normal coordinates are equal with probability zero.",
  software = "Base R rnorm()",
  source = "The array values created in this example",
  label = "normal-need", data_version = "1", values = values)
draws <- postrank_draws(values, regime = "iid", declarations = decl)
draws$criterion_ids

# Full form when identifiers such as fit_id ("none") differ from artifact_id:
decl_full <- postrank_declarations(
  targets = decl$targets,
  context = decl$context,
  provenance = decl$provenance,
  origin = modifyList(decl$origin, list(fit_id = "none")),
  identification_note = decl$identification_note,
  tie_justification = decl$tie_justification,
  joint_generation = decl$joint_generation,
  sampling_provenance = decl$sampling_provenance)
decl_full$origin$fit_id
}
\seealso{
\code{\link[=postrank_describe]{postrank_describe()}} for the flat-argument helper;
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}},
\code{vignette("a5-your-posterior-results", package = "postrank")}
}
\concept{input}
