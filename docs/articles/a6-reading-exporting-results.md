# Reading and exporting results

An analysis result records grade membership, disclosed and withheld
pairs, expected loss and the numerical evidence for optimality. These
components have distinct interpretations and should remain associated
when results are exported. We describe the console summaries and result
tables, followed by formats for retaining an analysis or producing a
readable report.

The examples use the six fictional sites in [Analysis with one or
several
criteria](https://joonho112.github.io/postrank/articles/a1-getting-started.md).
Their normal score distributions are specified, with larger scores
receiving higher priority. The first analysis uses one criterion and the
second adds a criterion for the same sites. The prepared results below
require neither optimization nor model fitting during rendering.

``` r

library(postrank)
sites <- pr_tutorial
```

The objects `one` and `two` are prepared analyses corresponding to the
calls in the introductory analysis. The same inspection and export
functions apply to other analyses returned by
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md).

## Console output and interpretation

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

The initial display gives the numbers of entities and grades, disclosed
and withheld pair counts, and computation status. Grade 1 has highest
priority; a shared grade withholds a comparison without declaring score
equality. Since the reported loss depends on the weights, withholding
cost and permitted grades, these settings are part of the interpretation
of any exported risk.

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

The summary adds settings, criterion-specific results, bounds and
recorded warnings. Monte Carlo fragility is unsupported here because the
input specifies an analytic normal law rather than target draws. An
unsupported diagnostic differs from one that was available but not
requested. Neither state implies a zero value, and the summary does not
calculate missing results.

The first prepared solve includes a small floating-point correction to
its lower bound. The summary retains the warning despite a zero reported
gap after correction. Further source records and identifiers are
available by requesting detailed output:

``` r

detailed <- summary(one, details = TRUE)
```

Printing `detailed` displays the additional records identifying the
input and computation. Numerical extraction uses the accessors below
rather than parsing the console representation.

## Grade and report-card tables

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

The default table has two columns: character `entity_id` and integer
`grade`. Rows follow the original input order. A fit, its enclosing
analysis, and a score-cut baseline use this same basic form. Optional
report cards do not change the default columns.

``` r

identical(grade_table$entity_id, sites$one$entity_ids)
#> [1] TRUE
identical(grade_table, as.data.frame(one$fit))
#> [1] TRUE
```

The `entity_id` column provides the key for joining results to other
tables. Row numbers and potentially changing display names do not serve
this role. A separately sorted copy may be used for presentation while
the original table retains its correspondence with input order.

The report-card table is requested explicitly:

``` r

card <- as.data.frame(one, what = "report_card")
knitr::kable(card[c("entity_id", "grade", "mean_score_A",
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

The table contains prepared score means and 90% equal-tail marginal
intervals under the specified normal law. These describe score
uncertainty rather than uncertainty in grade labels. Expected ranks and
disclosed and withheld comparison counts are also included. Selection by
column name avoids dependence on column positions.

Report-card rows are ordered by grade and their recorded secondary
order. That can differ from input order, as the two-criterion example
shows:

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

If a report card was not prepared, `what = "report_card"` reports the
reason for its absence, while the ordinary grade table may remain
available. Pairwise probabilities can suffice for grading without
identifying marginal intervals. Supplied intervals retain their original
level, such as the 95% intervals in the [Alabama
case](https://joonho112.github.io/postrank/articles/a4-alabama-opportunity.md).
Table conversion neither creates missing summaries nor changes an
interval’s level.

For code written before version 1.0, the explicit `what = "report_card"`
replaces the former behavior in which an analysis could return its full
card by default. The default table therefore retains the two-column
structure described above.

## Grades, pair relations and loss

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

The grade vector is named by entity ID. In the relation matrix, `[i, j]`
is 1 if row entity `i` is disclosed above column entity `j`, −1 for the
reverse direction and 0 for withholding. The diagonal is zero. Thus A
versus B is withheld and A is disclosed above C. Matrix entries
represent reporting decisions rather than posterior probabilities.

``` r

profile <- get_profile(one)
knitr::kable(profile[c("criterion", "weight", "E", "E_over_M",
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

`E` is the posterior expected number of wrong-direction comparisons
among the disclosed pairs. `E_over_N` divides by the number of disclosed
pairs; `E_over_M` divides by all possible pairs. The criterion’s `risk`
also includes the cost of withholding. For this one-criterion example,
the criterion loss and the overall loss are the same:

``` r

N <- sum(relations[upper.tri(relations)] != 0L)
M <- choose(length(grades), 2)
loss_from_parts <- (profile$E + one$settings$tau * (M - N)) / M
c(from_parts = loss_from_parts, stored = risk$risk)
#> from_parts     stored 
#> 0.04165164 0.04165164
```

For several criteria, `get_profile(two)` returns one row per criterion;
equal weights can yield different error rates.
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
returns a list containing `risk`, `lower_bound`, `gap` and `status`. The
risk is the primary objective of the specified problem: a weighted
average of criterion losses in these examples, or a worst-criterion
objective in minimax analyses. Comparison of reported losses therefore
requires their objective definitions.

For the same one-criterion input, the following calculation evaluates
the fixed action withholding every pair, without a new optimization:

``` r

withheld <- postrank_evaluate(
  setNames(rep(1L, length(grades)), names(grades)), sites$one,
  weights = c(score_A = 1), tau = one$settings$tau
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

Since no comparisons are disclosed, `E_over_N` is `NA` and the loss
equals the withholding cost. This is a valid grading with an undefined
error proportion, distinct from a computation that returned no valid
grade vector.

## Computation status and numerical results

The prepared examples have `optimal` status. In other analyses,
computation may terminate before establishing optimality. Whether
validated grades exist must also be considered when interpreting status.
The table describes possible states; it does not report additional
solver executions.

| Recorded state | Interpretation |
|----|----|
| `optimal`, with validated grades | Optimal within the recorded solver tolerances. The bound, gap and any numerical warnings provide the accompanying numerical evidence. |
| `feasible_not_certified`, with validated grades | A usable grading was found, but the available bound or gap does not establish the requested optimality. |
| `time_limit`, with validated grades | The time limit was reached; the stored grading can be read and evaluated, with its remaining gap or missing bound disclosed. |
| `time_limit`, without validated grades | There is no grading to interpret. The termination status and any usable lower bound can still be reported. |
| `infeasible` | The solver reports that the requested constraints cannot be satisfied. This is not a one-grade, all-withheld result. |

Results with `numerical_error`, `unknown` or an unexpected `unbounded`
status require examination of recorded warnings and validation details
before an action is used. Normalized status records the package’s
interpretation separately from the backend message. A gap quantifies
optimization uncertainty conditional on the supplied probabilities,
rather than posterior uncertainty about a population quantity.

In the absence of validated grades,
[`get_grades()`](https://joonho112.github.io/postrank/reference/get_grades.md)
and
[`get_relations()`](https://joonho112.github.io/postrank/reference/get_relations.md)
return `NULL`. The basic table and criterion profile have zero rows with
their usual columns.
[`get_risk()`](https://joonho112.github.io/postrank/reference/get_risk.md)
retains status and any usable lower bound, whereas action risk and gap
are `NA`. An empty result thus requires interpretation of the recorded
status; assigning all entities to grade 1 would introduce an action that
the computation did not return.

## Tabular export and object storage

CSV stores tabular output, whereas RDS retains the complete R object,
including settings, summaries and computation records. The examples use
a new temporary directory to avoid overwriting existing files:

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

A character ID column preserves leading zeros in identifiers such as
`"01001"`, and `row.names = FALSE` omits an additional row-index column.
Interval definitions, settings and solver status must be exported
separately when CSV is used for a report table.

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

Reading the RDS restores the prepared object without rerunning the
optimizer. Reproducibility additionally requires the package version and
source input. RDS is an R object format whose compatibility with every
future software version cannot be assumed.

## Standalone HTML reports

Supplying a fit together with its matching analysis includes the
prepared posterior report card alongside grades, loss, status and
available diagnostics:

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

The English HTML report embeds its figures for offline reading and uses
stored results throughout. Missing intervals or diagnostics retain their
recorded reasons for unavailability. An existing destination is refused,
so each saved version requires a new filename. Setting `figures = FALSE`
produces text and tables without embedded figures.

The temporary directory persists for the current R session. Longer-term
storage requires a new destination within the project. RDS retains the
analysis for subsequent R use, HTML provides a readable report and CSV
provides selected tables for other software.

Figure dimensions, labels and entity selection are described in [Figures
and sensitivity
analysis](https://joonho112.github.io/postrank/articles/a7-figures-sensitivity.md).
Input assumptions are discussed in [Analysis of supplied posterior
results](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md).

[Computing grades and choosing
settings](https://joonho112.github.io/postrank/articles/m5-computing-grades.md)
develops the meaning of solver bounds and admissible reports. [Monte
Carlo uncertainty and
diagnostics](https://joonho112.github.io/postrank/articles/m6-uncertainty-diagnostics.md)
covers the distinct numerical uncertainty in the posterior inputs.
