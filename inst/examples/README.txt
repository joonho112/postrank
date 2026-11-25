The file synthetic-iid.json contains an applied-0.1 draw example with 32
independent draws, three fictional entity IDs ("001", "site-B", "site C"), and
two criteria ("need_A", "need_B"). Its independent normal target distribution
is specified directly without fitting to empirical observations, and it does
not contain Stan output or empirical study data.

The script make-synthetic-input.R defines make_postrank_synthetic_input();
sourcing the script does not execute the function, and calling it preserves
the caller's random-number state. Its design fixes S = 32, seed = 20261019,
alpha = 0.05, and criterion allocations 0.025 and 0.025 before generation,
returning all required description blocks and draw IDs.

You can regenerate the JSON file in an installed postrank session:
  source(system.file("examples", "make-synthetic-input.R", package="postrank"))
  payload <- make_postrank_synthetic_input()
  write_postrank_draws(payload, "a-new-path.json")

The supplied JSON file was written with write_postrank_draws() at 17-digit
precision. Input validation checks object structure, values, and required
description fields; substantive model adequacy, joint generation, and sampler
convergence require separate justification. For walkthroughs of reading and
writing JSON draw files, see
vignette("a5-your-posterior-results", package="postrank").
