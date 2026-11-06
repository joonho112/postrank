# Specify a Multidomain Reporting Decision

Creates a decision recipe. Domain and unit identities, mask dimensions,
and protection rows are checked again when the recipe is bound to an
input. Smaller grade labels report higher priority; a grade tie
withholds direction.

## Usage

``` r
postrank_mdomain_decision(
  weights = NULL,
  tau = "1/10",
  scope = "all_pairs",
  q = NULL,
  t = "0",
  alpha = "1/20",
  expected = NULL,
  joint = NULL
)
```

## Arguments

- weights:

  Domain weights, or `NULL` for exactly equal weights. Named vectors
  must follow the input's domain order. Numeric weights whose total is
  within the core tolerance are normalized using their exact stored
  binary values; rational text weights must sum to exactly one. Zero
  weights are permitted and do not disable protection rows.

- tau:

  Tie loss in `(0, 1/2]`, as a scalar or a domain vector.

- scope:

  `"all_pairs"`, or a named list of symmetric binary masks with zero
  diagonals. Named masks must follow the input's unit order.

- q:

  Expected-error guard in `[0, 1]`, as a scalar or domain vector. `NULL`
  omits these guards.

- t:

  Joint exceedance threshold in `[0, 1]`, as a scalar or domain vector.
  `NULL` disables joint guards. An exceedance is strict, `F/N > t`.

- alpha:

  Joint-event probability limit in `[0, 1]`.

- expected:

  Explicit rows with `domain_id`, `scope_id`, and `q` columns. These
  override the convenience `q` rows. An empty data frame disables them.

- joint:

  Explicit rows with `domain_id`, `scope_id`, and `t` columns. These
  override the convenience `t` rows. An empty data frame disables them.

## Value

A `postrank_mdomain_decision` recipe. Validation does not certify the
scientific or sampling provenance of the input.

## Details

Convenience rows use a full-pair mask. A custom mask catalog without a
full-pair mask requires explicit rows, including an empty data frame to
disable a guard. Exact decimal/fraction strings retain their rational
value; numeric values retain their stored binary value. Joint guards
default to `t = "0"`, with `alpha = "1/20"`; expected guards default to
disabled.
