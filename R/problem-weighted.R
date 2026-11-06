.pr_weighted_model <- function(pairwise,settings) {
  base<-.pr_encoding_model(pairwise$entity_ids,settings$G_max)
  costs<-rep(-settings$tau,length(base$index$pairs))
  for(k in seq_along(pairwise$criterion_ids))costs<-costs+settings$weights[k]*pairwise$e[,,k][cbind(base$index$pair_i,base$index$pair_j)]
  base$model$objective[base$index$pairs]<-costs
  base
}
