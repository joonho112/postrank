# Live reproduction report for the installed cache reader (inst/scripts/_vignette-setup.R).
# Compares a sealed result with a freshly computed one from an explicitly selected backend:
# statuses, risks, bounds/gaps and pair-relation agreement. Equal or close risks do not force
# identical grades, and an alternative incumbent is not stale data.
.pr_live_comparison <- function(cached, fresh) {
  fit_of <- function(x) if (inherits(x, "postrank_analysis")) x$fit else if (inherits(x, "postrank_fit")) x else NULL
  a <- fit_of(cached); b <- fit_of(fresh)
  if (is.null(a) || is.null(b)) return(list(comparable = FALSE, reason = "not a fit or analysis"))
  ga <- if (isTRUE(a$incumbent_validated)) a$grade else NULL; gb <- if (isTRUE(b$incumbent_validated)) b$grade else NULL
  agreement <- if (is.null(ga) || is.null(gb)) NA_real_ else {
    ch <- .pr_relation_change(ga, gb); ch[["n_same"]] / choose(length(ga), 2)
  }
  gaps <- c(a$objective$risk_absolute_gap %||% NA_real_, b$objective$risk_absolute_gap %||% NA_real_)
  list(comparable = identical(a$problem_identity, b$problem_identity),
    cached = list(status = a$status$normalized, risk = a$objective$primary_action_risk %||% NA_real_,
      gap = gaps[1], backend = a$backend$name %||% NA_character_),
    live = list(status = b$status$normalized, risk = b$objective$primary_action_risk %||% NA_real_,
      gap = gaps[2], backend = b$backend$name %||% NA_character_),
    risk_difference = (b$objective$primary_action_risk %||% NA_real_) - (a$objective$primary_action_risk %||% NA_real_),
    tolerance = sum(gaps, na.rm = TRUE) + 1e-9, relation_agreement = agreement,
    interpretation = "Same-policy risks are compared within the reported gaps; differing grades at equal risk are alternative incumbents, not stale data.")
}
