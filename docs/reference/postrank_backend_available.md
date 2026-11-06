# Inspect Solver Package Availability

The installed Gurobi or HiGHS package is inspected through its package
and linkage information. The inspection does not load the solver
namespace, execute an optimization or check a license.

## Usage

``` r
postrank_backend_available(backend = c("gurobi", "highs"))
```

## Arguments

- backend:

  `"gurobi"` (default) or `"highs"`.

## Value

A `postrank_backend_availability` list with `installed`, `package_path`,
`wrapper_version`, `available_for_attempt`, `runtime_check` and
`license_check`. `available_for_attempt = TRUE` means no known obstacle
was found by this inspection, not that a solve or license check
succeeded.

## Details

The inspection can identify a known macOS mismatch between Gurobi's
linked R runtime and the running R. Other runtime failures may only
become apparent when solving. It does not change library paths or select
another backend. Choose HiGHS explicitly in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md);
neither function silently replaces an unavailable backend.

## See also

[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[`postrank_control()`](https://joonho112.github.io/postrank/reference/postrank_control.md)

## Examples

``` r
availability <- postrank_backend_available("highs")
availability$available_for_attempt
#> [1] TRUE
availability$runtime_check$executed
#> [1] FALSE
```
