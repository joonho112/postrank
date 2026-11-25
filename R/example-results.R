# One sentence for each stored example result, written from the call recorded in the cache manifest.
.pr_example_descriptions <- c(
  analysis_30x3 = "30 example sites, three criteria, from posterior draws (pr_example_draws).",
  analysis_30x3_tau35 = "analysis_30x3 with tau = 0.35.",
  case_alabama67 = "Alabama county case study (pr_case_alabama), two criteria.",
  case_cde_12 = "California school case study (pr_case_cde), one criterion.",
  case_krw_signed97 = "97-firm case study (pr_case_krw), two criteria.",
  commonality_30x3 = "Cost of one common grading for analysis_30x3.",
  commonality_30x3_tau35 = "Cost of one common grading for analysis_30x3_tau35.",
  comparison_30x3 = "postrank_compare() result for analysis_30x3.",
  comparison_30x3_tau35 = "postrank_compare() result for analysis_30x3_tau35.",
  frontier_30x3 = "analysis_30x3 graded at tau from 0.10 to 0.45.",
  gaussian_analysis_30x3 = "The 30-site example from Gaussian posteriors (pr_example_gaussian).",
  toy_analysis = "Three-entity toy example with two criteria (postrank_toy).",
  toy_commonality = "Cost of one common grading for toy_analysis.",
  toy_crossfit = "Cross-fitting for toy_analysis.",
  toy_frontier = "The toy example graded at three values of tau.",
  toy_minimax = "The toy example solved with the minimax objective (a postrank_fit).",
  tutorial_commonality = "Cost of one common grading for the two scores of tutorial_two.",
  tutorial_frontier = "tutorial_two graded at five values of tau.",
  tutorial_one = "Six tutorial sites graded on one score (pr_tutorial$one).",
  tutorial_sensitivity = "tutorial_two under a grid of tau, G_max and weights.",
  tutorial_two = "Six tutorial sites graded on two scores (pr_tutorial$two).")

# The installed reader of the stored results (inst/scripts/_vignette-setup.R), in an environment
# whose parent is the package namespace, so that it works installed and under pkgload::load_all().
.pr_example_reader <- function() {
  setup <- system.file("scripts", "_vignette-setup.R", package = "postrank")
  if (!nzchar(setup)) stop("the reader script scripts/_vignette-setup.R is not installed", call. = FALSE)
  reader <- new.env(parent = asNamespace("postrank"))
  sys.source(setup, envir = reader)
  reader
}

# A reader error rewritten for users: the asset prefix and the maintainer's rebuild instruction are dropped.
.pr_example_read_error <- function(name, message) {
  reason <- sub("\\. Rebuild with .*$", "", message)
  reason <- sub("^cached asset '[^']*': ", "", reason)
  what <- if (is.null(name)) "the list of stored examples" else paste0("the stored example '", name, "'")
  paste0(what, " could not be read (", reason, "). Reinstall postrank and try again.")
}

.pr_example_fail <- function(name, cond) {
  stop(structure(list(message = paste0("$: ", .pr_example_read_error(name, conditionMessage(cond))), call = NULL,
    code = "example_unreadable", path = "$", parent = cond),
    class = c("postrank_input_error", "postrank_error", "error", "condition")))
}

#' Stored Example Results
#'
#' `postrank_example()` reads results stored with the package. Call it without arguments to list the
#' examples or give a name to load one. Reading an example needs no solver.
#'
#' @param name Name of a stored result, as listed by `postrank_example()`. If `NULL` (the default),
#'   the list is returned instead.
#' @returns With `name = NULL`, a data frame with one row per stored result and the columns
#'   * `name` and `description`;
#'   * `class`: the class of the stored object;
#'   * `call`: an example call describing the calculation;
#'   * `computed_with`: the postrank and solver versions that were used;
#'   * `solves`: how many optimization problems were solved (0 for comparisons of stored results);
#'   * `created`: when it was computed (UTC).
#'
#'   Otherwise the stored object, for example a `postrank_analysis`, with its grades and numerical
#'   results. Local solver installation paths were replaced with portable labels when saving.
#' @details The grading analyses used postrank 1.1.0 and HiGHS. The two comparison examples
#'   summarize stored analyses. Some example calls are abbreviated or refer to another stored
#'   result, such as `tutorial_two`. In the calls for `toy_minimax` and `toy_frontier`,
#'   `w` stands for `c(need_A = 0.6, need_B = 0.4)`.
#'
#'   Before a result is returned, postrank checks that the stored file is unchanged (its size and
#'   SHA-256 checksum) and that this version of postrank can read it. Reading a result never runs a
#'   solver and never changes the stored files.
#' @seealso [get_grades()], [get_risk()], [postrank()]
#' @examples
#' ex <- postrank_example()
#' ex[, c("name", "description")]
#'
#' one <- postrank_example("tutorial_one")
#' get_grades(one)
#' @export
postrank_example <- function(name = NULL) {
  man <- tryCatch(jsonlite::read_json(system.file("extdata", "manifests", "cache-manifest.json",
    package = "postrank", mustWork = TRUE)), error = function(e) .pr_example_fail(NULL, e))
  keys <- sort(names(man$assets), method = "radix")
  if (is.null(name)) {
    rec <- function(field) vapply(keys, function(k) {
      v <- man$assets[[k]][[field]]
      if (is.null(v)) NA_character_ else as.character(v)
    }, "", USE.NAMES = FALSE)
    solves <- as.integer(rec("solves"))
    return(data.frame(name = keys, class = rec("object_class"), description = unname(.pr_example_descriptions[keys]),
      call = rec("call"),
      computed_with = ifelse(solves > 0L, paste0("postrank ", rec("package_version"), ", ", rec("backend"), " ",
        rec("backend_version")), paste0("postrank ", rec("package_version"), ", no solver")),
      solves = solves, created = rec("created_at"), stringsAsFactors = FALSE))
  }
  .pr_assert(is.character(name) && length(name) == 1L && !is.na(name), "name must be the name of one stored example",
    "invalid_example_name", "$.name")
  if (!name %in% keys) .pr_abort(paste0("there is no stored example named '", name, "'; available: ",
    paste(keys, collapse = ", ")), "unknown_example", "$.name")
  tryCatch(.pr_example_reader()$load_or_compute(name), error = function(e) .pr_example_fail(name, e))
}
