emomLM <- function(y, x, xadj, phi, tau=1, tau.adj=10^6, alpha.phi=.01, lambda.phi=.01, niter=10^3, modelPrior, initSearch='SCAD', verbose=TRUE) {
#Fit linear model with emom prior on regression coefficients
# Input
# - y: vector with response variable
# - x: design matrix with covariates to be selected
# - xadj: design matrix with ajustment covariates for which no selection process is to be performed (i.e. always included in the model). xadj should include a column of 1's to account for the intercept term. By default xadj is set to matrix(1,ncol=1,nrow=length(y))
# - phi: residual variance. If unknown leave phi missing, a prior phi ~ Inverse Gamma (alpha.phi,lambda.phi) is used.
# - tau: prior dispersion for eMOM prior on the coefficients associated to x
# - tau.adj: prior dispersion for multivariate normal prior on the coefficients associated to xadj
# - niter: number of Gibbs sampling iterations
# - modelPrior: function to compute the model log-prior probability
# Output: list with 2 elements
# - postSample: posterior samples
# - margpp: marginal posterior probability for inclusion of each covariate (approx by averaging marginal post prob for inclusion in each Gibbs iteration. This approx is more accurate than simply taking colMeans(postSample)).
require(mvtnorm)
if (missing(phi)) { unknownPhi <- TRUE } else { unknownPhi <- FALSE }
if (is.vector(y)) y <- matrix(y,ncol=1)
if (missing(xadj)) xadj <- matrix(1,nrow=nrow(y),ncol=1)
#Pre-compute useful quantities
n <- nrow(y); p1 <- ncol(x); p2 <- ncol(xadj)
XtX <- t(x) %*% x
S2 <- t(xadj) %*% xadj + diag(1/tau.adj,nrow=p2)
S2inv <- solve(S2)
cholS2inv <- chol(S2inv, pivot = TRUE)
cholS2inv <- cholS2inv[,order(attr(cholS2inv, "pivot"))]
#Initialize
postDelta <- postTheta1 <- matrix(NA,nrow=niter,ncol=p1)
postTheta2 <- matrix(NA,nrow=niter,ncol=p2)
postPhi <- double(niter)
if (initSearch=='none') {
  sel <- rep(FALSE,p1)
  postDelta[1,] <- sel
  postTheta1[1,] <- rep(0,p1)
} else if (initSearch=='SCAD') {
  cvscad <- cv.ncvreg(X=x,y=y,family="gaussian",penalty="SCAD",nfolds=10,dfmax=1000,max.iter=10^4)
  postTheta1[1,] <- ncvreg(X=x,y=y,penalty="SCAD",dfmax=1000,lambda=rep(cvscad$lambda[cvscad$cv],2))$beta[-1, 1]
  postDelta[1,] <- postTheta1[1,]!=0
}
postTheta2[1,] <- S2inv %*% t(xadj) %*% y
linpred1 <- x %*% t(postTheta1[1,,drop=FALSE])
linpred2 <- xadj %*% t(postTheta2[1,,drop=FALSE])
e <- y-linpred2
postPhi[1] <- ifelse(unknownPhi, var(e), phi)
#Iterate
for (i in 2:niter) {
  #Sample delta1, theta1
  curDelta <- postDelta[i-1,]; curTheta1 <- postTheta1[i-1,]
  for (j in 1:p1) {
    ej <- e+curTheta1[j]*x[,j]
    newval <- MHTheta1emom(ej,j=j,delta=curDelta,theta1=curTheta1,phi=postPhi[i-1],tau=tau,xj=x[,j],modelPrior=modelPrior)
    curDelta[j] <- newval$delta; curTheta1[j] <- newval$theta1
    if (newval$accept) e <- ej - curTheta1[j]*x[,j]   #Update residuals
  }
  postDelta[i,] <- curDelta; postTheta1[i,] <- curTheta1
  #Sample theta2
  e <- e+linpred2
  postTheta2[i,] <- simTheta2(e=e, xadj=xadj, S2inv=S2inv, cholS2inv=cholS2inv, phi=postPhi[i-1])
  linpred2 <- xadj %*% t(postTheta2[i,,drop=FALSE])
  e <- e - linpred2
  #Sample phi
  postPhi[i] <- ifelse(unknownPhi, simPhiemom(phiCurrent=postPhi[i-1],alpha.phi=alpha.phi,lambda.phi=lambda.phi,n=n,delta=curDelta,p2=p2,theta1=curTheta1[curDelta],theta2=postTheta2[i,],tau=tau,tau.adj=tau.adj,ssr=sum(e^2)), phi)
  if (verbose & ((i %% (niter/10))==0)) cat('.')
}
if (verbose) cat('\n')
ans <- cbind(postDelta,postTheta1,postTheta2,postPhi)
colnames(ans) <- c(paste('delta',1:ncol(postDelta),sep=''),paste('theta',1:ncol(postTheta1),sep=''),paste('thetaAdj',1:ncol(postTheta2),sep=''),'postPhi')
return(ans)
}


emomPM <- function(y, x, xadj, tau=1, tau.adj=10^6, niter=10^3, modelPrior, initSearch="SCAD", verbose=TRUE) {
#Fit probit model with emom prior on regression coefficients
# Input
# - y: vector with response variable (must be a factor with 2 levels or a character which can be converted to factor with 2 levels)
# - x: design matrix with covariates to be selected
# - xadj: design matrix with ajustment covariates for which no selection process is to be performed (i.e. always included in the model). xadj should include a column of 1's to account for the intercept term. By default xadj is set to matrix(1,ncol=1,nrow=length(y))
# - tau: prior dispersion for eMOM prior on the coefficients associated to x
# - tau.adj: prior dispersion for multivariate normal prior on the coefficients associated to xadj
# - niter: number of Gibbs sampling iterations
# - modelPrior: function to compute the model log-prior probability
# Output: list with 2 elements
# - postSample: posterior samples
# - margpp: marginal posterior probability for inclusion of each covariate (approx by averaging marginal post prob for inclusion in each Gibbs iteration. This approx is more accurate than simply taking colMeans(postSample)).
require(mvtnorm)
if (is.character(y)) { y <- as.numeric(factor(y))-1 } else if (is.factor(y)) { y <- as.numeric(y)-1 }
if (length(unique(y))>2) stop('y has more than 2 levels')
if (missing(xadj)) xadj <- matrix(1,nrow=nrow(y),ncol=1)
#Pre-compute useful quantities
n <- length(y); p1 <- ncol(x); p2 <- ncol(xadj)
XtX <- t(x) %*% x
S2 <- t(xadj) %*% xadj + diag(1/tau.adj,nrow=p2)
S2inv <- solve(S2)
cholS2inv <- chol(S2inv, pivot = TRUE)
cholS2inv <- cholS2inv[,order(attr(cholS2inv, "pivot"))]
#Initialize
postDelta <- postTheta1 <- matrix(NA,nrow=niter,ncol=p1)
postTheta2 <- matrix(NA,nrow=niter,ncol=p2)
if (initSearch=='none') {
  sel <- rep(FALSE,p1)
  postDelta[1,] <- sel
  postTheta1[1,] <- rep(0,p1)
} else if (initSearch=='SCAD') {
  cvscad <- cv.ncvreg(X=x,y=y,family="binomial",penalty="SCAD",nfolds=10,dfmax=1000,max.iter=10^4)
  postTheta1[1,] <- ncvreg(X=x,y=y,penalty="SCAD",dfmax=1000,lambda=rep(cvscad$lambda[cvscad$cv],2))$beta[-1, 1]
  postDelta[1,] <- postTheta1[1,]!=0
}
postTheta2[1,] <- coef(glm(factor(y) ~ -1 + xadj, family=binomial(link='probit')))
linpred1 <- x %*% t(postTheta1[1,,drop=FALSE])
linpred2 <- xadj %*% t(postTheta2[1,,drop=FALSE])
#Iterate
for (i in 2:niter) {
  #Sample latent variables z
  linpred <- linpred1+linpred2; plinpred <- pnorm(-linpred)
  u <- ifelse(y,runif(n,plinpred,1),runif(n,0,plinpred))
  e <- qnorm(u)
  z <- linpred + e
  #Sample delta1, theta1
  curDelta <- postDelta[i-1,]; curTheta1 <- postTheta1[i-1,]
  for (j in 1:p1) {
    ej <- e+curTheta1[j]*x[,j]
    newval <- MHTheta1emom(ej,j=j,delta=curDelta,theta1=curTheta1,phi=1,tau=tau,xj=x[,j],modelPrior=modelPrior)
    curDelta[j] <- newval$delta; curTheta1[j] <- newval$theta1
    if (newval$accept) e <- ej - curTheta1[j]*x[,j]   #Update residuals
  }
  postDelta[i,] <- curDelta; postTheta1[i,] <- curTheta1
  linpred1 <- x %*% matrix(curTheta1,ncol=1)
  #Sample theta2
  e <- e+linpred2
  postTheta2[i,] <- simTheta2(e=e, xadj=xadj, S2inv=S2inv, cholS2inv=cholS2inv, phi=1)
  linpred2 <- xadj %*% t(postTheta2[i,,drop=FALSE])
  #e <- e - linpred2
  if (verbose & ((i %% (niter/10))==0)) cat('.')
}
if (verbose) cat('\n')
ans <- cbind(postDelta,postTheta1,postTheta2)
colnames(ans) <- c(paste('delta',1:ncol(postDelta),sep=''),paste('theta',1:ncol(postTheta1),sep=''),paste('thetaAdj',1:ncol(postTheta2),sep=''))
return(ans)
}



## eMOM MCMC scheme routines

proposaleMOM <- function(m,S,phi,tau,e,xj,m1,nu) {
#Approximate univariate eMOM posterior with a 2 component T mixture with nu df
# Posterior: N(e; xj*theta; phi*I) * emom(theta; phi, tau) / m1
# Mixture: w1 * T_nu(theta;mu1,sigma21) + (1-w1) * T_nu(theta;mu2,sigma22)  (sigma21, sigma22 denote variances)
# - m,S: posterior parameters
# - phi: residual variance
# - tau: prior dispersion parameter
# - e: response variable
# - xj: predictor
# - m1: normalization constant
# - nu: desired degrees of freedom
# Output: named vector with parameters of approximating mixture
  mu <- polyroot(c(-2*phi^2*tau/S,0,0,-m,1))  #Posterior mode
  mu <- Re(mu[abs(Im(mu))< 1e-7])
  fmode <- exp(sum(dnorm(e, mu[2]*xj, sd=sqrt(phi), log=TRUE)) + demom(mu[2], tau=tau, phi=phi, logscale=TRUE) - m1) #Value at mode
  sigma2 <- 1/diag(fppemomNeg(mu,m=m,S=S,phi=phi,tau=tau)) #Proposal variances
  #w1 <- max(0,(fmode - 1/sqrt(2*pi*sigma2[2]))/(dnorm(mu[2],mu[1],sd=sqrt(sigma2[1])) - 1/sqrt(2*pi*sigma2[2]))) #Weight
  ct2 <- exp(lgamma(.5*nu+.5) - .5*log(nu) - lgamma(.5*nu) - .5*log(pi*sigma2[2]))
  w1 <- max(0,(fmode - ct2)/(dnorm(mu[2],mu[1],sd=sqrt(sigma2[1])) - ct2)) #Weight
  ans <- c(mu,sigma2,w1)
  names(ans) <- c('mu1','mu2','sigma21','sigma22','w1')
  return(ans)
}

    
MHTheta1emom <- function(e,j,delta,theta1,phi,tau,xj,modelPrior) {
  #MH step to simulate (delta[j], theta1[j]) from its posterior given the data, delta[-j], theta1[-j], theta2 and phi parameters
  # Input
  # - e: partial residuals, i.e. y - predicted y given all covariates except covariate j
  # - j: index of the element in delta and theta1 to update
  # - delta: current value for delta
  # - theta1: current value for theta1
  # - phi: current value for phi
  # - tau: current value for tau
  # - xj: vector containing the column of the design matrix associated with theta1[j]
  # - modelPrior: function to compute the model log-prior probability
  # Ouput: list with the following elements
  # - delta: new value for delta[j] (can be the same as input value if proposal not accepted)
  # - theta1: new value for theta1[j]
  # - accept: logical variable indicated whether proposed new value has been accepted or not
  #Propose
  m1 <- emomMargKuniv(y=e, x=xj, phi=phi, tau=tau, logscale=TRUE)
  logbf <- sum(dnorm(e,0,sd=sqrt(phi),log=TRUE)) - m1
  delta0 <- delta1 <- delta; delta0[j] <- FALSE; delta1[j] <- TRUE
  logpratio01 <- modelPrior(delta0) - modelPrior(delta1)
  p <- 1/(1 + exp(logbf+logpratio01))
  deltaProp <- rbinom(n=1,size=1,prob=p)
  nu <- sqrt(ifelse(is.matrix(e),nrow(e),length(e)))
  #Acceptance prob
  if ((!delta[j]) & (deltaProp==0)) {
    thetaProp <- 0
    lambda <- 1
  } else {
    S <- sum(xj^2) + 1/tau; m <- sum(xj*e)/S
    propPars <- proposaleMOM(m=m,S=S,phi=phi,tau=tau,e=e,xj=xj,m1=m1,nu=nu)
    thetaProp <- rTmix2comp(pars=propPars, df=nu)
    #thetaProp <- ifelse(runif(1)<propPars['w1'], propPars['mu1']+rmvt(n=1,sigma=matrix(propPars['sigma21'],nrow=1),df=nu), propPars['mu2']+rmvt(n=1,sigma=matrix(propPars['sigma22'],nrow=1),df=nu))
    if (delta[j] & (deltaProp==1)) {
      lhood <- sum(dnorm(e,thetaProp*xj,sd=sqrt(phi),log=TRUE)) - sum(dnorm(e,theta1[j]*xj,sd=sqrt(phi),log=TRUE))
      lprior <- demom(thetaProp,tau=tau,phi=phi,logscale=TRUE) - demom(theta1[j],tau=tau,phi=phi,logscale=TRUE)
      lprop <- dTmix2comp(theta1[j],pars=propPars,df=nu,logscale=TRUE) - dTmix2comp(thetaProp,pars=propPars,df=nu,logscale=TRUE)
      lambda <- exp(lhood + lprior + lprop)
    } else if ((!delta[j]) & (deltaProp==1)) {
      num <- sum(dnorm(e,thetaProp*xj,sd=sqrt(phi),log=TRUE)) + demom(thetaProp,tau=tau,phi=phi,logscale=TRUE)
      den <- dTmix2comp(thetaProp,pars=propPars,df=nu,logscale=TRUE) + m1
      lambda <- exp(num-den)
    } else if ((delta[j]) & (deltaProp==0)) {
      thetaProp <- 0
      num <- dTmix2comp(theta1[j],pars=propPars,df=nu,logscale=TRUE) + m1
      den <- sum(dnorm(e,theta1[j]*xj,sd=sqrt(phi),log=TRUE)) + demom(theta1[j],tau=tau,phi=phi,logscale=TRUE)
      lambda <- exp(num-den)
    }
  }
  if (runif(1)<lambda) {
    ans <- list(delta=(deltaProp==1), theta1=thetaProp, accept=TRUE)
  } else {
    ans <- list(delta=delta[j], theta1=theta1[j], accept=FALSE)
  }
  return(ans)
}


## eMOM MCMC routines
postPhiemom <- function(phi, a, l, t, logscale=TRUE) {
  #Posterior density for variance phi given all other parameters under an emom prior
  # i.e. exp(t*phi) IG(phi;a/2,l/2) / normk, where normk is the normalization constant
  normk <- mgfInvGamma(t,a/2,l/2,logscale=TRUE)
  ans <- phi*t + dinvgamma(phi,a/2,scale=l/2,log=TRUE) - normk
  if (!logscale) ans <- exp(ans)
  return(ans)
}

postPhiemomApprox <- function(a,l,t) {
  #Find IG approximating post distrib of phi (residual variance) under an eMOM prior, conditional on (theta,delta)
  #Returns shape and scale parameter of approximating IG.
  if (a<=2) {
    shape <- a/2; scale <- l/2
  } else {
    k <- mgfInvGamma(t,a/2,l/2,logscale=TRUE)
    m <- exp(mgfInvGamma(t,a/2-1,l/2,logscale=TRUE) - k + log(.5*l) - log(a/2-1))
    if (a<=4) {
      shape <- a/2
    } else {
      m2 <- exp(mgfInvGamma(t,a/2-2,l/2,logscale=TRUE) - k + 2*log(.5*l) - log(a/2-1) - log(a/2-2))
      shape <- m^2/(m2-m^2)+2
    }
    scale <- (shape-1)*m
  }
  ans <- c(shape,scale); names(ans) <- c('shape','scale')
  return(ans)
}

simPhiemom <- function(phiCurrent, alpha.phi, lambda.phi, n, delta, p2, theta1, theta2, tau, tau.adj, ssr) {
 #MH step to draw from posterior of the variance given all other parameters under a pmom prior
 # - phiCurrent: current value for phi
 # - other params which define the posterior
  a <- alpha.phi + n + sum(delta) + p2
  l <- lambda.phi + sum(theta1^2)/tau + sum(theta2^2)/tau.adj + ssr
  t <- -tau*sum(1/theta1^2)
  approxpar <- postPhiemomApprox(a=a,l=l,t=t)
  phiProp <- 1/rgamma(1,shape=approxpar['shape'],rate=approxpar['scale'])
  accprob <- exp(postPhiemom(phiProp,a=a,l=l,t=t,logscale=TRUE) - postPhiemom(phiCurrent,a=a,l=l,t=t,logscale=TRUE) + dinvgamma(phiCurrent,shape=approxpar['shape'],scale=approxpar['scale'],log=TRUE) - dinvgamma(phiProp,shape=approxpar['shape'],scale=approxpar['scale'],log=TRUE))
  if (runif(1)< accprob) phiCurrent <- phiProp
  return(phiCurrent)
}


### Other eMOM routines
lbesselK <- function(x, nu) log(besselK(x,nu=nu,expon.scaled=TRUE)) - x

myrmvnorm <- function(n, mean=rep(0,nrow(V)), V=diag(length(mean)), scale) {
#Same as regular rmvnorm except that it allows for a vector variance scaling parameter
# i.e. generates n draws: N(mean,scale[1]*V),...,N(mean,scale[n]*V)
  if (!(length(scale) %in% c(1,n))) stop("scale should be either of length 1 or n")
  p <- length(mean)
  cholV <- t(chol(V))
  z <- t(cholV %*% matrix(rnorm(n*p,0,1),nrow=p,ncol=n))
  t(as.vector(mean) + t(z * sqrt(scale)))
}


mgfInvGamma <- function(t, a, l, logscale=TRUE) {
  #MGF of IG(a,l) evaluated at t
  ans <- log(2) + (a/2)*log(-t*l) - lgamma(a) + lbesselK(sqrt(-4*t*l), nu=a)
  if (!logscale) ans <- exp(ans)
  return(ans)
}


mgfInvChisq <- function(t, df, ncp) {
#MGF of inverse chi-square with df degrees of freedom and non-centrality parameter ncp evaluated at t
  minnu <- 0; nuseq <- minnu:(minnu+100)
  sumseq <- exp(dpois(nuseq,ncp/2,log=TRUE) + log(besselK(sqrt(-2*t),nuseq+.5*df,expon.scaled=TRUE)) - sqrt(-2*t)  + .5*nuseq*(log(-t)-log(2)) - lgamma(nuseq+.5*df))
  ct <- log(-t)*df/4 + (1-df/4)*log(2)
  s <- sum(sumseq[sumseq!= Inf])
  while ((sumseq[length(sumseq)]> .0001*s) & !any(sumseq==Inf)) {
    minnu <- minnu+100
    nuseq <- (minnu+1):(minnu+100)
    sumseq <- exp(dpois(nuseq,ncp/2,log=TRUE) + log(besselK(sqrt(-2*t),nuseq+.5*df,expon.scaled=TRUE)) - sqrt(-2*t)  - .5*nuseq*(log(-t)-log(2)) - lgamma(nuseq+.5*df))
    s <- s+sum(sumseq[sumseq!=Inf])
  }
  ans <- s*exp(ct)
  return(ans)
}

emomMargKuniv <- function(y,x,phi,tau=1,logscale=TRUE) {
#Univariate marginal density under an emom prior (known variance case)
# integral N(y; x*theta, phi*I) * exp(-tau*phi/theta^2) * N(theta; 0; tau*phi) * exp(sqrt(2)) d theta
# - y: response variable (must be a vector)
# - x: design matrix (must be a vector)
# - phi: residual variance
# - tau: prior variance parameter (defaults to length(y))
# - logscale: if set to TRUE the log of the integral is returned
  n <- length(y)
  if (n != length(y)) stop("Dimensions of x and y don't match")
  if (missing(tau)) tau <- n
  s <- sum(x^2) + 1/tau
  m <- sum(x*y)/s
  I <- log(mgfInvChisq(t=-tau*s, df=1, ncp=m^2*s/phi))
  if (is.infinite(I)) {
    f <- function(th, m, s) { exp(-1/th^2) * dnorm(th,m,sd=sqrt(1/s)) }
    I <- log(integrate(f, -Inf, Inf, m=m, s=s)$value)
  }
  ans <- I -.5*(sum(y^2) - s*m^2)/phi + sqrt(2) - .5*n*log(2*pi*phi) - .5*(log(s)+log(tau))
  if (!logscale) ans <- exp(ans)
  return(ans)
}

femomNeg <- function(th, m, S, phi, tau, logscale=TRUE) .5*mahalanobis(th, center=m, cov=S, inverted=TRUE)/phi + tau*phi*sum(1/th^2)
fpemomNeg <- function(th, m, S, phi, tau) S %*% matrix(th-m, ncol=1)/phi - 2*tau*phi/th^3
fppemomNeg <- function(th, m, S, phi, tau) S/phi + 6*tau*phi*diag(1/th^4,nrow=length(th))
emomIntegralApprox <- function(m, S, phi, tau, logscale=TRUE) {
  #Laplace approx to integral N(th; m, phi*solve(S)) prod(exp(-tau*phi/th^2)) wrt th
  opt <- nlminb(m, objective=femomNeg, gradient=fpemomNeg, m=m, S=S, phi=phi, tau=tau)$par
  fopt <- -femomNeg(opt,m=m,S=S,phi=phi,tau=tau)
  hess <- fppemomNeg(opt,m=m,S=S,phi=phi,tau=tau)
  #ans <- exp(fopt) * sqrt(det(S))/(sqrt(det(hess)) * phi^(length(m)/2))
  ans <- fopt + .5*log(det(S)) - .5*log(det(hess)) - .5*length(m)*log(phi)
  if (!logscale) ans <- exp(ans)
  return(ans)
}

