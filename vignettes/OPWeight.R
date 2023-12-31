## ----setup, echo = FALSE-------------------------------------------------
knitr::opts_chunk$set(tidy = FALSE, cache = FALSE, autodep = TRUE)

## ----loadlibs, message=FALSE, warning=FALSE------------------------------
# install OPWeight package
if (!requireNamespace("BiocManager", quietly=TRUE))
    install.packages("BiocManager")
BiocManager::install("OPWeight", suppressUpdates=TRUE)

# load packages
library("OPWeight")
library("ggplot2")
library("airway")
library("DESeq2")
library(cowplot)
library(tibble)
library(qvalue)
library(MASS)

## ----dataProcessing, message=FALSE, warning=FALSE------------------------
data("airway", package = "airway")
dds <- DESeqDataSet(se = airway, design = ~ cell + dex)
dds <- DESeq(dds)
de_res_air <- results(dds)

## ----colnames_de_res_air-------------------------------------------------
colnames(de_res_air)
dim(de_res_air)

## ----loadOPWeight, message=FALSE, warning=FALSE--------------------------
filters = de_res_air$baseMean + .0001  # add a small constant to make all values positive
set.seed(123)
# one should use more nrep to obtain more acurate results
opw_results <- opw(pvalue = de_res_air$pvalue, filter = filters, nrep = 1000,
                   alpha = .1, tail = 2, effectType = "continuous", method = "BH")

## ----outputsName---------------------------------------------------------
names(opw_results)

## ----nullProp------------------------------------------------------------
opw_results$nullProp

## ----no.OfRejections-----------------------------------------------------
opw_results$rejections

## ----probVsWeight--------------------------------------------------------
m = opw_results$totalTests
testRanks = 1:m
probs = opw_results$ranksProb
weights = opw_results$weight
dat = tibble(testRanks, probs, weights)
p_prob = ggplot(dat, aes(x = testRanks, y = probs)) + geom_point(size = .5, col="firebrick4") + 
    labs(x = "Test rank" , y = "p(rank | effect)")
p_weight = ggplot(dat, aes(x = testRanks, y = weights)) + geom_point(size = .5, col="firebrick4")+
    labs(x = "Test rank" , y = "Weight")
plot_grid(p_prob, p_weight, labels = c("a", "b"))

## ----summaryPlots--------------------------------------------------------
Data <- tibble(pval=de_res_air$pvalue, filter=de_res_air$baseMean)


hist_pval <- ggplot(Data, aes(x = Data$pval)) +
        geom_histogram(colour = "#1F3552", fill = "#4281AE")+
		labs(x = "P-values")

hist_filter <- ggplot(Data, aes(x = Data$filter)) +
        geom_histogram( colour = "#1F3552", fill = "#4274AE")+
		labs(x = "Filter statistics")
        
pval_filter <- ggplot(Data, aes(x = rank(-Data$filter), y = -log10(pval))) +
		geom_point()+
		labs(x = "Ranks of filters", y = "-log(pvalue)")
		
p_ecdf <- ggplot(Data, aes(x = pval)) +
			stat_ecdf(geom = "step")+
			labs(x = "P-values", title="Empirical cumulative distribution")+
			theme(plot.title = element_text(size = rel(.7)))

p <- plot_grid(hist_pval, hist_filter, pval_filter, p_ecdf, 
               labels = c("a", "b", "c", "d"), ncol = 2)
# now add the title
title <- ggdraw() + draw_label("Airway: data summary")
plot_grid(title, p, ncol = 1, rel_heights=c(0.1, 1)) 


## ----dataAnalysis--------------------------------------------------------
# initial stage--------
pvals = de_res_air$pvalue
tests = qnorm(pvals/2, lower.tail = FALSE)
filters = de_res_air$baseMean + .0001    # to ensure filters are postive for the box-cox

# formulate a data set-------------
Data = tibble(pvals, filters)
OD <- Data[order(Data$filters, decreasing=TRUE), ]
Ordered.pvalue <- OD$pvals


# estimate the true null and alternative test sizes------
m = length(Data$pvals); m
nullProp = qvalue(Data$pvals, pi0.method="bootstrap")$pi0; nullProp
m0 = ceiling(nullProp*m); m0
m1 = m - m0; m1

# fit box-cox regression
#--------------------------------

bc <- boxcox(filters ~ tests)
lambda <- bc$x[which.max(bc$y)]; lambda
model <- lm(filters^lambda ~ tests)

# etimated test efects of the true altrnatives------------
test_effect = if(m1 == 0) {0
} else {sort(tests, decreasing = TRUE)[1:m1]}		# two-tailed test

# for the continuous effects etimated mean effects
mean_testEffect = mean(test_effect, na.rm = TRUE)
mean_testEffect
mean_filterEffect = model$coef[[1]] + model$coef[[2]]*mean_testEffect
mean_filterEffect

## ----ranksProb-----------------------------------------------------------
set.seed(123)
prob_cont <- sapply(1:m, prob_rank_givenEffect, et = mean_filterEffect,
                   ey = mean_filterEffect, nrep = 1000, m0 = m0, m1 = m1)

## ----weights-------------------------------------------------------------
# delInterval can be smaller to otain the better results
wgt <- weight_continuous(alpha = .1, et = mean_testEffect, m = m, 
                         delInterval = .01, ranksProb = prob_cont)

## ----results-------------------------------------------------------------
alpha = .1
padj <- p.adjust(Ordered.pvalue/wgt, method = "BH")
rejections_list = OD[which((padj <= alpha) == TRUE), ]
n_rejections = dim(rejections_list)[1]
n_rejections

## ------------------------------------------------------------------------
opw_results2 <- opw(pvalue = pvals, filter = filters, weight = wgt, 
                     effectType = "continuous", alpha = .1, method = "BH")
opw_results2$rejections

