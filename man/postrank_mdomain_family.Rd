% Please edit documentation in R/mdomain-family.R
\name{postrank_mdomain_family}
\alias{postrank_mdomain_family}
\title{Build a Bounded Multidomain Candidate Family}
\usage{
postrank_mdomain_family(
  input,
  columns = NULL,
  order = NULL,
  cuts = NULL,
  max_grades = NULL,
  max_actions = 100000L
)
}
\arguments{
\item{input}{A validated \code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}} object.}

\item{columns}{A list named in input domain order, each entry a list of
numeric grade vectors named in exact input unit order. Labels are
canonicalized and duplicate columns removed, preserving ties and direction.}

\item{order}{A list named in input domain order of explicit unit-ID
permutations, or the explicit choice \code{"posterior_mean"}. The latter orders
the current supplied states by decreasing weighted mean and uses unit IDs
to break ties; it is recorded as sample-adaptive. \code{NULL} generates no
ordered partitions beyond all-withheld.}

\item{cuts}{A list named in input domain order of permitted cut positions
between consecutive units. Cuts require an order; no cuts are guessed.}

\item{max_grades}{A positive integer or domain-ordered vector of grade caps.
\code{NULL} permits up to the input unit count.}

\item{max_actions}{Maximum exact product size, checked before banks are
materialized. Each domain also has a hard cap of 1,000 raw supplied columns
and 1,000 deduplicated bank entries. Exceeding a cap errors without truncation.}
}
\value{
A \code{postrank_mdomain_family} wrapping an immutable native candidate
family, source hashes, construction provenance, and exact size receipts.
}
\description{
Construct explicit domain banks and their Cartesian product description.
A tied grade withholds direction. All-withheld columns are always included.
}
\details{
Structural equality guards also apply to zero-weight domains.
Generated cuts that split an equality class are excluded; supplied columns
that split a class are rejected. Construction and evaluation refer to the
same input. External-column adaptation is not scientifically verified,
and construction receipts do not provide numerical assurance.
}
\concept{multidomain}
