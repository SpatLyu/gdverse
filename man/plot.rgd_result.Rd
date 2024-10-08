% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rgd.R
\name{plot.rgd_result}
\alias{plot.rgd_result}
\title{plot RGD result}
\usage{
\method{plot}{rgd_result}(x, slicenum = 2, alpha = 0.95, keep = TRUE, ...)
}
\arguments{
\item{x}{Return by \code{rgd()}.}

\item{slicenum}{(optional) The number of labels facing inward. Default is \code{2}.}

\item{alpha}{(optional) Confidence level. Default is \code{0.95}.}

\item{keep}{(optional) Whether to keep Q-value results for insignificant variables,
default is \code{TRUE}.}

\item{...}{(optional) Other arguments passed to \code{ggplot2::theme()}.}
}
\value{
A ggplot2 layer
}
\description{
S3 method to plot output for RGD model result in \code{rgd()}.
}
\author{
Wenbo Lv \email{lyu.geosocial@gmail.com}
}
