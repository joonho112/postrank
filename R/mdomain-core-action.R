# Standalone action normalization for the local P2 reference engine.
# Numeric label order encodes report priority: smaller grade means higher.
# This function validates supplied reporting guards, not their scientific provenance.
p2_validate_action <- function(grades, unit_ids, domain_ids,
                               equality_classes = NULL, grade_caps = NULL,
                               canonicalize = TRUE) {
  fail <- function(message) stop(message, call. = FALSE)
  with_names <- function(x, labels) { names(x) <- labels; x }
  ids <- function(x, size, label) {
    if (!is.character(x) || !is.null(dim(x)) || length(x) != size ||
        anyNA(x) || any(!nzchar(trimws(x))) || anyDuplicated(x)) {
      fail(paste0(label, " must be unique nonempty character IDs of length ", size))
    }
    unname(x)
  }
  if (!is.matrix(grades) || !is.numeric(grades) ||
      !typeof(grades) %in% c("integer", "double")) {
    fail("grades must be a finite numeric matrix; character labels require an explicit order mapping")
  }
  n <- nrow(grades)
  D <- ncol(grades)
  if (n < 2L || D < 1L) fail("grades require n >= 2 and D >= 1")
  if (anyNA(grades) || any(!is.finite(grades))) fail("grades must contain only finite numeric values")
  if (!is.logical(canonicalize) || length(canonicalize) != 1L || is.na(canonicalize)) {
    fail("canonicalize must be one nonmissing logical value")
  }
  unit_ids <- ids(unit_ids, n, "unit_ids")
  domain_ids <- ids(domain_ids, D, "domain_ids")
  supplied_dimnames <- c(units = !is.null(rownames(grades)),
                        domains = !is.null(colnames(grades)))
  if (!is.null(rownames(grades)) && !identical(rownames(grades), unit_ids)) {
    fail("grade row names must match unit_ids exactly in declared order")
  }
  if (!is.null(colnames(grades)) && !identical(colnames(grades), domain_ids)) {
    fail("grade column names must match domain_ids exactly in declared order")
  }

  G <- matrix(0L, nrow = n, ncol = D,
              dimnames = list(unit_ids, domain_ids))
  raw_labels <- with_names(vector("list", D), domain_ids)
  K <- with_names(integer(D), domain_ids)
  for (d in seq_len(D)) {
    labels <- sort(unique(as.vector(grades[, d])))
    raw_labels[[d]] <- labels
    K[d] <- length(labels)
    if (canonicalize) {
      G[, d] <- match(grades[, d], labels)
    } else {
      if (!identical(as.numeric(labels), as.numeric(seq_len(K[d])))) {
        fail(paste0("canonicalize = FALSE requires occupied labels exactly 1..K in domain ", domain_ids[d]))
      }
      G[, d] <- as.integer(grades[, d])
    }
  }

  equality_supplied <- !is.null(equality_classes)
  if (is.null(equality_classes)) {
    equality_classes <- with_names(lapply(seq_len(D), function(d) {
      with_names(seq_len(n), unit_ids)
    }), domain_ids)
  } else {
    if (!is.list(equality_classes) || is.data.frame(equality_classes) ||
        length(equality_classes) != D ||
        !identical(names(equality_classes), domain_ids)) {
      fail("equality_classes must be a named list in exact domain_ids order")
    }
    for (d in seq_len(D)) {
      labels <- equality_classes[[d]]
      # Check names before factor conversion, which otherwise drops them.
      if (!is.null(names(labels)) && !identical(names(labels), unit_ids)) {
        fail("equality class vector names must match unit_ids exactly in declared order")
      }
      if (is.factor(labels)) labels <- as.character(labels)
      if (!is.atomic(labels) || !is.null(dim(labels)) ||
          !typeof(labels) %in% c("character", "integer", "double", "logical") ||
          is.object(labels) || length(labels) != n || anyNA(labels)) {
        fail(paste0("equality class labels must be a complete atomic vector in domain ", domain_ids[d]))
      }
      if (is.numeric(labels) && any(!is.finite(labels))) {
        fail("equality class labels must be finite")
      }
      if (is.character(labels) && any(!nzchar(trimws(labels)))) {
        fail("equality class labels must be nonempty")
      }
      # Match original numeric labels directly; string conversion could merge
      # distinct nearby floating-point class labels.
      class_index <- match(labels, unique(labels))
      for (cl in unique(class_index)) {
        if (length(unique(G[class_index == cl, d])) != 1L) {
          fail(paste0("equality guard violated in domain ", domain_ids[d]))
        }
      }
      names(labels) <- unit_ids
      equality_classes[[d]] <- labels
    }
  }

  caps_supplied <- !is.null(grade_caps)
  if (is.null(grade_caps)) {
    grade_caps <- with_names(rep.int(n, D), domain_ids)
  } else {
    if (!is.numeric(grade_caps) || !is.null(dim(grade_caps)) ||
        length(grade_caps) != D || anyNA(grade_caps) ||
        any(!is.finite(grade_caps)) || any(grade_caps < 1) ||
        any(grade_caps != floor(grade_caps))) {
      fail("grade_caps must supply one positive finite integer cap per domain; no recycling")
    }
    if (!is.null(names(grade_caps)) && !identical(names(grade_caps), domain_ids)) {
      fail("grade_caps names must match domain_ids exactly in declared order")
    }
    names(grade_caps) <- domain_ids
  }
  if (any(K > grade_caps)) fail("grade cap exceeded; no grades were merged to repair the action")

  M <- as.double(n) * (n - 1L) / 2
  pair_index <- matrix(0L, nrow = M, ncol = 2L,
                       dimnames = list(NULL, c("i", "j")))
  start <- 1L
  for (i in seq_len(n - 1L)) {
    js <- seq.int(i + 1L, n)
    positions <- seq.int(start, length.out = length(js))
    pair_index[positions, 1L] <- i
    pair_index[positions, 2L] <- js
    start <- start + length(js)
  }
  direction <- sign(G[pair_index[, 2L], , drop = FALSE] -
                    G[pair_index[, 1L], , drop = FALSE])
  storage.mode(direction) <- "integer"
  dimnames(direction) <- list(NULL, domain_ids)
  disclosed <- direction != 0L
  N <- with_names(as.integer(colSums(disclosed)), domain_ids)
  row_key <- vapply(seq_len(n), function(i) paste(G[i, ], collapse = ":"), character(1L))
  cell_number <- match(row_key, unique(row_key))
  cell_id <- with_names(paste0("profile_cell_", cell_number), unit_ids)
  common_column <- all(vapply(seq_len(D), function(d) {
    identical(G[, d], G[, 1L])
  }, logical(1L)))

  structure(list(
    G = G, n = n, D = D, unit_ids = unit_ids, domain_ids = domain_ids,
    K = K, C = as.integer(length(unique(row_key))), cell_id = cell_id,
    pair_index = pair_index, direction = direction, disclosed = disclosed,
    N = N, all_withheld = all(N == 0L), common_column = common_column,
    equality_classes = equality_classes,
    receipt = list(
      schema_version = "p2-profile-action-receipt-v1",
      canonicalize_requested = canonicalize,
      labels_changed = any(grades != G),
      raw_labels = raw_labels,
      supplied_dimnames = supplied_dimnames,
      mapping_policy = "declared order retained; present names checked exactly; no reordering",
      equality_classes_supplied = equality_supplied,
      equality_guard_status = "validated; supplied classes are not inferred from grades or posterior draws",
      equality_provenance_status = "not checked here; scientific/law compatibility belongs to input validation",
      grade_caps_supplied = caps_supplied,
      grade_caps = grade_caps,
      cell_id_semantics = "first-appearance membership identifiers; no ordinal or priority meaning",
      comparison_semantics = "+1 first unit higher; -1 second unit higher; 0 withholding, not equality",
      dependencies = "standalone; no input validator called"
    )
  ), class = c("p2_profile_action", "list"))
}
