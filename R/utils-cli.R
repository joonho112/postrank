# Null default (base R >= 4.4 has %||%; defined here for R 4.1-4.3).
`%||%` <- function(x, y) if (is.null(x)) y else x

# Console helpers (Chapter 13 SPEC-13.1-13.4). Every formatter returns a character
# vector, has no side effect and recomputes nothing: it formats stored slots only.

.pr_cli_tier <- function(tier = NULL) {
  if (!is.null(tier)) {
    .pr_assert(length(tier) == 1L && !is.na(tier) && tier %in% 1:3, "tier must be 1, 2 or 3", "invalid_display", "$.tier")
    return(as.integer(tier))
  }
  if (isTRUE(getOption("knitr.in.progress"))) return(3L)
  if (cli::num_ansi_colors() > 1L && cli::is_dynamic_tty()) return(1L)
  2L
}
.pr_cli_width <- function(width = NULL) {
  if (is.null(width)) width <- getOption("width", 80L)
  .pr_assert(is.numeric(width) && length(width) == 1L && is.finite(width), "width must be a number", "invalid_display", "$.width")
  max(40L, as.integer(width))
}
.pr_cli_n_head <- function(n_head) {
  .pr_assert(is.numeric(n_head) && length(n_head) == 1L && is.finite(n_head) && n_head >= 1, "n_head must be a positive integer",
    "invalid_display", "$.n_head")
  as.integer(n_head)
}
.pr_cli_assert_class <- function(x, classes, formatter) {
  if (!inherits(x, classes)) .pr_abort(sprintf("%s() formats %s objects, not %s", formatter, paste(classes, collapse = " or "),
    class(x)[1L]), "wrong_class", "$.x")
  invisible(TRUE)
}

# Number policy (SPEC-13.3): risks/bounds 4 decimals; ratios/agreement 3; rates one-decimal
# percentages; gaps/tolerances/MCSE format(digits = 3); counts integer; NA verbatim.
.pr_fmt <- function(x, kind = c("risk", "ratio", "pct", "gap", "count", "num")) {
  kind <- match.arg(kind)
  if (is.null(x) || !length(x)) return("NA")
  vapply(x, function(v) {
    if (is.na(v)) return("NA")
    switch(kind,
      risk = formatC(v, digits = 4, format = "f", decimal.mark = "."),
      ratio = formatC(v, digits = 3, format = "f", decimal.mark = "."),
      pct = paste0(formatC(100 * v, digits = 1, format = "f", decimal.mark = "."), "%"),
      gap = if (v == 0) "0" else format(v, digits = 3, decimal.mark = ".", scientific = abs(v) < 1e-3),
      count = format(as.integer(round(v)), big.mark = ""),
      num = format(v, digits = 4, decimal.mark = "."))
  }, "")
}
.pr_cli_header <- function(class, phrase) paste0("<", class, ">  ", phrase)
.pr_cli_line <- function(...) paste0("  ", ...)
.pr_cli_pointer <- function(text) paste0("  i  ", text)
.pr_cli_warning_line <- function(w, width) {
  w <- unique(as.character(w)); w <- w[nzchar(w)]
  if (!length(w)) return(character())
  first <- paste0("  !  ", length(w), if (length(w) == 1L) " warning recorded: " else " warnings recorded; first: ", w[1L])
  if (nchar(first) > width) first <- paste0(substr(first, 1L, width - 3L), "...")
  first
}
# Wrap each line to the width; continuation lines are indented two more spaces.
.pr_cli_wrap <- function(lines, width) {
  # strwrap alone leaves long IDs and hashes wider than the requested display.
  hard_wrap <- function(text, budget) {
    if (nchar(text, type = "width") <= budget) return(text)
    chars <- strsplit(text, "", fixed = TRUE)[[1L]]
    out <- character(); current <- ""; used <- 0L
    for (ch in chars) {
      size <- nchar(ch, type = "width")
      if (used + size > budget && nzchar(current)) { out <- c(out, current); current <- ""; used <- 0L }
      current <- paste0(current, ch); used <- used + size
    }
    c(out, current)
  }
  unlist(lapply(lines, function(line) {
    if (nchar(line, type = "width") <= width) return(line)
    indent <- nchar(sub("^(\\s*).*", "\\1", line))
    indent <- min(indent, width - 8L)
    wrapped <- strwrap(trimws(line), width = width - indent - 2L)
    pieces <- unlist(lapply(wrapped, hard_wrap, budget = width - indent - 2L), use.names = FALSE)
    paste0(strrep(" ", indent), c(pieces[1L], if (length(pieces) > 1L) paste0("  ", pieces[-1L])))
  }), use.names = FALSE)
}
# Tier 1 adds ANSI styling only; ansi_strip(tier 1) == tier 2 byte for byte (T-ux-07).
.pr_cli_style <- function(lines, tier) {
  if (!identical(tier, 1L)) return(lines)
  vapply(lines, function(l) {
    if (grepl("^<[A-Za-z_]+>", l)) {
      tok <- sub("^(<[A-Za-z_]+>).*$", "\\1", l); return(paste0(cli::style_bold(tok), substring(l, nchar(tok) + 1L)))
    }
    if (grepl("^  i  ", l)) return(cli::style_dim(l))
    if (grepl("^  !  ", l)) return(cli::col_yellow(l))
    if (grepl("status optimal", l, fixed = TRUE)) return(sub("optimal", cli::col_green("optimal"), l, fixed = TRUE))
    l
  }, "", USE.NAMES = FALSE)
}
.pr_cli_finish <- function(lines, width, tier) .pr_cli_style(.pr_cli_wrap(lines, width), tier)

# Contextual wording guard (SPEC-13.3): a lint aid for authored text, not a runtime filter.
# Flags misleading affirmative statements; allows negations and stored identifiers.
.pr_cli_guard <- function(text) {
  text <- tolower(paste(text, collapse = " "))
  text <- gsub("\\s+", " ", text)
  sentences <- unlist(strsplit(text, "(?<=[.;!?])\\s+", perl = TRUE))
  patterns <- c(unique_optimum = "\\bunique optim", no_error = "\\b(no error|error-free|without error)",
    certified = "\\bcertif(ied|icate)\\b", proves = "\\bprov(e|es|en|ed)\\b.*\\b(superior|optimal|better)\\b",
    guaranteed = "\\bguarantee[sd]?\\b")
  negation <- "\\b(not|never|without|cannot|isn't|is not|does not|unknown|false)\\b"
  hits <- character()
  for (s in sentences) for (nm in names(patterns)) {
    if (!grepl(patterns[[nm]], s, perl = TRUE)) next
    rest <- sub(patterns[[nm]], " ", s, perl = TRUE)   # the flagged phrase itself is not a negation
    if (!grepl(negation, rest, perl = TRUE)) hits <- c(hits, paste0(nm, ": ", trimws(s)))
  }
  unique(hits)
}
.pr_grade_sizes <- function(grade) {
  tab <- tabulate(unname(grade), nbins = max(grade))
  paste(tab, collapse = " / ")
}
.pr_members <- function(grade, entity_ids, width, max_n = 60L) {
  if (length(grade) > max_n) return(.pr_cli_line(sprintf("%d entities; membership in get_grades(x)", length(grade))))
  g <- grade[entity_ids]
  unlist(lapply(sort(unique(g)), function(k) {
    ids <- names(g)[g == k]
    prefix <- sprintf("  grade %d (%d): ", k, length(ids))
    budget <- 2L * width - nchar(prefix) - 12L
    used <- cumsum(nchar(ids) + 2L)
    keep <- max(1L, sum(used <= budget))
    text <- paste0(prefix, paste(ids[seq_len(keep)], collapse = ", "),
      if (keep < length(ids)) sprintf(" +%d more", length(ids) - keep) else "")
    .pr_cli_wrap(text, width)
  }), use.names = FALSE)
}

.pr_cli_details <- function(details) {
  .pr_assert(is.logical(details) && length(details) == 1L && !is.na(details),
    "details must be TRUE or FALSE", "invalid_display", "$.details")
  invisible(details)
}
.pr_policy_lines <- function(s) {
  c(paste0("Loss: ", if (identical(s$objective, "minimax")) "the largest selected criterion loss." else "the weighted average of criterion losses."),
    if (!is.null(s$exact_G)) paste0("Exactly ", s$exact_G, " occupied grades.") else if (!is.null(s$G_max))
      paste0("At most ", s$G_max, " grades; fewer may be used."),
    if (!is.null(s$tau)) paste0("Withholding cost (tau): ", .pr_fmt(s$tau, "num"), " per withheld pair."),
    if (!is.null(s$q)) paste0("Expected error limits among disclosed pairs: ",
      paste(names(s$q), .pr_fmt(s$q, "ratio"), collapse = "; "), "."),
    if (identical(s$objective, "minimax")) paste0("Minimax criteria: ",
      paste(s$minimax_criteria %||% names(s$weights), collapse = ", "), "."))
}
.pr_summary_legacy_lines <- function(x) {
  h <- x$headline
  c(if (!is.null(h$n)) paste0(h$n, " entities", if (!is.null(h$K)) paste0("; ", h$K, if (h$K == 1) " criterion." else " criteria.") else "."),
    if (!is.null(h$risk)) paste0("Posterior loss: ", .pr_fmt(h$risk, "risk"), "."),
    if (!is.null(h$status)) .pr_status_words(h$status),
    "This saved summary predates the readable view. Its original structured fields are retained; use details = TRUE to inspect them.")
}
.pr_summary_sections <- function(cls, x) {
  if (startsWith(cls, "postrank_tie_")) return(.pr_tie_sections(x, cls))
  if (cls %in% c("postrank_fit", "postrank_analysis")) {
    fit <- if (cls == "postrank_analysis") x$fit else x
    pw <- fit$problem$pairwise; ev <- fit$evaluation; s <- fit$problem$settings
    ok <- isTRUE(fit$incumbent_validated) && !is.null(fit$grade)
    result <- c(if (ok) paste0(length(fit$grade), " entities in ", ev$G, if (ev$G == 1L) " grade" else " grades",
      " (sizes ", .pr_grade_sizes(fit$grade), ")."), .pr_fit_result_lines(fit))
    profile <- data.frame(Criterion = pw$criterion_ids, Weight = unname(s$weights[pw$criterion_ids]),
      Loss = if (ok) .pr_fmt(ev$criterion_risk[pw$criterion_ids], "risk") else "NA",
      `Error / disclosed` = if (ok) .pr_fmt(ev$E_over_N[pw$criterion_ids], "ratio") else "NA",
      check.names = FALSE, stringsAsFactors = FALSE)
    view <- list(Result = result, Settings = .pr_policy_lines(s), `Criterion results` = profile,
      `Reading the loss` = c("Grade 1 has highest priority. A shared grade withholds that pair's comparison.",
        "Each criterion loss averages expected errors on disclosed pairs and the withholding cost over all unordered pairs.",
        "Error / disclosed uses only the disclosed pairs; it is NA when their count is zero. Tau is a loss cost, not an error-rate limit."),
      Computation = .pr_gap_lines(fit, if (cls == "postrank_analysis") x$control$absolute_risk_gap else NULL, TRUE))
    if (cls == "postrank_analysis") view$`Optional results` <- vapply(names(x$extras), function(e) .pr_extra_words(e, x$extras[[e]]), "")
    view$`Input assumptions` <- if (inherits(pw, "postrank_probabilities"))
      c("The supplied comparison probabilities are used as declared. Their source and accuracy are not independently verified.",
        paste0("Conditioning: ", pw$source$conditioning),
        "No target draw count, Monte Carlo error or joint posterior law is inferred from them.") else
      c("Losses describe the supplied posterior and target definitions; source declarations are not independently verified.",
        "A low posterior loss does not verify the statistical model.")
    return(view)
  }
  if (cls %in% c("postrank_settings", "postrank_problem")) {
    s <- if (cls == "postrank_settings") x else x$settings
    view <- list(Settings = .pr_policy_lines(s), `Criterion weights` =
      data.frame(Criterion = names(s$weights), Weight = unname(s$weights)))
    if (cls == "postrank_problem") view <- c(list(Result = c("No grades have been calculated yet.",
      paste0(length(x$pairwise$entity_ids), " entities. ", .pr_criteria_words(x$pairwise$criterion_ids)))), view)
    view$Interpretation <- "Tau is the cost of withholding a comparison, not an error-rate limit. Fewer grades generally withhold more comparisons."
    return(view)
  }
  # Store only short text/table views, never the original posterior or solver model.
  formatter <- .pr_formatter_of[[cls]]
  if (is.null(formatter)) return(list(Result = "Inspect the stored result fields."))
  lines <- get(paste0("format_postrank_", formatter, "_cli"), mode = "function")(x, width = 10000L, tier = 2L, n_head = 10L)
  lines <- lines[!grepl("^  (i  |!  )", lines)]
  lines[1L] <- sub("^<[^>]+>  ", "", lines[1L])
  view <- list(Result = trimws(lines))
  if (cls %in% c("postrank_settings", "postrank_problem", "postrank_baseline", "postrank_report_card", "postrank_comparison")) {
    s <- if (cls == "postrank_settings") x else x$settings
    view$Settings <- .pr_policy_lines(s)
    if (length(s$weights)) view$`Criterion weights` <- data.frame(Criterion = names(s$weights), Weight = unname(s$weights))
  }
  if (cls == "postrank_draws") view$Targets <- data.frame(Criterion = x$criterion_ids,
    Target = vapply(x$targets, function(t) t$estimand, ""),
    Units = vapply(x$targets, function(t) t$units %||% "unspecified", ""), stringsAsFactors = FALSE)
  if (inherits(x, "postrank_probabilities")) {
    view$Targets <- data.frame(Criterion = names(x$targets), Target = unname(x$targets))
    view$Source <- c(x$source$description, paste0("Conditioning: ", x$source$conditioning),
      if (is.null(x$summaries)) "Marginal means and intervals were not supplied." else
        c(paste0("Supplied summaries: ", x$summaries$description), if (!is.null(x$summaries$level))
          paste0("Intervals are fixed at ", .pr_fmt(x$summaries$level, "pct"), ".") else "Marginal intervals were not supplied."))
    view$`Numerical corrections` <- data.frame(Criterion = names(x$correction$maximum_absolute_change),
      `Largest change` = unname(x$correction$maximum_absolute_change), check.names = FALSE)
  }
  if (cls == "postrank_diagnostics") view$`Trace diagnostics` <- do.call(rbind, lapply(names(x$summaries), function(id) {
    d <- x$summaries[[id]]$diagnostics
    data.frame(Trace = id, MCSE = .pr_metric_text(d$mcse_mean), Rhat = .pr_metric_text(d$rhat),
      `Bulk ESS` = .pr_metric_text(d$ess_bulk), check.names = FALSE, stringsAsFactors = FALSE)
  }))
  view
}

.pr_table_lines <- function(df, n_head, width) {
  n_head <- .pr_cli_n_head(n_head)
  if (!nrow(df)) return(.pr_cli_line("No rows are available."))
  shown <- df[seq_len(min(nrow(df), n_head)), , drop = FALSE]
  for (nm in names(shown)) {
    if (is.double(shown[[nm]])) shown[[nm]] <- .pr_fmt(shown[[nm]], "num")
    if (is.logical(shown[[nm]])) shown[[nm]] <- ifelse(is.na(shown[[nm]]), "NA", ifelse(shown[[nm]], "yes", "no"))
  }
  out <- paste0("  ", utils::capture.output(print(shown, row.names = FALSE, right = FALSE)))
  if (any(nchar(out, type = "width") > width)) out <- unlist(lapply(seq_len(nrow(shown)), function(i) {
    values <- vapply(shown, function(column) as.character(column[i]), "")
    c(.pr_cli_line(paste0(names(shown)[1L], ": ", values[1L])),
      if (ncol(shown) > 1L) paste0("    ", names(shown)[-1L], ": ", values[-1L]))
  }), use.names = FALSE)
  if (nrow(df) > n_head) out <- c(out, .pr_cli_line(sprintf("Showing %d of %d rows; the full table is retained in the object.", n_head, nrow(df))))
  trimws(out, which = "right")
}

.pr_metric_text <- function(metric) {
  if (isTRUE(metric$available)) return(.pr_fmt(metric$value, "gap"))
  reason <- metric$unavailable_reason %||% "not available for this input"
  paste0("NA (", gsub("_", " ", reason), ")")
}
