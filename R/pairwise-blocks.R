# Aggregate directed pairs in blocks while retaining each complete draw row.
# Working comparison storage is O(S * min(block_size, n*(n-1))) plus the n^2
# result; no draw-by-all-pairs-by-criterion indicator tensor is constructed.
.pr_pairwise_blocks_one <- function(values, block_size) {
  .pr_assert(is.numeric(block_size) && length(block_size)==1L &&
               is.null(dim(block_size)), "block_size must be one positive integer", "invalid_block_size")
  .pr_safe_integer(block_size, positive=TRUE, path="$.block_size")
  n <- ncol(values)
  e <- matrix(NA_real_,n,n,dimnames=list(entity_i=colnames(values),entity_j=colnames(values)))
  total <- as.double(n)*(n-1L)
  first <- 1
  while(first <= total) {
    last <- min(total, first+block_size-1)
    pair <- seq.int(first,last)-1
    # Row-major ordered pairs with the diagonal skipped, without allocating an
    # S-by-pair object outside the current block or a complete pair index grid.
    i <- pair %/% (n-1L)+1
    j <- pair %% (n-1L)+1
    j <- j+(j>=i)
    e[cbind(i,j)] <- colMeans(values[,i,drop=FALSE] <= values[,j,drop=FALSE])
    first <- last+1
  }
  e
}
