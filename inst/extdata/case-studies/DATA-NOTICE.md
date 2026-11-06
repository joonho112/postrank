# Public-source case-study data

This distribution includes three compact case-study inputs adapted from
public sources. The maintainer has confirmed their redistribution with the
source-specific conditions recorded below. The package code's MIT license
does not relicense external observations or their documented derivatives.
Dependent cached analyses and rendered case materials retain the same
conditions.

## California chronic absenteeism (`pr_case_cde`)

The input is derived from selected California Department of Education
(CDE) chronic-absence counts and the case-study author's frozen
empirical-Bayes analysis. It retains 12 schools, the statewide estimated
prior, comparison probabilities and same-target posterior summaries.
Attribution: California Department of Education, 2026 California School
Dashboard chronic absenteeism data, academic year 2025-26. See the
[CDE chronic-absenteeism data collection](https://www.cde.ca.gov/ta/ac/cm/chronicdatafiles.asp)
and [CDE source conditions](https://www.cde.ca.gov/re/di/cr/index.asp).

Documented changes include school selection, target orientation, numerical
integration and compact author-derived summaries. Original CDE raw
download files, full source tables, logos and the statewide pairwise
matrix are not included. No Creative Commons or package-code license is
substituted for the CDE source conditions. No CDE endorsement is implied.

## Firms in the KRW study (`pr_case_krw`)

The replication archive README states **CC-BY-NC** for its data and does
not specify a license version. The compact adaptation preserves that
noncommercial condition without inventing a version or replacing it with
MIT or unrestricted CC BY.

Attribution: Patrick Kline, Evan K. Rose and Christopher R. Walters (2024),
*Data and Code for: A Discrimination Report Card*, American Economic
Association/ICPSR replication deposit E198284V1, DOI
[10.3886/E198284V1](https://doi.org/10.3886/E198284V1). The associated article
is *A Discrimination Report Card*, American Economic Review, DOI
[10.1257/aer.20230700](https://doi.org/10.1257/aer.20230700).

Changes include fixed 97-firm extraction, continuous midpoint-cell
comparison probabilities and matching marginal summaries, and separate
archived law-labelled result tables. Full posterior grids and full source
research files are not bundled. No endorsement by the original authors is
implied.

## Historical Alabama opportunity (`pr_case_alabama`)

The selected observation CSV and documented derivatives use **CC BY 4.0**,
with attribution and change notices retained in the object. Attribution:
Raj Chetty, John Friedman, Nathaniel Hendren, Maggie R. Jones and Sonya R.
Porter (2022), *Replication Data for: The Opportunity Atlas: Mapping the
Childhood Roots of Social Mobility*, Harvard Dataverse V1.0, DOI
[10.7910/DVN/NKCQM1](https://doi.org/10.7910/DVN/NKCQM1); Opportunity Insights
and U.S. Census Bureau. See the
[CC BY 4.0 deed](https://creativecommons.org/licenses/by/4.0/).

Changes include Alabama filtering, native identifiers and county names,
point scales and incarceration orientation, separate M1 model summaries,
compact probability inputs and archived result tables. The original
release notice is preserved as historical source evidence; its statement
that the original observation release contains no posterior or grades does
not describe the additional derived contents of this teaching object. No
endorsement is implied.

## Historical provenance and reproduction scope

The frozen case objects retain the preparation decisions and source-review
records made when those inputs were assembled. Those historical metadata
fields describe that earlier preparation stage; the maintainer-confirmed
public distribution and its current source conditions are described in
this notice. The frozen numeric inputs, results and source hashes have not
been changed to revise publication metadata.

Each case object's provenance retains source identifiers, attribution and
documented transformations. Original research files and local extraction
scripts are not distributed here. A probability input contains neither
posterior draws nor new MCSE/ESS diagnostics. The pilot source register
identifies nonpublic research references without exposing local working
paths or implying public access to those records.


## Fictional 40-site multidomain teaching illustration

`extdata/mdomain/synthetic40-card.json` contains two frozen unit-by-domain
report cards and compact numerical summaries derived from JoonHo Lee's
*Need-Based Pre-K Funding Tutorial* artificial teaching example:
https://github.com/joonho112/need-based-prek-funding-tutorial .
The original artificial teaching values and these adapted illustration
values use CC BY 4.0: https://creativecommons.org/licenses/by/4.0/ .
Credit: JoonHo Lee (2026). The source artificial posterior artifact has SHA-256
`bd36f6c0bad7d8d5abb540899b8d8ddca536e2705410118ddfc76d6b6bb5c590`.

Changes comprise extracting the two S/C teaching coordinates, retaining
fictional site identifiers, selecting two declared finite-bank profile
cards, and saving grades, counts, risks and descriptive MCMC diagnostic
summaries. The full posterior draws, geometry, catchments, factual records
and research archives are not included. The illustration is not an analysis
of actual Alabama sites. Its cached output is distinct from the eight P1
R data objects and their original prepared computations. The tutorial's
original code is MIT-licensed separately; that code license does not
replace the CC BY 4.0 terms for these artificial teaching values.
