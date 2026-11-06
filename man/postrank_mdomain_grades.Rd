% Please edit documentation in R/mdomain-evaluate.R
\name{postrank_mdomain_grades}
\alias{postrank_mdomain_grades}
\title{Extract Verified Multidomain Grades}
\usage{
postrank_mdomain_grades(x)
}
\arguments{
\item{x}{A \code{postrank_mdomain_evaluation}, or a \code{postrank_mdomain_fit} with a
stored validated public evaluation. An unsuccessful fit has no card.}
}
\value{
A named integer unit by domain grade matrix in original input order.
}
\description{
Extract Verified Multidomain Grades
}
\details{
The input and stored result receipt are checked before extraction.
Altered result objects must be evaluated again. This accessor never solves
a decision problem or recomputes posterior quantities.
}
\concept{multidomain}
