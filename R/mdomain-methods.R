# Display methods consume stored records only. They never bind, evaluate or
# solve, and remain usable for stored results without optional arithmetic tools.

.md_display_number <- function(value, exact=NULL) {
  if (!is.null(exact) && length(exact) == 1L && !is.na(exact)) return(exact)
  if (length(value) != 1L || is.na(value)) return("not evaluated")
  format(value, digits=7)
}

#' @export
print.postrank_mdomain_input <- function(x, ...) {
  cat("Multidomain posterior input\n")
  cat(" ", x$n, " units; ", x$D, " domains; ", x$layout, "\n", sep="")
  cat("  Representation: ", paste(unique(unname(x$representation)), collapse=", "), "\n", sep="")
  cat("  Coupling: ", x$coupling_status, "\n", sep="")
  cat("  Proper law: producer declaration; numerical guarantee: none\n")
  invisible(x)
}

#' @export
summary.postrank_mdomain_input <- function(object, ...) {
  payloads <- object$payloads
  payload_table <- if (length(payloads)) do.call(rbind, lapply(payloads, function(p)
    data.frame(payload_id=p$payload_id, domains=paste(p$domain_ids,collapse=", "),
      states=length(p$state_ids), representation=p$representation,
      exact_masses=!is.null(p$weights_exact), stringsAsFactors=FALSE))) else
    data.frame(payload_id=character(),domains=character(),states=integer(),
      representation=character(),exact_masses=logical(),stringsAsFactors=FALSE)
  structure(list(input_id=object$input_id, n=object$n, D=object$D,
    unit_ids=object$unit_ids, domain_ids=object$domain_ids, layout=object$layout,
    representations=object$representation, coupling_status=object$coupling_status,
    payload_table=payload_table, capabilities=object$capabilities,
    intended_law=object$intended_law, target_spec=object$target_spec,
    receipts=object$receipts), class=c("summary.postrank_mdomain_input", "list"))
}

#' @export
print.summary.postrank_mdomain_input <- function(x, ...) {
  cat("Multidomain input summary: ", x$n, " units, ", x$D, " domains\n", sep="")
  cat("  ", x$layout, "; coupling: ", x$coupling_status, "\n", sep="")
  if (nrow(x$payload_table)) print(x$payload_table, row.names=FALSE)
  cat("  Numerical guarantee: none; law metadata are producer declarations\n")
  invisible(x)
}

#' @export
print.postrank_mdomain_decision <- function(x, ...) {
  cat("Multidomain decision recipe\n")
  cat("  Withholding cost tau: ", paste(x$tau,collapse=", "), "\n", sep="")
  cat("  Mean guards: ", if (!is.null(x$expected)) paste(nrow(x$expected),"explicit rows") else
    if (is.null(x$q)) "disabled" else "full-scope convenience rows", "\n", sep="")
  cat("  Joint guards: ", if (!is.null(x$joint)) paste(nrow(x$joint),"explicit rows") else
    if (is.null(x$t)) "disabled" else "full-scope convenience rows", "\n", sep="")
  cat("  Joint cap alpha: ", x$alpha, "; exact rational policy fields\n", sep="")
  invisible(x)
}

#' @export
summary.postrank_mdomain_decision <- function(object, ...) {
  fields <- c("weights", "tau", "q", "t", "alpha")
  parameters <- do.call(rbind, lapply(fields, function(field) {
    value <- object[[field]]
    if (field == "weights" && !is.null(object$receipts$weights_supplied_exact))
      value <- object$receipts$weights_supplied_exact
    data.frame(parameter=field, domain_id=if (is.null(value)) NA_character_ else
      if (is.null(names(value))) rep(NA_character_,length(value)) else names(value),
      exact_value=if (is.null(value)) NA_character_ else as.character(value), stringsAsFactors=FALSE)
  }))
  structure(list(parameters=parameters, scope=object$scope,
    expected=object$expected, joint=object$joint, receipts=object$receipts),
    class=c("summary.postrank_mdomain_decision", "list"))
}

#' @export
print.summary.postrank_mdomain_decision <- function(x, ...) {
  cat("Multidomain decision summary (unbound recipe)\n")
  print(x$parameters, row.names=FALSE)
  cat("  Scope catalog and explicit protection rows are retained in this summary.\n")
  invisible(x)
}

#' @export
print.postrank_mdomain_evaluation <- function(x, ...) {
  cat("Fixed multidomain report evaluation\n")
  cat("  ", x$input$n, " units; ", x$input$D, " domains; mode: ", x$mode, "\n", sep="")
  cat("  Risk: ", .md_display_number(x$risk,x$risk_exact),
      "; joint probability: ", .md_display_number(x$J,x$J_exact), "\n", sep="")
  cat("  Joint guards: ", x$status$joint, "; ", x$status$feasibility, "\n", sep="")
  cat("  Basis: ", x$assurance$numerical_basis, "; ", x$status$arithmetic, "\n", sep="")
  cat("  Intended posterior feasibility certificate: none\n")
  invisible(x)
}

#' @export
summary.postrank_mdomain_evaluation <- function(object, ...) {
  fields <- c("mode", "grades", "M", "risk", "risk_exact", "J", "J_exact",
    "domain_table", "scope_table", "expected_constraints", "event_table",
    "mean_feasible", "joint_feasible", "feasible_for_represented_measure",
    "joint_evaluated", "joint_protection_enabled", "status", "assurance", "receipts")
  structure(unclass(object)[fields],
    class=c("summary.postrank_mdomain_evaluation", "list"))
}

#' @export
print.summary.postrank_mdomain_evaluation <- function(x, ...) {
  cat("Multidomain evaluation summary\n")
  cat("  Risk: ", .md_display_number(x$risk,x$risk_exact),
      "; joint probability: ", .md_display_number(x$J,x$J_exact), "\n", sep="")
  cat("  ", x$status$feasibility, "; joint guards: ", x$status$joint, "\n", sep="")
  print(x$domain_table, row.names=FALSE)
  cat("  Basis: ", x$assurance$numerical_basis, "; ", x$status$arithmetic, "\n", sep="")
  cat("  Intended posterior feasibility certificate: none\n")
  invisible(x)
}
