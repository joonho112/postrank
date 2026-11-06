# Plot Criterion-Wise Error Rates or Risk

The figure displays criterion-specific expected directional-error rates
or risks for the stored grading. Each criterion is represented by one
point. Point area indicates a positive criterion weight; zero-weight
criteria are retained as small hollow points.

## Usage

``` r
postrank_plot_profile(
  x,
  show = c("E_over_N", "E_over_M", "risk"),
  budgets = TRUE,
  ...,
  criterion_labels = NULL
)
```

## Arguments

- x:

  A `postrank_fit` or `postrank_analysis` with a stored evaluation.

- show:

  `"E_over_N"` for expected errors per disclosed pair; `"E_over_M"` for
  expected errors per all unordered pairs; or `"risk"` for criterion
  risk, including the cost of withholding.

- budgets:

  Logical; show available error-budget ticks for `show = "E_over_N"`.

- ...:

  Unused.

- criterion_labels:

  Optional partial named character vector mapping raw criterion IDs to
  display names. Text is wrapped; IDs and numerical plot data remain
  unchanged. Supply this argument by name.

## Value

A `ggplot` object. Without a validated incumbent, it is a status panel.
When `N = 0`, the `E_over_N` view explains that the ratio is undefined
and omits the corresponding point.

## Details

`E_k` is the stored expected number of wrong-direction comparisons on
criterion `k`, `N` counts disclosed pairs, and `M = choose(n, 2)` counts
all unordered pairs. These are posterior expectations for the selected
action, not observed error counts. Withholding is not a claim of
equality.

For `E_over_N`, a declared budget `q_k` appears as a tick connected to
its criterion's point. For `risk`, a dashed line marks `tau`, the
ordinary all-withheld risk. In minimax mode, orange rings identify
criteria attaining the largest criterion risk. All axes begin at zero.
The figure reads the stored evaluation without selecting a new grade or
recomputing its risk.

## See also

[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
[`postrank_plot_data()`](https://joonho112.github.io/postrank/reference/postrank_plot_data.md),
[`postrank_plot_frontier()`](https://joonho112.github.io/postrank/reference/postrank_plot_frontier.md)

## Examples

``` r
# Read prepared tutorial results; no model fitting or optimization.
source(system.file("scripts", "_vignette-setup.R", package = "postrank"),
  local = TRUE)
one <- load_or_compute("tutorial_one")
postrank_plot_profile(one)

two <- load_or_compute("tutorial_two")
postrank_plot_profile(two, show = "E_over_M",
  criterion_labels = c(score_A = "Score A", score_B = "Score B"))
```
