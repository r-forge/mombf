// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <RcppArmadillo.h>
#include <Rcpp.h>

using namespace Rcpp;

// rcpparma_outerproduct
arma::mat rcpparma_outerproduct(const arma::colvec& x);
RcppExport SEXP _mombf_rcpparma_outerproduct(SEXP xSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const arma::colvec& >::type x(xSEXP);
    rcpp_result_gen = Rcpp::wrap(rcpparma_outerproduct(x));
    return rcpp_result_gen;
END_RCPP
}
// rcpparma_innerproduct
double rcpparma_innerproduct(const arma::colvec& x);
RcppExport SEXP _mombf_rcpparma_innerproduct(SEXP xSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const arma::colvec& >::type x(xSEXP);
    rcpp_result_gen = Rcpp::wrap(rcpparma_innerproduct(x));
    return rcpp_result_gen;
END_RCPP
}
// rcpparma_bothproducts
Rcpp::List rcpparma_bothproducts(const arma::colvec& x);
RcppExport SEXP _mombf_rcpparma_bothproducts(SEXP xSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< const arma::colvec& >::type x(xSEXP);
    rcpp_result_gen = Rcpp::wrap(rcpparma_bothproducts(x));
    return rcpp_result_gen;
END_RCPP
}

RcppExport SEXP bsplineCI(SEXP, SEXP, SEXP);
RcppExport SEXP eprod_I(SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP greedyVarSelCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP mnormCI(SEXP, SEXP, SEXP);
RcppExport SEXP modelSelectionEnumCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP modelSelectionGibbsCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP nlpMarginalCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP normalmixGibbsCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP pimomMarginalKI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP pimomMarginalUI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP pmomLM_I(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP pmomMarginalKI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP pmomMarginalUI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP rnlpCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP rnlpPostCI_lm(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP rnorm_truncMultCI(SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP rtmvnormCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP rtmvnormProdCI(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
RcppExport SEXP testfunctionCI(SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"_mombf_rcpparma_outerproduct", (DL_FUNC) &_mombf_rcpparma_outerproduct, 1},
    {"_mombf_rcpparma_innerproduct", (DL_FUNC) &_mombf_rcpparma_innerproduct, 1},
    {"_mombf_rcpparma_bothproducts", (DL_FUNC) &_mombf_rcpparma_bothproducts, 1},
    {"bsplineCI",             (DL_FUNC) &bsplineCI,              3},
    {"eprod_I",               (DL_FUNC) &eprod_I,                5},
    {"greedyVarSelCI",        (DL_FUNC) &greedyVarSelCI,        41},
    {"mnormCI",               (DL_FUNC) &mnormCI,                3},
    {"modelSelectionEnumCI",  (DL_FUNC) &modelSelectionEnumCI,  39},
    {"modelSelectionGibbsCI", (DL_FUNC) &modelSelectionGibbsCI, 45},
    {"nlpMarginalCI",         (DL_FUNC) &nlpMarginalCI,         30},
    {"normalmixGibbsCI",      (DL_FUNC) &normalmixGibbsCI,      13},
    {"pimomMarginalKI",       (DL_FUNC) &pimomMarginalKI,       15},
    {"pimomMarginalUI",       (DL_FUNC) &pimomMarginalUI,       17},
    {"pmomLM_I",              (DL_FUNC) &pmomLM_I,              36},
    {"pmomMarginalKI",        (DL_FUNC) &pmomMarginalKI,        16},
    {"pmomMarginalUI",        (DL_FUNC) &pmomMarginalUI,        18},
    {"rnlpCI",                (DL_FUNC) &rnlpCI,                 9},
    {"rnlpPostCI_lm",         (DL_FUNC) &rnlpPostCI_lm,         11},
    {"rnorm_truncMultCI",     (DL_FUNC) &rnorm_truncMultCI,      5},
    {"rtmvnormCI",            (DL_FUNC) &rtmvnormCI,             7},
    {"rtmvnormProdCI",        (DL_FUNC) &rtmvnormProdCI,         9},
    {"testfunctionCI",        (DL_FUNC) &testfunctionCI,         1},
    {NULL, NULL, 0}
};

RcppExport void R_init_mombf(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
