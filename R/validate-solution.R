.pr_solution_tolerances <- function(tolerances) {
  .pr_assert(is.list(tolerances)&&!is.data.frame(tolerances)&&
    (!length(tolerances)||(!is.null(names(tolerances))&&!anyNA(names(tolerances))&&!anyDuplicated(names(tolerances)))),
    "tolerances must be a uniquely named list","invalid_tolerances")
  defaults <- list(feasibility=1e-7,integrality=1e-6,objective=1e-7)
  .pr_assert(all(names(tolerances)%in%names(defaults)),"unknown solution tolerance","invalid_tolerances")
  out <- utils::modifyList(defaults,tolerances,keep.null=TRUE)
  for(name in names(defaults)) .pr_assert(typeof(out[[name]])%in%c("integer","double")&&
    is.null(dim(out[[name]]))&&length(out[[name]])==1L&&is.finite(out[[name]])&&out[[name]]>=0,
    paste(name,"tolerance must be a nonnegative finite scalar"),"invalid_tolerances")
  out
}

.pr_solution_model_dimensions <- function(problem) {
  model <- problem$model; p <- length(model$objective); rows <- nrow(model$A)
  .pr_assert(inherits(model$A,"Matrix")||is.matrix(model$A),"problem requires a matrix A","invalid_problem")
  .pr_assert(ncol(model$A)==p&&length(model$var_lower)==p&&length(model$var_upper)==p&&
    length(model$types)==p&&length(model$row_lower)==rows&&length(model$row_upper)==rows,
    "model matrix/vector dimensions disagree","invalid_problem")
  .pr_assert(typeof(model$objective)%in%c("integer","double")&&is.null(dim(model$objective))&&all(is.finite(model$objective))&&
    is.character(model$types)&&is.null(dim(model$types))&&all(model$types%in%c("I","B","C"))&&identical(model$sense,"min"),
    "invalid objective, minimization sense or variable types","invalid_problem")
  coefficients <- if(inherits(model$A,"Matrix")&&"x"%in%methods::slotNames(model$A)) methods::slot(model$A,"x") else if(is.matrix(model$A)) model$A else numeric()
  .pr_assert(typeof(coefficients)%in%c("integer","double","logical")&&all(is.finite(coefficients)),
    "model A contains nonfinite or unsupported coefficients","invalid_problem")
  for(pair in list(c("var_lower","var_upper"),c("row_lower","row_upper"))) {
    lower <- model[[pair[1]]]; upper <- model[[pair[2]]]
    .pr_assert(typeof(lower)%in%c("integer","double")&&typeof(upper)%in%c("integer","double")&&
      is.null(dim(lower))&&is.null(dim(upper))&&!anyNA(lower)&&!anyNA(upper)&&all(lower<=upper),"invalid model bounds","invalid_problem")
  }
  indices <- c(problem$index$labels,problem$index$pairs,problem$index$t,as.vector(problem$index$assignment))
  .pr_assert(typeof(indices)%in%c("integer","double")&&all(is.finite(indices))&&all(indices==floor(indices))&&
    all(indices>=1&indices<=p)&&!anyDuplicated(indices),"invalid model variable indices","invalid_problem")
  n <- length(problem$pairwise$entity_ids)
  settings <- problem$settings
  .pr_loss_settings(problem$pairwise,settings$weights,settings$tau)
  .pr_assert(typeof(settings$G_max)%in%c("integer","double")&&is.null(dim(settings$G_max))&&
    length(settings$G_max)==1L&&is.finite(settings$G_max)&&settings$G_max==floor(settings$G_max)&&
    settings$G_max>=1&&settings$G_max<=n,"invalid problem G_max","invalid_problem")
  .pr_assert(is.character(settings$objective)&&length(settings$objective)==1L&&
    settings$objective%in%c("weighted","minimax"),"unsupported problem objective","invalid_problem")
  if(!is.null(settings$exact_G)) .pr_assert(typeof(settings$exact_G)%in%c("integer","double")&&
    is.null(dim(settings$exact_G))&&length(settings$exact_G)==1L&&is.finite(settings$exact_G)&&
    settings$exact_G==floor(settings$exact_G)&&settings$exact_G>=1&&settings$exact_G<=settings$G_max,
    "invalid problem exact_G","invalid_problem")
  if(!is.null(settings$q)) .pr_assert(typeof(settings$q)%in%c("integer","double")&&
    is.null(dim(settings$q))&&length(settings$q)>0L&&all(is.finite(settings$q))&&
    all(settings$q>=0&settings$q<=1)&&!is.null(names(settings$q))&&!anyNA(names(settings$q))&&
    !anyDuplicated(names(settings$q))&&all(names(settings$q)%in%problem$pairwise$criterion_ids),
    "invalid problem protection settings","invalid_problem")
  .pr_problem_q_thresholds(problem)
  if(identical(settings$objective,"minimax")) {
    .pr_assert(length(problem$index$t)==1L,"minimax problem lacks a scalar epigraph variable","invalid_problem")
    selected <- settings$minimax_criteria
    .pr_assert(is.null(selected)||(is.character(selected)&&is.null(dim(selected))&&length(selected)>0L&&
      !anyNA(selected)&&!anyDuplicated(selected)&&all(selected%in%problem$pairwise$criterion_ids)),
      "invalid minimax criterion set","invalid_problem")
  }
  if(!is.null(settings$exact_G)) {
    .pr_assert(is.matrix(problem$index$assignment)&&identical(dim(problem$index$assignment),c(n,as.integer(settings$exact_G))),
      "exact-G assignment index must be n by exact_G","invalid_problem")
    .pr_assert(all(model$types[problem$index$assignment]=="B"),"exact-G assignments must be binary","invalid_problem")
  }
  .pr_assert(length(problem$index$labels)==n&&length(problem$index$pairs)==n*(n-1)&&
    length(problem$index$pair_i)==length(problem$index$pairs)&&length(problem$index$pair_j)==length(problem$index$pairs),
    "invalid label/pair map dimensions","invalid_problem")
  i <- problem$index$pair_i; j <- problem$index$pair_j
  .pr_assert(typeof(i)%in%c("integer","double")&&typeof(j)%in%c("integer","double")&&
    is.null(dim(i))&&is.null(dim(j))&&all(is.finite(i))&&all(is.finite(j))&&
    all(i==floor(i))&&all(j==floor(j))&&all(i>=1&i<=n)&&all(j>=1&j<=n)&&
    all(i!=j)&&!anyDuplicated((i-1)*n+j),"invalid ordered pair coordinates","invalid_problem")
  invisible(TRUE)
}

# Maximum selected-criterion risk implied by pair indicators (risk units).
.pr_minimax_needed_t <- function(problem,pairs) {
  selected <- problem$settings$minimax_criteria
  if(is.null(selected)) selected <- problem$pairwise$criterion_ids
  M <- choose(length(problem$pairwise$entity_ids),2); tau <- problem$settings$tau
  i <- problem$index$pair_i; j <- problem$index$pair_j; N <- sum(pairs)
  max(vapply(selected,function(k) (sum(problem$pairwise$e[,,k][cbind(i,j)]*pairs)+tau*(M-N))/M,numeric(1L)))
}

.pr_solution_residuals <- function(model,primal) {
  bounds <- pmax(0,model$var_lower-primal,primal-model$var_upper)
  activity <- as.numeric(model$A%*%primal)
  rows <- pmax(0,model$row_lower-activity,activity-model$row_upper)
  rows[!is.finite(activity)] <- Inf
  list(bounds_max=max(c(0,bounds)),rows_max=max(c(0,rows)),
       bound_violations=bounds,row_violations=rows,row_activity=activity)
}

#' Check a Solver Candidate for the Grading Problem
#'
#' A numerical solver candidate is checked for feasible grades under the
#' specified problem, and its pairwise relations and posterior risk are
#' recomputed. The check is performed within [postrank_solve()] and can also be
#' applied directly to a returned raw solution. Feasibility of a candidate does
#' not establish optimality.
#'
#' @param problem A validated `postrank_problem`.
#' @param solution Numeric primal vector in the problem's model-column order,
#'   such as `fit$raw_solution`, or `NULL` when no candidate was returned.
#'   A named grade vector alone is not a primal vector; use [postrank_evaluate()]
#'   to score grades without validating the optimization variables.
#' @param tolerances Named list of nonnegative finite `feasibility`,
#'   `integrality` and `objective` tolerances. Defaults are `1e-7`, `1e-6`
#'   and `1e-7`, respectively.
#' @return A `postrank_solution_validation` list with `valid`, `issues`,
#'   `warnings`, raw/rounded residuals, `integrality_residual`, `rounded_solution`,
#'   raw labels/pair variables, and `tolerances`. For a valid candidate,
#'   `grade`, `evaluation` and `recomputed_raw_objective` describe the checked
#'   action. `epigraph_shortfall` and `epigraph_repaired` record any permitted
#'   minimax adjustment. `validity_basis` is `"rounded_integer_solution"`.
#'   Invalid or absent candidates have `grade` and `evaluation` set to `NULL`;
#'   malformed problems or tolerance settings raise input errors.
#' @details Integer residuals must be within tolerance before the rounded
#'   variables are accepted. The rounded solution must satisfy bounds and rows,
#'   reconstruct the same pair relations as its grades, and meet the grade cap,
#'   any exact count and error-budget constraints. Raw-primal residuals are
#'   retained as diagnostics and can produce warnings even if the rounded action
#'   passes. Thus `valid` refers to the checked action within the tolerances.
#'
#'   For minimax, a shortfall of the continuous auxiliary variable within the
#'   objective tolerance is raised to the action's maximum criterion risk before
#'   checking the rounded constraints. Larger shortfalls are not repaired.
#'   This function checks neither a solver lower bound nor optimality, posterior
#'   calibration or the scientific accuracy of the supplied probabilities.
#' @seealso [postrank_solve()], [postrank_evaluate()]
#' @examples
#' problem <- postrank_problem(pr_tutorial$one, weights = c(score_A = 1),
#'   tau = .2, G_max = 3L)
#' absent <- validate_postrank_solution(problem, NULL)
#' absent$valid
#' if (requireNamespace("highs", quietly = TRUE)) {
#'   fit <- postrank_solve(problem, backend = "highs",
#'     control = postrank_control(time_limit = 10))
#'   checked <- validate_postrank_solution(problem, fit$raw_solution)
#'   checked$valid
#' }
#' @concept decision
#' @export
validate_postrank_solution <- function(problem,solution,tolerances=list()) {
  .pr_validate_problem(problem); .pr_solution_model_dimensions(problem)
  tolerance <- .pr_solution_tolerances(tolerances)
  result <- list(valid=FALSE,issues=list(),warnings=character(),raw_residuals=NULL,rounded_residuals=NULL,
    integrality_residual=NA_real_,rounded_solution=NULL,raw_labels=NULL,raw_pairs=NULL,
    grade=NULL,evaluation=NULL,recomputed_raw_objective=NA_real_,epigraph_shortfall=NA_real_,epigraph_repaired=FALSE,
    validity_basis="rounded_integer_solution",tolerances=tolerance)
  issues <- list()
  issue <- function(code,message,path="$.solution") {
    issues[[length(issues)+1L]] <<- list(code=code,path=path,message=message,severity="error")
  }
  finish <- function() {
    result$issues <- issues; result$valid <- !length(issues)
    if(!result$valid) result[c("grade","evaluation")] <- list(NULL,NULL)
    class(result) <- c("postrank_solution_validation","list"); result
  }
  if(is.null(solution)) {issue("no_incumbent","no primal incumbent was supplied");return(finish())}
  if(!typeof(solution)%in%c("integer","double")||!is.null(dim(solution))) {
    issue("invalid_primal_type","primal must be one real numeric vector in model-column order");return(finish())
  }
  model <- problem$model; index <- problem$index
  if(length(solution)!=length(model$objective)) {
    issue("invalid_primal_length","primal length differs from model columns");return(finish())
  }
  result$raw_labels <- solution[index$labels]; result$raw_pairs <- solution[index$pairs]
  if(anyNA(solution)||any(!is.finite(solution))) {
    issue("nonfinite_primal","primal contains missing or nonfinite values");return(finish())
  }
  integer <- which(model$types%in%c("I","B"))
  result$integrality_residual <- max(c(0,abs(solution[integer]-round(solution[integer]))))
  rounded <- solution; rounded[integer] <- round(rounded[integer])
  # The minimax epigraph t is an auxiliary continuous variable determined by the
  # action. A shortfall within the objective tolerance is raised to the action's
  # maximum criterion risk before the rounded rows are checked, because the
  # epigraph rows scale the shortfall by M. Larger shortfalls remain violations.
  if(length(index$t)==1L) {
    needed <- .pr_minimax_needed_t(problem,rounded[index$pairs])
    shortfall <- needed-rounded[index$t]
    result$epigraph_shortfall <- max(0,shortfall)
    result$epigraph_repaired <- is.finite(shortfall)&&shortfall>0&&shortfall<=tolerance$objective
    if(result$epigraph_repaired) rounded[index$t] <- needed
  }
  result$rounded_solution <- rounded
  result$raw_residuals <- .pr_solution_residuals(model,solution)
  result$rounded_residuals <- .pr_solution_residuals(model,rounded)
  result$recomputed_raw_objective <- sum(model$objective*rounded)
  if(result$integrality_residual>tolerance$integrality)
    issue("integrality_violation","primal is not sufficiently close to integers")
  # Validity is judged on the rounded integer solution (the released action).
  # Raw-primal residuals are solver-tolerance diagnostics, reported as warnings.
  if(result$raw_residuals$bounds_max>tolerance$feasibility)
    result$warnings <- c(result$warnings,sprintf("Raw primal bound residual %.3g exceeds the feasibility tolerance; validity is judged on the rounded integer solution.",result$raw_residuals$bounds_max))
  if(result$raw_residuals$rows_max>tolerance$feasibility)
    result$warnings <- c(result$warnings,sprintf("Raw primal row residual %.3g exceeds the feasibility tolerance; validity is judged on the rounded integer solution.",result$raw_residuals$rows_max))
  if(result$rounded_residuals$bounds_max>tolerance$feasibility)
    issue("rounded_bound_violation","rounded primal violates a variable bound")
  if(result$rounded_residuals$rows_max>tolerance$feasibility)
    issue("rounded_row_violation","rounded primal violates a linear constraint")
  if(any(!rounded[model$types=="B"]%in%c(0,1)))
    issue("binary_violation","rounded binary variable is not zero or one")
  if(!is.finite(result$recomputed_raw_objective))
    issue("nonfinite_objective","recomputed raw objective is not finite")
  if(length(issues)) return(finish())

  labels <- stats::setNames(rounded[index$labels],problem$pairwise$entity_ids)
  grade <- canonical_postrank_grade(labels,problem$pairwise$entity_ids)
  expected_pairs <- as.numeric(grade[index$pair_i]<grade[index$pair_j])
  if(!identical(as.numeric(rounded[index$pairs]),expected_pairs))
    issue("pair_relation_mismatch","rounded pair variables differ from reconstructed grade relations")
  if(length(unique(grade))>problem$settings$G_max)
    issue("grade_limit_violation","canonical grade exceeds G_max")
  evaluation <- postrank_evaluate(grade,problem$pairwise,problem$settings$weights,problem$settings$tau,
    problem$settings$objective,problem$settings$minimax_criteria)
  if(!is.null(problem$settings$exact_G)&&evaluation$G!=problem$settings$exact_G)
    issue("exact_grade_violation","canonical grade does not use exactly the requested nonempty grades")
  if(!is.null(problem$settings$q)) {
    q <- .pr_problem_q_thresholds(problem)
    if(any(evaluation$E[names(q)]-q*evaluation$N>tolerance$feasibility))
      issue("protection_violation","recomputed criterion errors violate the active public or envelope threshold")
  }
  objective <- problem$settings$objective
  if(identical(objective,"weighted")) {
    if(abs(result$recomputed_raw_objective-evaluation$weighted_raw_objective)>tolerance$objective)
      issue("objective_reconstruction_mismatch","raw objective differs from grade-based weighted objective")
  } else if(identical(objective,"minimax")) {
    .pr_assert(length(index$t)==1L,"minimax problem lacks a scalar epigraph variable","invalid_problem")
    selected <- problem$settings$minimax_criteria
    if(is.null(selected)) selected <- problem$pairwise$criterion_ids
    .pr_assert(length(selected)>0L&&all(selected%in%names(evaluation$criterion_risk)),
      "invalid minimax criterion set","invalid_problem")
    if(max(evaluation$criterion_risk[selected])-rounded[index$t]>tolerance$objective)
      issue("minimax_epigraph_violation","epigraph value is below recomputed maximum criterion risk")
    if(abs(result$recomputed_raw_objective-rounded[index$t])>tolerance$objective)
      issue("objective_reconstruction_mismatch","minimax raw objective differs from epigraph t")
  } else .pr_abort("unsupported objective in problem","invalid_problem")
  if(!length(issues)) {result$grade <- grade;result$evaluation <- evaluation}
  finish()
}
