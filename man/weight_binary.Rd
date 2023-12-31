% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/weight_binary.R
\name{weight_binary}
\alias{weight_binary}
\title{Weight for the Binary effect sizes}
\usage{
weight_binary(alpha, et, m, m1, tail = 1L, delInterval = 0.001, ranksProb)
}
\arguments{
\item{alpha}{Numeric, significance level of the hypothesis test}

\item{et}{Numeric, mean effect size of the test statistics}

\item{m}{Integer, totoal number of hypothesis test}

\item{m1}{Integer, number of true alternative hypothesis}

\item{tail}{Integer (1 or 2), right-tailed or two-tailed hypothesis test.
default is right-tailed test.}

\item{delInterval}{Numeric, interval between the \code{delta} values of a
sequence. Note that, \code{delta} is a LaGrange multiplier, necessary to
normalize the weight}

\item{ranksProb}{Numeric vector of the ranks probability of the tests
given the effect size}
}
\value{
\code{weight} Numeric vector of normalized weight of the tests for
the binary case
}
\description{
Compute weight from the probability of the rank given the effect size
for the binary effect size
}
\details{
If one wants to test \deqn{H_0: epsilon_i=0 vs. H_a: epsilon_i = epsilon,}
then \code{et} and \code{ey} should be median or any discrete value of the test
and filter effect sizes, respectively. This is called hypothesis testing for
the Binary effect sizes. \code{m1} can be estimated using \code{qvalue} from
a bioconductor package \code{qvalue}.
}
\examples{

# compute the probabilities of the ranks of a test being rank 1 to 100 if the
# targeted test effect is 2 and the overall mean filter effect is 1.
ranks <- 1:100
prob2 <- sapply(ranks, prob_rank_givenEffect, et = 2, ey = 1, nrep = 10000,
                              m0 = 50, m1 = 50)
# plot the prooabbility
plot(ranks, prob2)

# compute weight for the binary case
weight_bin <- weight_binary(alpha = .05, et = 1, m = 100, m1 = 50, tail=1,
                             delInterval = .0001, ranksProb = prob2)

# plot the weight
plot(ranks, weight_bin)

}
\seealso{
\code{\link{prob_rank_givenEffect}} \code{\link{weight_continuous}}
\code{\link{qvalue}}
}
\author{
Mohamad S. Hasan, shakilmohamad7@gmail.com
}
