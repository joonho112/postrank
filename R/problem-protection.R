# Append criterion-specific posterior expected-error restrictions. Public q
# validation belongs to postrank_problem(); row coefficients never use weights.
.pr_add_protection <- function(base,pairwise,settings) {
  q <- settings$q
  if(is.null(q)||!length(q)) return(base)
  criteria <- match(names(q),pairwise$criterion_ids)
  .pr_assert(!anyNA(criteria),"protection criterion absent from pairwise coefficients","invalid_problem")
  P <- length(base$index$pairs); R <- length(q); columns <- ncol(base$model$A)
  coefficients <- unlist(lapply(seq_len(R),function(r)
    pairwise$e[,,criteria[r]][cbind(base$index$pair_i,base$index$pair_j)]-q[r]),use.names=FALSE)
  rows <- Matrix::sparseMatrix(i=rep(seq_len(R),each=P),j=rep(base$index$pairs,times=R),
    x=coefficients,dims=c(R,columns))
  base$model$A <- rbind(base$model$A,Matrix::drop0(rows))
  base$model$row_lower <- c(base$model$row_lower,rep(-Inf,R))
  base$model$row_upper <- c(base$model$row_upper,rep(0,R))
  base$model$row_names <- c(base$model$row_names,paste0("protection_",criteria))
  base
}
