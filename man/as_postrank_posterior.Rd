% Please edit documentation in R/as-postrank-posterior.R
\name{as_postrank_posterior}
\alias{as_postrank_posterior}
\title{Import Mapped Posterior Draws}
\usage{
as_postrank_posterior(x, variable_map, metadata, source_coordinates)
}
\arguments{
\item{x}{A \code{posterior::draws_array} with named \code{iteration}, \code{chain} and
\code{variable} axes (requires the optional \code{posterior} package).}

\item{variable_map}{List of \code{n * K} named lists, each with \code{entity_id},
\code{criterion_id}, \code{source_target_variable_id} and \code{derivation_note}. Every
entity-by-criterion pair must map once to a distinct variable in \code{x};
extra variables in \code{x} may remain unused.}

\item{metadata}{Complete \code{applied-0.1} list for joint equal-weight draws
(\code{joint_draws}), including \code{tensor$shape}, ordered \code{entity_ids} and
\code{criterion_ids}, target descriptions, source records and sampling history.
\code{tensor$values} may be omitted; if present, it must match the mapped
values from \code{x}.}

\item{source_coordinates}{List of \code{S} named lists, one per declared draw
slot, each with \code{slot_id}, \code{iteration_index} and \code{chain_index}. Indices
are integer positions along the \code{iteration} and \code{chain} axes of \code{x} (not
original MCMC iteration numbers), and must cover every iteration-by-chain
position of \code{x} once.}
}
\value{
A validated \code{postrank_draws} object with
\code{validation$source_values_checked = TRUE} and a \code{validation$source_audit}
list recording the checked cell count, variable and chain mappings, and
\code{source_object_sha256}.
}
\description{
\code{as_postrank_posterior()} imports a \code{posterior::draws_array} into a
\code{postrank_draws} object using supplied variable and draw-position mappings,
and checks that every imported cell equals its source cell in \code{x}. Entity
and criterion labels come from \code{variable_map} and \code{metadata}, never from
parsing variable names.
}
\details{
Values in \code{x} must already be oriented so that larger values mean higher
priority; this function performs no negation or rescaling. The imported
array has dimensions \verb{S x n x K}, keeping the third dimension when \code{K = 1}.

When \code{metadata} specifies \code{regime = "mcmc"}, original chain IDs and
iteration numbers come from \code{metadata$joint_draws$draw_index} and
\code{chain_history}. Each chain of \code{x} must map to a distinct declared chain
with strictly increasing original iteration numbers. When \code{regime = "iid"},
the \code{chain} axis of \code{x} is treated only as a storage index.
\code{\link[=postrank_draws]{postrank_draws()}} also accepts \code{draws_df} and \code{draws_matrix} objects by
converting them with \code{posterior::as_draws_array()} first.

\code{source_audit$source_object_sha256} hashes \code{unclass(x)} in R memory; it does
not check external files named in \code{origin}. Cell-by-cell equality confirms
the import mapping, not scientific identification, jointness or MCMC
convergence. Required strings are checked for non-empty text without the
placeholder-word list of \code{\link[=postrank_declarations]{postrank_declarations()}}.
}
\examples{
\dontshow{if (requireNamespace("posterior", quietly = TRUE)) withAutoprint(\{ # examplesIf}
# Map the bundled two-criterion IID sample through posterior::draws_array:
meta <- unclass(postrank_toy)
meta$schema_version <- meta$input_schema_version
meta$input_schema_version <- meta$validation <- NULL
a <- meta$joint_draws$tensor$values
map <- meta$joint_draws$variable_map
var_ids <- vapply(map, `[[`, character(1), "source_target_variable_id")
src_arr <- array(as.numeric(a), c(dim(a)[1], 1, length(map)),
  dimnames = list(iteration = as.character(seq_len(dim(a)[1])),
    chain = "1", variable = var_ids))
src <- posterior::as_draws_array(src_arr)
coords <- lapply(seq_len(dim(a)[1]), function(s)
  list(slot_id = dimnames(a)$draw[s], iteration_index = s, chain_index = 1L))
imported <- as_postrank_posterior(src, map, meta, coords)
imported$validation$source_values_checked
identical(imported$joint_draws$tensor$values, a)
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_draws_from_array]{postrank_draws_from_array()}},
\code{\link[=validate_postrank_draws]{validate_postrank_draws()}}
}
\concept{input}
