# Internal conditions shared by the multidomain interface.
.md_error <- function(message, code="mdomain_invalid", field=NULL,
                      requested=NULL, available=NULL) {
  condition <- structure(list(message=message, call=NULL, code=code, field=field,
                              requested=requested, available=available),
                         class=c("postrank_mdomain_error","error","condition"))
  stop(condition)
}
.md_require_gmp <- function() {
  if (!requireNamespace("gmp", quietly=TRUE))
    .md_error("Install the suggested package 'gmp' to use multidomain calculations.",
              "mdomain_dependency", "gmp")
  invisible(TRUE)
}
.md_attempt <- function(expr, code="mdomain_invalid", field=NULL) {
  .md_require_gmp()
  tryCatch(force(expr), error=function(e) {
    if (inherits(e,"postrank_mdomain_error")) stop(e)
    .md_error(conditionMessage(e), code, field)
  })
}
