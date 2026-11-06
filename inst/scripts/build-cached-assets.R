# Builder of the sealed example assets. Inert when sourced:
# it runs only in an explicit maintainer process with POSTRANK_BUILD_CACHED_ASSETS=true, from
# the package source root, after the package is installed or loaded with pkgload:
#   POSTRANK_BUILD_CACHED_ASSETS=true Rscript inst/scripts/build-cached-assets.R
# Every solve selects backend = "highs" explicitly with a recorded control; this documented
# fixture choice does not change the Gurobi default of the API. Actual statuses and gaps are
# recorded; a time limit is not a success guarantee. Only this builder writes cache files.
if (identical(Sys.getenv("POSTRANK_BUILD_CACHED_ASSETS"), "true") && sys.nframe() == 0L) local({
  stopifnot(file.exists("DESCRIPTION"), dir.exists(file.path("inst", "extdata")))
  suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = FALSE))
  sha <- function(p) digest::digest(file = p, algo = "sha256")
  utc <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  pkg_version <- as.character(utils::packageVersion("postrank"))
  # Bind the public metadata, reader/builder, R source and fixed data.
  # Cached results and manifests are excluded from their own source identity.
  src_files <- sort(c("DESCRIPTION", "LICENSE", file.path("inst", "extdata", "case-studies", "DATA-NOTICE.md"),
    file.path("inst", "scripts", "build-cached-assets.R"), file.path("inst", "scripts", "_vignette-setup.R"),
    list.files("R", "\\.R$", full.names = TRUE),
    list.files("data", "\\.rda$", full.names = TRUE)), method = "radix")
  entries <- lapply(src_files, function(f) list(path = f, sha256 = sha(f)))
  source_id <- digest::digest(paste(vapply(entries, function(e) paste0(e$path, "\t", e$sha256), ""), collapse = "\n"),
    algo = "sha256", serialize = FALSE)
  source_manifest <- list(manifest_schema_version = "1", package_version = pkg_version,
    identity_schema = list(draws = "legacy .pr_identity (0.0.1.9002)", coefficients = "postrank-typed-coefficient-identity-v1"),
    entry_order = "UTF-8 byte (radix) order of path", source_id_encoding = "sha256 of '<path>\\t<sha256>' lines joined by '\\n'",
    entries = entries, source_id = source_id)
  ctrl <- postrank_control(time_limit = 60, threads = 1L, seed = 1304L)
  w3 <- c(poverty = .5, frl = .25, snap = .25)
  stub_input <- function(a, data_name) {
    a$input <- list(postrank_cache_stub = TRUE, data_object = data_name, input_identity = postrank:::.pr_input_identity_of(a$input))
    a
  }
  assets <- list()
  add <- function(key, value, data_name = NULL, solves, call) {
    if (!is.null(data_name)) value <- stub_input(value, data_name)
    assets[[key]] <<- list(value = value, data_name = data_name, solves = solves, call = call)
  }
  # The same six synthetic sites, first with one criterion and then with two.
  # Retain the complete small input: pr_tutorial is a plain list, not a stub target.
  for (part in c("one", "two")) {
    input <- pr_tutorial[[part]]
    K <- length(input$criterion_ids)
    weights <- stats::setNames(rep(1 / K, K), input$criterion_ids)
    value <- postrank(input, weights = weights, tau = .2, G_max = 3L,
      backend = "highs", control = ctrl)
    add(paste0("tutorial_", part), value, NULL, 1L,
      sprintf("postrank(pr_tutorial$%s, weights = %s, tau = .2, G_max = 3L, backend = \"highs\", control = postrank_control(time_limit = 60, threads = 1L, seed = 1304L))",
        part, if (part == "one") "c(score_A = 1)" else "c(score_A = .5, score_B = .5)"))
  }
  tutorial <- assets$tutorial_two$value
  add("tutorial_frontier", postrank_frontier(tutorial, tau = c(.05, .1, .2, .3, .4),
    backend = "highs", control = ctrl), NULL, 5L,
    "postrank_frontier(tutorial_two, tau = c(.05, .1, .2, .3, .4), backend = \"highs\", control = postrank_control(time_limit = 60, threads = 1L, seed = 1304L))")
  add("tutorial_commonality", postrank_commonality_cost(tutorial, backend = "highs", control = ctrl), NULL, 2L,
    "postrank_commonality_cost(tutorial_two, backend = \"highs\", control = postrank_control(time_limit = 60, threads = 1L, seed = 1304L))")
  tutorial_grid <- postrank_settings_grid(tutorial$settings, tau = c(.1, .3), G_max = c(2L, 4L),
    weights = list(A_heavy = c(score_A = .8, score_B = .2), B_heavy = c(score_A = .2, score_B = .8)))
  add("tutorial_sensitivity", postrank_sensitivity(tutorial, tutorial_grid, backend = "highs", control = ctrl), NULL, 7L,
    "postrank_sensitivity(tutorial_two, postrank_settings_grid(tutorial_two$settings, tau = c(.1, .3), G_max = c(2L, 4L), weights = list(A_heavy = c(score_A = .8, score_B = .2), B_heavy = c(score_A = .2, score_B = .8))), backend = \"highs\", control = postrank_control(time_limit = 60, threads = 1L, seed = 1304L))")
  a25 <- postrank(pr_example_draws, weights = w3, tau = .25, G_max = 4L, backend = "highs", control = ctrl)
  add("analysis_30x3", a25, "pr_example_draws", 1L, "postrank(pr_example_draws, weights = c(poverty = .5, frl = .25, snap = .25), tau = .25, G_max = 4L, backend = \"highs\")")
  a35 <- postrank(pr_example_draws, weights = w3, tau = .35, G_max = 4L, backend = "highs", control = ctrl)
  add("analysis_30x3_tau35", a35, "pr_example_draws", 1L, "postrank(pr_example_draws, weights = c(poverty = .5, frl = .25, snap = .25), tau = .35, G_max = 4L, backend = \"highs\")")
  g25 <- postrank(pr_example_gaussian, weights = w3, tau = .25, G_max = 4L, backend = "highs", control = ctrl)
  add("gaussian_analysis_30x3", g25, "pr_example_gaussian", 1L, "postrank(pr_example_gaussian, weights = c(poverty = .5, frl = .25, snap = .25), tau = .25, G_max = 4L, backend = \"highs\")")
  fr <- postrank_frontier(a25, tau = seq(.10, .45, by = .05), backend = "highs", control = ctrl)
  add("frontier_30x3", fr, NULL, 8L, "postrank_frontier(analysis_30x3, tau = seq(.10, .45, by = .05), backend = \"highs\")")
  add("commonality_30x3", postrank_commonality_cost(a25, backend = "highs", control = ctrl), NULL, 3L,
    "postrank_commonality_cost(analysis_30x3, backend = \"highs\")")
  add("commonality_30x3_tau35", postrank_commonality_cost(a35, backend = "highs", control = ctrl), NULL, 3L,
    "postrank_commonality_cost(analysis_30x3_tau35, backend = \"highs\")")
  add("comparison_30x3_tau35", postrank_compare(a35), NULL, 0L, "postrank_compare(analysis_30x3_tau35)")
  add("comparison_30x3", postrank_compare(a25), NULL, 0L, "postrank_compare(analysis_30x3)")
  wt <- c(need_A = .6, need_B = .4)
  ta <- postrank(postrank_toy, weights = wt, tau = .25, G_max = 3L, backend = "highs", control = ctrl)
  add("toy_analysis", ta, "postrank_toy", 1L, "postrank(postrank_toy, weights = c(need_A = .6, need_B = .4), tau = .25, G_max = 3L, backend = \"highs\")")
  pwt <- postrank_pairwise(postrank_toy)
  add("toy_minimax", postrank_solve(postrank_problem(pwt, wt, .25, 3L, objective = "minimax"), backend = "highs", control = ctrl), NULL, 1L,
    "postrank_solve(postrank_problem(postrank_pairwise(postrank_toy), w, .25, 3L, objective = \"minimax\"), backend = \"highs\")")
  add("toy_frontier", postrank_frontier(pwt, wt, tau = c(.15, .25, .4), G_max = 3L, backend = "highs", control = ctrl), NULL, 3L,
    "postrank_frontier(postrank_pairwise(postrank_toy), w, tau = c(.15, .25, .4), G_max = 3L, backend = \"highs\")")
  add("toy_commonality", postrank_commonality_cost(ta, backend = "highs", control = ctrl), NULL, 2L,
    "postrank_commonality_cost(toy_analysis, backend = \"highs\")")
  add("toy_crossfit", postrank_crossfit(postrank_toy, fit = ta$fit, backend = "highs", control = ctrl), NULL, 2L,
    "postrank_crossfit(postrank_toy, fit = toy_analysis$fit, backend = \"highs\")")
  # Public case studies retain their complete compact probability input. Their
  # data objects are five-element lists, not typed inputs for the stub restorer.
  # These are fresh, bounded solves of the selected numerical inputs, not imported
  # historical fits or certifications of the source posterior approximation.
  case_specs <- list(
    case_cde_12 = list(data = "pr_case_cde", tau = .2, G = 3L),
    case_krw_signed97 = list(data = "pr_case_krw", tau = .25, G = 4L),
    case_alabama67 = list(data = "pr_case_alabama", tau = .2, G = 5L))
  case_ctrl <- postrank_control(time_limit = 30, threads = 1L, seed = 1304L)
  for (key in names(case_specs)) {
    spec <- case_specs[[key]]; case <- get(spec$data)
    input <- case$input; ks <- input$criterion_ids
    weights <- stats::setNames(rep(1 / length(ks), length(ks)), ks)
    level <- input$summaries$level
    value <- postrank(input, weights = weights, tau = spec$tau, G_max = spec$G,
      level = level, backend = "highs", control = case_ctrl, fragility = FALSE)
    call <- sprintf("postrank(%s$input, weights = setNames(rep(1/%d, %d), %s$input$criterion_ids), tau = %s, G_max = %dL, level = %s, backend = \"highs\", control = postrank_control(time_limit = 30, threads = 1L, seed = 1304L), fragility = FALSE)",
      spec$data, length(ks), length(ks), spec$data, spec$tau, spec$G, level)
    add(key, value, NULL, 1L, call)
  }
  # No machine path enters a shipped object (T-doc-05). The frozen engine records the solver
  # wrapper's library directory as backend$wrapper_path; it is replaced by <R_LIBS>/<package>
  # and the replacement count is recorded. Any other absolute path stops the build.
  redact <- function(value) {
    n <- 0L
    walk <- function(v) {
      if (!is.list(v)) return(v)
      nm <- names(v)
      for (i in seq_along(v)) {
        e <- v[[i]]
        if (!is.null(nm) && identical(nm[i], "wrapper_path") && is.character(e) && length(e) == 1L && grepl("^/|^[A-Za-z]:[\\\\/]", e)) {
          v[[i]] <- file.path("<R_LIBS>", basename(e)); n <<- n + 1L
        } else if (is.list(e)) v[[i]] <- walk(e)
      }
      v
    }
    out <- walk(value)
    chars <- function(x) if (is.character(x)) x else if (is.list(x)) unlist(lapply(x, chars), use.names = FALSE) else character()
    left <- grep("^/|/Users/|/home/|^[A-Za-z]:[\\\\/]", chars(out), value = TRUE)
    if (length(left)) stop("absolute path left in a cached asset: ", left[[1L]], call. = FALSE)
    list(value = out, n = n)
  }
  dir <- file.path("inst", "extdata", "cached"); dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  backend_version <- tryCatch(as.character(utils::packageVersion("highs")), error = function(e) NA_character_)
  records <- list()
  for (key in names(assets)) {
    a <- assets[[key]]; r <- redact(a$value); v <- r$value
    fit <- if (inherits(v, "postrank_analysis")) v$fit else if (inherits(v, "postrank_fit")) v else NULL
    meta <- list(key = key, cache_schema_version = "1", package_version = pkg_version, source_id = source_id,
      created_at = utc(), r_version = R.version.string, backend = "highs", backend_version = backend_version,
      seed = ctrl$seed, control = ctrl[c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap", "strategy")],
      solves = a$solves, call = a$call, object_class = class(v)[1L],
      data_object = a$data_name, input_identity = if (inherits(v, "postrank_analysis")) v$input$input_identity else v$input_identity,
      problem_identity = if (!is.null(fit)) fit$problem_identity else NULL,
      status = if (!is.null(fit)) fit$status$normalized else NULL,
      risk_absolute_gap = if (!is.null(fit)) fit$objective$risk_absolute_gap else NULL,
      redactions = list(field = "backend$wrapper_path", replacement = "<R_LIBS>/<package>", count = r$n))
    if (key %in% names(case_specs)) {
      meta$case_data <- case_specs[[key]]$data
      meta$data_distribution <- unname(c(case_cde_12 = "public-source-maintainer-confirmed",
        case_krw_signed97 = "CC-BY-NC", case_alabama67 = "CC-BY-4.0")[[key]])
      meta$data_notice <- "extdata/case-studies/DATA-NOTICE.md"
      meta$control <- case_ctrl[c("time_limit", "threads", "seed", "absolute_risk_gap", "relative_gap", "strategy")]
      meta$seed <- case_ctrl$seed
    }
    path <- file.path(dir, paste0(key, ".rds"))
    if (file.exists(path)) file.remove(path)
    saveRDS(list(value = v, metadata = meta), path, compress = "xz", version = 2)
    meta$file <- file.path("extdata", "cached", paste0(key, ".rds")); meta$bytes <- file.size(path); meta$sha256 <- sha(path)
    records[[key]] <- meta
    cat(sprintf("%-26s %8d bytes  %s\n", key, meta$bytes, meta$status %||% ""))
  }
  writeLines(jsonlite::toJSON(source_manifest, auto_unbox = TRUE, pretty = TRUE),
    file.path("inst", "extdata", "manifests", "source-manifest.json"))
  writeLines(jsonlite::toJSON(list(manifest_schema_version = "1", package_version = pkg_version, source_id = source_id,
    created_at = utc(), assets = records, total_bytes = sum(vapply(records, `[[`, 1, "bytes"))), auto_unbox = TRUE,
    pretty = TRUE, null = "null", digits = NA), file.path("inst", "extdata", "manifests", "cache-manifest.json"))
  cat("cache manifest written; source_id", source_id, "\n")
})
