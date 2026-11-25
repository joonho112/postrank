% Please edit documentation in R/mdomain-family.R
\name{postrank_mdomain_family}
\alias{postrank_mdomain_family}
\title{Build a Candidate Family of Multidomain Grade Profiles}
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

\item{columns}{Optional named list in exact domain order, where each domain
entry is a list of numeric grade vectors named in exact unit order. Grade
labels are canonicalized to \verb{1..G} and duplicate columns are removed; a
supplied column that splits a structural equality class or exceeds
\code{max_grades} stops with an error.}

\item{order}{\code{"posterior_mean"} (ranks units on each domain by decreasing
exact state-weighted mean, breaking ties by UTF-8 unit ID and recording
\code{sample_adaptive = TRUE}), a domain-ordered named list of unit-ID
permutations, or \code{NULL} (the default, which adds no ordered-partition
columns beyond all-withheld and \code{columns}).}

\item{cuts}{Optional domain-ordered named list of distinct integer cut
positions in \verb{1..(n - 1)} between consecutive units along \code{order}. Requires
non-\code{NULL} \code{order}; no cut positions are guessed when \code{cuts} is \code{NULL}.}

\item{max_grades}{Positive integer scalar or domain-ordered integer vector
capping the number of occupied grades per domain (\code{NULL} allows up to \code{n}
grades).}

\item{max_actions}{Positive integer cap (\code{100000L} by default) on the exact
Cartesian product size across domains, checked in \code{gmp} integer arithmetic
before any bank is materialized. Each domain also enforces a hard limit of
\verb{1,000} raw supplied \code{columns} and \verb{1,000} deduplicated bank entries;
exceeding any cap stops with an error without truncating the family.}
}
\value{
A \code{postrank_mdomain_family} list wrapping the domain banks,
\code{input_id}, \code{source_input_hash}, \code{family_hash}, \code{provenance}, and exact
candidate-count records in \code{receipts} (including \code{receipts$preflight} and
\code{product_size_exact}).
}
\description{
\code{postrank_mdomain_family()} builds a bank of candidate grade vectors for each
domain and defines their Cartesian product as the candidate set for
\code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}}. Every domain bank automatically includes the
single-grade all-withheld column (\code{1} for all units), and equal grades within
a domain leave a pair unordered. Requires optional package \code{gmp}.
}
\details{
Structural equality classes (\code{input$equality_classes}) apply on every domain,
including zero-weight domains: cut positions that would split an equality
class are skipped automatically (\code{blocked_cuts}), whereas externally supplied
\code{columns} that split a class are rejected. When \code{order = "posterior_mean"},
the candidate family depends on the same supplied states later used by
\code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}}, which is recorded in \code{provenance} without
claiming out-of-sample validation or numerical guarantees.
}
\examples{
\dontshow{if (requireNamespace("gmp", quietly = TRUE)) withAutoprint(\{ # examplesIf}
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
fam <- postrank_mdomain_family(
  inp,
  order = "posterior_mean",
  cuts = list(need_A = 1:2, need_B = 1:2),
  max_grades = 3L
)
fam$receipts$product_size_exact
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=postrank_mdomain_input]{postrank_mdomain_input()}}, \code{\link[=postrank_mdomain_solve]{postrank_mdomain_solve()}},
\code{\link[=postrank_mdomain_decision]{postrank_mdomain_decision()}}
}
\concept{multidomain}
