# Minimize max_k E[L_k] through one risk-scale epigraph variable. This uses
# criterion marginals, never the draw-level maximum or weighted primary risk.
.pr_add_minimax <- function(base,pairwise,settings) {
  .pr_assert(is.null(base$index$t),"minimax epigraph already present","invalid_problem")
  selected <- settings$minimax_criteria
  if(is.null(selected)) selected <- pairwise$criterion_ids
  criteria <- match(selected,pairwise$criterion_ids)
  .pr_assert(length(criteria)>0L&&!anyNA(criteria),"minimax requires known nonempty criteria","invalid_problem")
  P <- length(base$index$pairs); R <- length(criteria); old_columns <- ncol(base$model$A)
  t_column <- old_columns+1L; M <- choose(length(pairwise$entity_ids),2)
  empty <- Matrix::sparseMatrix(i=integer(),j=integer(),x=numeric(),dims=c(nrow(base$model$A),1L))
  existing <- cbind(base$model$A,empty)
  coefficients <- unlist(lapply(criteria,function(k)
    pairwise$e[,,k][cbind(base$index$pair_i,base$index$pair_j)]-settings$tau),use.names=FALSE)
  rows <- Matrix::sparseMatrix(i=c(rep(seq_len(R),each=P),seq_len(R)),
    j=c(rep(base$index$pairs,times=R),rep(t_column,R)),x=c(coefficients,rep(-M,R)),
    dims=c(R,t_column))
  base$model$A <- rbind(existing,Matrix::drop0(rows))
  base$model$objective <- c(rep(0,old_columns),1)
  base$model$var_lower <- c(base$model$var_lower,0)
  base$model$var_upper <- c(base$model$var_upper,1)
  base$model$types <- c(base$model$types,"C")
  base$model$var_names <- c(base$model$var_names,"minimax_t")
  base$model$row_lower <- c(base$model$row_lower,rep(-Inf,R))
  base$model$row_upper <- c(base$model$row_upper,rep(-M*settings$tau,R))
  base$model$row_names <- c(base$model$row_names,paste0("minimax_",criteria))
  base$index$t <- t_column
  base
}
