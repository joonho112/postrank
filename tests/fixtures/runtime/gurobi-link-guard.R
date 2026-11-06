# Self-contained fresh-child availability check; never loads or calls Gurobi.
args <- commandArgs(TRUE)
config <- readRDS(args[[1L]])
.libPaths(c(config$postrank_library, config$global_library), include.site = FALSE)
if (!is.null(config$source_root)) {
  core <- new.env(parent = globalenv())
  for (name in c("validate-draws-common.R", "problem-class.R", "backend-gurobi.R", "backend-availability.R"))
    sys.source(file.path(config$source_root, "R", name), core)
  availability <- get("postrank_backend_available", core)
} else {
  loadNamespace("postrank")
  availability <- getFromNamespace("postrank_backend_available", "postrank")
}
before <- isNamespaceLoaded("gurobi")
record <- availability("gurobi")
saveRDS(list(availability = record, namespace_loaded_before = before,
  namespace_loaded_after = isNamespaceLoaded("gurobi"), library_paths = .libPaths(),
  check = "Actual fresh-child global-library availability; no Gurobi namespace or solver call"), config$output)
