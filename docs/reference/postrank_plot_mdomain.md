# Plot a Multidomain Grade Profile

`postrank_plot_mdomain()` plots a stored multidomain report card as a
unit-by-domain grade table (`view = "grades"`), a one- or two-domain
cell occupancy chart (`view = "cells"`), or a domain-by-domain
directional comparison of two units (`view = "pair"`), without
re-evaluating or searching candidates.

## Usage

``` r
postrank_plot_mdomain(
  x,
  view = c("grades", "cells", "pair"),
  units = NULL,
  domains = NULL,
  ...
)
```

## Arguments

- x:

  A `postrank_mdomain_evaluation` or `postrank_mdomain_fit` (for a
  `postrank_mdomain_assessment`, pass `x$evaluation`).

- view:

  One of `"grades"` (the default), `"cells"`, or `"pair"`.

- units:

  Optional character vector of distinct unit IDs from `x` in the desired
  display order. Required with exactly two distinct unit IDs when
  `view = "pair"`.

- domains:

  Optional character vector of distinct domain IDs from `x` in the
  desired display order. Required with one or two domain IDs when
  `view = "cells"` and `x` has more than two domains.

- ...:

  Optional named display arguments chosen from `title` (character scalar
  or `NULL`), `unit_labels` (named character vector keyed by raw unit
  IDs), `domain_labels` (named character vector keyed by raw domain
  IDs), and `base_size` (positive finite number, default `11`). Passing
  any other argument stops with an error.

## Value

A `ggplot` object with underlying plot data in `$data` and a
`"postrank_mdomain"` attribute containing `view`, `unit_ids`,
`domain_ids`, `original_units`, `original_pairs`, full `caption` text,
and `uses_stored_card = TRUE`.

## Details

Within each domain, grade `1` has highest priority and equal grades
leave a pair unordered rather than claiming equal targets:

- `view = "grades"`: draws a unit-by-domain tile grid labeled with
  integer grades
  ([`scale_fill_grade()`](https://joonho112.github.io/postrank/reference/scale_colour_grade.md)
  up to 64 grades); any domain with a single occupied grade (`K_d = 1`)
  is shaded light gray and marked `"(all withheld)"`.

- `view = "cells"`: counts displayed units in each grade (bar chart for
  one domain) or `(grade_x, grade_y)` cell (tile chart with reversed
  y-axis for two domains). Cell coordinates locate per-domain grade
  combinations without defining a total order across cells, and counts
  sum over any domains omitted from `domains`.

- `view = "pair"`: compares `units[1]` against `units[2]` on each
  displayed domain, marking `"+"` (`"Favors <units[1]>"`), `"-"`
  (`"Favors <units[2]>"`), or `"0"` (`"Direction withheld"`, or
  `"Same modeled target (direction withheld)"` when the pair shares a
  structural equality class on that domain), and notes in the subtitle
  when opposite directions appear across domains.

Figure captions report the original full-card risk `risk` and joint
exceedance probability `J` even when a subset of `units` or `domains` is
displayed.

## See also

[`postrank_mdomain_evaluate()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_evaluate.md),
[`postrank_mdomain_solve()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_solve.md),
[`postrank_mdomain_grades()`](https://joonho112.github.io/postrank/reference/postrank_mdomain_grades.md),
[`theme_postrank()`](https://joonho112.github.io/postrank/reference/theme_postrank.md)

## Examples

``` r
inp <- postrank_mdomain_input(
  postrank_toy,
  provenance = list(input_id = "toy", law_id = "toy-normal", proper_law = TRUE)
)
G <- matrix(
  c(1L, 1L, 2L, 3L, 1L, 2L),
  nrow = 3L,
  ncol = 2L,
  dimnames = list(inp$unit_ids, inp$domain_ids)
)
ev <- postrank_mdomain_evaluate(inp, G)
postrank_plot_mdomain(ev, view = "grades")

postrank_plot_mdomain(ev, view = "cells", domains = c("need_A", "need_B"))

postrank_plot_mdomain(ev, view = "pair", units = c("001", "site-B"))
```
