# Public q remains in [0,1]. Only internally constructed envelope problems carry
# a separate signed threshold, with the defining q +/- epsilon identity checked.
.pr_problem_q_thresholds <- function(problem) {
  q<-problem$settings$q;envelope<-problem$protection_envelope
  if(is.null(envelope))return(q)
  .pr_fields(envelope,c("mode","public_q","epsilon","thresholds","coefficient_bound_identity"),path="$.protection_envelope")
  .pr_assert(is.character(envelope$mode)&&length(envelope$mode)==1L&&envelope$mode%in%c("inner","outer"),"unknown protection envelope mode","invalid_envelope")
  .pr_assert(!is.null(q)&&identical(envelope$public_q,q),"envelope public_q must preserve the original public budget","invalid_envelope")
  e<-envelope$epsilon;t<-envelope$thresholds
  for(v in list(e,t)) .pr_assert(typeof(v)%in%c("integer","double")&&is.null(dim(v))&&
    length(v)==length(q)&&identical(names(v),names(q))&&all(is.finite(v)),"invalid named envelope thresholds","invalid_envelope")
  .pr_assert(all(e>=0&e<=1),"envelope epsilon reference must be in [0,1]","invalid_envelope")
  expected<-if(envelope$mode=="inner")q-e else q+e
  .pr_assert(identical(as.numeric(t),as.numeric(expected)),"envelope thresholds must equal original q plus/minus epsilon without clipping","invalid_envelope")
  .pr_string(envelope$coefficient_bound_identity)
  t
}
