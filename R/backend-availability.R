.pr_backend_package_metadata <- function(backend) {
  path <- tryCatch(find.package(backend, quiet = TRUE), error = function(e) character())
  if (!length(path)) return(list(installed = FALSE, package_path = NA_character_, wrapper_version = NA_character_))
  version <- tryCatch(unname(read.dcf(file.path(path, "DESCRIPTION"), fields = "Version")[1L, 1L]),
                      error = function(e) NA_character_)
  list(installed = TRUE, package_path = path[[1L]], wrapper_version = version)
}

.pr_backend_availability_record <- function(backend, metadata, linkage = NULL) {
  blocked <- !is.null(linkage) && (identical(linkage$status, "absolute_R_runtime_link_mismatch") ||
    identical(linkage$condition_code, "gurobi_R_runtime_mismatch"))
  structure(list(backend = backend, installed = isTRUE(metadata$installed),
    package_path = metadata$package_path, wrapper_version = metadata$wrapper_version,
    available_for_attempt = isTRUE(metadata$installed) && !blocked,
    runtime_check = list(executed = FALSE, status = if (!isTRUE(metadata$installed)) "not_run_package_absent" else
      if (blocked) "blocked_known_R_runtime_mismatch" else "not_executed",
      known_linkage_check = linkage, general_runtime_verified = FALSE),
    license_check = list(executed = FALSE, status = if (backend == "highs") "not_applicable" else "not_checked", valid = NA),
    interpretation = "Package presence and read-only linkage metadata only. No solver, namespace load or license query was executed; available_for_attempt does not establish runtime usability or a valid license."),
    class = c("postrank_backend_availability", "list"))
}

#' Inspect Solver Package Availability
#'
#' `postrank_backend_available()` checks whether the `gurobi` or `highs` R
#' package is installed and passes static runtime-linkage checks, without
#' loading the solver namespace, running an optimization or querying a license.
#'
#' @param backend Solver package to inspect, `"gurobi"` (the default) or
#'   `"highs"`.
#' @returns A `postrank_backend_availability` list containing `backend`,
#'   `installed`, `package_path`, `wrapper_version`, `available_for_attempt`,
#'   `runtime_check`, `license_check` and `interpretation`.
#' @details
#' `available_for_attempt = TRUE` means the package directory was found and, on
#' macOS for Gurobi, no mismatch between Gurobi's linked R library and the
#' running R session was detected. Because no namespace is loaded and no
#' license or test solve is run, `available_for_attempt = TRUE` does not
#' confirm that a solve will succeed or that a Gurobi license is active.
#'
#' Calling this function does not change library paths or select a solver. To
#' use HiGHS in [postrank()] or [postrank_solve()], pass `backend = "highs"` or
#' set `options(postrank.backend = "highs")`; `postrank` never switches solvers
#' automatically.
#' @seealso [postrank()], [postrank_solve()], [postrank_options]
#' @examples
#' avail <- postrank_backend_available("highs")
#' avail$available_for_attempt
#' avail$runtime_check$executed
#' @concept decision
#' @export
postrank_backend_available <- function(backend = c("gurobi", "highs")) {
  backend <- match.arg(backend)
  metadata <- .pr_backend_package_metadata(backend)
  linkage <- NULL
  if (isTRUE(metadata$installed) && backend == "gurobi") {
    linkage <- tryCatch(.pr_gurobi_runtime_guard(metadata$package_path),
      postrank_backend_unavailable = function(e) {
        record <- e$details
        record$condition_code <- e$code; record$message <- conditionMessage(e)
        record
      }, error = function(e) list(status = "metadata_guard_error", message = conditionMessage(e)))
  }
  .pr_backend_availability_record(backend, metadata, linkage)
}

# Shared availability check for every solving path (label-MIP backend wrappers
# and the staged engine). It runs before any solver namespace is loaded, so a
# requested but absent backend fails with its own condition code and never loads
# or selects another backend.
.pr_backend_require <- function(backend) {
  .pr_assert(is.character(backend) && length(backend) == 1L && !is.na(backend) && backend %in% c("gurobi", "highs"),
    "backend must be gurobi or highs", "invalid_backend")
  if (identical(backend, "gurobi")) {
    package_path <- tryCatch(find.package("gurobi", quiet = TRUE), error = function(e) character())
    if (!length(package_path)) .pr_stop("Gurobi R package is unavailable. Install or explicitly activate a compatible library before choosing backend='gurobi'.",
      "postrank_backend_unavailable", "gurobi_package_missing", details = list(backend = "gurobi"))
    guard <- .pr_gurobi_runtime_guard(package_path)
    loaded <- tryCatch(requireNamespace("gurobi", quietly = TRUE), error = function(e) e)
    if (!isTRUE(loaded)) .pr_stop("Gurobi R package could not be loaded; activate a compatible library in a fresh R session.",
      "postrank_backend_unavailable", "gurobi_load_failed",
      details = list(backend = "gurobi", package_path = package_path, cause = if (inherits(loaded, "error")) conditionMessage(loaded) else "requireNamespace returned FALSE", runtime_guard = guard))
    return(list(package_path = package_path, runtime_guard = guard))
  }
  package_path <- tryCatch(find.package("highs", quiet = TRUE), error = function(e) character())
  if (!length(package_path)) .pr_stop("HiGHS R package is unavailable. Install it before explicitly selecting backend='highs'.",
    "postrank_backend_unavailable", "highs_package_missing", details = list(backend = "highs"))
  loaded <- tryCatch(requireNamespace("highs", quietly = TRUE), error = identity)
  if (!isTRUE(loaded)) .pr_stop("HiGHS R package could not be loaded.", "postrank_backend_unavailable", "highs_load_failed",
    details = list(backend = "highs", package_path = package_path, cause = if (inherits(loaded, "error")) conditionMessage(loaded) else "requireNamespace returned FALSE"))
  list(package_path = package_path, runtime_guard = NULL)
}
