# Exact finite-law fixture boundary

`core-cases.json` is the unchanged applied-book fixture with schema
`p1-applied-tiny-oracle-v1`, source SHA-256
`a58d68801dc44a884b88ef6423071120c51770259e5d62039cfe4e492e7f703d`.
It contains 6 cases and 30 decision settings; each case has positive integer
state masses with an integer denominator and state/entity/criterion targets.

Do not pass this document directly to a production JSON constructor or claim it
conforms to the production input schema. A later adapter must explicitly map
the law's integer `states[[s]]$mass`, `denominator`, entity and criterion IDs,
and `theta[state][entity][criterion]` into the canonical exact-law API. Settings
(`weights`, `tau`, `protect`, `Gmax`, `exact_G`, mode) belong to the decision
problem, not to the posterior input. Preserve rational strings until the
production exact arithmetic boundary and record any conversion to doubles for
solver coefficients separately.

All targets in these fixtures use larger-is-higher-priority; grades use
smaller-is-higher-priority. Every positive-mass state is tie-free within a
criterion. The oracle's stricter 1,000,000 target and rational-component limits
do not silently define the production API's safe-integer limits.

Provenance, license limitations and the fresh replay commands are documented in
`validation/oracles/README.md` and `validation/oracles/source-manifest.json`.


Packaged-test expectations
--------------------------

`pairwise-expectations.json` retains only the six case IDs and literal rational
pairwise coefficients from the preserved R oracle result. Its attribution
records the original result and fixture SHA-256. The full oracle execution,
review and license records remain repository-only under `validation/oracles/`;
package tests require no access to that directory. This subset is a factual
expected-value fixture, not a production calculation or a new oracle run.

`tests/testthat/helper-exact-fixture.R` is a self-contained packaged-test copy
of the project's posterior-only adapter. It preserves the explicit synthetic
source declarations and never imports decision risk code. The source copy and
its SHA-256 are recorded in that helper.
