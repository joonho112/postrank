# Read fixed literals only; no calculations from production posterior functions.
read_fixed_gaussian_fixture <- function(fixture_id, root) {
  catalog<-jsonlite::read_json(file.path(root,'tests/fixtures/gaussian-fixed.json'),simplifyVector=FALSE)
  ids<-vapply(catalog$fixtures,function(x)x$fixture_id,character(1))
  pos<-match(fixture_id,ids);if(is.na(pos))stop('unknown fixed fixture')
  f<-catalog$fixtures[[pos]];entities<-unlist(f$entity_ids);criteria<-unlist(f$criterion_ids)
  row_matrix<-function(rows) do.call(rbind,lapply(rows,function(x)as.numeric(unlist(x))))
  V<-array(0,c(length(criteria),length(criteria),length(entities)),dimnames=list(criteria,criteria,entities))
  for(i in seq_along(entities))V[,,i]<-row_matrix(f$V_by_entity[[i]])
  Y<-row_matrix(f$Y_rows);dimnames(Y)<-list(entities,criteria)
  Sigma<-row_matrix(f$Sigma_rows);dimnames(Sigma)<-list(criteria,criteria)
  list(Y=Y,V=V,mu=stats::setNames(as.numeric(unlist(f$mu)),criteria),Sigma=Sigma,literal=f,catalog=catalog)
}
