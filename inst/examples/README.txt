The file synthetic-iid.json contains a complete applied-0.1 software example
with 32 IID states, three opaque entity IDs and two labeled criteria. The
independent Normal target law is specified directly. It is not fitted to
observations and contains neither Stan output, Alabama results nor a copy of
an upstream oracle.

The script make-synthetic-input.R defines make_postrank_synthetic_input();
sourcing the script does not execute the function. The generator preserves
the caller's RNG state. Its design specifies S=32, seed=20261019, alpha=.05 and
allocations .025/.025 before generation. All metadata fields and original draw
IDs are returned.

The input can be regenerated in an installed postrank session:
  source(system.file("examples", "make-synthetic-input.R", package="postrank"))
  payload <- make_postrank_synthetic_input()
  write_postrank_draws(payload, "a-new-path.json")

The supplied JSON was written with postrank's 17-digit lossless JSON emitter.
Validation establishes conformity of the input structure and values to the
specified format. Scientific model validity, jointness and convergence require
separate justification. Further details are given in
vignette("inputs-and-producers", package="postrank").
