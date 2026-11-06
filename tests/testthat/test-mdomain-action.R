md_action_metadata <- function() {
  units <- c("A", "B", "C"); domains <- c("need", "cost")
  structure(list(n=3L, D=2L, unit_ids=units, domain_ids=domains,
    input_id="designed-action-input",
    equality_classes=setNames(rep(list(units), 2L), domains)),
    class=c("p2_profile_input", "list"))
}

test_that("identified grade matrices canonicalize numerical order and preserve ties", {
  skip_if_not_installed("gmp")
  input <- md_action_metadata()
  grades <- matrix(c(-10,-10,2.5, 90,10,50), 3,
                   dimnames=list(input$unit_ids, input$domain_ids))
  action <- .md_action(input, grades)
  expect_s3_class(action, "p2_profile_action")
  expect_identical(action$G, matrix(c(1L,1L,2L, 3L,1L,2L), 3,
    dimnames=list(input$unit_ids, input$domain_ids)))
  expect_identical(action$direction[,"need"], c(0L,1L,1L))
  expect_identical(action$direction[,"cost"], c(-1L,-1L,1L))
  expect_identical(action$N, c(need=2L, cost=3L))
  expect_false(action$all_withheld)
  expect_true(action$receipt$canonicalize_requested)
  expect_true(action$receipt$labels_changed)
  expect_identical(action$receipt$original_grades, grades)
  expect_identical(action$receipt$input_id, input$input_id)
  expect_identical(dimnames(action$G), dimnames(grades))
  # Strict monotone relabeling changes no disclosed comparison or profile cell.
  relabeled <- .md_action(input, grades*7 + 200)
  expect_identical(relabeled$G, action$G)
  expect_identical(relabeled$direction, action$direction)
  expect_identical(relabeled$cell_id, action$cell_id)
})

test_that("withholding does not declare structural equality", {
  skip_if_not_installed("gmp")
  input <- md_action_metadata()
  grades <- matrix(0, 3, 2, dimnames=list(input$unit_ids, input$domain_ids))
  action <- .md_action(input, grades)
  expect_true(action$all_withheld)
  expect_identical(action$N, c(need=0L, cost=0L))
  expect_identical(unname(action$direction), matrix(0L, 3, 2))
  expect_identical(action$C, 1L)
  expect_identical(length(unique(action$equality_classes$need)), 3L)
  expect_true(action$receipt$equality_classes_supplied)
})

test_that("structurally identical units must receive the same grade in their domain", {
  skip_if_not_installed("gmp")
  input <- md_action_metadata()
  input$equality_classes$need <- c("same", "same", "other")
  good <- matrix(c(3,3,7, 1,2,3), 3,
                 dimnames=list(input$unit_ids, input$domain_ids))
  expect_identical(.md_action(input, good)$G[,"need"], c(A=1L, B=1L, C=2L))
  bad <- good; bad["B","need"] <- 4
  expect_error(.md_action(input, bad), "equality guard violated in domain need",
               class="postrank_mdomain_error")
})

test_that("grade identity is mandatory and reordered matrices are rejected", {
  skip_if_not_installed("gmp")
  input <- md_action_metadata()
  grades <- matrix(c(1,2,3,3,2,1), 3,
                   dimnames=list(input$unit_ids, input$domain_ids))
  for (bad in list(unname(grades), grades[3:1,,drop=FALSE],
                  grades[,2:1,drop=FALSE])) {
    expect_error(.md_action(input, bad), "names must match",
                 class="postrank_mdomain_error")
  }
  bad <- grades; rownames(bad) <- c("A", "B", "other")
  err <- tryCatch(.md_action(input, bad), error=identity)
  expect_identical(err$code, "mdomain_action_identity")
  expect_identical(err$field, "grades")
  expect_identical(err$requested, rownames(bad))
  expect_identical(err$available, input$unit_ids)
  bad <- grades; rownames(bad) <- c("A", "A", "C")
  expect_error(.md_action(input, bad), class="postrank_mdomain_error")
})

test_that("grade values require a complete finite numeric matrix", {
  skip_if_not_installed("gmp")
  input <- md_action_metadata()
  grades <- matrix(1, 3, 2, dimnames=list(input$unit_ids, input$domain_ids))
  for (value in c(NA_real_, Inf, -Inf, NaN)) {
    bad <- grades; bad[1,1] <- value
    expect_error(.md_action(input, bad), "finite numeric",
                 class="postrank_mdomain_error")
  }
  bad <- grades; storage.mode(bad) <- "character"
  expect_error(.md_action(input, bad), "numeric matrix", class="postrank_mdomain_error")
  bad <- grades > 0
  expect_error(.md_action(input, bad), "numeric matrix", class="postrank_mdomain_error")
  expect_error(.md_action(input, grades[,1]), "matrix", class="postrank_mdomain_error")
  expect_error(.md_action(list(), grades), "validated multidomain input",
               class="postrank_mdomain_error")
})
