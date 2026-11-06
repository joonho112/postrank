# Validate an identified reporting matrix in the original input order. Numeric
# labels are deliberately canonicalized within domain, preserving ties and order.
.md_action <- function(input, grades) {
  if (!inherits(input, "p2_profile_input"))
    .md_error("input must be a validated multidomain input", "mdomain_input_invalid", "input")
  if (!is.matrix(grades))
    .md_error("grades must be a named numeric unit-by-domain matrix",
              "mdomain_action_invalid", "grades")
  if (is.null(rownames(grades)) || !identical(rownames(grades), input$unit_ids))
    .md_error("grade row names must match the input unit IDs exactly in declared order",
              "mdomain_action_identity", "grades", requested=rownames(grades), available=input$unit_ids)
  if (is.null(colnames(grades)) || !identical(colnames(grades), input$domain_ids))
    .md_error("grade column names must match the input domain IDs exactly in declared order",
              "mdomain_action_identity", "grades", requested=colnames(grades), available=input$domain_ids)
  .md_attempt({
    action <- p2_validate_action(grades, input$unit_ids, input$domain_ids,
                                 equality_classes=input$equality_classes,
                                 canonicalize=TRUE)
    action$receipt$original_grades <- grades
    action$receipt$input_id <- input$input_id
    action$receipt$public_identity_policy <- "both dimensions named in original input order; no reordering"
    action
  }, "mdomain_action_invalid", "grades")
}
