#' @title spatial rough set-based geographical detector
#'
#' @param formula A formula of spatial rough set-based geographical detector model.
#' @param data A data.frame, tibble or sf object of observation data.
#' @param wt Spatial adjacency matrix. If `data` is a `sf` polygon object, the queen
#' adjacency matrix is used when no `wt` object is provided. In other cases, you must
#' provide a `wt` object.
#' @param type (optional) The type of geographical detector, which must be one of
#' `factor`(default), `interaction` and `ecological`.
#' @param alpha (optional) Specifies the size of the alpha (confidence level). Default is `0.95`.
#'
#' @return A list.
#' \describe{
#' \item{\code{factor}}{the result of spatial rough set-based factor detector}
#' \item{\code{interaction}}{the result of spatial rough set-based interaction detector}
#' \item{\code{ecological}}{the result of spatial rough set-based ecological detector}
#' }
#' @export
#'
#' @examples
#' data('srs_table')
#' data('srs_wt')
#' srs_geodetector(d ~ a1 + a2 + a3, data = srs_table, wt = srs_wt)
#' srs_geodetector(d ~ a1 + a2 + a3, data = srs_table,
#'                 wt = srs_wt, type = 'interaction')
#' srs_geodetector(d ~ a1 + a2 + a3, data = srs_table,
#'                 wt = srs_wt, type = 'ecological')
#'
srs_geodetector = \(formula, data, wt = NULL, type = "factor", alpha = 0.95){
  if (!(type %in% c("factor","interaction","ecological"))){
    stop("`type` must be one of `factor`,`interaction` and `ecological`!")
  }

  if (inherits(data,"sf")){
    if (is.null(wt)){
      wt = sdsfun::spdep_contiguity_swm(data, style='B',
                                        zero.policy = TRUE)
    }
    data = sf::st_drop_geometry(data)
  } else {
    if (is.null(wt)){
      stop("When data is not a `sf` object, you must provide `wt`!")
    }
  }
  data = tibble::as_tibble(data)

  formulavars = sdsfun::formula_varname(formula, data)
  response = data[, formulavars[[1]], drop = TRUE]
  explanatory = data[, formulavars[[2]]]

  switch(type,
         "factor" = {
           res = purrr::map_dfr(names(explanatory),
                                \(i) srs_factor_detector(response,
                                                         data[,i,drop = TRUE],
                                                         wt)) %>%
             dplyr::mutate(variable = names(explanatory)) %>%
             dplyr::select(variable,dplyr::everything()) %>%
             dplyr::arrange(dplyr::desc(`PD`))
           res = list("factor" = res)
           class(res) = "srs_factor_detector"
         },
         "interaction" = {
           res = utils::combn(names(explanatory), 2, simplify = FALSE) %>%
             purrr::map_dfr(\(i) srs_interaction_detector(response,
                                                          data[,i[1],drop = TRUE],
                                                          data[,i[2],drop = TRUE],
                                                          wt) %>%
                              tibble::as_tibble() %>%
                              dplyr::mutate(variable1 = i[1],
                                            variable2 = i[2]) %>%
                              dplyr::select(variable1,variable2,Interaction,
                                            dplyr::everything()))
           res = list("interaction" = res)
           class(res) = "srs_interaction_detector"
         },
         "ecological" = {
           res = utils::combn(names(explanatory), 2, simplify = FALSE) %>%
             purrr::map_dfr(\(i) srs_ecological_detector(response,
                                                         data[,i[1],drop = TRUE],
                                                         data[,i[2],drop = TRUE],
                                                         wt, alpha) %>%
                              tibble::as_tibble() %>%
                              dplyr::mutate(variable1 = i[1],
                                            variable2 = i[2]) %>%
                              dplyr::select(variable1,variable2,Ecological,
                                            dplyr::everything()))
           res = list("ecological" = res)
           class(res) = "srs_ecological_detector"
         }
  )
  return(res)
}

#' @title spatial rough set-based factor detector
#' @references
#' Bai, H., Li, D., Ge, Y., Wang, J., & Cao, F. (2022). Spatial rough set-based
#' geographical detectors for nominal target variables. Information Sciences, 586, 525–539.
#' https://doi.org/10.1016/j.ins.2021.12.019
#'
#' @param y Variable Y, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param x Covariate X, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param wt Spatial adjacency matrix.
#'
#' @return A list.
#' \describe{
#' \item{\code{PD}}{the average local explanatory power}
#' \item{\code{SE_PD}}{the degree of spatial heterogeneity of the local explanatory power}
#' }
#' @export
#'
#' @examples
#' data('srs_table')
#' data('srs_wt')
#' srs_factor_detector(srs_table$d,srs_table$a1,srs_wt)
#'
srs_factor_detector = \(y,x,wt){
  y = all2int(y)
  x = all2int(x)
  obs = matrix(x, ncol = 1)
  diag(wt) = 0
  res = SRS_PD(y,obs,wt)
  return(res)
}

#' @title spatial rough set-based interaction detector
#' @references
#' Bai, H., Li, D., Ge, Y., Wang, J., & Cao, F. (2022). Spatial rough set-based
#' geographical detectors for nominal target variables. Information Sciences, 586, 525–539.
#' https://doi.org/10.1016/j.ins.2021.12.019
#'
#' @param y Dependent variable, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param x1 Covariate \eqn{X_1}, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param x2 Covariate \eqn{X_2}, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param wt Spatial adjacency matrix.
#'
#' @return A list.
#' \describe{
#' \item{\code{Variable1 PD}}{the average local explanatory power for variable1}
#' \item{\code{Variable2 PD}}{the average local explanatory power for variable2}
#' \item{\code{Variable1 and Variable2 interact PD}}{the average local explanatory power for variable1 and variable2 interact}
#' \item{\code{Variable1 SE_PD}}{the degree of spatial heterogeneity of the local explanatory power for variable1}
#' \item{\code{Variable2 SE_PD}}{the degree of spatial heterogeneity of the local explanatory power for variable2}
#' \item{\code{Variable1 and Variable2 SE_PD}}{the degree of spatial heterogeneity of the local explanatory power for variable1 and variable2 interact}
#' \item{\code{Interaction}}{the interact result type}
#' }
#' @export
#'
#' @examples
#' data('srs_table')
#' data('srs_wt')
#' srs_interaction_detector(srs_table$d,srs_table$a1,srs_table$a2,srs_wt)
#'
srs_interaction_detector = \(y,x1,x2,wt){
  pd1a = gdverse::srs_factor_detector(y,x1,wt)
  pd1 = pd1a[[1]]
  pd2a = gdverse::srs_factor_detector(y,x2,wt)
  pd2 = pd2a[[1]]

  y = all2int(y)
  x1 = all2int(x1)
  x2 = all2int(x2)
  obs = cbind(x1,x2)
  diag(wt) = 0
  pd12a = SRS_MULTIPD(y,obs,wt)
  pd12 = pd12a[[1]]

  if (pd12 < min(pd1, pd2)) {
    interaction = "Weaken, nonlinear"
  } else if (pd12 >= min(pd1, pd2) & pd12 <= max(pd1, pd2)) {
    interaction = "Weaken, uni-"
  } else if (pd12 > max(pd1, pd2) & (pd12 < pd1 + pd2)) {
    interaction = "Enhance, bi-"
  } else if (pd12 == pd1 + pd2) {
    interaction = "Independent"
  } else {
    interaction = "Enhance, nonlinear"
  }
  interd = list(pd1,pd2,pd12,pd1a[[2]],pd2a[[2]],pd12a[[2]],interaction)
  names(interd) = c("Variable1 PD","Variable2 PD",
                    "Variable1 and Variable2 interact PD",
                    "Variable1 SE_PD","Variable2 SE_PD",
                    "Variable1 and Variable2 interact SE_PD",
                    "Interaction")
  return(interd)
}

#' @title spatial rough set-based ecological detector
#' @references
#' Bai, H., Li, D., Ge, Y., Wang, J., & Cao, F. (2022). Spatial rough set-based
#' geographical detectors for nominal target variables. Information Sciences, 586, 525–539.
#' https://doi.org/10.1016/j.ins.2021.12.019
#'
#' @param y Dependent variable, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param x1 Covariate \eqn{X_1}, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param x2 Covariate \eqn{X_2}, \code{factor}, \code{character} or \code{discrete numeric}.
#' @param wt Spatial adjacency matrix.
#' @param alpha (optional) Confidence level of the interval,default is `0.95`.
#'
#' @return A list.
#' \describe{
#' \item{\code{T-statistic}}{the result of T statistic for spatial rough set-based ecological detector}
#' \item{\code{P-value}}{the result of P value for spatial rough set-based ecological detector}
#' \item{\code{Ecological}}{does one spatial feature \eqn{X_1} play a more important role than \eqn{X_2}}
#' }
#' @export
#'
#' @examples
#' data('srs_table')
#' data('srs_wt')
#' srs_ecological_detector(srs_table$d,srs_table$a1,srs_table$a2,srs_wt)
#'
srs_ecological_detector = \(y,x1,x2,wt,alpha = 0.95){
  y = all2int(y)
  x1 = all2int(x1)
  x2 = all2int(x2)
  xobs1 = matrix(x1, ncol = 1)
  xobs2 = matrix(x2, ncol = 1)
  diag(wt) = 0
  pd1 = SRS_PDTEST(y,xobs1,wt)
  pd2 = SRS_PDTEST(y,xobs2,wt)
  tt = tryCatch({
    stats::t.test(pd1,pd2,conf.level = alpha)
  }, error = function(e){
    list("statistic" = 0,
         "parameter" = 0,
         "p.value" = 1)
  })
  risk = ifelse(tt$p.value < (1 - alpha), "Yes", "No")
  risk = factor(risk,levels = c("Yes", "No"), labels = c("Yes", "No"))
  ecod = list(tt$statistic,tt$p.value,risk)
  names(ecod) = c("T-statistic","P-value","Ecological")
  return(ecod)
}

#' @title print spatial rough set-based factor detector
#' @description
#' S3 method to format output for spatial rough set-based factor detector in `srsgd()`.
#'
#' @param x Return by `srsgd()`.
#' @param ... (optional) Other arguments passed to `knitr::kable()`.
#'
#' @return Formatted string output
#' @method print srs_factor_detector
#' @export
#'
print.srs_factor_detector = \(x, ...) {
  cat("Spatial Rough Set-based Factor Detector \n")
  class(x) = 'factor_detector'
  print(x)
}

#' @title print spatial rough set-based interaction detector
#' @description
#' S3 method to format output for spatial rough set-based interaction detector in `srsgd()`.
#'
#' @param x Return by `srsgd()`.
#' @param ... (optional) Other arguments passed to `knitr::kable()`.
#'
#' @return Formatted string output
#' @method print srs_interaction_detector
#' @export
#'
print.srs_interaction_detector = \(x, ...) {
  cat("Spatial Rough Set-based Interaction Detector \n")
  class(x) = 'interaction_detector'
  print(x)
}

#' @title print spatial rough set-based ecological detector
#' @description
#' S3 method to format output for spatial rough set-based ecological detector in `srsgd()`.
#'
#' @param x Return by `srsgd()`.
#' @param ... (optional) Other arguments passed to `knitr::kable()`.
#'
#' @return Formatted string output
#' @method print srs_ecological_detector
#' @export
#'
print.srs_ecological_detector = \(x, ...) {
  cat("Spatial Rough Set-based Ecological Detector \n")
  class(x) = 'ecological_detector'
  print(x)
}

#' @title plot spatial rough set-based factor detector result
#' @description
#' S3 method to plot output for spatial rough set-based factor detector in `srsgd()`.
#'
#' @param x Return by `srsgd()`.
#' @param slicenum (optional) The number of labels facing inward. Default is `2`.
#' @param ... (optional) Other arguments passed to `ggplot2::theme()`.
#'
#' @return A ggplot2 layer.
#' @method plot srs_factor_detector
#' @export
#'
plot.srs_factor_detector = \(x, slicenum = 2, ...) {
  g = x$factor %>%
    dplyr::select(variable, qv = `PD`) %>%
    dplyr::filter(!is.na(qv)) %>%
    dplyr::mutate(variable = forcats::fct_reorder(variable, qv, .desc = TRUE)) %>%
    dplyr::mutate(variable_col = c("first",rep("others",times = nrow(.)-1))) %>%
    dplyr::mutate(qv_text = paste0(sprintf("%4.2f", qv * 100), "%"))
  fig_factor = ggplot2::ggplot(g,
                               ggplot2::aes(x = qv, y = variable, fill = variable_col)) +
    ggplot2::geom_col() +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.1))) +
    ggplot2::scale_y_discrete(limits = rev) +
    ggplot2::scale_fill_manual(breaks = c("first", "others"),
                               values = c("#DE3533","#808080")) +
    ggplot2::geom_text(data = dplyr::slice(g, seq(1,slicenum)),
                       ggplot2::aes(label = qv_text),
                       hjust = 1.25, color = "black", fontface = "bold") +
    ggplot2::geom_text(data = dplyr::slice(g, -seq(1,slicenum)),
                       ggplot2::aes(label = qv_text),
                       hjust = -0.1, color = "black", fontface = "bold") +
    ggplot2::labs(x = "Average local explanatory power", y = "") +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                   legend.position = "off", ...)
  return(fig_factor)
}

#' @title plot spatial rough set-based interaction detector result
#' @description
#' S3 method to plot output for spatial rough set-based interaction detector in `srsgd()`.
#'
#' @param x Return by `srsgd()`.
#' @param alpha (optional) Picture transparency. Default is `1`.
#' @param ... (optional) Other arguments passed to `ggplot2::theme()`.
#'
#' @return A ggplot2 layer
#' @method plot srs_interaction_detector
#' @export
#'
plot.srs_interaction_detector = \(x,alpha = 1,...){
  class(x) = 'interaction_detector'
  x$interaction = x$interaction %>%
    dplyr::rename(`Variable1 and Variable2 interact Q-statistics` = `Variable1 and Variable2 interact PD`)
  fig_interaction = plot(x, alpha, ...)
  return(fig_interaction)
}

#' @title plot spatial rough set-based ecological detector
#' @description
#' S3 method to plot output for spatial rough set-based ecological detector in `srsgd()`.
#'
#' @param x Return by `srsgd()`.
#' @param ... (optional) Other arguments passed to `ggplot2::theme()`.
#'
#' @return A ggplot2 layer
#' @method plot srs_ecological_detector
#' @export
#'
plot.srs_ecological_detector = \(x, ...) {
  class(x) = 'ecological_detector'
  fig_ed = plot(x)
  return(fig_ed)
}
