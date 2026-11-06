.pr_solution_identity <- function(grade,entity_ids) {
  canonical <- canonical_postrank_grade(grade,entity_ids)
  sorted <- sort(entity_ids,method="radix")
  ordered <- canonical[sorted]
  relation <- sign(outer(unname(ordered),unname(ordered),`-`))
  list(relation_identity=.pr_identity(list(entity_ids=sorted,relation=relation)),
    canonical_grade=canonical,representative_policy="one_validated_incumbent",
    deterministic_representative=FALSE,primary_objective_perturbed=FALSE,
    interpretation="Different optimal relations can have equal primary risk; backend/seed repeatability is not uniqueness.")
}
