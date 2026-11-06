#' Specify a Multidomain Reporting Decision
#'
#' Creates a decision recipe. Domain and unit identities, mask dimensions, and
#' protection rows are checked again when the recipe is bound to an input.
#' Smaller grade labels report higher priority; a grade tie withholds direction.
#'
#' @param weights Domain weights, or `NULL` for exactly equal weights. Named
#'   vectors must follow the input's domain order. Numeric weights whose total
#'   is within the core tolerance are normalized using their exact stored binary
#'   values; rational text weights must sum to exactly one. Zero weights are
#'   permitted and do not disable protection rows.
#' @param tau Tie loss in `(0, 1/2]`, as a scalar or a domain vector.
#' @param scope `"all_pairs"`, or a named list of symmetric binary masks with
#'   zero diagonals. Named masks must follow the input's unit order.
#' @param q Expected-error guard in `[0, 1]`, as a scalar or domain vector.
#'   `NULL` omits these guards.
#' @param t Joint exceedance threshold in `[0, 1]`, as a scalar or domain
#'   vector. `NULL` disables joint guards. An exceedance is strict, `F/N > t`.
#' @param alpha Joint-event probability limit in `[0, 1]`.
#' @param expected Explicit rows with `domain_id`, `scope_id`, and `q` columns.
#'   These override the convenience `q` rows. An empty data frame disables them.
#' @param joint Explicit rows with `domain_id`, `scope_id`, and `t` columns.
#'   These override the convenience `t` rows. An empty data frame disables them.
#' @details Convenience rows use a full-pair mask. A custom mask catalog without
#'   a full-pair mask requires explicit rows, including an empty data frame to
#'   disable a guard. Exact decimal/fraction strings retain their rational value;
#'   numeric values retain their stored binary value. Joint guards default to
#'   `t = "0"`, with `alpha = "1/20"`; expected guards default to disabled.
#' @return A `postrank_mdomain_decision` recipe. Validation does not certify the
#'   scientific or sampling provenance of the input.
#' @concept multidomain
#' @export
postrank_mdomain_decision <- function(weights=NULL, tau="1/10", scope="all_pairs",
                                     q=NULL, t="0", alpha="1/20",
                                     expected=NULL, joint=NULL) {
  checked_weights <- if (is.null(weights)) NULL else
    .md_attempt({
      parsed <- p2_decision_numbers(weights, "weights")
      if (any(parsed$exact < 0) || sum(parsed$exact) <= 0)
        p2_input_error("weights must be nonnegative with a positive total")
      if (!is.null(names(weights))) p2_ids(names(weights), length(weights), "weight domain IDs")
      weights
    }, "mdomain_decision_invalid", "weights")
  checked_scope <- .md_attempt({
    if (identical(scope, "all_pairs")) {
      scope
    } else {
      if (!is.list(scope) || is.data.frame(scope))
        p2_input_error("scope must be 'all_pairs' or a named list of binary matrices")
      if (length(scope)) {
        p2_ids(names(scope), length(scope), "scope IDs")
        for (id in names(scope)) {
          a <- scope[[id]]
          if (!(is.numeric(a) || is.logical(a)) || is.complex(a) || !is.matrix(a) ||
              nrow(a) < 2L || nrow(a) != ncol(a) || any(!is.finite(a)) ||
              any(!a %in% c(0,1)) || any(diag(a) != 0) || !all(a == t(a)))
            p2_input_error(paste("Scope", id, "must be finite binary symmetric n x n with zero diagonal"))
        }
      }
      scope
    }
  }, "mdomain_decision_invalid", "scope")
  checked_tau <- .md_decision_exact(tau, "tau", lower=0, upper="1/2", strict_lower=TRUE)
  checked_q <- if (is.null(q)) NULL else .md_decision_exact(q, "q")
  checked_t <- if (is.null(t)) NULL else .md_decision_exact(t, "t")
  checked_alpha <- .md_decision_exact(alpha, "alpha", scalar=TRUE)
  checked_expected <- .md_decision_rows(expected, "q", "expected")
  checked_joint <- .md_decision_rows(joint, "t", "joint")
  structure(list(weights=checked_weights, tau=checked_tau, scope=checked_scope,
                 q=checked_q, t=checked_t, alpha=checked_alpha,
                 expected=checked_expected, joint=checked_joint,
                 receipts=list(schema_version="postrank-mdomain-decision-recipe-v1",
                   defaults=list(tau="1/10", q=NULL, t="0", alpha="1/20"),
                   parameter_semantics="exact rational text; numeric values mean their stored binary value",
                   weights_normalization="performed by core when bound to an input",
                   weights_supplied_exact=if (is.null(checked_weights)) NULL else {
                     z <- as.character(p2_decision_numbers(checked_weights, "weights")$exact)
                     names(z) <- names(checked_weights)
                     z
                   },
                   explicit_expected=!is.null(expected), explicit_joint=!is.null(joint))),
            class=c("postrank_mdomain_decision", "list"))
}

.md_decision_exact <- function(x, field, lower=0, upper=1,
                               strict_lower=FALSE, scalar=FALSE) {
  .md_attempt({
    parsed <- p2_decision_numbers(x, field)
    lo <- p2_decision_numbers(lower, field)$exact
    hi <- p2_decision_numbers(upper, field)$exact
    if ((scalar && length(parsed$exact) != 1L) ||
        any(if (strict_lower) parsed$exact <= lo else parsed$exact < lo) ||
        any(parsed$exact > hi))
      p2_input_error(paste(field, "must contain", if (scalar) "one value" else "values",
                           "in", if (strict_lower) "(0, 1/2]" else "[0, 1]"))
    if (!is.null(names(x))) p2_ids(names(x), length(x), paste(field, "domain IDs"))
    out <- as.character(parsed$exact)
    names(out) <- names(x)
    out
  }, "mdomain_decision_invalid", field)
}

.md_decision_rows <- function(rows, value_name, field) {
  if (is.null(rows)) return(NULL)
  .md_attempt({
    if (is.data.frame(rows) && nrow(rows) == 0L) {
      out <- data.frame(domain_id=character(), scope_id=character(), stringsAsFactors=FALSE)
      out[[value_name]] <- character()
      out
    } else {
      needed <- c("domain_id", "scope_id", value_name)
      if (!is.data.frame(rows) || anyDuplicated(names(rows)) || !setequal(names(rows), needed))
        p2_input_error(paste("Protection rows require exactly", paste(needed, collapse=", ")))
      for (id in c("domain_id", "scope_id"))
        if (!is.character(rows[[id]]) || !is.null(dim(rows[[id]])) || anyNA(rows[[id]]) ||
            any(!nzchar(trimws(rows[[id]]))))
          p2_input_error(paste(id, "must contain nonempty character IDs"))
      if (anyDuplicated(rows[c("domain_id", "scope_id")]))
        p2_input_error("Duplicate domain-scope protection row")
      out <- rows[needed]
      out[[value_name]] <- .md_decision_exact(rows[[value_name]], value_name)
      out
    }
  }, "mdomain_decision_invalid", field)
}

.md_bind_decision <- function(input, decision=NULL) {
  if (!inherits(input, "p2_profile_input"))
    .md_error("input must be a validated multidomain input", "mdomain_input_invalid", "input")
  if (is.null(decision)) decision <- postrank_mdomain_decision()
  if (!inherits(decision, "postrank_mdomain_decision"))
    .md_error("decision must be a postrank_mdomain_decision recipe",
              "mdomain_decision_invalid", "decision")
  # Rebuild rather than trust a mutable recipe's class or cached receipts.
  recipe <- .md_attempt({
    fields <- c("weights", "tau", "scope", "q", "t", "alpha", "expected", "joint")
    if (!all(fields %in% names(decision))) p2_input_error("decision recipe is missing required fields")
    do.call(postrank_mdomain_decision, decision[fields])
  }, "mdomain_decision_invalid", "decision")
  scopes <- if (identical(recipe$scope, "all_pairs")) NULL else recipe$scope
  .md_attempt({
    catalog <- p2_decision_scopes(scopes, input$n, input$unit_ids)
    full_ids <- names(catalog)[vapply(catalog, function(a)
      sum(a) == as.double(input$n) * (input$n-1L), logical(1))]
    full_id <- if ("full" %in% full_ids) "full" else if (length(full_ids)) full_ids[[1L]] else NULL
    convenience <- function(values, field) {
      if (is.null(values)) return(data.frame())
      if (is.null(full_id))
        p2_input_error(paste("Convenience", field, "rows require a full-pair mask; supply explicit protection rows"))
      values <- p2_decision_domain_vector(values, input$domain_ids, field, broadcast=TRUE)
      out <- data.frame(domain_id=input$domain_ids, scope_id=rep(full_id, input$D), stringsAsFactors=FALSE)
      out[[field]] <- unname(values)
      out
    }
    expected <- if (is.null(recipe$expected)) convenience(recipe$q, "q") else recipe$expected
    joint <- if (is.null(recipe$joint)) convenience(recipe$t, "t") else recipe$joint
    bound <- p2_validate_decision(input, weights=recipe$weights, tau=recipe$tau,
      scopes=scopes, expected=expected, joint=joint, alpha=recipe$alpha)
    bound$receipts$public_recipe <- recipe$receipts
    bound$receipts$public_recipe$bound_from_exact_fields <- TRUE
    bound
  }, "mdomain_decision_invalid", "decision")
}
