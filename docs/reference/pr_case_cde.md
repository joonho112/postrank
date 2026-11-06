# Chronic Absence in a Small California School Example

A one-criterion teaching example using 12 schools from a frozen 2026
California School Dashboard chronic-absence analysis. Larger target
values mean lower chronic-absence probability: \\\theta=-p\\. The target
uses proportion units. Source attribution and documented transformations
are retained in the object and the installed DATA-NOTICE.

## Usage

``` r
pr_case_cde
```

## Format

A named list with five elements:

- input:

  A validated `postrank_probabilities` input for 12 schools and one
  criterion, with genuine posterior means and fixed 90% equal-tail
  marginal intervals for the same oriented target.

- units:

  12 rows in input order: school CDS IDs as character strings,
  chronic-absence numerators, eligible denominators, observed
  proportions, and the two selection strata. Counts are local source
  observations, not posterior estimates.

- alternatives:

  `order_32` and `order_64` are supported inputs calculated with more
  quadrature nodes per prior bin. They use the same posterior law,
  observations and supplied marginal summaries.

- reference:

  Settings and three fixed teaching actions, their risk evaluations,
  compact continuous posterior parameters, separate upstream and
  constructor corrections, quadrature diagnostics, and archived
  statewide summary rows. These are archive records rather than current
  native fits.

- provenance:

  Source-relative filenames and SHA-256 hashes, dates, selection rule,
  model conditioning, target direction, citation and historical
  source-review records. No raw CDE download is bundled.

## Source

California Department of Education, 2026 California School Dashboard
chronic absenteeism data, academic year 2025–26.
<https://www.cde.ca.gov/ta/ac/cm/chronicdatafiles.asp>. Source copyright
statement: <https://www.cde.ca.gov/re/di/cr/index.asp> (accessed
2026-10-30). Model, numerical integration and teaching selection by the
case-study authors. No CDE endorsement is implied.

## Details

The source frame contains 5,834 elementary-type, non-DASS, ALL-student
schools with usable chronic-absence counts and denominators at least 30;
charter schools remain eligible. It is not all California schools. The
teaching selection takes one school from each of four observed-rate rank
groups crossed with three denominator rank groups. Within a cell, the
lower middle school ordered by observed rate, denominator and CDS ID is
selected. The subset is deliberately spread, not a representative
statewide sample. Input order follows the rate group and then the
denominator group.

The empirical Bayes prior G was estimated on the full source frame and
remains fixed for this subset. Uncertainty is conditional on that
estimated G; uncertainty in estimating G is not propagated. The prior is
uniform within 161 continuous bins. Within a bin the posterior is a
truncated Beta(y+1,n-y+1) density, weighted by that school's posterior
bin mass. It is neither a uniform posterior within bins nor a set of
bin-center atoms. Independent school posteriors given G have zero
equality probability.

The primary comparison probabilities use 16 Gauss-Legendre nodes per
bin. Stored refinements use 32 and 64 nodes. Source integration retains
raw probabilities before correcting values outside \\\[0,1\]\\ by at
most 64 machine epsilons. The public input then applies a separate
symmetric reverse-complement correction with tolerance 1e-6. Neither a
small correction nor agreement between refinement orders is a certified
integration-error bound. No posterior draws or Monte Carlo diagnostics
are claimed.

The supplied target mean is \\-E\[p\]\\. Its 90% interval is
\\\[-q\_{.95}(p), -q\_{.05}(p)\]\\; the negative direction reverses the
endpoints. Request `level = .9` to use these intervals in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md).
Other interval levels cannot be recovered from the supplied summaries.
The retained intervals are marginal, not simultaneous.

The three sample actions withhold all comparisons or use fixed
observed-rate and posterior-mean tertiles. They have no optimization
guarantee. Archived statewide rows describe fixed-order contiguous cuts
and other baselines. Optimal cuts conditional on a declared order are
not an unrestricted statewide optimum; their independent-pair relaxation
lower bound has a separate scope. These posterior-conditioned risks do
not provide external validation. Current-probability comparisons do not
reproduce Dashboard Status-plus-Change colors or establish causal
effects. Suspension is a separate extension and is not included here.

The asset contains selected public-source IDs/counts and author-derived
numerical results, not CDE raw files or logos. The original source
attribution and historical preparation records remain in the provenance.
The installed DATA-NOTICE describes the current distribution scope. No
Creative Commons or package-code license is substituted for the CDE
source conditions.

## See also

[`vignette("a2-cde-accountability", package = "postrank")`](https://joonho112.github.io/postrank/articles/a2-cde-accountability.md),
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)

## Examples

``` r
x <- pr_case_cde
x$units
#>         entity_id chronic_absent_count eligible_count observed_rate
#> 1  30665976068399                   20            363    0.05509642
#> 2  38684786113997                   26            409    0.06356968
#> 3  30736506094718                   55            873    0.06300115
#> 4  58727516056840                   49            390    0.12564103
#> 5  30736436030639                   56            448    0.12500000
#> 6  01750936118038                  112            909    0.12321232
#> 7  19647330106427                   67            348    0.19252874
#> 8  37684520105882                  105            552    0.19021739
#> 9  36676866035711                  124            642    0.19314642
#> 10 34674216033732                   99            340    0.29117647
#> 11 19648816021687                  128            448    0.28571429
#> 12 36677106035901                  164            569    0.28822496
#>    observed_rate_group denominator_group
#> 1                    1                 1
#> 2                    1                 2
#> 3                    1                 3
#> 4                    2                 1
#> 5                    2                 2
#> 6                    2                 3
#> 7                    3                 1
#> 8                    3                 2
#> 9                    3                 3
#> 10                   4                 1
#> 11                   4                 2
#> 12                   4                 3
postrank_posterior_means(x$input, level = .9)
#>                 criterion
#> entity           negative_chronic_absence
#>   30665976068399              -0.05959043
#>   38684786113997              -0.06741062
#>   30736506094718              -0.06484309
#>   58727516056840              -0.12739063
#>   30736436030639              -0.12655681
#>   01750936118038              -0.12403027
#>   19647330106427              -0.19124897
#>   37684520105882              -0.18945586
#>   36676866035711              -0.19241127
#>   34674216033732              -0.28618836
#>   19648816021687              -0.28201593
#>   36677106035901              -0.28525081
#> attr(,"lower")
#>                 criterion
#> entity           negative_chronic_absence
#>   30665976068399              -0.08106193
#>   38684786113997              -0.08862801
#>   30736506094718              -0.07901464
#>   58727516056840              -0.15546707
#>   30736436030639              -0.15276486
#>   01750936118038              -0.14226231
#>   19647330106427              -0.22621309
#>   37684520105882              -0.21700330
#>   36676866035711              -0.21816439
#>   34674216033732              -0.32690719
#>   19648816021687              -0.31715130
#>   36677106035901              -0.31650101
#> attr(,"upper")
#>                 criterion
#> entity           negative_chronic_absence
#>   30665976068399              -0.04074866
#>   38684786113997              -0.04848198
#>   30736506094718              -0.05176929
#>   58727516056840              -0.10134991
#>   30736436030639              -0.10218227
#>   01750936118038              -0.10668051
#>   19647330106427              -0.15842066
#>   37684520105882              -0.16315798
#>   36676866035711              -0.16773115
#>   34674216033732              -0.24741189
#>   19648816021687              -0.24818431
#>   36677106035901              -0.25464526
#> attr(,"level")
#> [1] 0.9
#> attr(,"interval_source")
#> [1] "supplied_marginal_summaries"
ev <- postrank_evaluate(x$reference$actions$posterior_mean_tertiles,
  x$input, tau = .2, weights = x$reference$settings$weights)
ev[c("G", "N", "M", "primary_risk")]
#> $G
#> [1] 3
#> 
#> $N
#> [1] 48
#> 
#> $M
#> [1] 66
#> 
#> $primary_risk
#> [1] 0.08225512
#> 
x$reference$statewide$metrics[c("method", "N", "E", "risk")]
#>                  method        N        E       risk
#> 1        posterior_mean 11343829 150190.6 0.07548678
#> 2               all_tie        0      0.0 0.20000000
#> 3              raw_rate 11337601 150248.7 0.07556340
#> 4      matched_raw_rate 11343829 151730.7 0.07557729
#> 5         expected_rank 11342876 149871.2 0.07547921
#> 6 matched_expected_rank 11343829 150110.8 0.07548208
```
