# Historical Economic Opportunity in 67 Alabama Counties

A compact example combining income and incarceration outcomes for
children born in 1978–1983, at parent income percentile 25, with race
and gender pooled. Income ranks use household incomes from 2014–2015;
incarceration is measured on April 1, 2010. The example favors higher
income and lower incarceration. It describes historical conditional
outcomes, not current county conditions or the causal effect of a
policy.

## Usage

``` r
pr_case_alabama
```

## Format

A named list with five elements:

- input:

  A validated `postrank_probabilities` input for all 67 counties and
  both criteria, from selected numerical pool A. It includes genuine
  marginal posterior means and fixed 95% equal-tail intervals.

- units:

  67 rows in input order, with county IDs and names, published estimates
  and standard errors, oriented point scales, and source fields. The
  published population count is descriptive; it is not a binomial
  denominator for the fitted model.

- alternatives:

  `pool_B` supplies probabilities from a separate numerical run;
  `income` and `incarceration` are one-criterion inputs from pool A. All
  retain their same-target marginal summaries.

- reference:

  Archived settings, seven grade vectors, A/B evaluations,
  single-criterion solver results, commonality comparisons, and
  numerical precision information. These were computed with postrank
  0.9.0 and HiGHS 1.12.0.3; they are not fresh fits by the installed
  package.

- provenance:

  Source-relative filenames and hashes, outcome dates, directions, model
  conditioning, attribution and CC BY 4.0 notice.

## Source

Raj Chetty, John Friedman, Nathaniel Hendren, Maggie R. Jones and Sonya
R. Porter (2022), *Replication Data for: The Opportunity Atlas: Mapping
the Childhood Roots of Social Mobility*, Harvard Dataverse V1.0,
[doi:10.7910/DVN/NKCQM1](https://doi.org/10.7910/DVN/NKCQM1) . Source:
Opportunity Insights and U.S. Census Bureau. Selected CSV:
<https://opportunityinsights.org/wp-content/uploads/2018/10/county_outcomes_simple.csv>.
Observations and documented derivatives are available under [CC BY
4.0](https://creativecommons.org/licenses/by/4.0/). Changes include
Alabama filtering, county identifiers and names, point scales,
incarceration orientation, separate M1 posterior summaries, and compact
package inputs. Attribution and earlier change notices are retained in
`provenance$rights`. No endorsement is implied.

## Details

The two criteria were fitted separately using the published conditional
estimates and total standard errors, with Gaussian observation models
and logistic-normal partial pooling. Their comparison probabilities
support additive expected loss; they do not supply a joint posterior
across criteria. The retained probabilities are Monte Carlo estimates,
including observed zeros and ones, not exact posterior-certainty
statements.

A and B use the same observations and model. They are separate numerical
pools, not independent observational replications. Pool A uses 16,000
retained draws per criterion and pool B uses 8,000 in the source study;
those draws are not included here and the supplied inputs do not claim
retained samples or newly computed diagnostics. B failed the source's
sensitive-pair MCSE target of .005 in 486 directional criterion rows
(maximum .00586708). Its fixed-action risk precision was assessed
separately. The archived MCSEs came from the original chains; they
cannot be recalculated from these probability summaries. Constant-trace
pair MCSE is unavailable.

The archived common grades use weights .5/.5, withholding cost .20, and
at most five grades. Their grade vector equals the expected-rank cut
baseline B3 in this example. B3 optimizes within a fixed score order;
the common optimization's lower bound has a different scope. Numerical
solver gaps do not measure Monte Carlo error or posterior uncertainty.

To use the supplied marginal intervals in
[`postrank()`](https://joonho112.github.io/postrank/reference/postrank.md)
or
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md),
request `level = .95`; intervals at other levels cannot be recovered
from the stored summaries. A negative incarceration target has higher
priority when original incarceration is lower. This direction differs
from the source project's later policy-v2 needs analysis, which is not
included.

## See also

[`vignette("a4-alabama-opportunity", package = "postrank")`](https://joonho112.github.io/postrank/articles/a4-alabama-opportunity.md),
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md),
[`postrank_report_card()`](https://joonho112.github.io/postrank/reference/postrank_report_card.md)

## Examples

``` r
x <- pr_case_alabama
x$units[c("entity_id", "county_name", "income_estimate_points",
          "incarceration_estimate_points")]
#>    entity_id       county_name income_estimate_points
#> 1      01001    Autauga County               36.16662
#> 2      01003    Baldwin County               38.88471
#> 3      01005    Barbour County               34.93856
#> 4      01007       Bibb County               36.33907
#> 5      01009     Blount County               39.18788
#> 6      01011    Bullock County               34.56590
#> 7      01013     Butler County               35.72486
#> 8      01015    Calhoun County               36.18467
#> 9      01017   Chambers County               34.05749
#> 10     01019   Cherokee County               36.54216
#> 11     01021    Chilton County               38.80566
#> 12     01023    Choctaw County               39.69731
#> 13     01025     Clarke County               38.43071
#> 14     01027       Clay County               40.67803
#> 15     01029   Cleburne County               41.24786
#> 16     01031     Coffee County               38.67109
#> 17     01033    Colbert County               37.32456
#> 18     01035    Conecuh County               36.79720
#> 19     01037      Coosa County               35.26630
#> 20     01039  Covington County               40.55416
#> 21     01041   Crenshaw County               40.94989
#> 22     01043    Cullman County               40.45547
#> 23     01045       Dale County               38.08032
#> 24     01047     Dallas County               33.59591
#> 25     01049     DeKalb County               39.64774
#> 26     01051     Elmore County               37.79939
#> 27     01053   Escambia County               36.77946
#> 28     01055     Etowah County               36.48461
#> 29     01057    Fayette County               40.14124
#> 30     01059   Franklin County               40.57241
#> 31     01061     Geneva County               39.07105
#> 32     01063     Greene County               32.80988
#> 33     01065       Hale County               35.58530
#> 34     01067      Henry County               35.83888
#> 35     01069    Houston County               35.78941
#> 36     01071    Jackson County               39.40713
#> 37     01073  Jefferson County               34.39328
#> 38     01075      Lamar County               42.91585
#> 39     01077 Lauderdale County               39.63314
#> 40     01079   Lawrence County               38.76409
#> 41     01081        Lee County               36.43400
#> 42     01083  Limestone County               36.66204
#> 43     01085    Lowndes County               32.95280
#> 44     01087      Macon County               31.51837
#> 45     01089    Madison County               36.34087
#> 46     01091    Marengo County               37.04521
#> 47     01093     Marion County               39.46356
#> 48     01095   Marshall County               38.71275
#> 49     01097     Mobile County               35.89604
#> 50     01099     Monroe County               36.83310
#> 51     01101 Montgomery County               32.73328
#> 52     01103     Morgan County               36.94260
#> 53     01105      Perry County               33.66066
#> 54     01107    Pickens County               36.96542
#> 55     01109       Pike County               36.58015
#> 56     01111   Randolph County               37.27583
#> 57     01113    Russell County               33.11930
#> 58     01115  St. Clair County               39.96482
#> 59     01117     Shelby County               41.37784
#> 60     01119     Sumter County               34.42878
#> 61     01121  Talladega County               35.62244
#> 62     01123 Tallapoosa County               36.50265
#> 63     01125 Tuscaloosa County               35.64417
#> 64     01127     Walker County               37.56627
#> 65     01129 Washington County               41.84945
#> 66     01131     Wilcox County               34.92828
#> 67     01133    Winston County               38.81479
#>    incarceration_estimate_points
#> 1                      3.0568201
#> 2                      2.2593379
#> 3                      3.3516064
#> 4                      3.1666659
#> 5                      2.0527514
#> 6                      1.9160038
#> 7                      2.2641044
#> 8                      2.6158130
#> 9                      2.1025730
#> 10                     2.2722345
#> 11                     2.4616089
#> 12                     1.6524242
#> 13                     0.8765213
#> 14                     1.3831642
#> 15                     3.3694934
#> 16                     2.0128127
#> 17                     1.6486695
#> 18                     2.5915811
#> 19                     5.4470308
#> 20                     3.3456240
#> 21                     0.4156141
#> 22                     1.6264709
#> 23                     2.7194157
#> 24                     1.7692221
#> 25                     1.4112711
#> 26                     2.1436155
#> 27                     2.9329097
#> 28                     3.2291852
#> 29                     2.9594278
#> 30                     1.4650149
#> 31                     2.0717705
#> 32                     1.9655667
#> 33                     1.3388982
#> 34                     4.1606449
#> 35                     3.3435084
#> 36                     1.6184419
#> 37                     3.3812899
#> 38                     1.9769415
#> 39                     1.4968146
#> 40                     1.2946686
#> 41                     3.2386627
#> 42                     2.1279225
#> 43                     1.9019283
#> 44                     2.8751468
#> 45                     3.4139868
#> 46                     1.7205138
#> 47                     1.1958894
#> 48                     2.2106096
#> 49                     3.0182857
#> 50                     1.8446466
#> 51                     3.8189784
#> 52                     2.9585253
#> 53                     2.2606874
#> 54                     1.3777658
#> 55                     3.1929813
#> 56                     2.7786372
#> 57                     4.4859175
#> 58                     1.8427383
#> 59                     2.9622365
#> 60                     2.6894433
#> 61                     3.1609647
#> 62                     2.4581661
#> 63                     2.7525434
#> 64                     1.6979430
#> 65                     1.7598644
#> 66                     1.5689397
#> 67                     1.9895431
postrank_posterior_means(x$input, level = .95)[1:3, ]
#>        criterion
#> entity    income incarceration
#>   01001 36.20615     -2.881527
#>   01003 38.84718     -2.233233
#>   01005 35.06699     -3.013570
ev <- postrank_evaluate(x$reference$actions$P, x$input,
  weights = c(income = .5, incarceration = .5), tau = .2)
ev[c("G", "N", "M", "primary_risk")]
#> $G
#> [1] 5
#> 
#> $N
#> [1] 1249
#> 
#> $M
#> [1] 2211
#> 
#> $primary_risk
#> [1] 0.1503937
#> 
```
