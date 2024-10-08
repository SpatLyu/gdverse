#' @title robust geographical detector(RGD) model
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' Function for robust geographical detector(RGD) model.
#' @references
#' Zhang, Z., Song, Y.*, & Wu, P., 2022. Robust geographical detector. International Journal of Applied Earth Observation and Geoinformation. 109, 102782.
#' DOI: 10.1016/j.jag.2022.102782.
#' @note
#' Please set up python dependence and configure `GDVERSE_PYTHON` environment variable if you want to run `rgd()`.
#' See `vignette('rgdrid',package = 'gdverse')` for more details.
#'
#' @param formula A formula of RGD model.
#' @param data A data.frame, tibble or sf object of observation data.
#' @param discvar Name of continuous variable columns that need to be discretized. Noted that
#' when `formula` has `discvar`, `data` must have these columns. By default, all independent
#' variables are used as `discvar`.
#' @param discnum A numeric vector of discretized classes of columns that need to be discretized.
#' Default all `discvar` use `3:22`.
#' @param minsize (optional) The min size of each discretization group. Default all use `1`.
#' @param cores (optional) Positive integer (default is 1). When cores are greater than 1, use
#' multi-core parallel computing.
#'
#' @return A list.
#' \describe{
#' \item{\code{factor}}{the result of RGD model}
#' \item{\code{disc}}{robust discrete results}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' ## The following code needs to configure the Python environment to run:
#' data('ndvi')
#' g = rgd(NDVIchange ~ ., data = ndvi,
#'         discvar = names(ndvi)[-1:-3],
#'         discnum = 3:8, cores = 6)
#' }
rgd = \(formula, data, discvar = NULL, discnum = 3:22, minsize = 1, cores = 1){
  formula = stats::as.formula(formula)
  formula.vars = all.vars(formula)
  if (inherits(data,'sf')) {data = sf::st_drop_geometry(data)}
  if (formula.vars[2] != "."){
    data = dplyr::select(data,dplyr::all_of(formula.vars))
  }
  yname = formula.vars[1]
  if (is.null(discvar)) {
    discvar = colnames(data)[-which(colnames(data) == yname)]
  }
  discdf =  dplyr::select(data,dplyr::all_of(c(yname,discvar)))
  discedvar = colnames(data[,-which(colnames(data) %in% discvar)])

  resqv = vector("list", length(discnum))
  resdisc = vector("list", length(discnum))
  for (i in seq_along(discnum)) {
    g = robust_disc(paste0(yname,'~',paste0(discvar,collapse = '+')),
                    discdf, discnum[i], minsize, cores = cores)
    resdisc[[i]] = g
    newdata = data %>%
      dplyr::select(dplyr::all_of(discedvar)) %>%
      dplyr::bind_cols(g)
    resqv[[i]] = gd(paste0(yname,' ~ .'),data = newdata,type = "factor")[[1]]
  }
  qv = purrr::map2_dfr(resqv, discnum,
                       \(.x,.n) .x %>%
                         dplyr::mutate(discnum = .n))
  disc = purrr::map2_dfr(resdisc, discnum,
                         \(.x,.n) dplyr::mutate(.x,discnum = .n))
  res = list("factor" = qv, "disc" = disc)
  class(res) = "rgd_result"
  return(res)
}

#' @title print RGD result
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to format output for RGD model from `rgd()`.
#'
#' @param x Return by `rgd()`.
#' @param ... (optional) Other arguments passed to `knitr::kable()`.
#'
#' @return Formatted string output
#' @method print rgd_result
#' @export
print.rgd_result = \(x, ...) {
  cat("***          Robust Geographical Detector       ")
  qv = x[[1]]
  qv = qv %>%
    dplyr::filter(discnum == max(qv$discnum)) %>%
    dplyr::select(1:3)
  print(knitr::kable(qv,format = "markdown",digits = 12,align = 'c',...))
  cat("\n")
  cat("#### Only display the results corresponding to the maximum number of discretizations!")
}

#' @title plot RGD result
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to plot output for RGD model result in `rgd()`.
#'
#' @param x Return by `rgd()`.
#' @param slicenum (optional) The number of labels facing inward. Default is `2`.
#' @param alpha (optional) Confidence level. Default is `0.95`.
#' @param keep (optional) Whether to keep Q-value results for insignificant variables,
#' default is `TRUE`.
#' @param ... (optional) Other arguments passed to `ggplot2::theme()`.
#'
#' @return A ggplot2 layer
#' @method plot rgd_result
#' @export
#'
plot.rgd_result = \(x, slicenum = 2, alpha = 0.95, keep = TRUE, ...) {
  qv = x[[1]]
  qv = qv %>%
    dplyr::filter(discnum == max(qv$discnum)) %>%
    dplyr::select(1:3)
  res = list("factor" = qv)
  class(res) = "factor_detector"
  fig_p = plot.factor_detector(res, slicenum, alpha, keep, ...)
  return(fig_p)
}
