# Plot Disclosure, Error and Risk Across Settings

A prepared frontier is displayed over a grid of withholding costs or
error budgets. The available panels give disclosure `N/M`, criterion
error `E_k/N` and risk at each setting. The figure uses stored results
without repeating the grid calculations.

## Usage

``` r
postrank_plot_frontier(
  x,
  panels = c("disclosure", "error", "risk"),
  highlight = NULL,
  mark_uncertified = TRUE,
  ...
)
```

## Arguments

- x:

  A `postrank_frontier` with stored grid results.

- panels:

  Nonempty subset of `"disclosure"`, `"error"` and `"risk"`. Selected
  panels retain this standard display order.

- highlight:

  Optional value on the displayed horizontal axis (`tau` or the varied
  error budget), marked by a dashed line.

- mark_uncertified:

  Logical; draw rows whose recorded status is not `"optimal"` hollow.
  `FALSE` gives every available row its ordinary point style. This
  legacy argument name does not imply numerical certification.

- ...:

  Unused.

## Value

A `ggplot` object. When no selected panel has an available value, a
status panel explains the missing incumbent or undefined error rate.

## Details

`M` is the number of all unordered pairs and `N` the number disclosed.
Point shape distinguishes grade counts; criterion color and line style
identify error series. Rows without an incumbent retain their status in
the subtitle and receive no point. Lines stop at unavailable rows and at
undefined `E_k/N` when `N = 0`; a single available point has no
connecting line. Axes start at zero and adapt to the available values.

Changing `tau` changes the loss. Risks at different `tau` values
therefore do not rank policies under one shared loss. Changing an error
budget changes the feasible action family. If a budget grid contains
several `tau` values, they receive separate panel columns rather than a
common connecting line.

Disclosure is nondecreasing in `tau` for exact optima when all other
settings are fixed, but the set of disclosed pairs need not be nested.
Recorded optimal statuses and numerical gaps do not establish exact
monotonicity of the displayed actions or posterior validity. Available
statuses and gaps remain visible even when points are styled alike.

## See also

[`postrank_frontier()`](https://joonho112.github.io/postrank/reference/postrank_frontier.md),
[`postrank_plot_data()`](https://joonho112.github.io/postrank/reference/postrank_plot_data.md),
[`postrank_plot_profile()`](https://joonho112.github.io/postrank/reference/postrank_plot_profile.md)

## Examples

``` r
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
frontier <- load_or_compute("tutorial_frontier")
postrank_plot_frontier(frontier, highlight = .2)
```
