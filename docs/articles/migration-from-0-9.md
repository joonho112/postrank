# Moving from the earlier 0.9 interface

The current version retains the posterior loss and strict input
definitions of the earlier 0.9 interface. The changes concern
one-criterion analyses, result extraction and presentation. This article
describes their implications for existing scripts, using stored results
without further optimization. The candidate has not been published.

## Result tables

`as.data.frame(analysis)` now returns exactly `entity_id` and `grade` in
input entity order. This stable table supports joins and exports. The
row order is not a ranking: grade 1 has highest priority, and rows in
the same grade have their comparison withheld.

``` r

as.data.frame(one)
#>   entity_id grade
#> 1         A     1
#> 2         B     1
#> 3         C     2
#> 4         D     2
#> 5         E     3
#> 6         F     3
```

Posterior means, interval endpoints and relation counts are available
through an explicit request for the report card:

``` r

card <- as.data.frame(one, what = "report_card")
names(card)
#>  [1] "entity_id"             "grade"                 "sort_rank"            
#>  [4] "n_above"               "n_below"               "n_withheld"           
#>  [7] "mean_score_A"          "lower_score_A"         "upper_score_A"        
#> [10] "expected_rank_score_A"
```

The report card retains the row order and columns used for reporting.
Its intervals are marginal posterior intervals for the targets, not
uncertainty intervals for grade assignments. The interval level and
source are recorded in `one$report_card`. An input carrying supplied
intervals cannot reconstruct other levels; CDE and KRW provide 90%,
while Alabama provides 95%.

The two table forms can be exported separately:

``` r

write.csv(as.data.frame(two), "grades.csv", row.names = FALSE)
write.csv(as.data.frame(two, what = "report_card"),
  "report-card.csv", row.names = FALSE)
```

## One-criterion and multiple-criterion weights

For a one-criterion
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
analysis, the weight defaults to one and may be omitted. This default
applies to the one-call analysis. Lower-level functions such as
[`postrank_problem()`](https://joonho112.github.io/postrank/reference/postrank_problem.md)
and
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md)
still take the weights their signatures require.

``` r

one <- postrank(pr_tutorial$one, tau = .2, G_max = 3L, backend = "highs")
two <- postrank(pr_tutorial$two,
  weights = c(score_A = .5, score_B = .5), tau = .2, G_max = 3L,
  backend = "highs")
```

Both tutorial inputs retain the same six sites and the same score-A law.
The two-criterion call changes the decision loss by adding score B. Loss
weights are declared preferences, not empirical reliability weights.
Typed settings provide a reusable policy specification. The policy is
supplied through either `settings` or the corresponding separate
arguments; conflicting specifications are rejected.

## Computational controls and status

The default backend remains Gurobi. An explicit `backend` argument takes
precedence over the `postrank.backend` option. If the option is unset,
Gurobi is used. HiGHS is an explicit alternative, and an unavailable
selection does not trigger a fallback.

Progress messages are suppressed by default. A control with
`verbose = NULL` reads `postrank.verbose` when solving; explicit `TRUE`
or `FALSE` overrides the option. This affects progress messages, not
numerical controls or results. The separate `output` control governs
solver output.

``` r

quiet <- postrank_control(verbose = FALSE)
fit <- postrank(pr_tutorial$one, tau = .2, G_max = 3L,
  backend = "highs", control = quiet)
```

An ordinary fit is characterized by its validated grade, normalized
status and numerical bound. A backend’s optimal label is qualified as
feasible but uncertified when a usable lower bound or sufficiently small
gap is missing. Raw status is retained. A time limit remains a
time-limit status; a missing incumbent remains missing and is not
replaced with an all-withheld grade.

Withholding every pair is a feasible action in an ordinary at-most-G
problem. It has risk `tau` and no defined `E/N` because `N = 0`. An
all-withheld grading is therefore distinguishable from a failed
optimization with no validated action.

## Display settings

Report-card plots now limit the default display to 30 rows, spreading
the selection across occupied grades. An explicit entity selection can
show more. Display labels are separate from stable entity IDs. Mean
ordering requires a single displayed criterion or an explicit `order_by`
naming the criterion that defines the order, on the plot or when
preparing a card.

``` r

postrank_plot_report_card(two, max_rows = 6L, ncol = 1L)
postrank_plot_report_card(two, entities = pr_tutorial$units$entity_id,
  entity_labels = c(A = "Site Alpha"), ncol = 1L)
postrank_plot_report_card(one, order = "mean")
postrank_plot_report_card(two, order = "mean", order_by = "score_A")
```

The plotting functions use prepared results. Pairwise-probability plots
show the stored directional-error matrix; they do not estimate new
probabilities.
[`postrank_plot_data()`](https://joonho112.github.io/postrank/reference/postrank_plot_data.md)
returns the underlying tables for further analysis without applying the
plot’s display selection. See the [figure
gallery](https://joonho112.github.io/postrank/articles/figure-gallery.md)
and [Figures and sensitivity
analysis](https://joonho112.github.io/postrank/articles/a7-figures-sensitivity.md).

The exported `format_postrank_*_cli()` wrappers remain supported and
match [`format()`](https://rdrr.io/r/base/format.html) with the same
arguments. The call `format(x, width = 72, tier = 2)` returns reusable
text, whereas accessors provide values for calculations.
`summary(x, details = TRUE)` includes the detailed stored summary fields
in its console display. The console display does not define a schema for
extracting values programmatically.

## Supplied comparison probabilities

[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
accepts already calculated tie-free pairwise probabilities with an
explicit event, zero-tie declaration, zero margin, conditioning, target
descriptions and source kind. It keeps raw values and any permitted
numerical correction. Optional means and intervals must refer to those
same oriented targets. These inputs do not provide a sample size, ESS,
MCSE or integration-error certificate.

Its initial decision scope is weighted at-most-G, including fixed-order
cuts. Native Gaussian and mixture problems have the same decision scope,
although their fixed-order cuts also accept an exact grade count. Draw
inputs support additional validated modes. The help for each operation
specifies the available modes, which cannot be inferred from the
coefficient dimensions alone.

Genuine equality uses the separate `postrank_tie_*` domain and its
capability record. It does not reinterpret ordinary objects. Its strict
wrong-event and distinct-event withholding loss can have all-withhold
risk R0 below `tau`; raw disclosure and distinct-opportunity ratios have
different denominators. Tie-aware fits also qualify a raw optimal label
when the usable bound is missing or its gap is too wide. Their
relative-gap scale uses the action risk minus R0, preserving that
separate loss offset. See [True ties and withheld
comparisons](https://joonho112.github.io/postrank/articles/m4-ties-and-withholding.md).

## Historical inputs and result provenance

The definitions of earlier strict constructors, schemas and scientific
payload identities are unchanged. Declaration checks do not
retrospectively establish the validity of, or modify, the scientific
statements attached to an older object. Existing result views represent
absent historical information as unavailable. A new calculation is
required for quantities that were not stored.

Prepared documentation assets are tied to their generating package
version and source manifest. Reading an asset does not alter its
provenance. Source changes require regeneration of the affected assets
through the builder. This is separate from the archived research results
inside case objects: their producer versions remain historical facts.

The three case-study inputs retain their individual source conditions
and attribution. The CDE input preserves its source identification, KRW
retains the source’s CC-BY-NC notice with no license version
substituted, and Alabama retains CC BY 4.0 attribution and change
notices. The code license does not override these third-party source
conditions.

## Earlier articles

The three earlier articles, `quickstart`, `inputs-and-producers` and
`baselines-and-the-cost-of-a-common-grade`, retain their distinct
examples and link to the Applied and Methods series where appropriate.
[Getting
started](https://joonho112.github.io/postrank/articles/a1-getting-started.md)
introduces the current interface; the Applied and Methods series provide
further practical and methodological detail.
