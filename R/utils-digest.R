# Versioned typed content encoding for tabular data digests (Chapter 14 CACHE-14,
# T-pil-01). Locale-independent: UTF-8 length-prefixed names and strings, explicit
# missing markers, little-endian fixed-width numbers. Encoding "postrank-table-v1":
#   header  "postrank-table-v1" | nrow (int32) | ncol (int32)
#   column  name (len-prefixed UTF-8) | type code (1 byte: 1 character, 2 double,
#           3 integer, 4 logical) | values
#   values  character: 0x00 for NA, else 0x01 + len (int32) + UTF-8 bytes
#           double:    0x00 for NA (any NaN), else 0x01 + 8-byte IEEE-754 LE
#           integer:   0x00 for NA, else 0x01 + int32 LE
#           logical:   one byte 0 = FALSE, 1 = TRUE, 2 = NA
.pr_table_encoding <- "postrank-table-v1"
.pr_int32 <- function(x) writeBin(as.integer(x), raw(), size = 4L, endian = "little")
.pr_lenstr <- function(x) { b <- charToRaw(enc2utf8(x)); c(.pr_int32(length(b)), b) }
.pr_encode_table <- function(df) {
  stopifnot(is.data.frame(df))
  out <- list(.pr_lenstr(.pr_table_encoding), .pr_int32(nrow(df)), .pr_int32(ncol(df)))
  for (nm in names(df)) {
    v <- df[[nm]]
    code <- if (is.character(v)) 1L else if (is.double(v)) 2L else if (is.integer(v)) 3L else if (is.logical(v)) 4L else
      stop("unsupported column type: ", nm, call. = FALSE)
    body <- switch(code,
      unlist(lapply(v, function(z) if (is.na(z)) as.raw(0L) else c(as.raw(1L), .pr_lenstr(z)))),
      unlist(lapply(v, function(z) if (is.na(z)) as.raw(0L) else c(as.raw(1L), writeBin(z, raw(), size = 8L, endian = "little")))),
      unlist(lapply(v, function(z) if (is.na(z)) as.raw(0L) else c(as.raw(1L), .pr_int32(z)))),
      as.raw(ifelse(is.na(v), 2L, as.integer(v))))
    out <- c(out, list(.pr_lenstr(nm), as.raw(code), if (is.null(body)) raw() else body))
  }
  do.call(c, out)
}
.pr_table_digest <- function(df) digest::digest(.pr_encode_table(df), algo = "sha256", serialize = FALSE)
