## Author: Justin Abraham
## Name: covselect.r
## Desc.: Performs LASSO with repeated k-fold cross-validation
## Args.: depvar, vector of covariates
## Input: GE_HH-Baseline_Wide.dta
## Output: coef-outcome.dta dataset of LASSO coefficients
## Notes: This script takes in a Stata dataset and an argument of variable names to trim to a parsimonious set using LASSO. The idea is to use LASSO to select covariates most correlated with the dependent variable. Functionally, Stata can call this RScript file using shell commands. The key component is the "glmnet" package which is used to perform the LASSO. (For those who know: this algorithm uses cyclical coordinate de-scent in a path-wise fashion.) First, I take the .dta and convert it into a matrix omitting rows without observations (complete-case omission). Second, I use "glmnet" to fit a LASSO whose tuning parameter (lambda) is selected by 10-fold cross-validation. In this case, 1 subsample acts as the testing data and 9 subsamples are the training data. The result of this command is a fitted model with coefficients minimizing the squared prediction error. The sparse set comprises of variables on the RHS with non-zero coefficients.
## Instead of selecting based on one instance of LASSO, I repeat 100 times and minimize the average of the errors (variation in the CV across iterations comes from the random partitioning of the data into 10 folds). Furthermore, I choose not the minimizing lambda but the largest lambda such that the error is within 1 standard error of the minimum error. This "one SE rule" is an anti-conservative measure proposed by Tibshirani. The output of this script is a .dta file detailing the sparse set and their coefficient estimates.

required.packages <- c("haven", "dplyr", "glmnet", "foreign")
packages.missing <- required.packages[!required.packages %in% installed.packages()[,"Package"]]

if(length(packages.missing) > 0) {install.packages(required.packages, repo="https://cran.cnr.berkeley.edu/")}
lapply(required.packages, library, character.only = TRUE)

set.seed(479316908)

## Parse arguments ##

args <- commandArgs(trailingOnly=TRUE)

varlist <- c(unlist(strsplit(args, "\\s+")))
ylabel <- varlist[1]
xlabels <- varlist[2:length(varlist)]

## Load data and arguments ##

dta <- read_dta("data/UCT_FINAL_LASSO.dta")
dta_cc <- dta[complete.cases(dta[,varlist]),]

## Convert data into matrix format ##

x = as.matrix(select_(dta_cc, .dots = xlabels))
y = as.matrix(select_(dta_cc, ylabel))

## LASSO with repeated k-fold validation ##

k = 10
iterations = 300

lambdas = NULL

for (i in 1:iterations)
{
    fit <- cv.glmnet(x, y, nfolds = k)
    errors = data.frame(fit$lambda, fit$cvm, fit$cvsd)
    lambdas <- rbind(lambdas, errors)
}

## Take averages of repeated CV error ##

lam_avg <- aggregate(lambdas[, 2:3], list(lambdas$fit.lambda), mean)
lam_count <- aggregate(lambdas[, 1], list(lambdas$fit.lambda), length)
lam_avg[, 3] = lam_avg[, 3] / lam_count[, 2]

## Select subset of lambdas within 1 SE of CV error ##

minindex <- which(lam_avg[, 2] == min(lam_avg[, 2]))
mincvm <- lam_avg[minindex, 2]
minsd <- lam_avg[minindex, 3]
cvm1se <- mincvm + minsd

lam_sub <- subset(lam_avg, lam_avg[, 2] <= cvm1se)

## Select max lambda within 1 SE of CV error ##

maxindex = which(lam_sub[, 1] == max(lam_sub[, 1]))
maxlambda = lam_sub[maxindex, 1]

## Report LASSO coefficients ##

fit <- glmnet(x, y, lambda = maxlambda)

varnames <- rownames(as.matrix(coef(fit)))
coefs <- data.frame(cbind(varnames, as.matrix(coef(fit))))

names(coefs) <- c("predictors", paste("coefs_", ylabel, sep = ""))

path <- paste("data/lasso-", ylabel, ".csv", sep = "")
write.csv(coefs, file = path)
