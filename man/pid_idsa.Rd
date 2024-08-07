% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pid_idsa.R
\name{pid_idsa}
\alias{pid_idsa}
\title{IDSA Q-saistics \code{PID}}
\usage{
pid_idsa(formula, rawdata, discdata, wt, overlaymethod = "and")
}
\arguments{
\item{formula}{A formula for IDSA Q-saistics}

\item{rawdata}{Raw observation data}

\item{discdata}{Discrete explanatory variables data}

\item{wt}{Spatial weight matrix}

\item{overlaymethod}{(optional) Spatial overlay method. One of \code{and}, \code{or}, \code{intersection}.
Default is \code{and}.}
}
\value{
The value of IDSA Q-saistics \code{PID}.
}
\description{
IDSA Q-saistics \code{PID}
}
\details{
\eqn{Q_{IDSA} = \frac{\theta_r}{\phi}}
}
\examples{
\dontrun{
library(sf)
ushi = read_sf(system.file('extdata/USHI.gpkg',package = 'gdverse')) |>
  dplyr::select(dplyr::all_of(c("NDVI","BH","WAR","SUHI")))
coord = ushi |>
  st_centroid() |>
  st_coordinates()
wt = inverse_distance_weight(coord[,1],coord[,2])
ushi_disc = ushi |>
  st_drop_geometry() |>
  dplyr::mutate(dplyr::across(1:3,\(.x) st_unidisc(.x,12)))
pid_idsa('NDVI~.', rawdata = ushi,
         discdata = ushi_disc, wt = wt)
}
}
