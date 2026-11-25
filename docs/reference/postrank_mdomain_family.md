# Build a Candidate Family of Multidomain Grade Profiles

`postrank_mdomain_family()` builds a bank of candidate grade vectors for
each domain and defines their Cartesian product as the candidate set for
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md).
Every domain bank automatically includes the single-grade all-withheld
column (`1` for all units), and equal grades within a domain leave a
pair unordered. Requires optional package `gmp`.

## Usage

``` r
postrank_mdomain_family(
  input,
  columns = NULL,
  order = NULL,
  cuts = NULL,
  max_grades = NULL,
  max_actions = 100000L
)
```

## Arguments

- input:

  A validated
  [`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md)
  object.

- columns:

  Optional named list in exact domain order, where each domain entry is
  a list of numeric grade vectors named in exact unit order. Grade
  labels are canonicalized to `1..G` and duplicate columns are removed;
  a supplied column that splits a structural equality class or exceeds
  `max_grades` stops with an error.

- order:

  `"posterior_mean"` (ranks units on each domain by decreasing exact
  state-weighted mean, breaking ties by UTF-8 unit ID and recording
  `sample_adaptive = TRUE`), a domain-ordered named list of unit-ID
  permutations, or `NULL` (the default, which adds no ordered-partition
  columns beyond all-withheld and `columns`).

- cuts:

  Optional domain-ordered named list of distinct integer cut positions
  in `1..(n - 1)` between consecutive units along `order`. Requires
  non-`NULL` `order`; no cut positions are guessed when `cuts` is
  `NULL`.

- max_grades:

  Positive integer scalar or domain-ordered integer vector capping the
  number of occupied grades per domain (`NULL` allows up to `n` grades).

- max_actions:

  Positive integer cap (`100000L` by default) on the exact Cartesian
  product size across domains, checked in `gmp` integer arithmetic
  before any bank is materialized. Each domain also enforces a hard
  limit of `1,000` raw supplied `columns` and `1,000` deduplicated bank
  entries; exceeding any cap stops with an error without truncating the
  family.

## Value

A `postrank_mdomain_family` list wrapping the domain banks, `input_id`,
`source_input_hash`, `family_hash`, `provenance`, and exact
candidate-count records in `receipts` (including `receipts$preflight`
and `product_size_exact`).

## Details

Structural equality classes (`input$equality_classes`) apply on every
domain, including zero-weight domains: cut positions that would split an
equality class are skipped automatically (`blocked_cuts`), whereas
externally supplied `columns` that split a class are rejected. When
`order = "posterior_mean"`, the candidate family depends on the same
supplied states later used by
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md),
which is recorded in `provenance` without claiming out-of-sample
validation or numerical guarantees.

## See also

[`postrank_mdomain_input()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_input.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md),
[`postrank_mdomain_decision()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_decision.md)

## Examples

``` r
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
#> [1] "16"
```
