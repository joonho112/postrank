# Moving from postrank 1.1.0 to 1.2.0

Existing P1 calls keep their signatures and behavior. `postrank()` chooses a
common grading; `get_profile()` reports criterion-specific consequences of that
common grading. Continue using them for the original task.

For distinct domain grades, use `postrank_mdomain_input()`,
`postrank_mdomain_decision()` and `postrank_mdomain_evaluate()` with a named
unit-by-domain grade matrix. `postrank_mdomain_family()` and
`postrank_mdomain_solve()` choose among a declared product bank.
`postrank_mdomain_grades()`, `postrank_mdomain_assess()` and
`postrank_plot_mdomain()` extract, assess and display the resulting card.
See the mdomain-quickstart and mdomain-decisions vignettes.

A complete state retains every unit and domain jointly. Pair probabilities
alone support additive loss but generally cannot identify a joint union event;
separate domain vectors do not acquire a coupling by matching row numbers.
Existing validated P1 draws retain their source-bound declarations when adapted;
supplemental conflicting declarations are rejected. Additional law identifiers
and a proper-law declaration are still required.

A grade tie withholds direction; it does not assert latent equality. Structurally
identical modeled targets share a grade. Error losses keep the original all-pair
denominator, while guard ratios use disclosed pairs in their declared scope.
When no such pairs are disclosed, the scoped error contribution is zero.

Use exact decimal/fraction strings for exact scientific policy boundaries.
Numeric values retain their stored binary value. Optimization is complete only
within the declared candidate bank. MCMC history produces descriptive diagnostics;
iid count certification requires a fixed event and separately declared validation
conditions. Computed finite-law feasibility and its arithmetic status do not
certify model adequacy, scientific independence or an intended posterior.

Prepared P1 caches remain original computations. Their source IDs, timestamps,
backend records and 1.1.0 versions are preserved; a separate exact-version reader
receipt binds the original manifests and the unchanged P1 code/data to the new
reader. Ordinary reads write or recompute nothing. The receipt is an integrity
record distributed with the package, not an external signature.
