# Independent selection oracles: ordered blocks generate ranks, and literal
# finite states generate weak-error counts. Neither helper calls a production
# enumerator, action canonicalizer, evaluator, pairwise coefficient or solver.
md_selection_rank_columns <- function(n, equality_classes=NULL, grade_cap=n) {
  partitions <- list(list(1L))
  for (unit in seq.int(2L,n)) {
    next_partitions <- list()
    for (blocks in partitions) {
      for (b in seq_along(blocks)) {
        joined <- blocks
        joined[[b]] <- c(joined[[b]],unit)
        next_partitions[[length(next_partitions)+1L]] <- joined
      }
      for (gap in 0:length(blocks))
        next_partitions[[length(next_partitions)+1L]] <-
          append(blocks,list(unit),after=gap)
    }
    partitions <- next_partitions
  }
  columns <- lapply(partitions,function(blocks) {
    grades <- integer(n)
    for (b in seq_along(blocks)) grades[blocks[[b]]] <- b
    grades
  })
  keep <- vapply(columns,function(g) {
    max(g)<=grade_cap && (is.null(equality_classes) ||
      all(vapply(unique(equality_classes),function(z)
        length(unique(g[equality_classes==z]))==1L,logical(1))))
  },logical(1))
  columns <- do.call(rbind,columns[keep])
  columns[do.call(order,lapply(seq_len(n),function(i) columns[,i])),,drop=FALSE]
}

md_selection_key <- function(grades) paste(as.vector(grades),collapse=",")

md_selection_actions <- function(columns,units,domains,common=FALSE) {
  if (common) {
    keys <- lapply(columns,function(a) apply(a,1L,paste,collapse=","))
    shared <- Reduce(intersect,keys)
    actions <- lapply(shared,function(k) matrix(rep(columns[[1L]][match(k,keys[[1L]]),],
      length(domains)),length(units),length(domains)))
  } else {
    indices <- expand.grid(lapply(columns,function(a) seq_len(nrow(a))),
      KEEP.OUT.ATTRS=FALSE)
    actions <- lapply(seq_len(nrow(indices)),function(i)
      do.call(cbind,lapply(seq_along(columns),function(d) columns[[d]][indices[i,d],])))
  }
  for (i in seq_along(actions)) dimnames(actions[[i]]) <- list(units,domains)
  actions[order(vapply(actions,md_selection_key,character(1)),method="radix")]
}

md_selection_score <- function(values,masses,grades,weights,tau,t="0",alpha="0",q=NULL) {
  S <- dim(values)[1L]; n <- dim(values)[2L]; D <- dim(values)[3L]
  F <- matrix(0L,S,D); N <- integer(D); M <- n*(n-1L)/2L
  for (d in seq_len(D)) for (i in seq_len(n-1L)) for (j in seq.int(i+1L,n)) {
    if (grades[i,d]==grades[j,d]) next
    N[d] <- N[d]+1L
    ahead <- if (grades[i,d]<grades[j,d]) i else j
    behind <- if (ahead==i) j else i
    F[,d] <- F[,d]+as.integer(values[,ahead,d]<=values[,behind,d])
  }
  mass_q <- gmp::as.bigq(masses)
  weight_q <- gmp::as.bigq(weights)
  tau_q <- gmp::as.bigq(rep(tau,length.out=D))
  t_q <- gmp::as.bigq(rep(t,length.out=D))
  risk_q <- gmp::as.bigq(0)
  union_event <- rep(FALSE,S); mean_ok <- TRUE
  for (d in seq_len(D)) {
    EF_q <- sum(mass_q*gmp::as.bigq(F[,d]))
    risk_q <- risk_q+weight_q[d]*(EF_q+tau_q[d]*(M-N[d]))/M
    if (N[d]>0L)
      union_event <- union_event | as.logical(gmp::as.bigq(F[,d])>t_q[d]*N[d])
    if (!is.null(q)) mean_ok <- mean_ok &&
      as.logical(EF_q<=gmp::as.bigq(rep(q,length.out=D))[d]*N[d])
  }
  J_q <- sum(mass_q*gmp::as.bigq(as.integer(union_event)))
  list(risk_exact=as.character(risk_q),J_exact=as.character(J_q),F=F,N=N,
    mean_feasible=mean_ok,
    protection_feasible=as.logical(J_q<=gmp::as.bigq(alpha)),
    feasible_for_represented_measure=mean_ok && as.logical(J_q<=gmp::as.bigq(alpha)))
}

md_selection_input <- function(values,masses,id) {
  units <- dimnames(values)[[2L]]; domains <- dimnames(values)[[3L]]
  targets <- setNames(lapply(domains,function(d) list(
    definition=paste("Specified finite-law coordinate",d),units="illustrative units",
    orientation="larger_is_higher",transformations=list(),
    equality_classes=setNames(units,units),
    equality_provenance="The declared coordinates have no structural identities between distinct units.")),domains)
  postrank_mdomain_input(values,targets=targets,
    provenance=list(input_id=id,law_id=paste0(id,"-complete-law"),proper_law=TRUE,
      producer="Independent literal finite-state selection test",
      joint_generation="Each listed state specifies every unit in every domain; exact masses define the complete law.",
      sampling_assumptions=list(finite_support_origin="The stated finite support and rational masses define the whole law.")),
    representation="exact_finite_law",masses=masses)
}

# Public columns carry the original input identities in both list dimensions.
md_selection_family <- function(input,columns) {
  named_columns <- setNames(lapply(columns,function(a)
    lapply(seq_len(nrow(a)),function(i) setNames(unname(a[i,]),input$unit_ids))),input$domain_ids)
  postrank_mdomain_family(input,columns=named_columns)
}

md_selection_expected_table <- function(actions,values,masses,weights,tau,t="0",alpha="0",q=NULL) {
  rows <- lapply(actions,function(G) {
    score <- md_selection_score(values,masses,G,weights,tau,t,alpha,q)
    data.frame(grade_key=md_selection_key(G),risk_exact=score$risk_exact,
      J_exact=score$J_exact,mean_feasible=score$mean_feasible,
      protection_feasible=score$protection_feasible,
      feasible_for_represented_measure=score$feasible_for_represented_measure,
      stringsAsFactors=FALSE)
  })
  tab <- do.call(rbind,rows); rownames(tab) <- NULL
  feasible <- which(tab$feasible_for_represented_measure)
  scores <- gmp::as.bigq(tab$risk_exact[feasible])
  tab$optimal <- seq_len(nrow(tab)) %in% feasible[as.logical(scores==min(scores))]
  tab
}

md_selection_check_solution <- function(solution,expected) {
  actual <- solution$candidate_table
  keys <- vapply(solution$actions,md_selection_key,character(1))
  expect_setequal(unname(keys),expected$grade_key)
  actual <- actual[match(names(keys)[match(expected$grade_key,keys)],actual$action_id),,drop=FALSE]
  for (field in c("risk_exact","J_exact","mean_feasible","protection_feasible",
                  "feasible_for_represented_measure","optimal"))
    expect_identical(actual[[field]],expected[[field]],info=field)
  optimizer_keys <- unname(keys[solution$optimizer_ids])
  expect_identical(optimizer_keys,expected$grade_key[expected$optimal])
  expect_identical(md_selection_key(solution$selected_action$G),optimizer_keys[1L])
  expect_identical(solution$candidate_table$action_id[solution$candidate_table$optimal],
    solution$optimizer_ids)
  invisible(actual)
}

md_selection_coupling_case <- function(kind=c("coincident","disjoint")) {
  kind <- match.arg(kind)
  signs <- if (kind=="coincident") rbind(c(1,1),c(-1,-1)) else
    rbind(c(1,1),c(-1,1),c(1,-1))
  values <- array(0,c(nrow(signs),2L,2L),dimnames=list(
    state=paste0("literal-",seq_len(nrow(signs))),unit=c("site-A","site-B"),
    domain=c("priority","benefit")))
  values[,1L,1L] <- signs[,1L]; values[,1L,2L] <- signs[,2L]
  list(values=values,masses=if(kind=="coincident") c("9/10","1/10") else
    c("4/5","1/10","1/10"))
}

md_selection_n5_case <- function() {
  # Literal design, not scored output: P2 Step8.6 runtime-design.json n5-bank.
  # A single complete state; u2/u3 have crossed priorities between domains.
  values <- array(0,c(1L,5L,2L),dimnames=list(state="complete-state",
    unit=paste0("u",1:5),domain=c("need","benefit")))
  values[1L,,] <- cbind(c(5,4,3,2,1),c(5,3,4,2,1))
  list(values=values,masses="1",orders=list(need=paste0("u",1:5),
    benefit=c("u1","u3","u2","u4","u5")),cuts=c(1L,3L,4L),cap=3L)
}

# Subsets of three declared cuts, with at most two cuts, independently produce
# the seven n5 columns. This does not call the public/core bank constructor.
md_selection_order_columns <- function(units,order,cuts,cap) {
  masks <- expand.grid(rep(list(c(FALSE,TRUE)),length(cuts)),KEEP.OUT.ATTRS=FALSE)
  masks <- masks[rowSums(masks)<cap,,drop=FALSE]
  result <- t(vapply(seq_len(nrow(masks)),function(i) {
    selected <- cuts[as.logical(masks[i,])]
    ranked <- vapply(seq_along(order),function(pos) 1L+sum(selected<pos),integer(1))
    ranked[match(units,order)]
  },integer(length(units))))
  result[do.call(base::order,lapply(seq_along(units),function(i) result[,i])),,drop=FALSE]
}

test_that("installed private ordered partitions match independent rank enumeration", {
  skip_if_not_installed("gmp")
  enumerate <- getFromNamespace("p2_enumerate_columns","postrank")
  counts <- integer(3L)
  for (n in 2:4) {
    expected <- md_selection_rank_columns(n)
    actual <- enumerate(n)
    counts[n-1L] <- nrow(actual)
    expect_identical(unname(actual),unname(expected))
    expect_false(anyDuplicated(apply(expected,1L,paste,collapse=","))>0L)
  }
  expect_identical(counts,c(3L,13L,75L))
  expect_identical(unname(enumerate(3L,c("same","same","other"))),
    unname(md_selection_rank_columns(3L,c("same","same","other"))))
  expect_identical(unname(enumerate(3L,grade_cap=2L)),
    unname(md_selection_rank_columns(3L,grade_cap=2L)))
  expect_identical(nrow(enumerate(3L,grade_cap=2L)),7L)
})

test_that("public selection reproduces complete same-marginal coupling optimizer sets", {
  skip_if_not_installed("gmp")
  results <- list()
  for (kind in c("coincident","disjoint")) {
    law <- md_selection_coupling_case(kind)
    input <- md_selection_input(law$values,law$masses,paste0("selection-",kind))
    columns <- rep(list(md_selection_rank_columns(2L)),2L)
    family <- md_selection_family(input,columns)
    decision <- postrank_mdomain_decision(
      weights=c(priority="1/2",benefit="1/2"),tau="1/4",q=NULL,t="0",alpha="3/20")
    fit <- postrank_mdomain_solve(input,family,decision)
    expected <- md_selection_expected_table(
      md_selection_actions(columns,input$unit_ids,input$domain_ids),
      law$values,law$masses,c("1/2","1/2"),"1/4",alpha="3/20")
    expect_s3_class(family,"postrank_mdomain_family")
    expect_s3_class(family$family,"p2_candidate_family")
    expect_s3_class(fit,"postrank_mdomain_fit")
    expect_s3_class(fit$solution,"p2_candidate_solution")
    expect_s3_class(fit$evaluation,"postrank_mdomain_evaluation")
    md_selection_check_solution(fit$solution,expected)
    expect_identical(postrank_mdomain_grades(fit),fit$solution$selected_action$G)
    expect_identical(postrank_mdomain_grades(fit$evaluation),postrank_mdomain_grades(fit))
    expect_identical(fit$solution$receipts$examined_actions,9L)
    expect_identical(fit$solution$receipts$objective_comparison,"exact_rational")
    expect_false(fit$solution$receipts$numerical_guarantee)
    expect_false(fit$solution$receipts$intended_posterior_feasibility_certified)
    results[[kind]] <- fit
  }
  co <- results$coincident; dis <- results$disjoint
  expect_identical(co$evaluation$risk_exact,"1/10")
  expect_identical(dis$evaluation$risk_exact,"7/40")
  expect_identical(co$evaluation$J_exact,"1/10")
  expect_identical(dis$evaluation$J_exact,"1/10")
  co_keys <- unname(vapply(co$solution$actions[co$solution$optimizer_ids],md_selection_key,character(1)))
  dis_keys <- unname(vapply(dis$solution$actions[dis$solution$optimizer_ids],md_selection_key,character(1)))
  expect_identical(co_keys,"1,2,1,2")
  expect_identical(dis_keys,c("1,1,1,2","1,2,1,1"))
  expect_identical(md_selection_key(postrank_mdomain_grades(dis)),dis_keys[1L])
})

test_that("matched finite common grades lose crossed priorities while the product attains zero", {
  skip_if_not_installed("gmp")
  values <- array(c(2,1,1,2),c(1L,2L,2L),dimnames=list(state="deterministic",
    unit=c("site-A","site-B"),domain=c("priority","benefit")))
  input <- md_selection_input(values,"1","selection-crossed-priorities")
  decision <- postrank_mdomain_decision(tau="1/4",q=NULL,t="0",alpha="0")
  columns <- rep(list(md_selection_rank_columns(2L)),2L)
  common_actions <- md_selection_actions(columns,input$unit_ids,input$domain_ids,common=TRUE)
  common <- md_selection_expected_table(common_actions,values,"1",c("1/2","1/2"),"1/4")
  expect_identical(nrow(common),3L)
  for (i in seq_along(common_actions)) {
    evaluated <- postrank_mdomain_evaluate(input,common_actions[[i]],decision)
    expect_identical(evaluated$risk_exact,common$risk_exact[i])
    expect_identical(evaluated$J_exact,common$J_exact[i])
    expect_identical(evaluated$feasible_for_represented_measure,
      common$feasible_for_represented_measure[i])
  }
  # The private common oracle searches exactly those same three supplied ranks.
  common_oracle <- getFromNamespace("p2_oracle","postrank")(input,
    getFromNamespace(".md_bind_decision","postrank")(input,decision),family="common")
  expect_s3_class(common_oracle,"p2_oracle_result")
  md_selection_check_solution(common_oracle,common)
  expect_identical(common$risk_exact[common$optimal],"1/4")
  expect_identical(common$grade_key[common$optimal],"1,1,1,1")
  product <- postrank_mdomain_solve(input,md_selection_family(input,columns),decision)
  expected <- md_selection_expected_table(md_selection_actions(columns,input$unit_ids,input$domain_ids),
    values,"1",c("1/2","1/2"),"1/4")
  md_selection_check_solution(product$solution,expected)
  expect_identical(product$evaluation$risk_exact,"0")
  expect_identical(product$evaluation$J_exact,"0")
  expect_identical(md_selection_key(postrank_mdomain_grades(product)),"1,2,2,1")
  expect_identical(length(product$solution$optimizer_ids),1L)
})

test_that("the literal n5 runtime design has a unique optimum in its full 49-action bank", {
  skip_if_not_installed("gmp")
  law <- md_selection_n5_case()
  input <- md_selection_input(law$values,law$masses,"selection-n5-runtime-design")
  columns <- lapply(law$orders,function(order)
    md_selection_order_columns(input$unit_ids,order,law$cuts,law$cap))
  family <- postrank_mdomain_family(input,order=law$orders,
    cuts=setNames(rep(list(law$cuts),2L),input$domain_ids),max_grades=law$cap,max_actions=49L)
  expect_identical(unname(family$family$column_counts),c(7L,7L))
  expect_identical(family$family$product_size_exact,"49")
  for (d in seq_along(columns))
    expect_identical(unname(family$family$banks[[d]]$columns),unname(columns[[d]]))
  decision <- postrank_mdomain_decision(weights=c(need="1/2",benefit="1/2"),
    tau="1/10",q=NULL,t="0",alpha="0")
  fit <- postrank_mdomain_solve(input,family,decision,max_actions=49L)
  expected <- md_selection_expected_table(md_selection_actions(columns,input$unit_ids,input$domain_ids),
    law$values,law$masses,c("1/2","1/2"),"1/10")
  md_selection_check_solution(fit$solution,expected)
  expect_identical(nrow(fit$solution$candidate_table),49L)
  expect_identical(fit$solution$receipts$examined_actions,49L)
  expect_identical(fit$solution$receipts$precomputed_domain_columns,14L)
  expect_identical(length(fit$solution$optimizer_ids),1L)
  expect_identical(fit$evaluation$risk_exact,"1/50")
  expect_identical(fit$evaluation$J_exact,"0")
  expect_identical(postrank_mdomain_grades(fit),matrix(rep(c(1L,2L,2L,3L,3L),2L),
    5L,2L,dimnames=list(input$unit_ids,input$domain_ids)))
  expect_false(fit$solution$receipts$full_ordered_partition_optimality_claim)
  expect_false(fit$solution$receipts$numerical_guarantee)
})
