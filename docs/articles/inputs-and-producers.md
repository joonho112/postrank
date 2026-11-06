# Strict inputs, declarations and external producers

This retained reference preserves the original examples and article URL.
[Analysis of supplied posterior
results](https://joonho112.github.io/postrank/articles/a5-your-posterior-results.md)
describes input construction, and [Posterior inputs and pairwise
probabilities](https://joonho112.github.io/postrank/articles/m3-posterior-inputs.md)
examines the information available under each representation.

postrank accepts posterior draws or coefficients from an external
estimation procedure, together with declarations of their scientific
meaning and sampling history. We describe the input routes, eight
required declarations, JSON representation, Gaussian and mixture
constructors, fixed-grade evaluation and transfer from an external
estimation pipeline. The package does not fit the underlying models.
Solver results in this article are read from source-bound caches, with
no new optimization.

``` r

library(postrank)
source(system.file("scripts", "_vignette-setup.R", package = "postrank", mustWork = TRUE), local = TRUE)
has_posterior <- requireNamespace("posterior", quietly = TRUE)   # optional producer route below
```

## (a) An array of draws with eight declarations

The array interface accepts a numeric `S x n x K` array indexed by draw,
entity and criterion, an explicit sampling `regime`, and a
[`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md)
bundle. All eight declarations are required and have no defaults;
generic placeholders such as `"unknown"` or `"TBD"` are rejected. The
declarations below describe the illustrative analysis and must be
replaced by the corresponding statements for an application.

``` r

decl <- postrank_declarations(
  targets = data.frame(criterion_id = c("need1", "need2"),
    estimand = "Latent need of each site (illustration)", entity_population = "Six example sites",
    time_reference = "Example year", units = "standardized units"),
  context = list(cohort_id = "example-cohort", data_version = "1",
    data_conditioning = "Simulated values for this article",
    model_summary = "Independent standard Normal draws (no data)"),
  provenance = list(producer = "inputs-and-producers vignette", artifact_id = "example-array",
    construction_note = "Generated in this article with set.seed(20261024)"),
  origin = list(source_id = "vignette", fit_id = "none", model_id = "standard-normal",
    source_format = "R array", source_artifact = "inputs-and-producers.Rmd"),
  identification_note = "The targets are the simulated coordinates themselves.",
  tie_justification = "Continuous draws; exact ties between distinct sites have probability zero.",
  joint_generation = "Each draw holds all sites and criteria from one simulated state.",
  sampling_provenance = "IID draws from the stated Normal law; nothing discarded or thinned.")
names(decl)
#> [1] "targets"             "context"             "provenance"         
#> [4] "origin"              "identification_note" "tie_justification"  
#> [7] "joint_generation"    "sampling_provenance"
```

``` r

set.seed(20261024)
values <- array(stats::rnorm(500 * 6 * 2), c(500, 6, 2),
  dimnames = list(NULL, paste0("site", 1:6), c("need1", "need2")))
draws <- postrank_draws(values, regime = "iid", declarations = decl)
draws
#> <postrank_draws>  6 entities with posterior input
#>   2 criteria: need1, need2.
#>   500 retained IID draws; each draw contains all entities and criteria.
#>   The input structure has been checked. The declared sampling history and
#>     statistical model have not been independently verified.
#>   i  summary(x) describes the targets; details = TRUE adds source records.
```

For numeric arrays,
[`postrank_draws()`](https://joonho112.github.io/postrank/reference/postrank_draws.md)
calls the strict constructor
[`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md),
which accepts the eight declarations as separate arguments and returns a
validated `postrank_draws` object. MCMC input additionally requires a
declared chain layout (`chains`, `warmup_per_chain` and `thin`, with
`thin = 1L` for unthinned output) and values stored chain by chain. For
a criterion with higher priority assigned to smaller values,
`orientation = c(need2 = "lower")` negates the values once and records
the transformation in the target’s `source_transform`.

An incomplete declaration bundle produces an error:

``` r

e <- tryCatch(postrank_declarations(targets = decl$targets, context = decl$context),
  error = identity)
conditionMessage(e)
#> [1] "$.declarations: missing required scientific declarations: provenance, origin, identification_note, tie_justification, joint_generation, sampling_provenance (they are not inferred or filled with placeholders)"
```

### Declaration checks by input route

All routes require the declarations in their input schema. The
high-level array constructor also rejects generic placeholder tokens in
descriptive text. This text check does not establish the scientific
validity of the declarations.

| Input route | Declaration checks in 0.9.x |
|----|----|
| [`postrank_declarations()`](https://joonho112.github.io/postrank/reference/postrank_declarations.md) and the high-level array constructor | Required bundle fields and placeholder-token checks, followed by structural validation |
| Direct [`postrank_draws_from_array()`](https://joonho112.github.io/postrank/reference/postrank_draws_from_array.md) | Legacy required declarations and structural validation |
| Existing `postrank_draws`, canonical JSON read/write | Legacy declaration-presence and structural checks; no added token lint |
| Criterionwise matrix metadata and `posterior` metadata bridge | Canonical metadata/coordinate checks; no added token lint |

The bundle checks the four narrative statements and required descriptive
fields in targets, context, provenance and origin. Criterion IDs follow
the ID rules; `fit_id` and `data_version` permit labels such as `"none"`
and are not subject to the placeholder-token check. Passing a canonical
route does not imply that the declaration bundle’s placeholder-token
check was run. No route verifies jointness, identification or
convergence as scientific facts.

## (b) The JSON format and the installed toy

The installed example has 32 independent states from a specified normal
law, three opaque IDs and two criteria. It is not an observed-data fit.

``` r

path <- system.file("examples", "synthetic-iid.json",
                    package = "postrank", mustWork = TRUE)
draws <- read_postrank_draws(path)
draws$entity_ids
#> [1] "001"    "site-B" "site C"
draws$criterion_ids
#> [1] "need_A" "need_B"
dim(draws$joint_draws$tensor$values)
#> [1] 32  3  2
draws$validation[c("valid", "schema_checked", "source_values_checked",
                   "jointness_verified", "convergence_verified")]
#> $valid
#> [1] TRUE
#> 
#> $schema_checked
#> [1] FALSE
#> 
#> $source_values_checked
#> [1] FALSE
#> 
#> $jointness_verified
#> [1] FALSE
#> 
#> $convergence_verified
#> [1] FALSE
```

The validation record distinguishes semantic checks from scientific
verification. R validation neither invokes a general Draft 2020-12
validator nor establishes joint generation or convergence. Input schema
`applied-0.1`, derived API schema `0.1.0` and package version identify
different components. The bundled `postrank_toy` contains the same
object.

``` r

generator <- system.file("examples", "make-synthetic-input.R",
                         package = "postrank", mustWork = TRUE)
source(generator)
payload <- make_postrank_synthetic_input()
rebuilt <- as_postrank_draws(payload)
rebuilt_values <- rebuilt$joint_draws$tensor$values
stored_values <- draws$joint_draws$tensor$values
stopifnot(identical(dim(rebuilt_values), dim(stored_values)),
          identical(dimnames(rebuilt_values), dimnames(stored_values)),
          max(abs(rebuilt_values - stored_values)) <= 1e-12)
names(payload)
#>  [1] "schema_version"       "input_kind"           "dependence_mode"     
#>  [4] "requested_functional" "entity_ids"           "criterion_ids"       
#>  [7] "targets"              "context"              "identification"      
#> [10] "tie_policy"           "provenance"           "joint_draws"
payload$targets[[1]]
#> $criterion_id
#> [1] "need_A"
#> 
#> $estimand
#> [1] "Toy latent site need under the explicitly specified independent Normal target law"
#> 
#> $entity_population
#> [1] "Three labeled synthetic entities"
#> 
#> $time_reference
#> [1] "Single fixed software example"
#> 
#> $units
#> [1] "toy real-valued need units"
#> 
#> $source_transform
#> [1] "identity"
#> 
#> $identification_basis
#> [1] "Direct specified target coordinates; no fitted factor model"
#> 
#> $orientation
#> [1] "higher_priority"
```

The regenerated values are compared with the stored sample at absolute
tolerance `1e-12`; dimensions and labels must agree exactly. This allows
floating-point variation across platforms without replacing the frozen
input or its identity. Sourcing defines the function without drawing
values or writing files; the function also preserves the caller RNG
state. IDs are character labels. Missing or nonfinite targets,
unresolved identification, observed entity ties and contradictory
histories are rejected, without jitter or hidden reordering.

``` r

copy_path <- tempfile(fileext = ".json")
write_postrank_draws(draws, copy_path)
roundtrip <- read_postrank_draws(copy_path)
stopifnot(identical(roundtrip$joint_draws$tensor$values,
                    draws$joint_draws$tensor$values))
unlink(copy_path)
```

The strict JSON reader rejects decoded duplicate keys, malformed
numbers, unsafe integer metadata and invalid Unicode surrogates.
Coordinates and singleton axes are preserved. These checks do not
constitute general schema validation.

## (c) Criterionwise matrices and `posterior` draws

When each criterion comes from its own fit, there is no joint
cross-criterion state. A named list of `S_k x n` matrices (one per
criterion; the `S_k` may differ) enters with complete canonical
criterionwise metadata: one declared block per criterion with its own
origin, sampling record, draw index and variable map. The matrix values
are inserted into those blocks; no joint state is inferred.

``` r

# `metadata` is a canonical applied-0.1 payload with dependence_mode =
# "criterionwise_expected_only" and one criterion_blocks[[k]] per criterion,
# each without its matrix values (see ?postrank_draws and ?as_postrank_draws).
draws_cw <- postrank_draws(list(need1 = m1, need2 = m2), metadata = metadata)
```

A `posterior` `draws_array`, `draws_df` or `draws_matrix` enters with
canonical joint metadata, explicit variable-mapping records and the
source coordinate of every retained draw. Here a producer has written
the toy’s states as a one-chain `draws_array` with variables
`theta[i,k]`; postrank maps them back and obtains the identical object.

``` r

if (has_posterior) {
  meta <- make_postrank_synthetic_input()
  vals <- meta$joint_draws$tensor$values
  map <- meta$joint_draws$variable_map
  vars <- vapply(map, `[[`, "", "source_target_variable_id")
  src <- array(NA_real_, c(dim(vals)[1], 1L, length(vars)),
    dimnames = list(iteration = NULL, chain = "1", variable = vars))
  for (m in seq_along(map)) src[, 1, vars[m]] <- vals[, map[[m]]$entity_id, map[[m]]$criterion_id]
  coords <- lapply(seq_len(dim(vals)[1]), function(s)
    list(slot_id = dimnames(vals)$draw[[s]], iteration_index = s, chain_index = 1L))
  meta$joint_draws$tensor$values <- NULL          # the values come from the producer
  from_posterior <- postrank_draws(posterior::as_draws_array(src), variables = map,
    metadata = meta, source_coordinates = coords)
  identical(from_posterior$validation$input_identity, postrank_toy$validation$input_identity)
}
#> [1] TRUE
```

## (d) Gaussian and mixture coefficients

Posterior information may be supplied as coefficients rather than draws.
The Gaussian constructor calculates pairwise error probabilities from
posterior means and covariances under an explicit
conditional-independence declaration, with six required provenance
fields. The object `pr_example_gaussian` represents the fixed law
underlying `pr_example_draws` in this form.

``` r

pr_example_gaussian
#> <postrank_coefficients>  30 entities under a declared conditional law
#>   3 criteria: poverty, frl, snap.
#>   Gaussian comparison probabilities and marginal summaries are available.
#>   Supported decisions use weighted loss and an upper limit on grades. Target
#>     draws, q constraints, exact grade counts and minimax decisions are
#>     unsupported here.
#>   i summary(x, details = TRUE) retains the conditional-law declarations and
#>     source records.
pr_example_gaussian$provenance[c("producer_id", "posterior_id")]
#> $producer_id
#> [1] "postrank maintainer script data-raw/make-pr-example-gaussian.R"
#> 
#> $posterior_id
#> [1] "pr-example-law A8 known-Gaussian posterior"
caps <- postrank_coefficient_capabilities(pr_example_gaussian)
unlist(caps[c("weighted_expected_risk", "posterior_means", "minimax_problem", "target_state_trace")])
#> weighted_expected_risk        posterior_means        minimax_problem 
#>                   TRUE                   TRUE                  FALSE 
#>     target_state_trace 
#>                  FALSE
```

The capability record permits weighted problems and posterior means for
this input. Minimax and protection problems are unsupported. Target-draw
traces are also unavailable, which excludes draw-based fragility and
cross-fitting.

``` r

g <- load_or_compute("gaussian_analysis_30x3")
g
#> <postrank_analysis>  30 entities in 1 grade; all comparisons withheld
#>   3 criteria: poverty, frl, snap.
#>   Posterior loss: 0.2500.
#>   Disclosed 0 of 435 pairs (0.0%); withheld 435.
#>   Expected error among disclosed pairs: NA (N = 0); no pairs were disclosed.
#>   A single shared grade withholds every comparison; it is not an error-free
#>     ranking.
#>   Solver: Optimal within solver tolerances.
#>   Optimization gap: 0; requested absolute gap 1e-08.
#>   Prepared: report card.
#>   Grade 1 has highest priority; a shared grade withholds the comparison.
#>   grade 1 (30): site001, site002, site003, site004, site005, site006,
#>     site007, site008, site009, site010, site011, site012, site013, site014 +16
#>     more
#>   i summary(x) explains the loss, settings and bounds; get_grades(x) returns
#>     all grades.
```

Cached asset `gaussian_analysis_30x3`: built by the maintainer with
postrank 1.1.0 and the explicitly selected highs backend (version
1.12.0.3) at 2026-10-30T14:15:54Z; 1 solve, recorded status optimal.
Reading it here solves nothing.

The report card uses analytic Gaussian intervals, with `interval_source`
equal to gaussian_analytic. Thus posterior means and intervals remain
available for typed coefficient input, whereas unsupported quantities
remain unavailable. Mixture intervals are obtained by numerical
inversion of the marginal CDF. If an endpoint fails the probability
tolerance in the target’s units, the result records
`posterior_quantile_failure`. A valid fit is retained when this prevents
construction of the report-card extra, and the reason for the
unavailable extra is recorded.

Prepared coefficient diagnostics can also be included in a report
without recomputing them:

``` r

gd <- postrank_coefficient_diagnose(pr_example_gaussian, fit = g$fit)
gd$diagnostics$mcse_mean$unavailable_reason
#> [1] "analytic_Gaussian_no_hyperstate_MC_trace"
gaussian_report <- postrank_report(g$fit, diagnostics = gd, analysis = g, figures = FALSE)
gaussian_report$diagnostic_table[, c("metric", "value", "available", "NA_reason")]
#>      metric value available                                NA_reason
#> 1 mcse_mean    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 2      rhat    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 3  ess_mean    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 4  ess_bulk    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
#> 5  ess_tail    NA     FALSE analytic_Gaussian_no_hyperstate_MC_trace
```

An analytic Gaussian law has no hyperstate Monte Carlo trace, so its
MCSE is unavailable, not zero. For a shared-hyperstate mixture,
conditional-risk metrics describe integration of expected weighted risk
over hyperstates; they do not describe target-loss draws or their
dispersion. Eligible hyperparameter-MCMC metrics need original
`chain_history` supplied to
[`postrank_coefficient_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_coefficient_diagnose.md);
the convenience
[`postrank_diagnose()`](https://joonho112.github.io/postrank/reference/postrank_diagnose.md)
dispatch supplies no such history. Finite metrics and the report do not
establish convergence, post-selection coverage or regret guarantees.

The coefficient estimates from 4,000 IID draws can be compared with the
known-law probabilities. Each `e[i,j,k]` has Monte Carlo standard error
bounded by `sqrt(.25 / 4000)`; the fixture’s regression band is five
times this value.

``` r

pw <- postrank_pairwise(pr_example_draws)
delta <- pw$e - pr_example_gaussian$e
c(max_pointwise_error = max(abs(delta), na.rm = TRUE), band = 5 * sqrt(.25 / 4000))
#> max_pointwise_error                band 
#>          0.02850931          0.03952847
```

A pointwise coefficient error differs from a weighted coefficient
envelope, which bounds fixed-action risk error uniformly for a specified
weight vector. The two quantities are not interchangeable.

A finite mixture of Gaussian states uses
[`postrank_mixture_coefficients()`](https://joonho112.github.io/postrank/reference/postrank_mixture_coefficients.md)
with the same declaration and provenance requirements:

``` r

ids <- c("A", "B"); ks <- "k1"
covariance <- array(.5, c(1, 1, 2), dimnames = list(criterion_i = ks, criterion_j = ks, entity = ids))
state <- function(d) list(mu = c(k1 = d),
  Sigma = matrix(1, 1, 1, dimnames = list(criterion_i = ks, criterion_j = ks)),
  means = matrix(c(d, .4), 2, 1, dimnames = list(entity = ids, criterion = ks)),
  covariance = covariance)
provenance <- list(producer_id = "vignette-example", producer_version = "1",
  posterior_id = "fixed-two-state-mixture", input_payload_sha256 = strrep("a", 64),
  source_sha256 = strrep("b", 64), config_sha256 = strrep("c", 64))
mix <- postrank_mixture_coefficients(list(s1 = state(-1), s2 = state(.5)), c(s1 = .5, s2 = .5),
  data.frame(state_id = c("s1", "s2")), "fixed_finite_mixture", "entities_given_shared_h", provenance)
round(mix$e[, , "k1"], 4)
#>         entity_j
#> entity_i      A      B
#>        A     NA 0.6897
#>        B 0.3103     NA
```

Arbitrary coefficient arrays are not accepted by these typed-law
constructors. The current
[`postrank_probabilities()`](https://joonho112.github.io/postrank/reference/postrank_probabilities.md)
interface separately accepts validated tie-free comparison
probabilities, as described in the posterior-input article.

## (e) Directional errors and a fixed action

`e[i,j,k]` estimates `P(theta[i,k] <= theta[j,k])`: the error when i is
placed above j. Diagonal NA sentinels are excluded; exact 0/1 values are
not clipped.

``` r

pairwise <- postrank_pairwise(draws, method = "blocks", block_size = 2L)
pairwise$sample_sizes
#> need_A need_B 
#>     32     32
pairwise$e[, , "need_A"]
#>         entity_j
#> entity_i  001 site-B site C
#>   001      NA 0.2500 0.0000
#>   site-B 0.75     NA 0.0625
#>   site C 1.00 0.9375     NA
weights <- c(need_A = .6, need_B = .4)
grade <- setNames(c(1L, 2L, 2L), draws$entity_ids)
evaluation <- postrank_evaluate(grade, pairwise, weights, tau = .25)
evaluation[c("E_over_M", "E_over_N", "disclosure_rate", "weighted_risk")]
#> $E_over_M
#>     need_A     need_B 
#> 0.08333333 0.59375000 
#> 
#> $E_over_N
#>   need_A   need_B 
#> 0.125000 0.890625 
#> 
#> $disclosure_rate
#> [1] 0.6666667
#> 
#> $weighted_risk
#> [1] 0.3708333
```

This user-supplied action places `001` above the others and withholds
their mutual comparison. It is not optimized. With M available unordered
pairs and N disclosed directions, risk is
`(sum(weights*E)+tau*(M-N))/M`. `E_over_M` and `E_over_N` have different
denominators. Criterion-named weights are explicit loss preferences and
are not automatically normalized.

``` r

all_tie <- setNames(rep(1L, length(draws$entity_ids)), draws$entity_ids)
abstained <- postrank_evaluate(all_tie, pairwise, weights, tau = .25)
stopifnot(abstained$N == 0, all(is.na(abstained$E_over_N)),
          abstained$weighted_risk == .25)
abstained[c("N", "E_over_N", "weighted_risk")]
#> $N
#> [1] 0
#> 
#> $E_over_N
#> need_A need_B 
#>     NA     NA 
#> 
#> $weighted_risk
#> [1] 0.25
```

The all-withheld action has risk tau. A zero error numerator does not
establish an error-free ranking. Canonical positive-integer labels
preserve the public pair relations.

## (f) A producer pipeline outside the package

The methods book’s hierarchical model is a normal-inverse-Wishart
example: site-level latent needs with a normal measurement model and an
inverse-Wishart prior on their covariance, fitted by MCMC. Estimation is
conducted outside postrank. The following unevaluated code illustrates
the transfer of latent draws from four chains of 1,000 retained
iterations each, after 1,000 warmup iterations and without thinning:

``` r

# theta: 4000 x n x K array of retained draws, stored chain by chain
# (rows 1-1000 chain 1, 1001-2000 chain 2, ...), produced by your own Stan/JAGS run.
decl <- postrank_declarations(
  targets = my_targets, context = my_context, provenance = my_provenance, origin = my_origin,
  identification_note = "...", tie_justification = "...",
  joint_generation = "Each retained iteration holds all sites and criteria from one MCMC state.",
  sampling_provenance = "4 NUTS chains, 1000 warmup + 1000 retained iterations each, no thinning.")
hb_draws <- postrank_draws(theta, regime = "mcmc", chains = 4L, warmup_per_chain = 1000L,
  thin = 1L, declarations = decl)
```

The repository’s Stan workflow provides an external posterior-production
pipeline. The following unevaluated code requires labeled inputs and
scientific metadata conforming to that pipeline’s contract.

``` r

for (file in sort(list.files("producers/R", pattern = "[.]R$", full.names = TRUE)))
  source(file)
bundle <- postrank_normal_hb_data(y, V, entity_ids, criterion_ids, measurement)
config <- jsonlite::fromJSON("config/stan-runtime.json")
run <- run_postrank_stan("producers/stan/normal_hb.stan", bundle,
                         "results/a-new-unique-attempt", config, "my-reviewed-HB-run")
sampler_diagnostics <- diagnose_postrank_stan(run)
stan_draws <- export_postrank_stan_draws(run, scientific_metadata)
```

Structural export does not prove sampler adequacy or model validity.
Unknown imports, variational and optimization output are not accepted as
MCMC draws.

## (g) Problems, solvers and diagnostics on the toy

The following calculations retain the examples from the earlier guide.
Prepared solver results were computed with HiGHS selected explicitly;
the corresponding optimization calls are displayed but are not
evaluated.

``` r

problem <- postrank_problem(pairwise, weights, tau = .25, G_max = 3L)
protected <- postrank_problem(pairwise, weights, .25, 3L,
                              q = c(need_B = .2))
exact_two <- postrank_problem(pairwise, weights, .25, 3L, exact_G = 2L)
minimax <- postrank_problem(pairwise, weights, .25, 3L, objective = "minimax")
stopifnot(identical(problem$input_identity, pairwise$input_identity))
problem$objective_units
#> $raw
#> [1] "weighted_Z"
#> 
#> $scale
#> [1] 0.3333333
#> 
#> $offset
#> [1] 0.25
minimax$objective_units
#> $raw
#> [1] "minimax_risk_t"
#> 
#> $scale
#> [1] 1
#> 
#> $offset
#> [1] 0
```

The default action family permits at most `G_max` occupied grades;
exact-G requires exactly G nonempty grades. Protection uses
`E_k <= q_k*N`. Minimax minimizes the maximum of expected criterion
risks, not the expected draw-level maximum.

Gurobi is the default backend, and HiGHS is an explicitly selected
alternative for the same sparse problem. Backend failures do not trigger
automatic substitution. Availability information is derived from package
metadata and does not test the solver runtime or license.

``` r

availability <- postrank_backend_available("highs")
availability[c("installed", "available_for_attempt")]
#> $installed
#> [1] TRUE
#> 
#> $available_for_attempt
#> [1] TRUE
```

``` r

fit_gurobi <- postrank_solve(problem, backend = "gurobi",
  control = list(time_limit = 10, threads = 1L, seed = 1304L,
                 absolute_risk_gap = 1e-6, relative_gap = 0))
```

``` r

control <- list(time_limit = 10, threads = 1L, seed = 1304L)
# Optional reproduction: postrank_solve(problem, backend = "highs", control = control)
fit <- load_or_compute("toy_analysis")$fit
fit$status$normalized
#> [1] "optimal"
fit$grade
#>    001 site-B site C 
#>      1      1      2
unlist(fit$objective[c("risk_upper_bound", "risk_lower_bound", "risk_absolute_gap")])
#>  risk_upper_bound  risk_lower_bound risk_absolute_gap 
#>            0.2125            0.2125            0.0000
fit$objective$bound_source
#> [1] "engine_lp_relaxation_bound_clamped"
```

Cached asset `toy_analysis`: built by the maintainer with postrank 1.1.0
and the explicitly selected highs backend (version 1.12.0.3) at
2026-10-30T14:15:54Z; 1 solve, recorded status optimal. Reading it here
solves nothing. It solves the same declared problem (weights .6/.4,
`tau = .25`, `G_max = 3`). The released grade is the independently
validated incumbent. The upper bound is its risk and the lower bound is
the solver’s, so a zero gap means the solver found no better grade for
these coefficients within its tolerances; it is not a numerical
certificate.

``` r

# Optional reproduction: postrank_solve(minimax, backend = "highs", control = control)
mm <- load_or_compute("toy_minimax")
mm$minimax_refine[c("mode", "applied", "improved", "reason")]
#> $mode
#> [1] "weighted"
#> 
#> $applied
#> [1] TRUE
#> 
#> $improved
#> [1] FALSE
#> 
#> $reason
#> [1] "released_action_lexicographic_and_pareto_certified"
minimax$minimax_diagnostics$degenerate_criteria
#> character(0)
```

Cross-fitting selects a grade on one half of the draws and evaluates it
on the other half; the fragility table flags pairs whose disclose-or-tie
margin is within two Monte Carlo standard errors. Both are descriptive.

``` r

# Optional reproduction: postrank_crossfit(draws, fit = fit, backend = "highs", control = control)
cf <- load_or_compute("toy_crossfit")
cf
#> <postrank_crossfit>  2 posterior-draw folds
#>   Fold sizes: 16 / 16; split: iid halves.
#>    Fold Training loss Held-out loss Optimism Status
#>    A    0.2167        0.2083        -0.0083  Optimal within solver tolerances
#>    B    0.2083        0.2167        0.0083   Optimal within solver tolerances
#>   Each grade is chosen on its training fold and evaluated on held-out
#>     posterior draws. This is not a check on new observed data.
#>   Mean optimism: 0.0000; mean absolute optimism: 0.0083.
#>   i x$interpretation_support records the sampling assumptions for this
#>     comparison.
postrank_mc_fragility(draws, fit = fit)$summary
#> $pairs
#> [1] 3
#> 
#> $traced
#> [1] 2
#> 
#> $fragile
#> [1] 0
#> 
#> $fragile_share
#> [1] 0
#> 
#> $mcse_unavailable
#> [1] 0
#> 
#> $fragile_disclosed
#> [1] 0
#> 
#> $fragile_tied
#> [1] 0
```

``` r

diagnostics <- postrank_diagnose(draws, grade = grade,
  settings = list(weights = weights, tau = .25, G_max = 3L))
diagnostics$summaries$weighted_total_loss$diagnostics$mcse_mean
#> $value
#> [1] 0.01651476
#> 
#> $raw_value
#> [1] 0.01651476
#> 
#> $result_kind
#> [1] "finite"
#> 
#> $available
#> [1] TRUE
#> 
#> $unavailable_reason
#> NULL
#> 
#> $warnings
#> character(0)
#> 
#> $error
#> NULL
#> 
#> $error_class
#> NULL
#> 
#> $method
#> [1] "iid_sample_sd_over_sqrt_S"
stopifnot(!diagnostics$convergence_verified,
          !diagnostics$finite_sample_certificate)
```

These are descriptive IID standard errors for the toy, not certificates.
For MCMC, the optional `posterior` package supplies Rhat, bulk and tail
ESS and MCSE; ESS is not an IID sample size.

The conditional IID reference calculation applies only when sample sizes
and alpha were fixed before sampling; for the toy they were fixed in its
generator.

``` r

design <- list(sample_sizes_fixed_before_sampling = TRUE,
               alpha_fixed_before_sampling = TRUE, adaptive_stopping = FALSE,
               planned_sample_sizes = c(need_A = 32L, need_B = 32L),
               declaration_note = "Fixed in the shipped toy generator before generation.")
bounds <- postrank_iid_bounds(draws, alpha = .05,
  alpha_by_criterion = c(need_A = .025, need_B = .025), design = design)
bounds[c("epsilon", "guarantee_status", "bound_computed", "numerically_verified",
          "finite_sample_certificate", "guarantee_issued")]
#> $epsilon
#>    need_A    need_B 
#> 0.2926346 0.2926346 
#> 
#> $guarantee_status
#> [1] "conditional_bound"
#> 
#> $bound_computed
#> [1] TRUE
#> 
#> $numerically_verified
#> [1] FALSE
#> 
#> $finite_sample_certificate
#> [1] FALSE
#> 
#> $guarantee_issued
#> [1] FALSE
stopifnot(!bounds$numerically_verified, !bounds$finite_sample_certificate)
```

`bound_computed = TRUE` records a theoretical floating-point calculation
of the radii. Without a verified outward enclosure, this result does not
provide a numerical guarantee.
