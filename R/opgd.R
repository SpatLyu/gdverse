#' @title optimal parameters-based geographical detector(OPGD) model
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' Function for optimal parameters-based geographical detector(OPGD) model.
#' @references
#' Song, Y., Wang, J., Ge, Y. & Xu, C. (2020) An optimal parameters-based geographical detector
#' model enhances geographic characteristics of explanatory variables for spatial heterogeneity
#' analysis: Cases with different types of spatial data, GIScience & Remote Sensing, 57(5), 593-610.
#' doi: 10.1080/15481603.2020.1760434.
#'
#' @param formula A formula of OPGD model.
#' @param data A data.frame or tibble of observation data.
#' @param discvar Name of continuous variable columns that need to be discretized.Noted that
#' when `formula` has `discvar`, `data` must have these columns.
#' @param discnum (optional) A vector of number of classes for discretization. Default is `3:22`.
#' @param discmethod (optional) A vector of methods for discretization,default is using
#' `c("sd","equal","pretty","quantile","fisher","headtails","maximum","box")`in `gdverse`.
#' @param cores (optional) A positive integer(default is 1). If cores > 1, a 'parallel' package
#' cluster with that many cores is created and used. You can also supply a cluster object.
#' @param type (optional) The type of geographical detector,which must be `factor`(default),
#' `interaction`, `risk`, `ecological`.You can run one or more types at one time.
#' @param alpha (optional) Specifies the size of confidence level.Default is `0.95`.
#' @param ... (optional) Other arguments passed to `gd_bestunidisc()`.A useful parameter is `seed`,
#'  which is used to set the random number seed.
#'
#' @return A list of the OPGD model result.
#' @export
#'
#' @examples
#' \dontrun{
#' library(terra)
#' library(tidyverse)
#' fvcpath = "https://github.com/SpatLyu/rdevdata/raw/main/FVC.tif"
#' fvc = terra::rast(paste0("/vsicurl/",fvcpath))
#' fvc = terra::aggregate(fvc,fact = 5)
#' fvc = as_tibble(terra::as.data.frame(fvc,na.rm = T))
#' opgd(fvc ~ ., data = fvc,
#'      discvar = names(select(fvc,-c(fvc,lulc))),
#'      cores = 6, type =c('factor','interaction'))
#' }
opgd = \(formula,data,discvar,discnum = NULL,discmethod = NULL,
         cores = 1, type = "factor", alpha = 0.95, ...){
  formula = stats::as.formula(formula)
  formula.vars = all.vars(formula)
  yname = formula.vars[1]
  if (formula.vars[2] != "."){
    data = dplyr::select(data,dplyr::all_of(formula.vars))
  }
  discdf =  dplyr::select(data,dplyr::all_of(c(yname,discvar)))
  g = gd_bestunidisc(paste0(yname,'~',paste0(discvar,collapse = '+')),
                     data = discdf,discnum = discnum,
                     discmethod = discmethod,cores = cores,...)
  discedvar = colnames(data[,-which(colnames(data) %in% discvar)])
  newdata = data %>%
    dplyr::select(dplyr::all_of(discedvar)) %>%
    dplyr::bind_cols(g$disv)
  if (length(type) == 1){
    res = gd(paste0(yname,' ~ .'),data = newdata,type = type,alpha = alpha)
  } else {
    res = vector("list", length(type))
    for (i in seq_along(type)){
      res[[i]] = gd(paste0(yname,' ~ .'),data = newdata,
                    type = type[i],alpha = alpha)
    }
  }

  return(res)
}
