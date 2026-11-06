% Please edit documentation in R/as-postrank-posterior.R
\name{as_postrank_posterior}
\alias{as_postrank_posterior}
\title{Import Explicitly Mapped Posterior Draws}
\usage{
as_postrank_posterior(x, variable_map, metadata, source_coordinates)
}
\arguments{
\item{x}{A \code{posterior::draws_array} with iteration, chain and variable axes.
The optional \code{posterior} package is required.}

\item{variable_map}{List of records containing \code{entity_id}, \code{criterion_id},
\code{source_target_variable_id} and \code{derivation_note}. Map each entity/criterion
target once to a distinct source variable. Unused source variables are allowed.}

\item{metadata}{Complete canonical \code{applied-0.1} metadata for joint
equal-weight draws, including the tensor shape and ordered IDs, target
definitions, source records and sampling history. Tensor values may be
omitted; if present, they must equal the mapped source values exactly.}

\item{source_coordinates}{One record per declared draw slot, containing
\code{slot_id}, \code{iteration_index} and \code{chain_index}. Indices are positions in
\code{x}, not original iteration numbers or chain IDs. Every source
iteration-by-chain position must be used exactly once.}
}
\value{
A validated \code{postrank_draws} object with
\code{validation$source_values_checked = TRUE} and a \code{validation$source_audit}
describing the mappings and comparisons performed.
}
\description{
This adapter maps a \code{posterior::draws_array} to the declared entities and
criteria, retaining its source history. Each imported target value is
compared with the corresponding source cell. Variable names are matched
through an explicit mapping; entity and criterion labels are not inferred
from those names.
}
\details{
Source values must already be the higher-priority targets. No negation or
other numerical transformation is performed. The target array has shape
\verb{S x n x K}, where \code{S} is the number of source iteration-by-chain positions;
\code{K = 1} retains its third axis.

Original MCMC chain IDs and iteration numbers come from \code{metadata}, not
from the source axis labels. Each source chain must map to one distinct
declared chain, with original iterations increasing in source iteration
order. Preserve actual warmup, discarding and thinning history. For IID
input the source chain axis is only a container grouping and makes no
MCMC claim. \code{\link[=postrank_draws]{postrank_draws()}} also accepts \code{posterior} data-frame and
matrix formats through \code{posterior::as_draws_array()}; a conversion cannot
recover a chain history that the export lost.

The audit's \code{source_object_sha256} identifies serialized \code{unclass(x)}.
The separately retained origin \code{source_hash} may identify an external
file; this adapter does not verify that file's bytes. Source-value equality
verifies the conversion, not scientific jointness, identification or
convergence. Canonical declaration checks apply without the additional
placeholder-text checks of \code{\link[=postrank_declarations]{postrank_declarations()}}.
}
\examples{
if (requireNamespace("posterior", quietly = TRUE)) {
  # Re-express the unchanged bundled two-criterion IID sample.
  # Its original declarations apply because no values or law are replaced.
  metadata <- unclass(postrank_toy)
  metadata$schema_version <- metadata$input_schema_version
  metadata$input_schema_version <- metadata$validation <- NULL
  a <- metadata$joint_draws$tensor$values
  map <- metadata$joint_draws$variable_map
  variable_ids <- vapply(map, `[[`, character(1), "source_target_variable_id")
  source_array <- array(as.numeric(a), c(dim(a)[1], 1, length(map)),
    dimnames = list(iteration = as.character(seq_len(dim(a)[1])),
      chain = "1", variable = variable_ids))
  source_draws <- posterior::as_draws_array(source_array)
  coordinates <- lapply(seq_len(dim(a)[1]), function(s)
    list(slot_id = dimnames(a)$draw[s], iteration_index = s, chain_index = 1L))
  imported <- as_postrank_posterior(source_draws, map, metadata, coordinates)
  imported$validation$source_values_checked
  identical(imported$joint_draws$tensor$values, a)
}
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}},
\code{\link[=validate_postrank_draws]{validate_postrank_draws()}}
}
\concept{input}
