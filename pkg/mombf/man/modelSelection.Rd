\name{modelSelection}
\alias{modelSelection}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{ Bayesian variable selection for linear models via non-local priors. }
\description{
  \code{modelSelection} implements Bayesian model selection for several
  non-local prior formulations such as the (product) MOM and iMOM. The
  implemented algorithm uses a Gibbs scheme, so that a posterior sample
  reflecting the uncertainty in model selection is obtained.
}
\usage{
modelSelection(y, x, center = TRUE, scale = TRUE, niter = 10^4, thinning
= 1, burnin = round(niter/10), priorCoef, priorDelta, priorVar, phi,
deltaini = rep(FALSE, ncol(x)), initSearch = "greedy", method, B = 10^5,
verbose = TRUE) 
}
%- maybe also 'usage' for other objects documented here.
\arguments{
\item{y}{Vector with observed responses}
\item{x}{Design matrix with all potential predictors}
\item{center}{If \code{center==TRUE}, \code{y} and \code{x} are centered to have zero mean, therefore eliminating the need to include an intercept term in x}
\item{scale}{If \code{scale==TRUE}, \code{y} and columns in \code{x} are scaled to have standard deviation 1}
\item{niter}{Number of Gibbs sampling iterations}
\item{thinning}{MCMC thinning factor, i.e. only one out of each \code{thinning} iterations are reported. Defaults to thinning=1, i.e. no thinning}
\item{burnin}{Number of burn-in MCMC iterations. Defaults to
  \code{.1*niter}. Set to 0 for no burn-in}
\item{priorCoef}{Prior distribution for the coefficients. Must be object of class \code{msPriorSpec} with slot \code{priorType} set to 'coefficients'. Possible values for slot \code{priorDistr} are 'pMOM', 'piMOM' and 'peMOM'}
\item{priorDelta}{Prior on model indicator space. Must be object of class \code{msPriorSpec} with slot \code{priorType} set to 'modelIndicator'. Possible values for slot \code{priorDistr} are 'uniform' and 'binomial'}
\item{priorVar}{Prior on residual variance. Must be object of class \code{msPriorSpec} with slot \code{priorType} set to 'nuisancePars'. Slot \code{priorDistr} must be equal to 'invgamma'}
\item{phi}{Residual variance. Typically this is unknown and therefore left missing. If specified argument priorVar is ignored}
\item{deltaini}{Logical vector of length \code{ncol(x)} indicating which coefficients should be initialized to be non-zero. Defaults to all variables being excluded from the model}
\item{initSearch}{Algorithm to refine \code{deltaini}. \code{initSearch=='greedy'} uses a greedy Gibbs sampling search. \code{initSearch=='SCAD'} sets \code{deltaini} to the non-zero elements in a SCAD fit with cross-validated regularization parameter. \code{initSearch=='none'} leaves \code{deltaini} unmodified}
\item{method}{Method to compute marginal
  densities. \code{method=='Laplace'} for Laplace approx,
  \code{method=='MC'} for Importance Sampling, \code{method=='Hybrid'}
  for Hybrid Laplace-IS (the latter method is only used for piMOM prior
  with unknown residual variance \code{phi}). See Details.}
\item{B}{Number of samples to use in Importance Sampling scheme. Ignored if \code{method=='Laplace'}}
\item{verbose}{Set \code{verbose==TRUE} to print iteration progress}
}
\details{
  Let delta be the vector indicating inclusion/exclusion of each
  column of x in the model. The algorithm sequentially samples from the
  posterior of each element in delta conditional on all the remaining
  elements in delta and the data.
  To perform this step it is necessary to evaluate the marginal density for any
  given delta, i.e. to integrate the likelihood of the data given
  (beta,delta) wrt the prior on beta given (delta,phi) times the prior
  on the residual variance phi.
  
  As these marginal densities are not available in closed form we
  implement Laplace-like approximations and exact evaluation via Importance
  Sampling. For the iMOM prior we also implement a Hybrid Laplace-IS
  which uses a Laplace approximation to evaluate the integral wrt beta
  and integrates wrt phi numerically.

  Regular Laplace approximations are used to compute marginals when the
  residual variance phi is known. In the more typical case where the
  variance is unknown, direct Laplace approximations can be poor due to
  the posterior for phi being highly non-normal.
  For MOM priors we integrate phi analytically and use a Laplace
  approximation. For iMOM priors we re-parameterize to log(phi) and then
  use a regular Laplace approximation.
  
  It should be noted that Laplace approximations tend to under-estimate
  the marginal densities when the MLE for some parameter is very close
  to 0. That is, it tends to be conservative in the sense of excluding
  more variables from the model than the exact calculations.

  For more details on the methods used to compute marginal densities see
  Johnson & Rossell (2011).
}
\value{
A list with elements
\item{postSample}{\code{matrix} with posterior samples for the model
  indicator. \code{postSample[i,j]==1}
  indicates that variable j was included in the model in the MCMC
  iteration i}
\item{postOther}{\code{postOther}
  returns posterior samples for parameters other than the model
  indicator, i.e. basically hyper-parameters.
  If hyper-parameters were fixed in the model specification, \code{postOther} will be empty.}
\item{margpp}{Marginal posterior probability for inclusion of each
  covariate. This is computed by averaging marginal post prob for
  inclusion in each Gibbs iteration, which is much more accurate than
  simply taking \code{colMeans(postSample)}}.
\item{postMode}{Model with highest posterior probability amongst all those visited}
\item{postModeProb}{Unnormalized posterior prob of posterior mode (log scale)}
\item{postProb}{Unnormalized posterior prob of each visited model (log
  scale)}
\item{coef}{Estimated coefficients (via posterior mode) for highest
  posterior probability model}
}
\references{
  Johnson V.E., Rossell D. Non-Local Prior Densities for Default
  Bayesian Hypothesis Tests. Journal of the Royal Statistical Society B,
  2010, 72, 143-170.
  Johnson V.E., Rossell D. Bayesian model selection in high-dimensional
  settings. Technical report. 2011
  See http://rosselldavid.googlepages.com for technical reports.
}
\author{ David Rossell }
\seealso{
 For more details on the prior specification see \code{\link{msPriorSpec-class}}
 To compute marginal densities for a given model see
  \code{\link{pmomMarginalK}}, \code{\link{pmomMarginalU}},
  \code{\link{pimomMarginalK}}, \code{\link{pimomMarginalU}}.
}
\examples{
#Simulate data
x <- matrix(rnorm(100*3),nrow=100,ncol=3)
theta <- matrix(c(1,1,0),ncol=1)
y <- x \%*\% theta + rnorm(100)

#Specify prior parameters
priorCoef <- new("msPriorSpec",priorType='coefficients',priorDistr='piMOM',priorPars=c(tau=1))
priorDelta <- new("msPriorSpec",priorType='modelIndicator',priorDistr='uniform',priorPars=double(0))
priorVar <- new("msPriorSpec",priorType='nuisancePars',priorDistr='invgamma',priorPars=c(alpha=.01,lambda=.01))

#Alternative prior for model space: 0.5 prior prob for including any covariate
priorDelta <-
new("msPriorSpec",priorType='modelIndicator',priorDistr='binomial',priorPars=c(p=.5))

#Alternative prior for model space: Beta hyper-prior for prob of inclusion
priorDelta <-
new("msPriorSpec",priorType='modelIndicator',priorDistr='binomial',priorPars=c(alpha.p=1,beta.p=1))


#Model selection
fit1 <- modelSelection(y=y, x=x, center=FALSE, scale=FALSE, niter=10^2,
priorCoef=priorCoef, priorDelta=priorDelta, priorVar=priorVar, phi=1,
method='Laplace')
fit1$postMode
fit1$margpp
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ models }
\keyword{ htest }
