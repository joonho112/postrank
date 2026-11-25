% Please edit documentation in R/example-results.R
\name{postrank_example}
\alias{postrank_example}
\title{Stored Example Results}
\usage{
postrank_example(name = NULL)
}
\arguments{
\item{name}{Name of a stored result, as listed by \code{postrank_example()}. If \code{NULL} (the default),
the list is returned instead.}
}
\value{
With \code{name = NULL}, a data frame with one row per stored result and the columns
\itemize{
\item \code{name} and \code{description};
\item \code{class}: the class of the stored object;
\item \code{call}: an example call describing the calculation;
\item \code{computed_with}: the postrank and solver versions that were used;
\item \code{solves}: how many optimization problems were solved (0 for comparisons of stored results);
\item \code{created}: when it was computed (UTC).
}

Otherwise the stored object, for example a \code{postrank_analysis}, with its grades and numerical
results. Local solver installation paths were replaced with portable labels when saving.
}
\description{
\code{postrank_example()} reads results stored with the package. Call it without arguments to list the
examples or give a name to load one. Reading an example needs no solver.
}
\details{
The grading analyses used postrank 1.1.0 and HiGHS. The two comparison examples
summarize stored analyses. Some example calls are abbreviated or refer to another stored
result, such as \code{tutorial_two}. In the calls for \code{toy_minimax} and \code{toy_frontier},
\code{w} stands for \code{c(need_A = 0.6, need_B = 0.4)}.

Before a result is returned, postrank checks that the stored file is unchanged (its size and
SHA-256 checksum) and that this version of postrank can read it. Reading a result never runs a
solver and never changes the stored files.
}
\examples{
ex <- postrank_example()
ex[, c("name", "description")]

one <- postrank_example("tutorial_one")
get_grades(one)
}
\seealso{
\code{\link[=get_grades]{get_grades()}}, \code{\link[=get_risk]{get_risk()}}, \code{\link[=postrank]{postrank()}}
}
