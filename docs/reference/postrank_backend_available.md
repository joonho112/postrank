# Inspect Solver Package Availability

`postrank_backend_available()` checks whether the `gurobi` or `highs` R
package is installed and passes static runtime-linkage checks, without
loading the solver namespace, running an optimization or querying a
license.

## Usage

``` r
postrank_backend_available(backend = c("gurobi", "highs"))
```

## Arguments

- backend:

  Solver package to inspect, `"gurobi"` (the default) or `"highs"`.

## Value

A `postrank_backend_availability` list containing `backend`,
`installed`, `package_path`, `wrapper_version`, `available_for_attempt`,
`runtime_check`, `license_check` and `interpretation`.

## Details

`available_for_attempt = TRUE` means the package directory was found
and, on macOS for Gurobi, no mismatch between Gurobi's linked R library
and the running R session was detected. Because no namespace is loaded
and no license or test solve is run, `available_for_attempt = TRUE` does
not confirm that a solve will succeed or that a Gurobi license is
active.

Calling this function does not change library paths or select a solver.
To use HiGHS in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
pass `backend = "highs"` or set `options(postrank.backend = "highs")`;
`postrank` never switches solvers automatically.

## See also

[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md),
[`postrank_solve()`](https://joonho112.github.io/postrank/reference/postrank_solve.md),
[postrank_options](https://joonho112.github.io/postrank/reference/postrank_options.md)

## Examples

``` r
avail <- postrank_backend_available("highs")
avail$available_for_attempt
#> [1] TRUE
avail$runtime_check$executed
#> [1] FALSE
```
