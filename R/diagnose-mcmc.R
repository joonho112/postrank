.pr_diagnostic_record <- function(raw_value=NA_real_,method,reason=NULL,warnings=character(),error=NULL,error_class=NULL,computed=TRUE) {
  valid_number <- typeof(raw_value)%in%c("integer","double")&&is.null(dim(raw_value))&&length(raw_value)==1L
  if(!valid_number) {
    raw_value <- NA_real_;error <- "Diagnostic function did not return one real number";computed <- TRUE
  }
  kind <- if(!computed) "not_computed" else if(!is.null(error)) "error" else if(is.nan(raw_value)) "NaN" else
    if(is.na(raw_value)) "NA" else if(identical(raw_value,Inf)) "Inf" else if(identical(raw_value,-Inf)) "-Inf" else "finite"
  available <- identical(kind,"finite")
  if(!available&&is.null(reason)) reason <- if(!is.null(error)) "diagnostic_error" else paste0("diagnostic_returned_",kind)
  list(value=if(available)as.numeric(raw_value) else NA_real_,raw_value=unname(raw_value),result_kind=kind,
    available=available,unavailable_reason=if(available)NULL else reason,warnings=warnings,error=error,
    error_class=error_class,method=method)
}

.pr_unavailable_diagnostics <- function(reason) {
  names <- c("rhat","ess_bulk","ess_tail","ess_mean","mcse_mean")
  stats::setNames(lapply(names,function(name).pr_diagnostic_record(method=name,reason=reason,computed=FALSE)),names)
}

.pr_posterior_diagnostic_functions <- function() {
  if(!requireNamespace("posterior",quietly=TRUE)) return(NULL)
  list(rhat=posterior::rhat,ess_bulk=posterior::ess_bulk,ess_tail=posterior::ess_tail,
    ess_mean=posterior::ess_mean,mcse_mean=posterior::mcse_mean)
}

.pr_mcmc_trace_metrics <- function(matrix,functions=.pr_posterior_diagnostic_functions()) {
  if(is.null(functions)) return(.pr_unavailable_diagnostics("posterior_package_unavailable"))
  stats::setNames(lapply(names(functions),function(name) {
    warnings <- character();error <- NULL;error_class <- NULL
    raw <- tryCatch(withCallingHandlers(functions[[name]](matrix),warning=function(w) {
      warnings <<- c(warnings,conditionMessage(w));invokeRestart("muffleWarning")
    }),error=function(e){error <<- conditionMessage(e);error_class <<- class(e);NA_real_})
    .pr_diagnostic_record(raw,method=paste0("posterior::",name),warnings=warnings,error=error,error_class=error_class)
  }),names(functions))
}

.pr_chain_trace_summary <- function(chain) {
  values <- chain$values
  list(chain_id=chain$chain_id,n=length(values),mean=mean(values),unique_value_count=length(unique(values)),
    constant=length(unique(values))==1L,transitions=sum(diff(values)!=0),original_iterations=chain$iterations)
}

.pr_mcmc_practical_flags <- function(diagnostics,chains) {
  thresholds <- list(rhat_max=1.01,ess_per_chain_min=100,ess_total_min=100*chains,
    interpretation="Exploration guidelines only; neither a convergence pass nor a finite-sample guarantee")
  check <- function(name,threshold,above=FALSE) {
    metric <- diagnostics[[name]]
    if(is.null(metric)||!isTRUE(metric$available)||!is.finite(metric$value)) return(NA)
    if(above)metric$value>threshold else metric$value<threshold
  }
  flags <- list(rhat_above_guideline=check("rhat",thresholds$rhat_max,TRUE),
    ess_mean_below_guideline=check("ess_mean",thresholds$ess_total_min),
    ess_bulk_below_guideline=check("ess_bulk",thresholds$ess_total_min))
  warnings <- character()
  if(isTRUE(flags$rhat_above_guideline)) warnings <- c(warnings,sprintf(
    "Exploration guideline: Rhat %.6g exceeds %.3g; investigate chain exploration. This is not a convergence verdict.",
    diagnostics$rhat$value,thresholds$rhat_max))
  for(name in c("ess_mean","ess_bulk")) if(isTRUE(flags[[paste0(name,"_below_guideline")]]))
    warnings <- c(warnings,sprintf(
      "Exploration guideline: %s %.6g is below %g (%g per chain across %d chains); this guideline does not certify convergence or MC precision.",
      name,diagnostics[[name]]$value,thresholds$ess_total_min,thresholds$ess_per_chain_min,chains))
  list(flags=flags,thresholds=thresholds,warnings=warnings)
}
