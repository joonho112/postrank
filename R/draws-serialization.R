# Strict JSON grammar and duplicate decoded keys are checked before jsonlite can
# collapse information. Nodes retain object/array shape for BOOK type checking.
.pr_json_scan <- function(text) {
  if (!is.character(text) || length(text) != 1L || is.na(text))
    .pr_abort("expected one JSON string", "invalid_json")
  chars <- strsplit(enc2utf8(text), "", fixed = TRUE)[[1L]]
  at <- 1L; size <- length(chars)
  fail <- function(message, path = "$") .pr_abort(message, "invalid_json", path)
  peek <- function() if (at <= size) chars[[at]] else ""
  space <- function() {
    while (at <= size && chars[[at]] %in% c(" ", "\t", "\r", "\n")) at <<- at + 1L
  }
  string <- function(path) {
    start <- at; at <<- at + 1L
    repeat {
      if (at > size) fail("unterminated string", path)
      ch <- peek()
      if (ch == '"') {
        at <<- at + 1L
        token <- paste0(chars[start:(at - 1L)], collapse = "")
        return(tryCatch(withCallingHandlers(jsonlite::fromJSON(token, simplifyVector = FALSE),
                          warning=function(w) fail("invalid Unicode string; decoder warning rejected",path)),
                        error = function(e) fail("invalid JSON string escape", path)))
      }
      if (ch == "\\") {
        at <<- at + 1L; escape <- peek()
        if (escape == "u") {
          if (at + 4L > size || !all(grepl("^[0-9a-fA-F]$", chars[(at+1L):(at+4L)])))
            fail("invalid unicode escape", path)
          unit <- strtoi(paste0(chars[(at+1L):(at+4L)],collapse=""),base=16L)
          if(unit >= 0xD800 && unit <= 0xDBFF) {
            if(at+10L > size || chars[[at+5L]]!="\\" || chars[[at+6L]]!="u" ||
               !all(grepl("^[0-9a-fA-F]$",chars[(at+7L):(at+10L)])))
              fail("unpaired high Unicode surrogate",path)
            low <- strtoi(paste0(chars[(at+7L):(at+10L)],collapse=""),base=16L)
            if(low < 0xDC00 || low > 0xDFFF) fail("high Unicode surrogate must pair with a low surrogate",path)
            at <<- at + 11L
          } else {
            if(unit >= 0xDC00 && unit <= 0xDFFF) fail("unpaired low Unicode surrogate",path)
            at <<- at + 5L
          }
        } else if (escape %in% c('"', "\\", "/", "b", "f", "n", "r", "t")) at <<- at + 1L
        else fail("invalid string escape", path)
      } else {
        if (utf8ToInt(ch) < 32L) fail("unescaped control character", path)
        at <<- at + 1L
      }
    }
  }
  value <- function(path, depth = 0L) {
    if (depth > 100L) fail("JSON nesting exceeds supported depth 100", path)
    space(); ch <- peek()
    if (ch == "{") {
      at <<- at + 1L; space(); fields <- list(); keys <- character()
      if (peek() == "}") { at <<- at + 1L; return(list(kind="object", children=fields)) }
      repeat {
        if (peek() != '"') fail("object key must be a string", path)
        key <- string(path)
        if (key %in% keys) fail(paste0("duplicate object key: ", key), path)
        keys <- c(keys, key); space()
        if (peek() != ":") fail("expected colon", path)
        at <<- at + 1L
        fields[[length(fields)+1L]] <- value(paste0(path, ".", key), depth + 1L)
        names(fields)[length(fields)] <- key; space()
        if (peek() == "}") { at <<- at + 1L; break }
        if (peek() != ",") fail("expected comma or object end", path)
        at <<- at + 1L; space()
      }
      return(list(kind="object", children=fields))
    }
    if (ch == "[") {
      at <<- at + 1L; space(); children <- list()
      if (peek() == "]") { at <<- at + 1L; return(list(kind="array", children=children)) }
      repeat {
        children[[length(children)+1L]] <- value(paste0(path,"[",length(children)+1L,"]"), depth+1L)
        space()
        if (peek() == "]") { at <<- at + 1L; break }
        if (peek() != ",") fail("expected comma or array end", path)
        at <<- at + 1L; space()
      }
      return(list(kind="array", children=children))
    }
    if (ch == '"') { string(path); return(list(kind="string")) }
    for (literal in c("true", "false", "null")) {
      end <- at + nchar(literal) - 1L
      if (end <= size && identical(paste0(chars[at:end],collapse=""),literal)) {
        at <<- at + nchar(literal)
        return(list(kind=if(literal=="null") "null" else "boolean"))
      }
    }
    start <- at
    while(at <= size && chars[[at]] %in% c("-","+",".",as.character(0:9),"e","E")) at <<- at + 1L
    if(at == start) fail("expected standard JSON value",path)
    token <- paste0(chars[start:(at-1L)],collapse="")
    if(!grepl("^-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?$",token,perl=TRUE))
      fail("malformed JSON number",path)
    number <- suppressWarnings(as.numeric(token))
    if (!is.finite(number)) fail("nonfinite JSON number", path)
    if(number==0 && grepl("[1-9]",sub("[eE].*$","",token)))
      fail("nonzero JSON number underflows to zero",path)
    if (startsWith(path,"$.finite_law.") && !.pr_json_safe_integer_token(token))
      .pr_abort("exact-law number is not a safe integer before floating conversion", "unsafe_integer", path)
    list(kind="number", token=token)
  }
  node <- value("$"); space()
  if (at <= size) fail("trailing content or malformed number")
  node
}

# Decimal/exponent arithmetic is performed on text, preventing a fractional or
# out-of-range integer token from rounding into the accepted safe range.
.pr_json_safe_integer_token <- function(token) {
  token <- sub("^-", "", token)
  parts <- strsplit(tolower(token), "e", fixed=TRUE)[[1L]]
  mantissa <- strsplit(parts[[1L]], ".", fixed=TRUE)[[1L]]
  fractional <- if(length(mantissa)==2L) nchar(mantissa[[2L]]) else 0L
  digits <- sub("^0+", "", paste0(mantissa,collapse=""))
  if (!nzchar(digits)) return(TRUE)
  exponent <- if(length(parts)==2L) suppressWarnings(as.numeric(parts[[2L]])) else 0
  if (!is.finite(exponent) || abs(exponent)>1000000) return(FALSE)
  shift <- exponent - fractional
  if (shift < 0) {
    remove <- -shift
    if (remove >= nchar(digits)) return(FALSE)
    suffix <- substr(digits,nchar(digits)-remove+1,nchar(digits))
    if (grepl("[1-9]",suffix)) return(FALSE)
    digits <- substr(digits,1,nchar(digits)-remove)
  } else {
    if(nchar(digits)+shift>16) return(FALSE)
    digits <- paste0(digits,strrep("0",shift))
  }
  nchar(digits)<16 || (nchar(digits)==16 && digits <= "9007199254740991")
}

.pr_serialization_schema <- function() {
  path <- ""
  if(!isNamespace(environment(.pr_serialization_schema))) {
    candidates <- file.path(c(".","..","../.."),"inst/schema/draws-schema.json")
    found <- candidates[file.exists(candidates)]
    if(length(found)) path <- found[[1L]]
  }
  if(!nzchar(path)) path <- system.file("schema", "draws-schema.json", package="postrank")
  if(!nzchar(path)) .pr_abort("BOOK serialization schema unavailable", "schema_unavailable")
  jsonlite::fromJSON(path,simplifyVector=FALSE)
}

# This enforces the JSON object/array/scalar binding subset of the frozen BOOK
# schema, not general Draft 2020-12 validation. Full schema QA is development-only.
.pr_json_shape_guard <- function(node, rule, schema, path="$") {
  if (!is.null(rule[["$ref"]])) {
    key <- sub("^#/[\u0024]defs/", "", rule[["$ref"]])
    return(.pr_json_shape_guard(node,schema[["$defs"]][[key]],schema,path))
  }
  if(!is.null(rule$anyOf)) {
    candidates <- lapply(rule$anyOf,function(r) tryCatch({.pr_json_shape_guard(node,r,schema,path);NULL},error=identity))
    if(!any(vapply(candidates,is.null,logical(1)))) {
      unsafe <- vapply(candidates,function(e)identical(e$code,"unsafe_integer"),logical(1))
      if(any(unsafe)) stop(candidates[[which(unsafe)[1L]]])
      .pr_abort("JSON value type differs from BOOK contract", "invalid_json_type",path)
    }
    return(invisible(TRUE))
  }
  expected <- rule$type
  if(is.null(expected) && !is.null(rule$const)) expected <- if(is.list(rule$const)) "array" else if(is.character(rule$const)) "string" else if(is.logical(rule$const)) "boolean" else "number"
  if(!is.null(expected)) {
    if(expected=="integer") {
      if(identical(node$kind,"number") && !.pr_json_safe_integer_token(node$token))
        .pr_abort("declared integer is not exact and safe before floating conversion","unsafe_integer",path)
      expected <- "number"
    }
    if(!identical(node$kind,expected)) .pr_abort(paste("expected JSON",expected,"got",node$kind),"invalid_json_type",path)
  }
  if(node$kind=="object" && !is.null(rule$properties)) {
    if(any(!unlist(rule$required,use.names=FALSE)%in%names(node$children)))
      .pr_abort("missing required JSON field", "invalid_json_type",path)
    if(identical(rule$additionalProperties,FALSE) && any(!names(node$children)%in%names(rule$properties)))
      .pr_abort("unknown JSON field", "invalid_json_type",path)
    for(key in names(node$children)) {
      if(!is.null(rule$properties[[key]])) .pr_json_shape_guard(node$children[[key]],rule$properties[[key]],schema,paste0(path,".",key))
    }
  }
  if(node$kind=="array" && !is.null(rule$items))
    for(i in seq_along(node$children)) .pr_json_shape_guard(node$children[[i]],rule$items,schema,paste0(path,"[",i,"]"))
  invisible(TRUE)
}

.pr_json_vector <- function(x, mode="character", path="$") {
  if(!is.list(x) || !is.null(names(x))) .pr_abort("expected JSON array", "invalid_json_type",path)
  ok <- vapply(x,function(z) length(z)==1L && is.null(dim(z)) && if(mode=="character") is.character(z) else is.numeric(z),logical(1))
  if(!all(ok)) .pr_abort("incorrect JSON array element type", "invalid_json_type",path)
  if(!length(x)) return(if(mode=="character") character() else numeric())
  unlist(x,use.names=FALSE)
}

.pr_json_bind_matrix <- function(x,rows,cols,dimnames,path) {
  if(!is.list(x)||length(x)!=rows) .pr_abort("matrix row count differs from shape", "invalid_shape",path)
  if(!is.null(dimnames) && !identical(as.integer(lengths(dimnames)),as.integer(c(rows,cols))))
    .pr_abort("matrix dimnames differ from declared shape","invalid_shape",path)
  converted <- vector("list",length(x))
  for(i in seq_len(rows)) {
    row <- .pr_json_vector(x[[i]],"numeric",paste0(path,"[",i,"]"))
    if(length(row)!=cols) .pr_abort("matrix column count differs from shape", "invalid_shape",path)
    converted[[i]] <- row
  }
  out <- matrix(NA_real_,rows,cols,dimnames=dimnames)
  for(i in seq_len(rows)) out[i,] <- converted[[i]]
  out
}

.pr_json_bind_payload <- function(x) {
  for(f in intersect(c("entity_ids","criterion_ids"),names(x))) x[[f]] <- .pr_json_vector(x[[f]],path=paste0("$.",f))
  bind_draws <- function(block, tensor=FALSE) {
    slot <- if(tensor) "tensor" else "matrix"; z <- block[[slot]]
    z$axis_order <- .pr_json_vector(z$axis_order)
    for(f in names(z$dimnames)) z$dimnames[[f]] <- .pr_json_vector(z$dimnames[[f]])
    z$dimnames <- z$dimnames[if(tensor)c("draw","entity","criterion") else c("draw","entity")]
    dims <- unlist(z$shape,use.names=FALSE)
    if(any(!is.finite(dims))||any(dims!=floor(dims))||any(dims<1)||any(dims>.Machine$integer.max))
      .pr_abort("invalid serialized dimensions", "invalid_shape")
    if(tensor) {
      if(length(z$values)!=z$shape$S) .pr_abort("tensor draw count differs from shape", "invalid_shape")
      if(!identical(as.integer(lengths(z$dimnames)),as.integer(c(z$shape$S,z$shape$n,z$shape$K))))
        .pr_abort("tensor dimnames differ from declared shape","invalid_shape")
      for(s in seq_len(z$shape$S)) {
        if(length(z$values[[s]])!=z$shape$n || any(lengths(z$values[[s]])!=z$shape$K))
          .pr_abort("tensor nested dimensions differ from declared shape","invalid_shape")
      }
      out <- array(NA_real_,c(z$shape$S,z$shape$n,z$shape$K),dimnames=z$dimnames)
      for(s in seq_len(z$shape$S)) out[s,,] <- .pr_json_bind_matrix(z$values[[s]],z$shape$n,z$shape$K,NULL,"$.joint_draws.tensor.values")
      z$values <- out
    } else z$values <- .pr_json_bind_matrix(z$values,z$shape$S,z$shape$n,z$dimnames,"$.criterion_blocks.matrix.values")
    block[[slot]] <- z
    for(c in seq_along(block$sampling$chain_history)) {
      for(f in c("retained_iterations","warmup_iterations","discarded_sampling_iterations"))
        block$sampling$chain_history[[c]][[f]] <- .pr_json_vector(block$sampling$chain_history[[c]][[f]],"numeric")
    }
    block
  }
  if(!is.null(x$joint_draws)) x$joint_draws <- bind_draws(x$joint_draws,TRUE)
  if(!is.null(x$criterion_blocks)) x$criterion_blocks <- lapply(x$criterion_blocks,bind_draws)
  if(!is.null(x$finite_law)) for(s in seq_along(x$finite_law$states))
    x$finite_law$states[[s]]$theta <- .pr_json_bind_matrix(x$finite_law$states[[s]]$theta,length(x$entity_ids),length(x$criterion_ids),list(entity=x$entity_ids,criterion=x$criterion_ids),"$.finite_law.states.theta")
  x
}

.pr_json_unbind_payload <- function(x) {
  for(f in c("entity_ids","criterion_ids")) x[[f]] <- as.list(unname(x[[f]]))
  unbind_draws <- function(block,tensor=FALSE) {
    slot <- if(tensor) "tensor" else "matrix"; z <- block[[slot]]
    z$axis_order <- as.list(unname(z$axis_order))
    z$dimnames <- lapply(z$dimnames,function(ids) as.list(unname(ids)))
    a <- z$values
    z$values <- if(tensor) lapply(seq_len(dim(a)[1L]),function(s) lapply(seq_len(dim(a)[2L]),function(i) as.list(unname(a[s,i,])))) else lapply(seq_len(nrow(a)),function(i) as.list(unname(a[i,])))
    block[[slot]] <- z
    for(c in seq_along(block$sampling$chain_history))
      for(f in c("retained_iterations","warmup_iterations","discarded_sampling_iterations"))
        block$sampling$chain_history[[c]][[f]] <- as.list(unname(block$sampling$chain_history[[c]][[f]]))
    block
  }
  if(!is.null(x$joint_draws)) x$joint_draws <- unbind_draws(x$joint_draws,TRUE)
  if(!is.null(x$criterion_blocks)) x$criterion_blocks <- lapply(x$criterion_blocks,unbind_draws)
  if(!is.null(x$finite_law)) for(s in seq_along(x$finite_law$states)) {
    a <- x$finite_law$states[[s]]$theta
    x$finite_law$states[[s]]$theta <- lapply(seq_len(nrow(a)),function(i) as.list(unname(a[i,])))
  }
  x
}

#' Read Posterior Draws or an Exact Finite Law from JSON
#'
#' The reader imports a saved posterior input, including its target
#' definitions, ordered IDs and original sampling history. Files in this format
#' are produced by [write_postrank_draws()].
#'
#' @param path Path to an existing `applied-0.1` JSON file.
#' @return A validated `postrank_draws` object from [as_postrank_draws()].
#'   Invalid JSON or unsupported input raises a structured error.
#' @details
#' The reader supports joint equal-weight draws, criterion-wise blocks and
#' complete exact finite laws. It preserves the singleton criterion dimension
#' for `K = 1` and does not orient, reorder or round supplied targets.
#' Duplicate decoded JSON keys, invalid JSON numbers and malformed supported
#' array shapes are rejected. Exact-law integer tokens are checked before
#' conversion so that unsafe values cannot pass by floating-point rounding.
#'
#' Supported JSON shape checks and R semantic checks are performed; this is
#' not a general JSON Schema validation. Required declarations are preserved
#' without the high-level array route's additional placeholder-text check.
#' Reading a file does not verify its scientific provenance, jointness or
#' convergence. Use [read_postrank_tie_draws()] for equality-neutral inputs;
#' this reader does not convert between the two input domains.
#' @seealso [write_postrank_draws()], [as_postrank_draws()],
#'   [validate_postrank_draws()]
#' @concept input
#' @examples
#' path <- system.file("examples", "synthetic-iid.json", package = "postrank")
#' draws <- read_postrank_draws(path)
#' draws$entity_ids
#' draws$criterion_ids
#' validate_postrank_draws(draws)$valid
#' @export
read_postrank_draws <- function(path) {
  .pr_string(path,"$.path")
  if(!file.exists(path)||dir.exists(path)) .pr_abort("JSON file does not exist","input_file_missing",path)
  text <- paste(readLines(path,warn=FALSE,encoding="UTF-8"),collapse="\n")
  node <- .pr_json_scan(text); schema <- .pr_serialization_schema()
  .pr_json_shape_guard(node,schema,schema)
  x <- tryCatch(jsonlite::fromJSON(text,simplifyVector=FALSE),error=function(e) .pr_abort(conditionMessage(e),"invalid_json"))
  as_postrank_draws(.pr_json_bind_payload(x))
}

#' Save a Posterior Input as JSON
#'
#' The writer saves posterior values and their scientific descriptions in the
#' format read by [read_postrank_draws()]. The input is validated before
#' writing, and its declared entity, criterion and draw order is preserved.
#'
#' @param x A `postrank_draws` or complete canonical `applied-0.1` payload.
#' @param path Destination JSON file. Its parent directory must exist.
#' @param overwrite Logical; allow replacement of an existing file.
#'   Defaults to `FALSE`.
#' @return The destination path, invisibly.
#' @details
#' Joint arrays, criterion-wise blocks and complete exact finite laws are
#' supported. Values are written with 17 significant digits, retaining
#' singleton dimensions and source sampling histories. The writer creates a
#' temporary file in the destination directory and renames it into place.
#'
#' The file contains the canonical input, not a saved validation receipt or
#' external source-value audit. Reading it performs validation again; a
#' prior adapter's source-value comparison is not claimed merely because the
#' file round-trips. Required declaration checks apply without the high-level
#' array route's extra placeholder check. Use [write_postrank_tie_draws()] for
#' an equality-neutral input.
#' @seealso [read_postrank_draws()], [validate_postrank_draws()],
#'   [as_postrank_posterior()]
#' @concept input
#' @examples
#' path <- tempfile(fileext = ".json")
#' write_postrank_draws(postrank_toy, path)
#' restored <- read_postrank_draws(path)
#' identical(restored$joint_draws$tensor$values,
#'   postrank_toy$joint_draws$tensor$values)
#' identical(restored$joint_draws$draw_index, postrank_toy$joint_draws$draw_index)
#' unlink(path)
#' @export
write_postrank_draws <- function(x,path,overwrite=FALSE) {
  .pr_string(path,"$.path")
  .pr_assert(is.logical(overwrite)&&length(overwrite)==1L&&!is.na(overwrite),"overwrite must be TRUE or FALSE")
  if(file.exists(path)&&!overwrite) .pr_abort("output already exists; set overwrite=TRUE explicitly","output_exists",path)
  if(!dir.exists(dirname(path))) .pr_abort("output directory does not exist","output_directory_missing",path)
  payload <- .pr_payload(as_postrank_draws(x))
  tree <- .pr_json_unbind_payload(payload)
  text <- as.character(jsonlite::toJSON(tree,auto_unbox=TRUE,null="null",na="null",digits=17,pretty=TRUE))
  node <- .pr_json_scan(text); schema <- .pr_serialization_schema()
  .pr_json_shape_guard(node,schema,schema)
  temp <- tempfile(".postrank-json-",tmpdir=dirname(path)); on.exit(unlink(temp),add=TRUE)
  writeLines(text,temp,useBytes=TRUE)
  if(!file.rename(temp,path)) .pr_abort("atomic JSON file replacement failed","output_write_failed",path)
  invisible(path)
}
