#' @title Probability of rank of test given effect size by exact method
#'
#' @description An exact method to comnpute the probability of rank of a
#' test being higher than any other test given the effect size from external
#' information.
#' @param k Integer, rank of a test
#' @param et Numeric, effect of the targeted test for importance sampling
#' @param ey Numeric, mean/median filter efffect from external information
#' @param nrep Integer, number of replications for importance sampling
#' @param m0 Integer, number of true null hypothesis
#' @param m1 Integer, number of true alternative hypothesis
#' @param effectType Character ("continuous" or "binary"), type of effect sizes
#'
#' @details If one wants to test \deqn{H_0: epsilon_i=0 vs. H_a: epsilon_i > 0,}
#' then \code{ey} should be mean of the filter effect sizes,
#' This is called hypothesis testing for the continuous effect sizes.\cr
#'
#' If one wants to test \deqn{H_0: epsilon_i=0 vs. H_a: epsilon_i = epsilon,}
#' then \code{ey} should be median or any discrete value of the
#' filter effect sizes. This is called hypothesis testing for the Binary
#' effect sizes.\cr
#'
#' \code{m1} and \code{m0} can be estimated using \code{qvalue} from
#' a bioconductor package \code{qvalue}.
#'
#' @author Mohamad S. Hasan, shakilmohamad7@gmail.com
#'
#' @export
#'
#' @import stats
#'
#' @seealso \code{\link{dnorm}} \code{\link{pnorm}} \code{\link{rnorm}}
#' \code{\link{qvalue}}
#'
#' @return \code{prob} Numeric, probability of the rank of a test
#'
#' @examples
#' # compute the probability of the rank of a test being third if all tests are
#' # from the true null
#' prob <- prob_rank_givenEffect_exact(k=3, et=0, ey=0, nrep=10000, m0=50, m1=50,
#'                                 effectType= "continuous")
#'
#' # compute the probabilities of the ranks of a test being rank 1 to 100 if the
#' # targeted test effect is 2 and the overall mean filter effect is 1.
#' ranks <- 1:100
#' prob <- sapply(ranks, prob_rank_givenEffect, et = 2, ey = 1, nrep = 10000,
#'                               m0 = 50, m1 = 50)
#'
#' # plot
#' plot(ranks, prob)
#'
#===============================================================================
# function to compute p(rank=k|filterEffect=ey) by exact method
#---------------------------------------------------------------
# we used only uniform effects for continuous case.
# internal parameters:-----
# k0 = ranks under null model
# fun.k0 = input=null rank; output=prob of specific combo of r0 and r1
# t = generate test statistics for target test with effect size et
# p0 = prob of null test having higher test stat value than t
# m = total number of tests
# a = lower limit of the uniform distribution
# b = upper limit of the uniform distribution
# el = vector of uniform effect sizes
# p1 = prob of alt test having higher test stat value than t
# E.T = does importance sampling for the integration over t
#===============================================================================
prob_rank_givenEffect_exact <- function(k, et, ey, nrep = 10000, m0, m1,
                                        effectType = c("binary", "continuous"))
{
    k0 <- 1:k
    fun.k0 <- function(k0)
    {
        t <- rnorm(nrep, et, 1)
        p0 <- pnorm(-t)

        if(effectType == "binary"){p1 <- pnorm(ey - t)
        } else { if(ey == 0){p1 <- pnorm(ey - t)
            } else {
                m = m0 + m1
                a = ey - 1
                b = ey
                xb = b - t
                xa = a - t
                p1 = (xb*pnorm(xb) - xa*pnorm(xa) + dnorm(xb) - dnorm(xa))/(b-a)
            }
        }

        E.T <- ifelse(et == 0, mean(dbinom(k0-1, m0-1, p0)*dbinom(k-k0, m1, p1)),
                      mean(dbinom(k0-1, m0, p0)*dbinom(k-k0, m1-1, p1)))
        return(E.T)
    }
    prob <- sum(sapply(k0,fun.k0))
    return(prob)
}
