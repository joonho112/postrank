# Capability checks describe information available, not scientific verification.
.md_require_capability <- function(input, mode="expected", domains=NULL) {
  if (is.null(domains)) domains <- input$domain_ids
  .md_input_check(is.character(domains) && !anyNA(domains) && !anyDuplicated(domains) &&
    all(domains %in% input$domain_ids),"Requested domains must be unique declared domain IDs.",
    "domains","mdomain_input_ids")
  .md_attempt(p2_require_capability(input,mode,domains),"mdomain_capability","capabilities")
  invisible(input)
}
