% Please edit documentation in R/data.R
\docType{data}
\name{pr_toy_mcmc}
\alias{pr_toy_mcmc}
\title{A Slowly Mixing Two-State Markov-Chain Example}
\format{
A numeric array of dimension 2048 x 3 x 2 (draws x sites \code{A}/\code{B}/\code{C}
x criteria \code{k1}/\code{k2}) with attribute \code{law} holding the transition matrix,
the two state matrices, RNG seed (\code{20261019}), analytic reference losses
(for weights \verb{(0.6, 0.4)} and \code{tau = 0.25}, grading \verb{(1, 2, 3)} has
stationary loss \code{4/15}, the stationary optimum \verb{(1, 2, 2)} has loss
\code{13/60}, and the pooled pair mean is \code{353/2048}), and a complete
\code{\link[=postrank_declarations]{postrank_declarations()}} object.
}
\source{
Built by \code{data-raw/make-pr-toy-mcmc.R} (seed \code{20261019}), adapted
from the theory book's diagnostic example (Lee, 2026).
}
\usage{
pr_toy_mcmc
}
\description{
\code{pr_toy_mcmc} is a synthetic MCMC array comprising four independent
stationary two-state Markov chains of 512 iterations each (\code{P(0 -> 1) = 0.012},
\code{P(1 -> 0) = 0.048}, stationary \code{P(Z = 1) = 0.2}, second eigenvalue \code{0.94}),
stored chain by chain for three fictional sites (\code{A}, \code{B}, \code{C}) on two
criteria (\code{k1}, \code{k2}). State 0 assigns targets \verb{(3, 2, 1)} on \code{k1} and
\verb{(3, 1, 2)} on \code{k2}; state 1 assigns \verb{(1, 3, 2)} and \verb{(1, 2, 3)}. The chains
mix slowly by design to illustrate MCMC diagnostics rather than a well-mixed
model fit.
}
\details{
Prepare it as a \code{postrank_draws} object using the descriptions stored in its
\code{law} attribute:
\verb{postrank_draws(pr_toy_mcmc, regime = "mcmc", chains = 4L,}
\verb{warmup_per_chain = 0L, thin = 1L,}
\verb{declarations = attr(pr_toy_mcmc, "law")$declarations)}.
}
\examples{
dim(pr_toy_mcmc)
mean(pr_toy_mcmc[, "A", "k1"] <= pr_toy_mcmc[, "B", "k1"])
}
\seealso{
\code{\link[=postrank_draws]{postrank_draws()}}, \code{\link[=postrank_diagnose]{postrank_diagnose()}}
}
\concept{data}
\keyword{datasets}
