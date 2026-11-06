# A complete independently constructed finite law for public-route tests.
# No external data or posterior archive is used.
md_test_array <- function() {
  values <- array(0,c(4L,3L,2L),
    dimnames=list(state=c("s1","s2","s3","s4"),unit=c("A","B","C"),domain=c("need","cost")))
  values[,,1L] <- rbind(c(3,2,1),c(2,3,1),c(3,1,2),c(1,2,3))
  values[,,2L] <- rbind(c(1,2,3),c(3,1,2),c(2,3,1),c(3,2,1))
  values
}

md_test_targets <- function() setNames(lapply(c("need","cost"),function(d)
  list(definition=paste("Specified fictional",d,"coordinate"),units="illustrative units",
    orientation="larger_is_higher",transformations=list(),equality_classes=c(A="A",B="B",C="C"),
    equality_provenance="The specified finite law has no model identities between distinct units.")),
  c("need","cost"))

md_test_provenance <- function() list(input_id="four-state-fictional-law",
  law_id="specified-four-state-law",proper_law=TRUE,producer="Independent package test generator",
  joint_generation="The four rows explicitly enumerate complete states of all six fictional coordinates.",
  within_domain_joint="Each matrix row specifies all three fictional coordinates for its domain.",
  sampling_assumptions=list(finite_support_origin="The four listed states with masses 1/4 each define the complete law."))

md_test_input <- function() postrank_mdomain_input(md_test_array(),targets=md_test_targets(),
  provenance=md_test_provenance(),representation="exact_finite_law",masses=rep("1/4",4L))

md_test_summary_spec <- function(encoding="strict_plus_equality") {
  x <- md_test_input()$original_spec
  x$layout <- "pairwise_summary"; x$representation <- "pairwise_probability_summary"
  x$coupling_status <- "unknown_cross_domain"; x$payloads <- list()
  pairs <- utils::combn(x$unit_ids,2L)
  tab <- do.call(rbind,lapply(x$domain_ids,function(d)
    data.frame(unit_i=pairs[1L,],unit_j=pairs[2L,],domain_id=d,
      p_i_gt_j=rep(0.5,ncol(pairs)),p_equal=rep(0,ncol(pairs)),stringsAsFactors=FALSE)))
  if(encoding=="two_strict") {tab$p_j_gt_i <- 1-tab$p_i_gt_j;tab$p_equal <- NULL}
  x$pair_summary <- list(encoding=encoding,identity_compatibility="asserted_exact",data=tab)
  x$provenance$pair_summary_hash <- p2_hash(tab)
  x
}
