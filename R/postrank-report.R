.pr_html <- function(x) {
  x<-as.character(x);x<-gsub("&","&amp;",x,fixed=TRUE);x<-gsub("<","&lt;",x,fixed=TRUE)
  x<-gsub(">","&gt;",x,fixed=TRUE);gsub('"',"&quot;",x,fixed=TRUE)
}
.pr_report_value <- function(x) {
  if(is.null(x))return("not provided")
  if(is.numeric(x))return(paste(ifelse(is.na(x),"NA",format(x,digits=8,trim=TRUE)),collapse=", "))
  if(is.list(x))return(paste(utils::capture.output(utils::str(x,give.attr=FALSE,max.level=2)),collapse="\n"))
  paste(x,collapse=", ")
}
.pr_html_table <- function(x) {
  if(is.null(x)||!nrow(x))return('<p class="missing">NA: not provided.</p>')
  cells <- vapply(seq_len(nrow(x)), function(i) paste0("<tr>", paste(vapply(names(x), function(key) {
    value <- .pr_report_value(x[[key]][i])
    if (key %in% c("reason", "NA_reason")) {
      reason <- value
      value <- switch(reason,
        supplied_probabilities_have_no_target_draws = "Unavailable: target draws were not supplied",
        supplied_marginal_intervals_unavailable = "Unavailable: marginal intervals were not supplied",
        not_requested = "Not requested", no_validated_incumbent = "Unavailable without validated grades",
        unsupported_input_kind = "Unsupported for this input", gsub("_", " ", reason))
      return(paste0('<td data-reason="', .pr_html(reason), '">', .pr_html(value), "</td>"))
    }
    if (key == "extra") value <- switch(value, report_card = "Report card", fragility = "Monte Carlo fragility",
      crossfit = "Cross-fit check", diagnostics = "Diagnostics", value)
    paste0("<td>", .pr_html(value), "</td>")
  }, ""), collapse = ""), "</tr>"), "")
  labels <- c(entity_id="Entity", common_grade="Grade", grade="Grade", criterion_id="Criterion",
    estimand="Target", time_reference="Time", units="Units", orientation="Priority direction",
    source_transform="Target transformation", expected_errors="Expected direction errors",
    error_per_all_pairs="Errors per all pairs", error_per_disclosed_pair="Errors per disclosed pair",
    criterion_risk="Posterior loss", weight="Loss weight", field="Measure", value="Value",
    extra="Result", requested="Requested", supported="Supported", available="Available", reason="Reason",
    sort_rank="Display order", n_above="Above", n_below="Below", n_withheld="Withheld")
  headers <- names(x); known <- headers %in% names(labels); headers[known] <- unname(labels[headers[known]])
  for (prefix in c("mean_", "lower_", "upper_", "expected_rank_")) {
    label <- c(mean_="Mean", lower_="Interval lower", upper_="Interval upper", expected_rank_="Expected rank")[[prefix]]
    selected <- !known & startsWith(names(x), prefix)
    headers[selected] <- paste0(label, " (", substring(names(x)[selected], nchar(prefix) + 1L), ")")
  }
  paste0('<div class="table-wrap"><table><thead><tr>',paste0("<th scope=\"col\">",.pr_html(headers),"</th>",collapse=""),"</tr></thead><tbody>",paste(cells,collapse=""),"</tbody></table></div>")
}
.pr_diagnostic_table <- function(diagnostics) {
  if(is.null(diagnostics)||!length(diagnostics$summaries))return(NULL)
  do.call(rbind,lapply(diagnostics$summaries,function(s) {
    get<-function(name)if(is.null(s$diagnostics[[name]]))NA_real_ else s$diagnostics[[name]]$value
    reason<-unique(c(s$unavailable_reason,unlist(lapply(s$diagnostics,function(m)if(!isTRUE(m$available))m$unavailable_reason else NULL),use.names=FALSE)))
    data.frame(trace=s$trace_id,quantity=s$quantity,regime=s$regime,draws=s$S,mean=s$mean,
      chains=s$chain_count,chain_lengths=paste(paste(names(s$chain_lengths),s$chain_lengths,sep="="),collapse="; "),
      transitions=paste(vapply(s$per_chain,function(c)paste0(c$chain_id,"=",c$transitions),character(1)),collapse="; "),
      MCSE=get("mcse_mean"),Rhat=get("rhat"),ESS_mean=get("ess_mean"),ESS_bulk=get("ess_bulk"),ESS_tail=get("ess_tail"),
      constant=isTRUE(s$constant_pooled),NA_reason=paste(reason,collapse="; "),warnings=paste(s$warnings,collapse="; "),stringsAsFactors=FALSE)
  }))
}
.pr_stability_table <- function(stability) {
  if(is.null(stability)||!length(stability$attempts))return(NULL)
  do.call(rbind,lapply(stability$attempts,function(a) {
    data.frame(attempt=a$id,selection=a$selection_id,setting=a$grid_id,
      status=if(is.null(a$status))a$attempt_status else a$status$normalized,
      validated=isTRUE(a$incumbent_validated),seed=a$actual_seed,gap=a$risk_absolute_gap,
      direction_reversals=if(is.null(a$comparison))NA_integer_ else a$comparison$direction_reversals,
      public_to_withheld=if(is.null(a$comparison))NA_integer_ else a$comparison$public_to_withheld,
      withheld_to_public=if(is.null(a$comparison))NA_integer_ else a$comparison$withheld_to_public,
      input_identity=a$input_identity,problem_identity=if(is.null(a$problem_identity))NA_character_ else a$problem_identity,
      error=if(is.null(a$error))"" else a$error$message,stringsAsFactors=FALSE)
  }))
}
.pr_report_source_history <- function(diagnostics) {
  if(is.null(diagnostics))return(NULL)
  out<-list()
  for(t in diagnostics$traces) {
    key<-if(is.null(t$criterion_id))"joint_total" else t$criterion_id
    if(is.null(out[[key]]))out[[key]]<-list(sampling=t$sampling,draw_ids=t$draw_ids,
      trace_count=length(t$values),source_input_identity=diagnostics$input_identity)
  }
  out
}
# Typed coefficient diagnostics have their own schema, not the draw-diagnostic seal.
# Validate the prepared record and its fit association without recomputing risks or traces.
.pr_report_check_coefficient_diagnostics <- function(d, fit) {
  bad <- function(ok, message) .pr_assert(isTRUE(ok), message, "invalid_diagnostics")
  p <- fit$problem$pairwise
  bad(is.list(d), "coefficient diagnostics must be a list record")
  bad(inherits(p, "postrank_coefficients") &&
    identical(d$schema_version, "coefficient-diagnostics-0.1.0") &&
    identical(d$input_kind, p$input_kind), "coefficient diagnostic schema/input kind disagrees with fit")
  bad(identical(d$provenance, p$provenance) && identical(d$validation, p$validation),
    "coefficient diagnostic source record disagrees with fit")
  metrics <- c("rhat", "ess_bulk", "ess_tail", "ess_mean", "mcse_mean")
  bad(is.list(d$diagnostics) && setequal(names(d$diagnostics), metrics),
    "coefficient diagnostics require all five metric records")
  for (name in metrics) {
    m <- d$diagnostics[[name]]
    bad(is.list(m) && is.logical(m$available) && length(m$available) == 1L && !is.na(m$available) &&
      is.numeric(m$value) && length(m$value) == 1L && is.null(dim(m$value)) &&
      is.character(m$method) && length(m$method) == 1L && !is.na(m$method) && nzchar(m$method) &&
      is.numeric(m$raw_value) && length(m$raw_value) == 1L &&
      is.character(m$result_kind) && length(m$result_kind) == 1L && !is.na(m$result_kind) &&
      is.character(m$warnings) && !anyNA(m$warnings) &&
      (is.null(m$error) || (is.character(m$error) && length(m$error) == 1L && !is.na(m$error))),
      paste("invalid coefficient diagnostic metric", name))
    bad(if (m$available) is.finite(m$value) else is.na(m$value) &&
      is.character(m$unavailable_reason) && length(m$unavailable_reason) == 1L &&
      !is.na(m$unavailable_reason) && nzchar(m$unavailable_reason),
      paste("coefficient diagnostic metric value/availability disagrees", name))
  }
  if (any(vapply(d$diagnostics, function(m) m$available, TRUE)))
    bad(identical(p$input_kind, "shared_hyperstate_mixture") &&
      identical(p$source$source_regime, "hyperparameter_mcmc") && is.list(d$layout) &&
      isTRUE(d$layout$history_structure_checked) && is.null(d$layout$reason) && is.matrix(d$layout$rows),
      "available coefficient MC metrics require declared MCMC and checked history layout")
  bad(identical(d$conditional_risk_mcse_available, d$diagnostics$mcse_mean$available) &&
    identical(d$conditional_risk_mcse_unavailable_reason, d$diagnostics$mcse_mean$unavailable_reason),
    "coefficient MCSE availability records disagree")
  bad(identical(d$convergence_verified, FALSE) && identical(d$finite_sample_certificate, FALSE) &&
    identical(d$numerical_certification, FALSE) && is.list(d$target_loss_trace) &&
    identical(d$target_loss_trace$available, FALSE),
    "coefficient diagnostics cannot establish target-loss traces or certification")
  if (is.null(fit$evaluation)) bad(is.null(d$evaluation), "diagnostic evaluation requires a validated incumbent") else {
    bad(is.list(d$evaluation), "coefficient diagnostics require a prepared evaluation")
    for (name in c("G", "N", "M", "E", "weighted_risk"))
      bad(isTRUE(all.equal(d$evaluation[[name]], fit$evaluation[[name]], tolerance = 1e-12)),
        paste("coefficient diagnostic evaluation disagrees with fit:", name))
  }
  tr <- d$conditional_risk_trace
  if (!is.null(tr)) {
    bad(identical(p$input_kind, "shared_hyperstate_mixture") && is.list(tr) &&
      identical(tr$quantity, "RB_conditional_expected_weighted_risk") &&
      identical(tr$state_index, p$source$state_index) && identical(tr$weights, p$source$weights),
      "conditional-risk trace source/schema disagrees with fit")
    bad(is.numeric(tr$values) && length(tr$values) == length(tr$weights) && all(is.finite(tr$values)) &&
      is.numeric(tr$weighted_mean) && length(tr$weighted_mean) == 1L && is.finite(tr$weighted_mean) &&
      abs(sum(tr$weights * tr$values) - tr$weighted_mean) <= 1e-12 &&
      !is.null(d$evaluation) && abs(tr$weighted_mean - d$evaluation$weighted_risk) <= 1e-12,
      "conditional-risk trace summary disagrees with the prepared evaluation")
  } else bad(!identical(p$input_kind, "shared_hyperstate_mixture") || is.null(d$grade),
    "a mixture diagnostic with a grade requires its conditional-risk trace")
  invisible(TRUE)
}

.pr_report_coefficient_diagnostic_table <- function(d) {
  names <- c("mcse_mean", "rhat", "ess_mean", "ess_bulk", "ess_tail")
  do.call(rbind, lapply(names, function(name) {
    m <- d$diagnostics[[name]]
    data.frame(quantity = "RB conditional expected weighted risk", metric = name,
      value = m$value, available = m$available,
      NA_reason = if (is.null(m$unavailable_reason)) "" else m$unavailable_reason,
      method = m$method, raw_value = m$raw_value, result_kind = m$result_kind,
      warnings = paste(m$warnings, collapse = "; "), error = m$error %||% "", stringsAsFactors = FALSE)
  }))
}

# The English report: eleven sections 0-10 with stable HTML ids plus a footer (Chapter 13).
.pr_report_strings_version <- "postrank-report-en-4"
.pr_report_sections <- c(header="Posterior grade report",frame="Units and outcomes",declarations="About the posterior",
  grades="Grades and comparisons",decision="Posterior loss and computation",profiles="Error by criterion",protection="Error limits",
  posterior="Target uncertainty",mc="Simulation accuracy",stability="Stability of comparisons",provenance="Settings and technical details")
.pr_report_figure_reasons <- c(figures_disabled="figures = FALSE was requested",no_validated_incumbent="no validated incumbent",
  report_card_not_prepared="no prepared report card (pass the matching analysis that carries one)",
  device_unavailable="no working PNG device",figure_failed="the figure could not be drawn")
.pr_report_figure_html <- function(f) {
  if(is.null(f))return("")
  if(isTRUE(f$available))return(paste0('<figure id="',f$id,'"><img src="data:image/png;base64,',f$png_base64,'" alt="',
    .pr_html(f$alt),'"><figcaption>',.pr_html(f$caption),"</figcaption></figure>"))
  why<-if(f$reason%in%names(.pr_report_figure_reasons)).pr_report_figure_reasons[[f$reason]] else NULL
  paste0('<p class="missing">Figure ',.pr_html(f$id)," not embedded: ",.pr_html(if(is.null(why))f$reason else why),".</p>")
}
.pr_report_kv <- function(x) {
  if(!length(x))return('<p class="missing">NA: not provided.</p>')
  val<-vapply(x,function(v)if(is.list(v)||length(v)>1L)as.character(jsonlite::toJSON(v,auto_unbox=TRUE,null="null",na="null",digits=17)) else .pr_report_value(v),character(1))
  .pr_html_table(data.frame(field=names(x),value=unname(val),stringsAsFactors=FALSE))
}
.pr_write_report_html <- function(report,path) {
  .pr_string(path,"$.output_file")
  .pr_assert(grepl("[.]html?$",path,ignore.case=TRUE),"report output_file must have html extension","invalid_report_path")
  .pr_assert(dir.exists(dirname(path)),"report parent directory does not exist","invalid_report_path")
  .pr_assert(!file.exists(path),"report already exists; choose a new output_file","report_exists")
  S<-.pr_report_sections;title<-S[["header"]]
  section<-function(id,body)paste0('<section id="',id,'"><h2>',.pr_html(S[[id]]),"</h2>",body,"</section>")
  para<-function(x,class=NULL)paste0("<p",if(is.null(class))"" else paste0(' class="',class,'"'),">",.pr_html(x),"</p>")
  ev<-report$disclosure;ok<-isTRUE(report$incumbent_validated)
  coefficient_diagnostics <- inherits(report$diagnostics, "postrank_coefficient_diagnostics")
  fig<-stats::setNames(report$figures,vapply(report$figures,`[[`,character(1),"id"))
  context<-report$context
  dims <- report$dimensions
  K <- if (is.null(dims)) length(report$settings$weights) else dims$criteria
  n <- if (is.null(dims)) length(report$grade) else dims$entities
  lead <- sprintf("%s entities compared on %s %s using the supplied posterior information.",
    n, K, if (K == 1L) "criterion" else "criteria")
  target_table <- if (!length(report$targets)) NULL else if (is.character(report$targets))
    data.frame(Criterion = names(report$targets), Target = unname(report$targets), stringsAsFactors = FALSE) else
    do.call(rbind,lapply(report$targets,function(t)
      data.frame(criterion_id=t$criterion_id,estimand=t$estimand,time_reference=t$time_reference,units=t$units,orientation=t$orientation,
        source_transform=if(is.null(t$source_transform))"not declared" else .pr_report_value(t$source_transform),stringsAsFactors=FALSE)))
  card<-report$report_card
  grade<-if(!ok||is.null(report$grade))NULL else if(!is.null(card))card$data else data.frame(entity_id=names(report$grade),common_grade=unname(report$grade))
  obj<-report$objective
  metrics<-data.frame(field=c("Occupied grades","Disclosed comparisons","All entity pairs","Fraction disclosed","Posterior loss","Weighted loss","Risk upper bound","Risk lower bound","Absolute risk gap","Bound source","Loss function","Solver status"),
    value=c(if(is.null(ev))rep("NA",4) else vapply(list(ev$G,ev$N,ev$M,ev$disclosure_rate),.pr_report_value,character(1)),
      vapply(list(obj$primary_action_risk,obj$weighted_auxiliary_risk,obj$risk_upper_bound,obj$risk_lower_bound,obj$risk_absolute_gap),.pr_report_value,character(1)),
      .pr_report_value(obj$bound_source %||% "not recorded"),.pr_report_value(report$settings$objective),.pr_report_value(report$status$normalized)),stringsAsFactors=FALSE)
  warnings<-unique(c(report$warnings,if(!is.null(report$diagnostics))report$diagnostics$warnings,
    if(coefficient_diagnostics) unlist(lapply(report$diagnostics$diagnostics, function(m) m$warnings), use.names=FALSE)))
  warning_block<-if(length(warnings))paste0('<aside class="warning"><strong>Warnings (',length(warnings),')</strong><ul>',paste0("<li>",.pr_html(warnings),"</li>",collapse=""),"</ul></aside>") else ""
  settings_html<-report$settings;settings_html$weights<-as.list(settings_html$weights)
  if(!is.null(settings_html$q))settings_html$q<-as.list(settings_html$q)
  setting_text<-jsonlite::toJSON(settings_html,auto_unbox=TRUE,pretty=TRUE,na="null",null="null",digits=17)
  provenance<-list(input_identity=report$input_identity,problem_identity=report$problem_identity,
    solution_identity=report$solution_identity,context=report$context,targets=report$targets,provenance=report$provenance,
    source_validation=report$source_validation,backend=report$backend,solver_status=report$status,
    raw_residuals=report$residuals,diagnostics_identity=if(is.null(report$diagnostics))NULL else report$diagnostics$diagnostics_identity,
    diagnostic_source_history=if(coefficient_diagnostics) list(state_index=report$diagnostics$conditional_risk_trace$state_index,
      layout=report$diagnostics$layout) else .pr_report_source_history(report$diagnostics),package_version=report$package_version,
    objective=report$objective,extras=report$extras,timings=as.list(report$timings),capabilities=report$capabilities,strings_version=report$strings_version,numerical_certification=FALSE)
  profile<-report$criterion_profile
  if(!is.null(profile)){profile$weight<-unname(report$settings$weights[profile$criterion_id])
    if(!is.null(report$settings$q)){profile$q<-unname(report$settings$q[profile$criterion_id]);profile$slack<-profile$q*ev$N-profile$expected_errors}}
  extras<-report$extras
  extras_table<-if(!length(extras))NULL else data.frame(extra=names(extras),requested=vapply(extras,function(e)isTRUE(e$requested),TRUE),
    supported=vapply(extras,function(e)isTRUE(e$supported),TRUE),available=vapply(extras,function(e)isTRUE(e$available),TRUE),
    reason=vapply(extras,function(e)if(is.null(e$reason))"" else e$reason,character(1)),stringsAsFactors=FALSE)
  fr<-report$fragility_summary
  fragility_text<-if(is.null(fr))'<p class="missing">Fragility: not available for this input or not requested.</p>' else
    para(sprintf("Fragility (pairwise Monte Carlo screen): %d of %d pairs traced; %d fragile (%d disclosed, %d withheld). A fragile pair is within z Monte Carlo standard errors of tau; flags are descriptive and need not change the jointly chosen grade.",
      fr$traced,fr$pairs,fr$fragile,fr$fragile_disclosed,fr$fragile_tied))
  diagnostic_text <- if (identical(report$declarations$source, "postrank_probabilities"))
    "This input contains comparison probabilities and optional marginal summaries. Target-draw diagnostics are unavailable. The accuracy of the supplied probabilities is assessed in their source calculation; marginal posterior intervals describe target uncertainty." else if (coefficient_diagnostics) paste0(
    "Typed coefficient diagnostics: stored weighted action risk = ",
    .pr_report_value(report$diagnostics$evaluation$weighted_risk), ". ",
    paste(report$diagnostics$interpretation, collapse = " "),
    " Target-loss draws and target-loss MCSE are unavailable. These summaries are descriptive for the supplied grade; post-selection coverage and regret guarantees are not available. ESS is not an IID sample size. NA metrics retain their reasons; NA is not zero uncertainty.") else
    "Pointwise descriptive MCSE; post-selection coverage and regret guarantees are not available for a grade selected with the same draws. ESS is not an IID sample size. Stability is not proof of convergence."
  status_text <- switch(report$status$normalized,
    feasible_not_certified = "feasible grade; requested optimality not established",
    time_limit = "time limit reached", numerical_error = "numerical issue; inspect warnings",
    report$status$normalized)
  status_line <- paste0("Solver: ", report$backend$name, " (", report$strategy, "); status: ", status_text)
  body<-paste0('<header id="header"><p class="eyebrow">POSTRANK</p><h1>',S[["header"]],"</h1>",para(lead),para(status_line,"status"),
    if(is.null(report$minimax_refine))"" else para(paste("Minimax second stage:",report$minimax_refine$mode,if(is.null(report$minimax_refine$reason))"" else report$minimax_refine$reason),"status"),
    warning_block,para("Grade 1 has highest priority. A shared grade withholds the comparison; it does not assert equality of the targets. These grades compare the supplied targets within the declared population, posterior and loss.","interpretation"),
    if(!ok)'<aside class="warning">No validated incumbent: no grades or action risks are reported. The solver status and bounds are shown below.</aside>' else if(ev$N==0)'<aside class="warning">All comparisons withheld: no pair is disclosed. E/N is NA. All-tie is an admissible action with risk tau; it is not an error-free ranking.</aside>' else "",
    "</header>",
    section("frame",paste0(.pr_html_table(target_table),if(is.null(context))para("Target descriptions were not supplied; the source details are recorded below.") else paste0("<details><summary>Data and model context</summary>",.pr_report_kv(context),"</details>"))),
    section("declarations",paste0(para("The analysis uses the posterior source and target definitions supplied by the analyst. Their presence is not independent verification."),"<details><summary>Read the supplied source and assumptions</summary>",.pr_report_kv(report$declarations),"</details>")),
    section("grades",paste0(if(!ok)para("NA: no validated incumbent; no grade is reported.","missing") else
      if(is.null(card))para("Prepared report card unavailable; entity grades only.","missing") else
      para(sprintf("Report card: %s%% %s intervals as stored.",format(100*card$level),gsub("_"," ",card$interval_source))),
      .pr_html_table(grade),.pr_report_figure_html(fig[["fig-report-card"]]))),
    section("decision",paste0(.pr_html_table(metrics),if(ok)para("One validated incumbent is shown; the number of optima is unknown.") else "",
      if(ok&&ev$N==0)para("All-tie note: every comparison is withheld; the risk equals tau.") else "")),
    section("profiles",paste0(.pr_html_table(profile),para("E_k/N is the expected number of wrong-direction disclosed pairs per disclosed pair; it is NA when nothing is disclosed."),
      .pr_report_figure_html(fig[["fig-criterion-profile"]]))),
    section("protection",paste0(para(if(identical(report$protection$status,"not_requested")) "No per-criterion error limits were requested." else gsub("_"," ",report$protection$status)),.pr_html_table(report$protection$margins),
      if(identical(report$protection$status,"not_requested")) "" else para("The recorded limit checks use floating-point tolerances. Their numerical and posterior interpretation follows the supplied input and protection settings."))),
    section("posterior",paste0(para("Posterior uncertainty of each target as a central posterior interval. This differs from Monte Carlo standard error, and a posterior mean may lie outside its central interval. The profile does not copy the common grade into criterion-specific rankings."),
      if(!is.null(report$posterior_profiles)).pr_html_table(report$posterior_profiles) else if(!is.null(card))para(sprintf("Intervals for each entity are in the report-card table above (%s%% %s).",format(100*card$level),gsub("_"," ",card$interval_source))) else
      para("NA: no posterior profile prepared.","missing"))),
    section("mc",paste0(para(diagnostic_text),
      if(is.null(report$diagnostics))'<p class="missing">NA: diagnostics_not_provided</p>' else if(coefficient_diagnostics)
        para(paste0("Hyperstate trace: ", if(is.null(report$diagnostics$conditional_risk_trace))
          paste0("unavailable: ",report$diagnostics$unavailable_reason %||% "not_provided") else
          paste(length(report$diagnostics$conditional_risk_trace$values), "stored states; conditional expected risks, not target-loss draws"))) else
        para(paste0("Total loss: ",.pr_report_value(report$diagnostics$total_loss))),
      .pr_html_table(report$diagnostic_table),fragility_text,if(is.null(extras_table))"" else .pr_html_table(extras_table))),
    section("stability",paste0(if(coefficient_diagnostics)'<p class="missing">NA: stability_unsupported_for_coefficients; no extra solve</p>' else if(is.null(report$diagnostics)||is.null(report$diagnostics$stability))'<p class="missing">NA: stability_not_requested; no extra solve</p>' else paste0(para(report$diagnostics$stability$interpretation),.pr_html_table(.pr_stability_table(report$diagnostics$stability))),
      if(is.null(report$crossfit))'<p class="missing">Cross-fit: not requested or unavailable; no extra solve.</p>' else paste0(para("Cross-fit (prepared by the analysis; descriptive):"),
        "<pre>",.pr_html(paste(format_postrank_crossfit_cli(report$crossfit,width=100L,tier=3L),collapse="\n")),"</pre>"))),
    section("provenance",paste0(.pr_report_kv(report$settings[intersect(c("weights","tau","G_max","q","exact_G","objective"),names(report$settings))]),"<details><summary>Full source, computation and content records</summary><pre>",.pr_html(setting_text),"</pre><pre>",.pr_html(jsonlite::toJSON(provenance,auto_unbox=TRUE,pretty=TRUE,na="null",null="null",digits=17)),"</pre></details>")),
    if(ok) '<footer id="footer">One validated incumbent is shown; the number of optima is unknown. Relation stability across all optima is unknown without a separate exhaustive search. Numerical certification: false. Bounds are solver values; the gap is not regret.</footer>' else
      '<footer id="footer">No validated incumbent is available; no grade is reported. Numerical certification: false. Bounds are solver values.</footer>')
  css<-"html,header,details{min-width:0}body{font-family:system-ui,-apple-system,sans-serif;color:#182b3a;background:#f4f6f8;margin:0;line-height:1.6;min-width:0;overflow-wrap:anywhere}main{max-width:1100px;margin:0 auto;padding:48px 28px;min-width:0}header{border-top:5px solid #153653;padding:25px 0}h1{font-size:2rem;line-height:1.25;margin:8px 0}h2{font-size:1.3rem;margin-top:0}.eyebrow{font-size:.75rem;letter-spacing:.12em;color:#153653}.status{font-weight:650}section{background:white;border:1px solid #d9e1e7;border-radius:8px;padding:24px;margin:24px 0;min-width:0}.table-wrap{display:block;width:100%;max-width:100%;min-width:0;overflow-x:auto}table{border-collapse:collapse;width:100%;font-size:.88rem;overflow-wrap:normal}th,td{text-align:left;padding:10px 12px;border-bottom:1px solid #e2e7ec;vertical-align:top;white-space:nowrap}th{background:#edf3f5;color:#244354}td:last-child{white-space:normal;min-width:80px}.warning{border-left:4px solid #b36b17;background:#fff4df;padding:18px 22px;margin:20px 0;overflow-wrap:anywhere}.missing{color:#5d6670}.interpretation{max-width:85ch}figure{margin:0 0 24px}figure img{max-width:100%;height:auto}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f4f7;padding:18px;border-radius:5px;font-size:.78rem;max-width:100%;min-width:0;box-sizing:border-box}footer{font-size:.85rem;color:#50616f;margin:32px 0}@media(max-width:600px){main{padding:20px 12px}h1{font-size:1.55rem}section{padding:16px;margin:16px 0}th,td{padding:8px}}"
  html<-paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>',title,"</title><style>",css,"</style></head><body><main>",body,"</main></body></html>")
  temp<-tempfile("postrank-report-",tmpdir=dirname(path),fileext=".html");on.exit(unlink(temp),add=TRUE)
  writeLines(enc2utf8(html),temp,useBytes=TRUE)
  committed<-suppressWarnings(file.link(temp,path))
  if(!isTRUE(committed)) {
    .pr_assert(!file.exists(path),"report already exists; choose a new output_file","report_exists")
    committed<-file.copy(temp,path,overwrite=FALSE)
  }
  .pr_assert(isTRUE(committed),"could not commit HTML report","report_write_failed")
  normalizePath(path,mustWork=TRUE)
}

#' Create a Standalone Report from Stored Results
#'
#' The report combines stored grades, criterion losses, solver qualifications
#' and available posterior summaries or diagnostics. A self-contained English
#' HTML file can be written for offline use. Supplying `analysis` with its
#' `fit` includes the prepared report card and other stored components. Report
#' construction does not optimize or evaluate new grades, calculate pairwise
#' probabilities or prepare missing summaries.
#'
#' @param fit A `postrank_fit`, such as `analysis$fit`.
#' @param diagnostics Optional matching `postrank_diagnostics` or
#'   `postrank_coefficient_diagnostics`. Omit to use matching diagnostics
#'   already stored in `analysis`. Source, grade and settings are checked;
#'   diagnostics are not recomputed.
#' @param output_file Optional path for a new HTML file. An existing file is
#'   refused. `NULL` returns the report object without writing HTML.
#' @param lang Report language. Only `"en"` is supported; another language
#'   raises `unsupported_language`.
#' @param figures Logical; embed eligible report-card and criterion-profile
#'   figures as PNGs. `FALSE` records `figures_disabled`.
#' @param analysis Optional `postrank_analysis` with the same fit identities.
#'   Supplies its prepared report card, declarations, extras and timings.
#' @return A `postrank_report` list containing the stored grades, criterion
#'   profile, disclosure, objective, status, numerical validation information
#'   and source records, plus `figures`, `declarations`, `sections` and
#'   `strings_version`. `output_file` records the written path, or `NULL`.
#'   `diagnostics` retains the supplied object. Its `diagnostic_table` is
#'   trace-oriented for draws; for coefficient inputs it has columns
#'   `quantity`, `metric`, `value`, `available`, `NA_reason`, `method`,
#'   `raw_value`, `result_kind`, `warnings` and `error`. Unavailable metrics
#'   retain their reasons rather than becoming zero.
#' @details Grade 1 has highest priority; shared grades withhold directions.
#'   A valid all-withheld report has N=0 and undefined conditional error
#'   ratios, not an error-free ranking. With no validated grade, the report
#'   instead shows the solver status, available bounds and reasons for
#'   unavailable grade-dependent content. An optimization gap concerns the
#'   supplied numerical problem, separately from posterior or model uncertainty.
#'
#' Marginal posterior intervals retain their source and level and describe
#' target uncertainty rather than Monte Carlo error. Stored diagnostics retain
#' their producer's methods, warnings and unavailable values. Required inputs,
#' including `chain_history` for eligible [postrank_coefficient_diagnose()]
#' calculations, must be supplied when diagnostics are prepared; report
#' construction cannot recover missing draws or history. Numerical checks of an
#' empirical error budget alone do not establish a guarantee for the true
#' posterior.
#'
#'   The HTML has eleven sections: `header`, `frame`, `declarations`, `grades`,
#'   `decision`, `profiles`, `protection`, `posterior`, `mc`, `stability` and
#'   `provenance`, followed by a footer. Tables include all stored rows; wide
#'   tables scroll horizontally. Included figures use their default display
#'   limits, so a report-card figure may show a stated subset while the table
#'   remains complete. Use the plotting functions separately for custom
#'   entity selection or labels; this function has no paging argument.
#'
#'   Figures are embedded in the HTML, with no separate image or network
#'   dependency. Each attempt records `id`, `available`, `reason`,
#'   `png_base64`, `caption` and `alt` in `figures`. A missing PNG device or
#'   failed figure leaves an explanatory record and a usable report.
#' @seealso [postrank()], [postrank_plot_report_card()], [postrank_plot_profile()],
#'   `vignette("a6-reading-exporting-results", package = "postrank")`
#' @concept reporting
#' @examples
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs",
#'     control = postrank_control(time_limit = 10), fragility = FALSE)
#'   html <- tempfile(fileext = ".html")
#'   report <- postrank_report(one$fit, analysis = one, output_file = html)
#'   report
#'   vapply(report$figures, `[[`, logical(1), "available")
#'   unlink(html)
#' }
#' @export
postrank_report <- function(fit,diagnostics=NULL,output_file=NULL,lang="en",figures=TRUE,analysis=NULL) {
  .pr_assert(inherits(fit,"postrank_fit"),"expected postrank_fit","invalid_fit")
  .pr_assert(is.character(lang)&&length(lang)==1L&&!is.na(lang),"lang must be a single string","unsupported_language","$.lang")
  if(!identical(lang,"en")) .pr_abort(paste0("lang = \"",lang,"\" is not supported; official report output is English (\"en\")"),"unsupported_language","$.lang")
  if (missing(lang)) .pr_summary_lang()
  .pr_assert(is.logical(figures)&&length(figures)==1L&&!is.na(figures),"figures must be TRUE or FALSE","invalid_report","$.figures")
  if(!is.null(analysis)) .pr_assert(inherits(analysis,"postrank_analysis")&&identical(analysis$fit$problem_identity,fit$problem_identity)&&
    identical(analysis$fit$solution_identity,fit$solution_identity),"analysis must be the postrank_analysis whose fit is fit","invalid_report","$.analysis")
  if(is.null(diagnostics)&&!is.null(analysis)&&!is.null(analysis$diagnostics)) diagnostics<-analysis$diagnostics
  if(!is.null(diagnostics)) {
    .pr_assert(inherits(diagnostics,c("postrank_diagnostics","postrank_coefficient_diagnostics")),
      "expected postrank_diagnostics or postrank_coefficient_diagnostics","invalid_diagnostics")
    if (inherits(diagnostics,"postrank_coefficient_diagnostics")) .pr_report_check_coefficient_diagnostics(diagnostics,fit) else {
      content<-diagnostics;content$diagnostics_identity<-NULL
      .pr_assert(identical(.pr_identity(content),diagnostics$diagnostics_identity),"diagnostics changed after calculation","stale_diagnostics")
    }
    .pr_assert(identical(diagnostics$input_identity,fit$input_identity),"diagnostics and fit input identity disagree","diagnostic_input_mismatch")
    .pr_assert(is.null(diagnostics$problem_identity)||identical(diagnostics$problem_identity,fit$problem_identity),"diagnostics and fit problem identity disagree","diagnostic_problem_mismatch")
    .pr_assert(identical(diagnostics$grade,fit$grade)&&identical(diagnostics$settings,fit$settings),"diagnostics grade/settings disagree with fit","diagnostic_grade_mismatch")
  }
  ev<-fit$evaluation;p<-fit$problem$pairwise;q<-fit$settings$q
  profile<-if(is.null(ev))NULL else data.frame(criterion_id=names(ev$E),expected_errors=unname(ev$E),error_per_all_pairs=unname(ev$E_over_M),error_per_disclosed_pair=unname(ev$E_over_N),criterion_risk=unname(ev$criterion_risk))
  margins<-if(is.null(q)||is.null(ev))NULL else data.frame(criterion_id=names(q),q=unname(q),E=unname(ev$E[names(q)]),N=ev$N,margin=unname(ev$E[names(q)]-q*ev$N))
  protection<-list(status=if(is.null(q))"not_requested" else if(is.null(ev))"not_established_no_validated_incumbent" else
    if(p$input_kind=="exact_finite_posterior")"finite_law_double_projection_tolerance_checked; no_general_numerical_certificate" else
      "empirical_feasibility_tolerance_checked; true_posterior_budget_not_established",margins=margins)
  envelope<-fit$problem$protection_envelope
  if(!is.null(envelope)) {
    thresholds<-.pr_problem_q_thresholds(fit$problem)
    protection$envelope<-envelope
    protection$status<-paste0("diagnostic_",envelope$mode,"_envelope_only; original_public_q_feasibility_and_true_posterior_safety_not_claimed")
    if(!is.null(margins)) {
      margins$envelope_threshold<-unname(thresholds[names(q)])
      margins$envelope_margin<-unname(ev$E[names(q)]-thresholds*ev$N)
      protection$margins<-margins
    }
  }
  out<-list(schema_version="0.1.0",lang="en",dimensions=list(entities=length(p$entity_ids),criteria=length(p$criterion_ids)),grade=fit$grade,criterion_profile=profile,
    disclosure=if(is.null(ev))NULL else list(G=ev$G,N=ev$N,M=ev$M,disclosure_rate=ev$disclosure_rate,abstention_rate=ev$abstention_rate),
    objective=fit$objective,status=fit$status,has_incumbent=fit$has_incumbent,incumbent_validated=fit$incumbent_validated,
    solution_identity=fit$solution_identity,settings=fit$settings,backend=fit$backend,warnings=fit$warnings,
    strategy=if(is.null(fit$engine$strategy))NA_character_ else fit$engine$strategy,minimax_refine=fit$minimax_refine,
    input_identity=fit$input_identity,problem_identity=fit$problem_identity,context=p$context,targets=p$targets,provenance=p$provenance,
    source_validation=p$validation,residuals=fit$solution_validation[c("raw_residuals","rounded_residuals","integrality_residual","tolerances")],
    protection=protection,posterior_profiles=if(is.null(diagnostics))NULL else diagnostics$posterior_profiles,
    diagnostics=diagnostics,diagnostic_table=if(inherits(diagnostics,"postrank_coefficient_diagnostics"))
      .pr_report_coefficient_diagnostic_table(diagnostics) else .pr_diagnostic_table(diagnostics),output_file=NULL,
    figures=.pr_report_figures(fit,analysis,figures),declarations=.pr_report_declarations(fit,analysis),
    report_card=if(is.null(analysis))NULL else analysis$report_card,extras=if(is.null(analysis))NULL else analysis$extras,
    crossfit=if(is.null(analysis))NULL else analysis$crossfit,
    fragility_summary=if(is.null(analysis)||is.null(analysis$fragility))NULL else analysis$fragility$summary,
    timings=if(is.null(analysis))NULL else analysis$timings,capabilities=if(is.null(analysis))NULL else analysis$metadata$capabilities,
    package_version=as.character(utils::packageVersion("postrank")),sections=names(.pr_report_sections),strings_version=.pr_report_strings_version,
    interpretation=c("Equal grades abstain; they do not establish latent equality.","Criterion error ratios are posterior expectations, not simultaneous guarantees.","Optimization gap is distinct from Monte Carlo and model uncertainty."))
  class(out)<-c("postrank_report","list")
  if(!is.null(output_file))out$output_file<-.pr_write_report_html(out,output_file)
  out
}
# Eligible shipped figures: the report card (only from a prepared analysis card) and the
# criterion profile (validated incumbent). The writer reads prepared objects only.
.pr_report_figures <- function(fit,analysis,figures) {
  rec<-function(id,reason)list(id=id,available=FALSE,reason=reason,png_base64=NULL,caption=NULL,alt=NULL)
  ids<-c("fig-report-card","fig-criterion-profile")
  if(!isTRUE(figures))return(lapply(ids,rec,reason="figures_disabled"))
  if(!isTRUE(fit$incumbent_validated))return(lapply(ids,rec,reason="no_validated_incumbent"))
  card<-if(is.null(analysis))NULL else analysis$report_card
  list(if(is.null(card))rec(ids[1],"report_card_not_prepared") else .pr_report_figure(function()postrank_plot_report_card(card),ids[1],7,8),
    .pr_report_figure(function()postrank_plot_profile(fit),ids[2],6.5,3.5))
}
.pr_report_figure <- function(make,id,width,height,dpi=144) {
  fail<-function(reason,detail=NULL)list(id=id,available=FALSE,reason=reason,png_base64=NULL,caption=NULL,alt=NULL,detail=detail)
  if(!isTRUE(capabilities("png")))return(fail("device_unavailable"))
  p<-tryCatch(make(),error=identity)
  if(inherits(p,"error"))return(fail("figure_failed",conditionMessage(p)))
  tmp<-tempfile(fileext=".png");on.exit(unlink(tmp),add=TRUE)
  err<-tryCatch({ggplot2::ggsave(tmp,p,width=width,height=height,dpi=dpi,device="png",bg="white");NULL},error=identity)
  if(inherits(err,"error")||!file.exists(tmp))return(fail("device_unavailable",if(inherits(err,"error"))conditionMessage(err) else NULL))
  flat<-function(x)if(is.null(x))NULL else gsub("\\s*\n\\s*"," ",x)
  labs<-lapply(p$labels[c("title","caption")],flat)
  list(id=id,available=TRUE,reason=NA_character_,png_base64=jsonlite::base64_enc(readBin(tmp,"raw",file.size(tmp))),
    caption=paste(c(labs$title,labs$caption),collapse=". "),alt=labs$title %||% id)
}
# Declarations as recorded: the analysis metadata when supplied, else the fit's source
# fields; typed coefficient sources keep their provenance and label the rest unavailable.
.pr_report_declarations <- function(fit,analysis) {
  if(!is.null(analysis)&&!is.null(analysis$metadata$declarations))return(analysis$metadata$declarations)
  p<-fit$problem$pairwise
  if(inherits(p,c("postrank_coefficients","postrank_probabilities")))return(.pr_declaration_summary(p))
  if(is.null(p$context))return(list(status="undeclared",source=p$input_kind %||% "unknown",provenance=p$provenance,
    note="No source declarations are recorded for this input; its provenance is shown as recorded."))
  list(status="declared",source=p$input_kind %||% "unknown",targets=p$targets,context=p$context,provenance=p$provenance,
    note="Declarations are recorded as supplied; they are not scientifically verified.")
}
