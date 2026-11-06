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
\item{targets}{One record per criterion, as a data frame or list of named
lists. Required fields are \code{criterion_id}, \code{estimand}, \code{entity_population},
\code{time_reference} and \code{units}; \code{source_transform} and \code{identification_basis}
are optional. Describe the actual target and any transformation.}

\item{context}{Named list with \code{cohort_id}, \code{data_version},
\code{data_conditioning} and \code{model_summary}.}

\item{provenance}{Named list with \code{producer}, \code{artifact_id} and
\code{construction_note}; optional \code{artifact_hash} and \code{created_at}.}

\item{origin}{Named list with \code{source_id}, \code{fit_id}, \code{model_id},
\code{source_format} and \code{source_artifact}; optional \code{source_hash}.}

\item{identification_note}{Why each labeled target is identified.}

\item{tie_justification}{Why distinct entities have zero probability of
exact equality on each criterion. A continuous marginal alone need not
imply this when entity targets are dependent.}

\item{joint_generation}{How each retained draw represents one joint state
of all entities and criteria, preserving the model's dependence.}

\item{sampling_provenance}{How the draws were produced, including the
sampling regime and any selection of retained draws.}
}
\value{
A \code{postrank_declarations} list containing these eight fields.
}
\description{
The declarations specify the targets represented by the posterior draws, the
information on which they are conditioned and the procedure used to generate
them. The resulting bundle provides the eight required scientific
declarations for \code{\link[=postrank_draws]{postrank_draws()}}. Its components can also be passed
separately to \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}}.
}
\details{
All eight declarations are required. The bundle checks completeness and
rejects generic placeholders such as \code{"unknown"}, \code{"TBD"} or \code{"..."} in
required descriptive text. IDs follow their own rules; \code{fit_id} and
\code{data_version} may legitimately be labels such as \code{"none"}. This text check
also applies to the high-level numeric-array route of \code{\link[=postrank_draws]{postrank_draws()}}.
Direct strict constructors and canonical metadata readers check required
text and structure without this additional placeholder check.

Identification, joint generation, zero equality probability and convergence
remain scientific declarations; validation does not establish their truth.
The example declarations therefore require replacement by descriptions of
the actual analysis. \code{source_transform} records an existing transformation,
whereas array orientation is performed separately by \code{\link[=postrank_draws]{postrank_draws()}}.
}
\examples{
# One criterion: a specified synthetic law, not a fitted data analysis.
set.seed(901)
values <- array(rnorm(64 * 3), c(64, 3, 1),
  dimnames = list(NULL, c("A", "B", "C"), "need"))
decl <- postrank_declarations(
  targets = data.frame(criterion_id = "need",
    estimand = "Latent site need in a specified standard Normal law",
    entity_population = "Three fictional sites A, B and C",
    time_reference = "Static illustration; no observation period",
    units = "Illustrative standardized need units"),
  context = list(cohort_id = "three-fictional-sites", data_version = "1",
    data_conditioning = "No observations; the target law is specified directly",
    model_summary = "Independent standard Normal coordinates"),
  provenance = list(producer = "Help-page R generator", artifact_id = "normal-need",
    construction_note = "64 IID states sampled with seed 901"),
  origin = list(source_id = "specified-normal-law", fit_id = "no-model-fit",
    model_id = "independent-standard-normal", source_format = "R array",
    source_artifact = "The rnorm array generated in this example"),
  identification_note = "The law directly defines every labeled site target.",
  tie_justification = paste("Independent continuous Normal coordinates have",
    "zero probability of exact equality."),
  joint_generation = paste("Every row is one state of all sites and included criteria;",
    "all coordinates are independent in this example."),
  sampling_provenance = "Base R rnorm with seed 901; IID states, no warmup or thinning.")
draws <- postrank_draws(values, regime = "iid", declarations = decl)
draws$criterion_ids

# Add an independent criterion while retaining every first-criterion draw.
two <- array(c(values, rnorm(64 * 3)), c(64, 3, 2),
  dimnames = list(NULL, c("A", "B", "C"), c("need", "cost")))
decl2 <- unclass(decl)
decl2$targets <- rbind(decl$targets, transform(decl$targets,
  criterion_id = "cost", estimand = "Latent cost in a standard Normal law",
  units = "Illustrative standardized cost units"))
decl2$provenance$artifact_id <- "normal-need-and-cost"
decl2 <- do.call(postrank_declarations, decl2)
two_draws <- postrank_draws(two, regime = "iid", declarations = decl2)
two_draws$criterion_ids
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}},
\code{vignette("a5-your-posterior-results", package = "postrank")}
}
\concept{input}
