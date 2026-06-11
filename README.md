
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gdverse <a href="https://stscl.github.io/gdverse/"><img src="man/figures/logo.png" align="right" height="139" alt="gdverse website" /></a>

<!-- badges: start -->

[![CRAN](https://www.r-pkg.org/badges/version/gdverse)](https://CRAN.R-project.org/package=gdverse)
[![CRAN
Release](https://www.r-pkg.org/badges/last-release/gdverse)](https://CRAN.R-project.org/package=gdverse)
[![CRAN
Checks](https://badges.cranchecks.info/worst/gdverse.svg)](https://cran.r-project.org/web/checks/check_results_gdverse.html)
[![Downloads_all](https://badgen.net/cran/dt/gdverse?color=orange)](https://CRAN.R-project.org/package=gdverse)
[![Downloads_month](https://cranlogs.r-pkg.org/badges/gdverse)](https://CRAN.R-project.org/package=gdverse)
[![License](https://img.shields.io/badge/license-GPL--3-brightgreen.svg?style=flat)](http://www.gnu.org/licenses/gpl-3.0.html)
[![R-CMD-check](https://github.com/stscl/gdverse/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/stscl/gdverse/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-20b2aa.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R-universe](https://stscl.r-universe.dev/badges/gdverse?color=cyan)](https://stscl.r-universe.dev/gdverse)
[![DOI](https://img.shields.io/badge/DOI-10.1111%2Ftgis.70032-63847e?logo=doi&style=flat)](https://onlinelibrary.wiley.com/doi/10.1111/tgis.70032)

<!-- badges: end -->

**Analysis of Spatial Stratified Heterogeneity**

## Overview

*gdverse* consolidates cutting-edge SSH methodologies into a unified
toolkit, redefining spatial association measurement as the evolutionary
successor to
[geodetector](https://CRAN.R-project.org/package=geodetector) and
[GD](https://CRAN.R-project.org/package=GD) in the R ecosystem.

Current models and functions provided by **gdverse** are:

| *Model* | *Function* | *Support* |
|----|----|----|
| [GD](https://doi.org/10.1080/13658810802443457) | `gd()` | ✔️ |
| [OPGD](https://doi.org/10.1080/15481603.2020.1760434) | `opgd()` | ✔️ |
| [GOZH](https://doi.org/10.1016/j.isprsjprs.2022.01.009) | `gozh()` | ✔️ |
| [LESH](https://doi.org/10.1080/17538947.2023.2271883) | `lesh()` | ✔️ |
| [SPADE](https://doi.org/10.1080/13658816.2018.1476693) | `spade()` | ✔️ |
| [IDSA](https://doi.org/10.1080/13658816.2021.1882680) | `idsa()` | ✔️ |
| [RGD](https://doi.org/10.1016/j.jag.2022.102782) | `rgd()` | ✔️ |
| [RID](https://doi.org/10.1016/j.spasta.2024.100814) | `rid()` | ✔️ |
| [SRSGD](https://doi.org/10.1016/j.ins.2021.12.019) | `srsgd()` | ✔️ |

## Installation

- Install from [CRAN](https://CRAN.R-project.org/package=gdverse) with:

``` r
install.packages("gdverse", dep = TRUE)
```

- Install development binary version from
  [R-universe](https://stscl.r-universe.dev/gdverse) with:

``` r
install.packages('gdverse',
                 repos = c("https://stscl.r-universe.dev",
                           "https://cloud.r-project.org"),
                 dep = TRUE)
```

- Install development source version from
  [GitHub](https://github.com/stscl/gdverse) with:

``` r
# install.packages("devtools")
devtools::install_github("stscl/gdverse",
                         build_vignettes = TRUE,
                         dep = TRUE)
```

✨ Please ensure that **Rcpp** is properly installed and the appropriate
**C++** compilation environment is configured in advance if you want to
install **gdverse** from github.

✨ The **gdverse** package supports the use of robust discretization for
the [robust geographical
detector](https://doi.org/10.1016/j.jag.2022.102782) and [robust
interaction detector](https://doi.org/10.1016/j.spasta.2024.100814). For
details on using them, please refer to
<https://stscl.github.io/gdverse/articles/rgdrid.html>.

## Example

``` r
library(gdverse)
data("ndvi")
ndvi
## # A tibble: 713 × 7
##    NDVIchange Climatezone Mining Tempchange Precipitation    GDP Popdensity
##         <dbl> <chr>       <fct>       <dbl>         <dbl>  <dbl>      <dbl>
##  1    0.116   Bwk         low         0.256          237.  12.6      1.45  
##  2    0.0178  Bwk         low         0.273          214.   2.69     0.801 
##  3    0.138   Bsk         low         0.302          449.  20.1     11.5   
##  4    0.00439 Bwk         low         0.383          213.   0        0.0462
##  5    0.00316 Bwk         low         0.357          205.   0        0.0748
##  6    0.00838 Bwk         low         0.338          201.   0        0.549 
##  7    0.0335  Bwk         low         0.296          210.  11.9      1.63  
##  8    0.0387  Bwk         low         0.230          236.  30.2      4.99  
##  9    0.0882  Bsk         low         0.214          342. 241       20.0   
## 10    0.0690  Bsk         low         0.245          379.  42.0      7.50  
## # ℹ 703 more rows
```

### OPGD model

``` r
discvar = names(ndvi)[-1:-3]
discvar
## [1] "Tempchange"    "Precipitation" "GDP"           "Popdensity"
ndvi_opgd = opgd(NDVIchange ~ ., data = ndvi, 
                 discvar = discvar, cores = 6)
ndvi_opgd
## ***   Optimal Parameters-based Geographical Detector     
##                 Factor Detector            
## 
## |   variable    | Q-statistic | P-value  |
## |:-------------:|:-----------:|:--------:|
## | Precipitation |  0.8693505  | 2.58e-10 |
## |  Climatezone  |  0.8218335  | 7.34e-10 |
## |  Tempchange   |  0.3330256  | 1.89e-10 |
## |  Popdensity   |  0.1990773  | 6.60e-11 |
## |    Mining     |  0.1411154  | 6.73e-10 |
## |      GDP      |  0.1004568  | 3.07e-10 |
```

### GOZH model

``` r
g = gozh(NDVIchange ~ ., data = ndvi)
g
## ***   Geographically Optimal Zones-based Heterogeneity Model       
##                 Factor Detector            
## 
## |   variable    | Q-statistic | P-value  |
## |:-------------:|:-----------:|:--------:|
## | Precipitation | 0.87255056  | 4.52e-10 |
## |  Climatezone  | 0.82129550  | 2.50e-10 |
## |  Tempchange   | 0.33324945  | 1.12e-10 |
## |  Popdensity   | 0.22321863  | 3.00e-10 |
## |    Mining     | 0.13982859  | 6.00e-11 |
## |      GDP      | 0.09170153  | 3.96e-10 |
```

## CITATION

Please cite **[gdverse](https://doi.org/10.1111/tgis.70032)** as:

    Lv, W., Lei, Y., Liu, F., Yan, J., Song, Y., Zhao, W., 2025. gdverse: An R Package for Spatial Stratified Heterogeneity Family. Transactions in GIS 29. https://doi.org/10.1111/tgis.70032

A BibTeX entry for LaTeX users is:

``` bib
@article{lyu2025gdverse, 
    title={{gdverse}: An {R} Package for Spatial Stratified Heterogeneity Family}, 
    volume={29}, 
    ISSN={1467-9671},
    DOI={10.1111/tgis.70032},
    number={2}, 
    journal={Transactions in GIS}, 
    publisher={Wiley}, 
    author={Lv, Wenbo and Lei, Yangyang and Liu, Fangmei and Yan, Jianwu and Song, Yongze and Zhao, Wufan},
    year={2025}, 
    month={mar}
}
```

## Reference

Lv, W., Lei, Y., Liu, F., Yan, J., Song, Y., Zhao, W., 2025. gdverse: An
R Package for Spatial Stratified Heterogeneity Family. Transactions in
GIS 29. <https://doi.org/10.1111/tgis.70032>.

Wang, J., Li, X., Christakos, G., Liao, Y., Zhang, T., Gu, X., Zheng,
X., 2010. Geographical Detectors‐Based Health Risk Assessment and its
Application in the Neural Tube Defects Study of the Heshun Region,
China. International Journal of Geographical Information Science 24,
107–127. <https://doi.org/10.1080/13658810802443457>.

Song, Y., Wang, J., Ge, Y., Xu, C., 2020. An optimal parameters-based
geographical detector model enhances geographic characteristics of
explanatory variables for spatial heterogeneity analysis: cases with
different types of spatial data. GIScience & Remote Sensing 57, 593–610.
<https://doi.org/10.1080/15481603.2020.1760434>.

Luo, P., Song, Y., Huang, X., Ma, H., Liu, J., Yao, Y., Meng, L., 2022.
Identifying determinants of spatio-temporal disparities in soil moisture
of the Northern Hemisphere using a geographically optimal zones-based
heterogeneity model. ISPRS Journal of Photogrammetry and Remote Sensing
185, 111–128. <https://doi.org/10.1016/j.isprsjprs.2022.01.009>.

Li, Y., Luo, P., Song, Y., Zhang, L., Qu, Y., Hou, Z., 2023. A locally
explained heterogeneity model for examining wetland disparity.
International Journal of Digital Earth 16, 4533–4552.
<https://doi.org/10.1080/17538947.2023.2271883>.

Cang, X., Luo, W., 2018. Spatial association detector (SPADE).
International Journal of Geographical Information Science 32, 2055–2075.
<https://doi.org/10.1080/13658816.2018.1476693>.

Song, Y., Wu, P., 2021. An interactive detector for spatial
associations. International Journal of Geographical Information Science
35, 1676–1701. <https://doi.org/10.1080/13658816.2021.1882680>.

Zhang, Z., Song, Y., Wu, P., 2022. Robust geographical detector.
International Journal of Applied Earth Observation and Geoinformation
109, 102782. <https://doi.org/10.1016/j.jag.2022.102782>.

Zhang, Z., Song, Y., Karunaratne, L., Wu, P., 2024. Robust interaction
detector: A case of road life expectancy analysis. Spatial Statistics
59, 100814. <https://doi.org/10.1016/j.spasta.2024.100814>.

Bai, H., Li, D., Ge, Y., Wang, J., Cao, F., 2022. Spatial rough
set-based geographical detectors for nominal target variables.
Information Sciences 586, 525–539.
<https://doi.org/10.1016/j.ins.2021.12.019>

 
