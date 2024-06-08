#' @title geographical detector model
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' Classical geographical detector model
#'
#' @param formula A formula of geographical detector model.
#' @param data A data.frame or tibble of observation data.
#' @param type (optional) The type of geographical detector,which must be one of `factor`(default),
#' `interaction`, `risk`, `ecological`.
#' @param ... (optional) Specifies the size of the alpha (confidence level).Default is `0.95`.
#'
#' @return A tibble of the corresponding result is stored under the corresponding detector type.
#' @importFrom stats as.formula
#' @importFrom utils combn
#' @importFrom purrr map_dfr
#' @importFrom tibble as_tibble
#' @importFrom dplyr mutate select arrange desc everything
#' @export
#'
#' @examples
#' gd(y ~ x1 + x2,
#'    tibble::tibble(y = 1:7,
#'                   x1 = c('x',rep('y',3),rep('z',3)),
#'                   x2 = c(rep('a',2),rep('b',2),rep('c',3))))
#'
#' gd(y ~ x1 + x2,
#'    tibble::tibble(y = 1:7,
#'                   x1 = c('x',rep('y',3),rep('z',3)),
#'                   x2 = c(rep('a',2),rep('b',2),rep('c',3))),
#'    type = 'interaction')
#'
#' gd(y ~ x1 + x2,
#'    tibble::tibble(y = 1:7,
#'                   x1 = c('x',rep('y',3),rep('z',3)),
#'                   x2 = c(rep('a',2),rep('b',2),rep('c',3))),
#'    type = 'risk',alpha = 0.95)
#'
#' gd(y ~ x1 + x2,
#'    tibble::tibble(y = 1:7,
#'                   x1 = c('x',rep('y',3),rep('z',3)),
#'                   x2 = c(rep('a',2),rep('b',2),rep('c',3))),
#'    type = 'ecological',alpha = 0.95)
#'
gd = \(formula,data,type = 'factor',...){
  formula = stats::as.formula(formula)
  formula.vars = all.vars(formula)
  response = data[, formula.vars[1], drop = TRUE]
  if (formula.vars[2] == "."){
    explanatory = data[,-which(colnames(data) == formula.vars[1])]
  } else {
    explanatory = subset(data, TRUE, match(formula.vars[-1], colnames(data)))
  }

  switch (type,
          "factor" = {
            res = purrr::map_dfr(names(explanatory),
                                 \(i) factor_detector(response,data[,i,drop = TRUE])) %>%
              dplyr::mutate(variable = names(explanatory)) %>%
              dplyr::select(variable,dplyr::everything()) %>%
              dplyr::arrange(dplyr::desc(`Q-statistic`))
            res = list("factor" = res)
            class(res) = "factor_detector"
          },
          "interaction" = {
            res = utils::combn(names(explanatory), 2, simplify = FALSE) %>%
              purrr::map_dfr(\(i) interaction_detector(response,
                                                       data[,i[1],drop = TRUE],
                                                       data[,i[2],drop = TRUE]) %>%
                               tibble::as_tibble() %>%
                               dplyr::mutate(variable1 = i[1],
                                             variable2 = i[2]) %>%
                               dplyr::select(variable1,variable2,Interaction,
                                             dplyr::everything()))
            res = list("interaction" = res)
            class(res) = "interaction_detector"
          },
          "risk" = {
            res = purrr::map_dfr(names(explanatory),
                                 \(i) risk_detector(response,
                                                    data[,i,drop = TRUE],
                                                    ...) %>%
                                   dplyr::mutate(variable = i) %>%
                                   dplyr::select(variable,zone1,zone2,Risk,
                                                 dplyr::everything()))
            res = list("risk" = res)
            class(res) = "risk_detector"
          },
          "ecological" = {
            res = utils::combn(names(explanatory), 2, simplify = FALSE) %>%
              purrr::map_dfr(\(i) ecological_detector(response,
                                                      data[,i[1],drop = TRUE],
                                                      data[,i[2],drop = TRUE],
                                                      ...) %>%
                               tibble::as_tibble() %>%
                               dplyr::mutate(variable1 = i[1],
                                             variable2 = i[2]) %>%
                               dplyr::select(variable1,variable2,Ecological,
                                             dplyr::everything()))
            res = list("ecological" = res)
            class(res) = "ecological_detector"
          }
  )
  return(res)
}

#' @title print factor detector
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to format output for factor detector in `gd()`.
#'
#' @param x Return by `gd()`.
#' @param ... Other arguments.
#'
#' @return Formatted string output
#' @importFrom pander pander
#' @export
print.factor_detector = \(x, ...) {
  cat("Spatial Stratified Heterogeneity Test \n",
      "\n          Factor detector         \n")
  pander::pander(x$factor)
}

#' @title print interaction detector
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to format output for interaction detector in `gd()`.
#'
#' @param x Return by `gd()`.
#' @param ... Other arguments.
#'
#' @return Formatted string output
#' @importFrom pander pander
#' @importFrom dplyr mutate select
#' @export
print.interaction_detector = \(x, ...) {
  cat("Spatial Stratified Heterogeneity Test \n",
      "\n         Interaction detector          \n")
  x = x$interaction %>%
    dplyr::mutate(`Interactive variable` = paste0(variable1,
                                                  rawToChar(as.raw(c(0x20, 0xE2, 0x88, 0xA9, 0x20))),
                                                  variable2)) %>%
    dplyr::select(`Interactive variable`,Interaction)
  pander::pander(x)
}

#' @title print risk detector
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to format output for risk detector in `gd()`.
#'
#' @param x Return by `gd()`.
#' @param ... Other arguments.
#'
#' @return Formatted string output
#' @importFrom knitr kable
#' @importFrom tidyr pivot_wider
#' @importFrom dplyr mutate select count pull filter all_of
#' @export
print.risk_detector = \(x, ...) {
  cat("Spatial Stratified Heterogeneity Test \n",
      "\n             Risk detector             \n")
  x = dplyr::select(x$risk,variable,zone1,zone2,Risk)
  xvar = x %>%
    dplyr::count(variable) %>%
    dplyr::pull(variable)
  rd2mat = \(x,zonevar){
    matt = x %>%
      dplyr::filter(variable == zonevar) %>%
      dplyr::select(-variable) %>%
      tidyr::pivot_wider(names_from = zone2,
                         values_from = Risk)
    matname = matt$zone1
    matt = dplyr::select(matt,zone1,dplyr::all_of(matname)) %>%
      dplyr::select(-zone1) %>%
      as.matrix()
    rownames(matt) = matname
    return(matt)
  }
  cat('\n')
  for (i in xvar){
    cat('--------------------------------------\n')
    cat(sprintf("Variable %s:",i))
    print(knitr::kable(rd2mat(x,i), format = "markdown"))
    #cat('--------------------------------------\n')
  }
}

#' @title print ecological detector
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to format output for ecological detector in `gd()`.
#'
#' @param x Return by `gd()`.
#' @param ... Other arguments.
#'
#' @return Formatted string output
#' @importFrom knitr kable
#' @importFrom tidyr pivot_wider
#' @importFrom dplyr select all_of
#' @export
print.ecological_detector = \(x, ...) {
  cat("Spatial Stratified Heterogeneity Test \n",
      "\n          ecological detector          \n")
  x = dplyr::select(x$ecological,
                    dplyr::all_of(c('variable1','variable2','Ecological')))
  ed2mat = \(x){
    matt = x %>%
      tidyr::pivot_wider(names_from = "variable2",
                         values_from = "Ecological")
    matname = matt$variable1
    matt = matt %>%
      dplyr::select(-variable1) %>%
      as.matrix()
    rownames(matt) = matname
    return(matt)
  }
  cat('\n')
  cat('--------------------------------------\n')
  print(knitr::kable(ed2mat(x), format = "markdown"))
}