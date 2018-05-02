######################################################################################
## GENERAL FUNCTIONS FOR NORMAL-INVERSE WISHART
######################################################################################

#log of the Multivariate gamma function
lmgamma= function(p,a) { 0.25*p*(p-1)*log(pi) + sum(lgamma(a + 0.5*(1-(1:p)))) }

diwish <- function(Sigma, nu, S, logscale=FALSE) {
    #Inverse Wishart density, adapted from LaplacesDemon package
    if (!is.matrix(Sigma)) Sigma <- matrix(Sigma)
    if (!is.matrix(S)) S <- matrix(S)
    if (!identical(dim(S), dim(Sigma))) stop("The dimensions of Sigma and S differ.")
    if (nu < nrow(S)) stop("The nu parameter is less than the dimension of S.")
    p <- nrow(Sigma)
    detSigma= as.numeric(determinant(Sigma,logarithm=TRUE)$modulus)
    detS= as.numeric(determinant(S,logarithm=TRUE)$modulus)
    ans <- -(nu * p/2) * log(2) - lmgamma(p,.5*nu) + (nu/2) * detS - ((nu + p + 1)/2) * detSigma - 0.5 * sum(diag((S %*% solve(Sigma))))
    if (!logscale) ans <- exp(ans)
    return(ans)
}


riwish <- function(nu, S, Sinv) {
    if (missing(Sinv)) Sinv <- solve(S)
    solve(rWishart(1, df=nu, Sigma=Sinv)[,,1])
}


dpostNIW <- function(mu,Sigma,x,g=1,mu0=rep(0,length(mu)),nu0=nrow(Sigma)+1,S0,logscale=FALSE) {
#Posterior Normal-IW density
#   x[i]       ~ N(mu,Sigma)
#   mu | Sigma ~ N(mu0, g Sigma)
#   Sigma ~ IW(nu0, S0)
# Input
# - x: n x p data matrix
# - g: prior dispersion parameter in the prior for mu
# - mu0: prior mean in the prior for mu
# - nu0: prior degrees of freedom for Sigma
# - S0: prior scale matrix for Sigma, by default set to I/nu0
# - logscale: set to TRUE to get the log-posterior density
# Output: Normal-IW posterior density evaluated at (mu,Sigma)
    if (!is.matrix(x)) stop("x must be a matrix")
    n= nrow(x); p= ncol(x)
    if (missing(S0)) { if (p==1) { S0= matrix(1/nu0) } else { S0= diag(p)/nu0 } }
    xbar= colMeans(x)
    nu1= nu0+n
    dm= matrix(xbar-mu0,ncol=1)
    S1= S0 + cov(x)*(n-1) + n/(1+n*g) * (dm %*% t(dm))
    w= n/(n+1/g)
    m1= w * xbar + (1-w) * mu0
    ans= dmvnorm(mu,m1,Sigma/(n+1/g),log=TRUE) + diwish(Sigma,nu=nu1,S=S1,logscale=TRUE)
    if (!logscale) ans= exp(ans)
    return(ans)
}



rpostNIW <- function(n,x,g=1,mu0=rep(0,length(mu)),nu0=nrow(Sigma)+1,S0,precision=FALSE) {
#Draws from posterior Normal-IW density
#   x[i]       ~ N(mu,Sigma)
#   mu | Sigma ~ N(mu0, g Sigma)
#   Sigma ~ IW(nu0, S0)
# Input
# - n: number of samples to be returned
# - x: n x p data matrix
# - g: prior dispersion parameter in the prior for mu
# - mu0: prior mean in the prior for mu
# - nu0: prior degrees of freedom for Sigma
# - S0: prior scale matrix for Sigma, by default set to I/nu0
# - precision: if set to TRUE, samples from the precision matrix Sigma^{-1} are returned instead
# Output: independent random draws from Normal-IW posterior
    if (!is.matrix(x)) stop("x must be a matrix")
    samplesize= nrow(x); p= ncol(x)
    if (missing(S0)) { if (p==1) { S0= matrix(1/nu0) } else { S0= diag(p)/nu0 } }
    xbar= colMeans(x)
    nu1= nu0+samplesize
    dm= matrix(xbar-mu0,ncol=1)
    S1= S0 + cov(x)*(samplesize-1) + samplesize/(1+samplesize*g) * (dm %*% t(dm))
    w= samplesize/(samplesize+1/g)
    m1= w * xbar + (1-w) * mu0
    ans= vector("list",2)
    if (!precision) { names(ans)= c("mu","Sigma") } else { names(ans)= c("mu","precision") }
    ans[[1]]= matrix(NA,nrow=samplesize,ncol=p)
    ans[[2]]= matrix(NA,nrow=samplesize,ncol=p*(p+1)/2)
    S1inv= solve(S1)
    for (i in 1:samplesize) {
        if (precision) {
            Sigmainv= rWishart(1, df=nu1, Sigma=S1inv)[,,1]
            Sigma= solve(Sigmainv)
            ans[[2]][i,]= Sigmainv[lower.tri(Sigmainv,diag=TRUE)]
        } else {
            Sigma= riwish(nu=nu1,Sinv=S1inv)
            ans[[2]][i,]= Sigma[lower.tri(Sigma,diag=TRUE)]
        }
        ans[[1]][i,]= rmvnorm(1,m1,Sigma/(samplesize+1/g))
    }
    return(ans)
}




######################################################################################
## MARGINAL LIKELIHOOD CALCULATIONS FOR NORMAL-INVERSE WISHART
######################################################################################


setMethod(marginalNIW, signature("missing","ANY","matrix","numeric","missing"), function(x, xbar, samplecov, n, z, g,  mu0=rep(0,ncol(x)), nu0=ncol(x)+4, S0, logscale=TRUE) {
#Integrated likelihood for
#   x[i]       ~ N(mu,Sigma)
#   mu | Sigma ~ N(mu0, g Sigma)
#   Sigma      ~ IW(nu0, S0)
#
#
# Input
# - xbar: p-vector with sample mean
# - samplecov: sample covariance
# - n: sample size
# - g: prior dispersion parameter in the prior for mu
# - mu0: prior mean in the prior for mu
# - nu0: prior degrees of freedom for Sigma
# - S0: prior scale matrix for Sigma, by default set to I/nu0
# - logscale: set to TRUE to get the log-integrated likelihood
    if (n==0) {
        ans= 0
    } else {
        p= ncol(samplecov)
        if (missing(S0)) { if (p==1) { S0= matrix(1/nu0) } else { S0= diag(p)/nu0 } }
        nupost= nu0+n
        if (n>1) { S= samplecov * (n-1) } else { S= matrix(0,nrow=p,ncol=p) }
        m= matrix(xbar-mu0,ncol=1)
        Spost= S0 + S + n/(1+n*g) * (m %*% t(m))
        detS0= as.numeric(determinant(S0,logarithm=TRUE)$modulus)
        detSpost= as.numeric(determinant(Spost,logarithm=TRUE)$modulus)
        ans= -.5*n*p*log(pi) + lmgamma(p,.5*nupost) - lmgamma(p,.5*nu0) + .5*nu0*detS0 - .5*nupost*detSpost - 0.5*p*log(1+n*g)
    }
    if (!logscale) ans= exp(ans)
    return(ans)
}
)

setMethod("marginalNIW", signature("matrix","missing","missing","missing","missing"), function(x, xbar, samplecov, n, z, g,  mu0=rep(0,ncol(x)), nu0=ncol(x)+4, S0,logscale=TRUE) {
#Integrated likelihood for
#   x[i]       ~ N(mu,Sigma)
#   mu | Sigma ~ N(mu0, g Sigma)
#   Sigma      ~ IW(nu0, S0)
#
#
# Input
# - x: n x p data matrix
# - g: prior dispersion parameter in the prior for mu
# - mu0: prior mean in the prior for mu
# - nu0: prior degrees of freedom for Sigma^{-1}
# - S0: prior scale matrix for Sigma^{-1}, by default set to I/nu0
# - logscale: set to TRUE to get the log-integrated likelihood
    if (!is.matrix(x)) stop("x must be a matrix")
    n= nrow(x); p= ncol(x)
    if (n==0) {
        ans= 0
    } else {
        if (missing(S0)) { if (p==1) { S0= matrix(1/nu0) } else { S0= diag(p)/nu0 } }
        nupost= nu0+n
        txc= t(x-colMeans(x)); S= txc %*% t(txc)
        m= matrix(colMeans(x)-mu0,ncol=1)
        Spost= S0 + S + n/(1+n*g) * (m %*% t(m))
        detS0= as.numeric(determinant(S0,logarithm=TRUE)$modulus)
        detSpost= as.numeric(determinant(Spost,logarithm=TRUE)$modulus)
        ans= -.5*n*p*log(pi) + lmgamma(p,.5*nupost) - lmgamma(p,.5*nu0) + .5*nu0*detS0 - .5*nupost*detSpost - 0.5*p*log(1+n*g)
    }
    if (!logscale) ans= exp(ans)
    return(ans)
}
)



setMethod("marginalNIW", signature("matrix","missing","missing","missing","vector"), function(x, xbar, samplecov, n, z, g,  mu0=rep(0,ncol(x)), nu0=ncol(x)+4, S0,logscale=TRUE) {
#Integrated likelihood for Normal-IW given cluster allocations z
#   x[i] | z[i]=k      ~ N(mu[k],Sigma[k])
#   mu[k] | Sigma[k] ~ N(mu0, g Sigma[k])
#   Sigma[k]^{-1} ~ W(nu0, S0)
#
# Output: integrated likelihood conditional on z
    if (length(z) != nrow(x)) stop("length(z) must be equal to nrow(x)")
    cluslabels= unique(z)
    cluslabels= cluslabels[order(cluslabels)]
    xbar= samplecov= vector("list",length(cluslabels))
    n= integer(length(cluslabels))
    for (i in 1:length(cluslabels)) {
        sel= (z==cluslabels[i])
        xbar[[i]]= colMeans(x[sel,,drop=FALSE])
        n[i]=sum(sel)
        if (n[i]>1) { samplecov[[i]]=cov(x[sel,,drop=FALSE]) } else { samplecov[[i]]= matrix(0,nrow=ncol(x),ncol=ncol(x)) }
    }
    ans= marginalNIW(xbar=xbar,samplecov=samplecov,n=n,g=g,mu0=mu0,nu0=nu0,S0=S0,logscale=TRUE)
    if (!logscale) ans= exp(ans)
    return(ans)
}
)


setMethod("marginalNIW", signature("missing","list","list","numeric","missing"), function(x, xbar, samplecov, n, z, g,  mu0=rep(0,ncol(x)), nu0=ncol(x)+4, S0,logscale=TRUE) {
#Integrated likelihood for Normal-IW given cluster allocations z
#   x[i] | z[i]=k      ~ N(mu[k],Sigma[k])
#   mu[k] | Sigma[k] ~ N(mu0, g Sigma[k])
#   Sigma[k]^{-1} ~ W(nu0, S0)
#
# Output: integrated likelihood conditional on z
    k= length(xbar)
    if ((length(samplecov) != k) | (length(n) !=k)) stop("length of xbar, samplecov and n must match")
    p= ncol(samplecov[[1]])
    if (missing(S0)) { if (p==1) { S0= matrix(1/nu0) } else { S0= diag(p)/nu0 } }
    ans= sum(sapply(1:k, function(i) marginalNIW(xbar=xbar[[i]],samplecov=samplecov[[i]],n=n[i],g=g,mu0=mu0,nu0=nu0,S0=S0,logscale=TRUE)))
    if (!logscale) ans= exp(ans)
    return(ans)
}
)
