# New-domain strict JSON scanner. Grammar and duplicate decoded keys are checked
# before binding. Use the same JSON numeric decoder as final payload conversion:
# on some R runtimes as.numeric() overflows at a valid finite upper boundary.
# Keep the legacy scanner and its behavior untouched.
.pr_tie_json_scan <- function(text) {
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
    # Exact-law lexical checks precede any numeric conversion. The shared schema
    # guard additionally checks all other declared integer tokens before binding.
    if (startsWith(path,"$.finite_law.") && !.pr_json_safe_integer_token(token))
      .pr_abort("exact-law number is not a safe integer before floating conversion", "unsafe_integer", path)
    number <- tryCatch(withCallingHandlers(
      jsonlite::fromJSON(token, simplifyVector = FALSE),
      warning = function(w) fail("JSON numeric decoder warning rejected", path)),
      error = function(e) fail("invalid or nonfinite JSON number", path))
    if (!is.numeric(number) || length(number) != 1L || !is.finite(number))
      fail("nonfinite JSON number", path)
    if(number==0 && grepl("[1-9]",sub("[eE].*$","",token)))
      fail("nonzero JSON number underflows to zero",path)
    # jsonlite may decode the integer token -0 as integer zero. Keep its numeric
    # sign for target-byte and identity round trips, without changing values.
    if (number == 0 && startsWith(token, "-")) number <- -as.numeric(abs(number))
    list(kind="number", token=token, number=as.numeric(number))
  }
  node <- value("$"); space()
  if (at <= size) fail("trailing content or malformed number")
  node
}

# Retain strict scanner numeric values when the full JSON decoder chooses an
# integer representation (notably -0). Shape and safe-integer token guards run
# before this binding. Explicit NULL slots and object key order are preserved.
.pr_tie_json_restore_numbers <- function(x, node) {
  if (identical(node$kind, "number")) return(node$number)
  if (node$kind %in% c("object", "array")) {
    .pr_assert(is.list(x) && length(x) == length(node$children),
      "JSON decoder/scanner shape disagreement", "invalid_json")
    for (i in seq_along(node$children))
      x[i] <- list(.pr_tie_json_restore_numbers(x[[i]], node$children[[i]]))
  }
  x
}
