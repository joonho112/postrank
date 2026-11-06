.pr_pair_index <- function(n) {
  i<-rep(seq_len(n),each=n-1L)
  j<-unlist(lapply(seq_len(n),function(a)setdiff(seq_len(n),a)),use.names=FALSE)
  list(i=i,j=j)
}
.pr_encoding_model <- function(entity_ids,G_max) {
  n<-length(entity_ids);pairs<-.pr_pair_index(n);P<-length(pairs$i);columns<-n+seq_len(P)
  one<-seq_len(P);rows<-rep(c(one,one+P),each=3L)
  cols<-c(as.vector(rbind(pairs$j,pairs$i,columns)),as.vector(rbind(pairs$j,pairs$i,columns)))
  coefficients<-rep(c(1,-1,-G_max),2L*P)
  A<-Matrix::sparseMatrix(i=rows,j=cols,x=coefficients,dims=c(2L*P,n+P))
  A<-methods::as(A,"generalMatrix");A<-methods::as(A,"CsparseMatrix")
  list(model=list(A=A,objective=rep(0,n+P),var_lower=c(rep(1,n),rep(0,P)),var_upper=c(rep(G_max,n),rep(1,P)),
    row_lower=c(rep(-Inf,P),rep(1-G_max,P)),row_upper=c(rep(0,P),rep(Inf,P)),types=c(rep("I",n),rep("B",P)),
    var_names=c(paste0("label_",seq_len(n)),paste0("pair_",seq_len(P))),
    row_names=c(paste0("encoding_upper_",seq_len(P)),paste0("encoding_lower_",seq_len(P))),sense="min"),
    index=list(labels=seq_len(n),pairs=columns,pair_i=pairs$i,pair_j=pairs$j,t=NULL,assignment=NULL),
    pair_map=data.frame(i=pairs$i,j=pairs$j,entity_i=entity_ids[pairs$i],entity_j=entity_ids[pairs$j],column=columns,stringsAsFactors=FALSE))
}
