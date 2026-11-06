test_that("joint JSON coordinates and singleton axes round trip", {
  for(dims in list(c(4L,3L,2L),c(1L,2L,1L))) {
    x <- pr_test_payload(S=dims[1],n=dims[2],K=dims[3])
    path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
    write_postrank_draws(x,path)
    raw <- jsonlite::fromJSON(path,simplifyVector=FALSE)
    expect_identical(raw$schema_version,"applied-0.1")
    expect_length(raw$joint_draws$tensor$values,dims[1])
    for(s in seq_len(dims[1])) for(i in seq_len(dims[2])) for(k in seq_len(dims[3]))
      expect_identical(raw$joint_draws$tensor$values[[s]][[i]][[k]],x$joint_draws$tensor$values[s,i,k])
    y <- read_postrank_draws(path)
    expect_identical(y$joint_draws$tensor$values,x$joint_draws$tensor$values)
    expect_identical(y$entity_ids,c("001","002",if(dims[2]>2)"003"))
    expect_false(y$validation$schema_checked)
    expect_false(y$validation$source_values_checked)
    expect_false(y$validation$jointness_verified)
    expect_false(y$validation$convergence_verified)
  }
})

test_that("criterionwise unequal lengths and MCMC history survive JSON", {
  for(x in list(pr_test_criterionwise(),pr_test_payload(regime="mcmc"))) {
    path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
    write_postrank_draws(as_postrank_draws(x),path)
    y <- read_postrank_draws(path)
    expect_equal(.pr_payload(y),x,tolerance=0)
  }
})

test_that("exact law and safe-integer endpoints round trip without rounding", {
  skip_if_not_installed("gmp")
  x <- pr_test_exact()
  x$finite_law$states[[1]]$theta[1,1] <- 9007199254740991
  x$finite_law$states[[1]]$theta[2,1] <- -9007199254740991
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  write_postrank_draws(x,path); y <- read_postrank_draws(path)
  expect_equal(.pr_payload(y),x,tolerance=0)
  expect_identical(y$finite_law$states[[1]]$theta,x$finite_law$states[[1]]$theta)
})

test_that("full double precision is preserved before ties can be introduced", {
  x <- pr_test_payload(S=1L,n=4L,K=1L)
  x$joint_draws$tensor$values[1,,1] <- c(1,1+2^-52,pi,1e-200)
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  write_postrank_draws(x,path); y <- read_postrank_draws(path)
  expect_identical(y$joint_draws$tensor$values,x$joint_draws$tensor$values)
})

test_that("duplicate JSON keys are rejected after escape decoding", {
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  for(text in c('{"schema_version":"a","schema_version":"b"}',
                '{"a":1,"\\u0061":2}',
                '{"outer":{"a":1,"\\u0061":2}}')) {
    writeLines(text,path)
    expect_error(read_postrank_draws(path),"duplicate object key",class="postrank_input_error")
  }
})

test_that("Unicode code-unit validation rejects lone surrogates before decoding", {
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  invalid <- c('"\\ud800"','"\\udc00"','"\\uD800x"','"\\uD800\\u0041"','"\\uDC00\\uD800"')
  for(text in invalid) {
    expect_error(.pr_json_scan(text),"surrogate",class="postrank_input_error")
  }
  write_postrank_draws(pr_test_payload(),path,overwrite=TRUE)
  original <- paste(readLines(path),collapse="\n")
  for(code in c("\\uD800","\\uDC00")) {
    # Both fixtures are otherwise valid; a schema error cannot mask decoder loss.
    producer <- sub('"producer": "postrank software tests"',paste0('"producer": "',code,'"'),original,fixed=TRUE)
    expect_false(identical(producer,original))
    writeLines(producer,path)
    expect_error(read_postrank_draws(path),"surrogate",class="postrank_input_error")
    ids <- gsub('"001"',paste0('"',code,'"'),original,fixed=TRUE)
    expect_false(identical(ids,original))
    writeLines(ids,path)
    expect_error(read_postrank_draws(path),"surrogate",class="postrank_input_error")
  }
  expect_identical(.pr_json_scan('"\\ud83d\\ude00"')$kind,"string")
  text <- gsub('"001"','"\\ud83d\\ude00"',original,fixed=TRUE)
  writeLines(text,path)
  y <- read_postrank_draws(path)
  expect_identical(y$entity_ids[[1]],"\U0001F600")
  expect_identical(dimnames(y$joint_draws$tensor$values)$entity[[1]],"\U0001F600")
})

test_that("nonstandard numbers, malformed grammar and overflow are rejected", {
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  for(text in c('{"a":NaN}','{"a":Infinity}','{"a":-Infinity}',
                '{"a":1e999}','{"a":1e-999}','{"a":01}','{"a":+1}','{"a":.1}',
                '{"a":1.}','{"a":1,}','{"a":"\\x01"}','{} {}')) {
    writeLines(text,path)
    expect_error(read_postrank_draws(path),class="postrank_input_error")
  }
})

test_that("integer token identity is preserved in shape and MCMC history", {
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  write_postrank_draws(pr_test_payload(S=1L,regime="mcmc"),path)
  text <- paste(readLines(path),collapse="\n")
  for(replacement in list(c('"iteration": 3','"iteration": 3.0000000000000001'),
                           c('"S": 1','"S": 1.0000000000000001'),
                           c('"retained_iterations": \\[\\s*3','"retained_iterations": [3.0000000000000001'))) {
    changed <- sub(replacement[1],replacement[2],text,perl=TRUE)
    expect_false(identical(changed,text))
    writeLines(changed,path)
    expect_error(read_postrank_draws(path),"integer",class="postrank_input_error")
  }
})

test_that("unsafe exact tokens cannot round into safe integer values", {
  skip_if_not_installed("gmp")
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  write_postrank_draws(pr_test_exact(),path)
  text <- paste(readLines(path),collapse="\n")
  for(token in c("9007199254740992","9007199254740991.1","9007199254740990.6","3.0000000000000001","3e-999")) {
    changed <- sub('"denominator": 3',paste0('"denominator": ',token),text,fixed=TRUE)
    writeLines(changed,path)
    expect_error(read_postrank_draws(path),"safe integer|underflows",class="postrank_input_error")
  }
  writeLines(sub('"denominator": 3','"denominator": 30e-1',text,fixed=TRUE),path)
  expect_s3_class(read_postrank_draws(path),"postrank_draws")
})

test_that("JSON array/object distinctions and unexpected fields are retained", {
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  write_postrank_draws(pr_test_payload(),path)
  original <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  for(change in c("unknown","numeric_id","object_records","wrong_shape")) {
    raw <- original
    if(change=="unknown") raw$context$unexpected <- "extra"
    if(change=="numeric_id") raw$entity_ids[[1]] <- 1
    if(change=="object_records") names(raw$targets) <- paste0("criterion",seq_along(raw$targets))
    if(change=="wrong_shape") raw$joint_draws$tensor$shape$n <- 1e8
    writeLines(as.character(jsonlite::toJSON(raw,auto_unbox=TRUE,null="null",digits=17)),path)
    expect_error(read_postrank_draws(path),class="postrank_input_error")
  }
})

test_that("JSON object property ordering does not permute tensor axes", {
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  x <- pr_test_payload(); write_postrank_draws(x,path)
  raw <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  raw$joint_draws$tensor$dimnames <- rev(raw$joint_draws$tensor$dimnames)
  raw$joint_draws$tensor$shape <- rev(raw$joint_draws$tensor$shape)
  writeLines(as.character(jsonlite::toJSON(raw,auto_unbox=TRUE,null="null",digits=17)),path)
  expect_identical(read_postrank_draws(path)$joint_draws$tensor$values,x$joint_draws$tensor$values)
})

test_that("writes require explicit overwrite and do not persist API receipts", {
  path <- tempfile(fileext=".json"); on.exit(unlink(path),add=TRUE)
  x <- as_postrank_draws(pr_test_payload())
  write_postrank_draws(x,path)
  expect_error(write_postrank_draws(x,path),"already exists",class="postrank_input_error")
  expect_invisible(write_postrank_draws(x,path,overwrite=TRUE))
  raw <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  expect_false("validation"%in%names(raw))
  expect_false("input_schema_version"%in%names(raw))
})
