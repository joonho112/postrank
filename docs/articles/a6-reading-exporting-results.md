# Reading and exporting grading results

A
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
result stores the assigned integer grades, the ordered and unordered
pair counts, the posterior expected loss, and the solver’s status, lower
bound, and gap. When you export a table or report, keep those policy
settings and solver records alongside the grades so a reader knows what
loss was minimized and whether the solver finished within tolerance.

Below we load the two stored tutorial results introduced in [Getting
started: grading with one or two
criteria](https://joonho112.github.io/postrank/articles/a1-getting-started.md)
using
[`postrank_example()`](https://joonho112.github.io/postrank/reference/postrank_example.md).
Reading stored results runs no solver and fits no model; the same
accessors and export functions work on any `postrank_analysis` returned
by
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md).

``` r

library(postrank)
sites <- pr_tutorial
one <- postrank_example("tutorial_one")
two <- postrank_example("tutorial_two")
```

## Console output and `summary()`

``` r

print(one)
#> <postrank_analysis>  6 entities in 3 grades (sizes 2 / 2 / 2)
#>   One criterion: score_A.
#>   Posterior loss: 0.0417.
#>   Disclosed 12 of 15 pairs (80.0%); withheld 3.
#>   Expected error among disclosed pairs: score_A 0.002.
#>   Solver: Optimal within solver tolerances.
#>   Optimization gap: 0; requested absolute gap 1e-08.
#>   Prepared: report card.
#>   Grade 1 has highest priority; a shared grade withholds the comparison.
#>   grade 1 (2): A, B
#>   grade 2 (2): C, D
#>   grade 3 (2): E, F
#>   !  1 warning recorded: Reported lower bound exceeded the validated action ris...
#>   i summary(x) explains the loss, settings and bounds; get_grades(x) returns
#>     all grades.
```

Printing `one` shows the entity and grade counts
(`6 entities in 3 grades`), the posterior loss (`0.0417`), the ordered
(“disclosed”, `12`) and unordered (“withheld”, `3`) pair counts, the
solver status and gap, and any warnings. Grade 1 is the highest
priority, and sharing a grade leaves that pair unordered without
claiming that the two sites have equal scores; see [Getting started:
grading with one or two
criteria](https://joonho112.github.io/postrank/articles/a1-getting-started.md).

``` r

summary(one)
#> <postrank_analysis_summary>
#> Result:
#>   6 entities in 3 grades (sizes 2 / 2 / 2).
#>   One criterion: score_A.
#>   Posterior loss: 0.0417.
#>   Disclosed 12 of 15 pairs (80.0%); withheld 3.
#>   Expected error among disclosed pairs: score_A 0.002.
#> Settings:
#>   Loss: the weighted average of criterion losses.
#>   At most 3 grades; fewer may be used.
#>   Withholding cost (tau): 0.2 per withheld pair.
#> Criterion results:
#>    Criterion Weight Loss   Error / disclosed
#>    score_A   1      0.0417 0.002
#> Reading the loss:
#>   Grade 1 has highest priority. A shared grade withholds that pair's comparison.
#>   Each criterion loss averages expected errors on disclosed pairs and the
#>     withholding cost over all unordered pairs.
#>   Error / disclosed uses only the disclosed pairs; it is NA when their count is
#>     zero. Tau is a loss cost, not an error-rate limit.
#> Computation:
#>   Solver: Optimal within solver tolerances.
#>   Optimization gap: 0; requested absolute gap 1e-08.
#>   Loss upper bound: 0.0417; lower bound: 0.0417.
#>   Solver: highs; elapsed time 0.339 seconds.
#>   The gap concerns optimization of the supplied probabilities. It does not
#>     measure posterior uncertainty or Monte Carlo error.
#> Optional results:
#>   Report card: available.
#>   Monte Carlo fragility: unsupported for this input.
#>   Cross-fit check: not requested.
#>   Monte Carlo diagnostics: not requested.
#> Input assumptions:
#>   Losses describe the supplied posterior and target definitions; source
#>     declarations are not independently verified.
#>   A low posterior loss does not verify the statistical model.
#> Recorded warnings:
#>   Reported lower bound exceeded the validated action risk by at most the
#>     objective tolerance; it was clamped to the action risk (absolute gap 0). This
#>     reflects floating-point rounding or solver tolerances, not a numerical
#>     certificate.
#>   i summary(x, details = TRUE) adds source records and identities; structured
#>     fields remain available.
```

`summary(one)` adds the policy settings (`weights`, `G_max`, and `tau`),
a per-criterion table, the availability of optional summaries, and the
full text of recorded warnings. Under `Optional results:`,
`"unsupported for this input"` (here for Monte Carlo fragility, which
was requested by default yet requires posterior draws rather than an
analytic normal distribution) is distinct from `"not requested"`
(meaning `FALSE` was passed before checking input support:
`crossfit = TRUE` also requires joint draws, whereas
`diagnostics = TRUE` on a normal input evaluates conditional-normal
summaries under the `"Monte Carlo diagnostics"` label). Neither label
means a value of zero, and
[`summary()`](https://rdrr.io/r/base/summary.html) never runs new
calculations.

On joint IID or MCMC draw inputs,
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
computes pairwise Monte Carlo fragility by default while leaving
cross-fitting and full trace diagnostics off unless requested. We can
inspect `extras` and `fragility$summary` on the stored 30-site,
three-criterion draw analysis (`analysis_30x3_tau35`):

``` r

a35 <- postrank_example("analysis_30x3_tau35")
do.call(rbind, lapply(a35[["extras"]], function(e) {
  data.frame(requested = e[["requested"]], available = e[["available"]],
    reason = if (is.null(e[["reason"]])) "" else e[["reason"]])
}))
#>             requested available        reason
#> report_card      TRUE      TRUE              
#> fragility        TRUE      TRUE              
#> crossfit        FALSE     FALSE not_requested
#> diagnostics     FALSE     FALSE not_requested
a35[["fragility"]][["summary"]][c("pairs", "traced", "fragile",
  "fragile_disclosed", "fragile_tied")]
#> $pairs
#> [1] 435
#> 
#> $traced
#> [1] 43
#> 
#> $fragile
#> [1] 20
#> 
#> $fragile_disclosed
#> [1] 14
#> 
#> $fragile_tied
#> [1] 6
```

A pair is flagged as fragile when its estimated weighted error in the
likelier direction is within `z = 2` Monte Carlo standard errors of
`tau`; these pairwise flags are descriptive summaries of simulation
noise and need not change the jointly chosen grades (when
`diagnostics = TRUE` or `crossfit = TRUE`, inspect `x$diagnostics` and
`x$crossfit`; see [Monte Carlo diagnostics, cross-fitting, and IID
bounds](https://joonho112.github.io/postrank/articles/m6-uncertainty-diagnostics.md)).

To add input and problem identity hashes, package and solver versions,
and source descriptions to the console summary, set `details = TRUE`. To
capture the formatted console lines as a character vector (matching the
exported `format_postrank_*_cli()` wrappers), call
[`format()`](https://rdrr.io/r/base/format.html):

``` r

detailed <- summary(one, details = TRUE)
head(format(one, width = 72, tier = 2), 4)
#> [1] "<postrank_analysis>  6 entities in 3 grades (sizes 2 / 2 / 2)"
#> [2] "  One criterion: score_A."                                    
#> [3] "  Posterior loss: 0.0417."                                    
#> [4] "  Disclosed 12 of 15 pairs (80.0%); withheld 3."
```

Printing `detailed` displays those extra provenance lines (including the
note `"Bounds are solver values; the gap is not regret"`, where regret
means excess loss relative to the best grading under the true
posterior), and `cat(..., sep = "\n")` writes captured
[`format()`](https://rdrr.io/r/base/format.html) lines to a log or file.
In scripts, extract numbers with the accessors below rather than parsing
printed console text.

## Grade tables and report-card tables

``` r

grade_table <- as.data.frame(one)
grade_table
#>   entity_id grade
#> 1         A     1
#> 2         B     1
#> 3         C     2
#> 4         D     2
#> 5         E     3
#> 6         F     3
```

By default,
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns a
two-column data frame with character `entity_id` and integer `grade` in
the original input entity order. Calling
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) on a
`postrank_analysis`, its `postrank_fit`, or a `postrank_baseline` always
returns these same two columns, whether or not a report card was
prepared:

``` r

identical(grade_table$entity_id, sites$one$entity_ids)
#> [1] TRUE
identical(grade_table, as.data.frame(one$fit))
#> [1] TRUE
```

Join results back to your own entity metadata by `entity_id` rather than
by row position or formatted display labels.

To extract the marginal posterior summaries alongside the grades,
request `what = "report_card"`:

``` r

card <- as.data.frame(one, what = "report_card")
names(card)
#>  [1] "entity_id"             "grade"                 "sort_rank"            
#>  [4] "n_above"               "n_below"               "n_withheld"           
#>  [7] "mean_score_A"          "lower_score_A"         "upper_score_A"        
#> [10] "expected_rank_score_A"
knitr::kable(card[, c("entity_id", "grade", "mean_score_A",
  "lower_score_A", "upper_score_A")], digits = 3, row.names = FALSE,
  col.names = c("Entity", "Grade", "Mean", "Interval lower", "Interval upper"))
```

| Entity | Grade |  Mean | Interval lower | Interval upper |
|:-------|------:|------:|---------------:|---------------:|
| A      |     1 |  1.20 |          0.871 |          1.529 |
| B      |     1 |  0.95 |          0.621 |          1.279 |
| C      |     2 |  0.25 |         -0.079 |          0.579 |
| D      |     2 |  0.15 |         -0.179 |          0.479 |
| E      |     3 | -0.50 |         -0.829 |         -0.171 |
| F      |     3 | -0.80 |         -1.129 |         -0.471 |

Along with `entity_id` and `grade`, `card` includes `sort_rank`, pair
counts for each entity (`n_above`, `n_below`, and `n_withheld`), and
per-criterion columns `mean_<criterion>`, `lower_<criterion>`,
`upper_<criterion>`, and `expected_rank_<criterion>` (here 90%
equal-tail marginal score intervals). If a criterion was negated at
input construction (`orientation = "lower"`), these columns remain on
that negated scale, so negating back to raw units swaps
`lower_<criterion>` and `upper_<criterion>`. Select columns by name
rather than column index. When a marginal posterior is skewed, its
posterior mean can sit outside its equal-tail interval, and report-card
tables and plots show the stored values unchanged; likewise, inputs that
carry precomputed intervals only at one level (such as 90% in
`pr_case_cde` and `pr_case_krw`, or 95% in `pr_case_alabama`) cannot
recompute other interval levels.

Rows of `as.data.frame(x, what = "report_card")` are ordered by `grade`
and then by the report card’s secondary sort rule (`sort_rank`), which
can differ from the original input order:

``` r

list(
  input_order = as.data.frame(two)$entity_id,
  report_card_order = as.data.frame(two, what = "report_card")$entity_id
)
#> $input_order
#> [1] "A" "B" "C" "D" "E" "F"
#> 
#> $report_card_order
#> [1] "A" "C" "B" "D" "E" "F"
```

If a report card could not be built (for example, when an input supplies
pairwise comparison probabilities without marginal intervals), calling
`as.data.frame(x, what = "report_card")` stops with an error explaining
why it is unavailable, while `as.data.frame(x)` still returns the
two-column grade table.

## Extracting grades, pair relations, profiles, and loss

``` r

grades <- get_grades(one)
grades
#> A B C D E F 
#> 1 1 2 2 3 3
relations <- get_relations(one)
relations[c("A", "B", "C"), c("A", "B", "C")]
#>         entity_j
#> entity_i  A  B C
#>        A  0  0 1
#>        B  0  0 1
#>        C -1 -1 0
```

[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md)
returns an integer vector named by `entity_id`.
[`get_relations()`](https://joonho112.github.io/postrank/reference/get_relations.md)
returns an `n x n` integer matrix in which entry `[i, j]` is `1` when
row entity `i` is placed in a higher-priority grade than column entity
`j`, `-1` for the opposite order, and `0` when the pair shares a grade
(or on the diagonal). Thus `[ "A", "B" ]` is `0` (left unordered) and
`[ "A", "C" ]` is `1` (`A` ordered above `C`).

``` r

profile <- get_profile(one)
knitr::kable(profile[, c("criterion", "weight", "E", "E_over_M",
  "E_over_N", "risk")], digits = 5, row.names = FALSE)
```

| criterion | weight |       E | E_over_M | E_over_N |    risk |
|:----------|-------:|--------:|---------:|---------:|--------:|
| score_A   |      1 | 0.02477 |  0.00165 |  0.00206 | 0.04165 |

``` r

risk <- get_risk(one)
risk
#> $risk
#> [1] 0.04165164
#> 
#> $lower_bound
#> [1] 0.04165164
#> 
#> $gap
#> [1] 0
#> 
#> $status
#> [1] "optimal"
```

In
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md),
`E` is the posterior expected number of wrong-direction ordered pairs on
that criterion, `E_over_N` divides `E` by the number of ordered pairs
`N`, `E_over_M` divides `E` by all `M` pairs, and `risk` adds the
unordered-pair cost `tau * (M - N) / M`:

``` r

N <- sum(relations[upper.tri(relations)] != 0L)
M <- choose(length(grades), 2)
tau <- 0.2
c(from_parts = (profile$E + tau * (M - N)) / M, stored = risk$risk)
#> from_parts     stored 
#> 0.04165164 0.04165164
```

With multiple criteria, `get_profile(two)` has one row per criterion,
while `get_risk(two)` returns a named list (`risk`, `lower_bound`,
`gap`, and `status`) for the overall objective (weighted average of
criterion losses by default, or worst-criterion loss when
`objective = "minimax"`).

You can also evaluate any fixed integer grade vector on the same input
without running a solver via
[`postrank_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_evaluate.md).
Placing every site in grade 1 leaves all pairs unordered:

``` r

withheld <- postrank_evaluate(
  setNames(rep(1L, length(grades)), names(grades)), sites$one,
  weights = c(score_A = 1), tau = 0.2
)
withheld[c("N", "E_over_N", "primary_risk")]
#> $N
#> [1] 0
#> 
#> $E_over_N
#> score_A 
#>      NA 
#> 
#> $primary_risk
#> [1] 0.2
```

Because `N` is `0`, `E_over_N` is `NA` (not `0`) and `primary_risk`
equals `tau` (`0.2`). That all-unordered report is a valid one-grade
action, which is distinct from a failed or timed-out solver run that
returned no checked grading.

## Solver status, bounds, and missing-grade states

Both stored tutorial results have status `"optimal"`. On larger problems
or tight time limits, a solver run can stop before proving optimality or
before finding any checked grading. Always read the status alongside
whether a checked grading is present (`!is.null(get_grades(x))`):

| Solver status and grading state | How to read it |
|:---|:---|
| `"optimal"`, with a checked grading | Optimal within the requested solver tolerances; check `lower_bound`, `gap`, and `warnings` for the numerical details. |
| `"feasible_not_certified"`, with a checked grading | A valid grading was found and checked, while the lower bound or gap did not reach the requested optimality tolerance. |
| `"time_limit"`, with a checked grading | Search stopped at the time limit; the stored best grading can be used and reported together with its remaining `gap` (or `NA` if no bound was obtained). |
| `"time_limit"`, without a checked grading | Search stopped before any candidate grading passed validation; there are no grades to use, though `status` and any `lower_bound` remain recorded. |
| `"infeasible"` | The requested constraints (for example, tight criterion error budgets `q` or `exact_G`) cannot be satisfied simultaneously; this is not an all-unordered grading. |

Statuses `"numerical_error"`, `"unknown"`, or `"unbounded"` indicate
solver trouble; inspect the recorded `warnings` before using any output.
As explained in [Computing grades, choosing settings, and reading solver
bounds](https://joonho112.github.io/postrank/articles/m5-computing-grades.md),
the optimization `gap` measures how close the returned grading’s loss is
to the solver’s lower bound for the supplied comparison probabilities,
not posterior uncertainty in the entity scores.

When a run finishes without a checked grading,
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md)
and
[`get_relations()`](https://joonho112.github.io/postrank/reference/get_relations.md)
return `NULL`,
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) and
[`get_profile()`](https://joonho112.github.io/postrank/reference/get_profile.md)
return zero-row data frames with their normal column names and types,
and
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
keeps `status` and any `lower_bound` while setting `risk` and `gap` to
`NA`. Never substitute `rep(1L, n)` for `NULL` grades: `NULL` means no
checked grading was returned.

## Saving CSV tables and RDS objects

Use CSV when exporting flat tables to other software, and RDS when
saving the complete `postrank_analysis` object in R with its settings,
report card, solver bounds, and warnings intact. Here we write both to a
fresh temporary folder:

``` r

export_dir <- tempfile("postrank-exports-")
dir.create(export_dir)
csv_file <- file.path(export_dir, "grades.csv")
rds_file <- file.path(export_dir, "analysis.rds")
```

``` r

write.csv(grade_table, csv_file, row.names = FALSE)
csv_again <- read.csv(csv_file,
  colClasses = c(entity_id = "character", grade = "integer"))
identical(csv_again, grade_table)
#> [1] TRUE
```

Specify `colClasses = c(entity_id = "character", grade = "integer")`
when reading CSV files back into R so leading zeros in IDs such as
`"01001"` are preserved, and `row.names = FALSE` when writing so no
extra row-number column is added. Because a CSV table drops policy
settings, interval levels, and solver status, record those alongside any
exported table.

``` r

saveRDS(one, rds_file)
restored <- readRDS(rds_file)
identical(get_grades(restored), grades)
#> [1] TRUE
identical(get_risk(restored), risk)
#> [1] TRUE
identical(as.data.frame(restored, what = "report_card"), card)
#> [1] TRUE
```

[`readRDS()`](https://rdrr.io/r/base/readRDS.html) restores the full
analysis object without calling a solver. Keep the `postrank` version
and source input alongside archived `.rds` files for long-term
reproducibility.

## Writing a standalone HTML report

[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)
writes a self-contained English HTML report from stored results without
running a solver. Note that its first argument must be the
`postrank_fit` object (`one$fit`, not `one` directly), while passing
`analysis = one` supplies the report card and any stored optional
summaries (matching diagnostics stored on `analysis` or passed via
`diagnostics =`, including
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md)
summaries and their `NA_reason` fields, are included when present;
missing summaries stay marked unavailable and are never recomputed):

``` r

html_file <- file.path(export_dir, "grades-report.html")
report <- postrank_report(one$fit, analysis = one,
  output_file = html_file, lang = "en")
report
#> <postrank_report>  Report saved as grades-report.html
#>   11 sections; 2 available figures.
#>   6 entities in 3 grades; disclosed 80.0% of pairs.
#>   Optimal within solver tolerances.
#>   !  1 warning recorded: Reported lower bound exceeded the validated action ris...
#>   i  Use output_file in postrank_report() to save the English HTML report.
basename(report$output_file)
#> [1] "grades-report.html"
```

Line 1 of `print(report)` (`Report saved as grades-report.html`)
confirms that the file was written to `output_file` (the generic footer
line mentioning `output_file` is always printed by `postrank_report`’s
console formatter). Figures are embedded directly in the HTML file for
offline viewing; set `figures = FALSE` for a smaller text-and-table
report.
[`postrank_report()`](https://joonho112.github.io/postrank/reference/postrank_report.md)
refuses to overwrite an existing `output_file`, so choose a new file
path for each saved report version, and write to a project directory
rather than [`tempfile()`](https://rdrr.io/r/base/tempfile.html) when
keeping reports across R sessions.

## Where next

- To customize the seven plot types and explore changes to `tau`,
  `G_max`, and `weights`, read [Figures and sensitivity to reporting
  settings](https://joonho112.github.io/postrank/articles/a7-figures-sensitivity.md).
- To build inputs from your own posterior draws or probability tables,
  read [Preparing your posterior draws and comparison
  probabilities](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md).
- For details on solver bounds, gaps, and Monte Carlo diagnostics, see
  [Computing grades, choosing settings, and reading solver
  bounds](https://joonho112.github.io/postrank/articles/m5-computing-grades.md)
  and [Monte Carlo diagnostics, cross-fitting, and IID
  bounds](https://joonho112.github.io/postrank/articles/m6-uncertainty-diagnostics.md).
