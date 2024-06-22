#' @title locally explained heterogeneity(LESH) model
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' Function for locally explained heterogeneity model.
#'
#' @references
#' Li, Y., Luo, P., Song, Y., Zhang, L., Qu, Y., & Hou, Z. (2023). A locally explained heterogeneity model for
#' examining wetland disparity. International Journal of Digital Earth, 16(2), 4533–4552.
#' https://doi.org/10.1080/17538947.2023.2271883
#'
#' @param formula  A formula of LESH model.
#' @param data A data.frame or tibble of observation data.
#' @param cores (optional) A positive integer(default is 1). If cores > 1, a 'parallel' package
#' cluster with that many cores is created and used. You can also supply a cluster object.
#' @param ... (optional) Other arguments passed to `rpart_disc()`.
#'
#' @return A list of the LESH model result.
#' @importFrom dplyr starts_with left_join
#' @export
#'
#' @examples
#' \dontrun{
#' data('ndvi')
#' g = lesh(NDVIchange ~ ., data = ndvi, cores = 6)
#' g
#' }
lesh = \(formula,data,cores = 1,...){
  spd = spd_lesh(formula,data,cores,...)
  pd = gozh(formula,data,cores,type = 'interaction',...)[[1]]
  res = pd %>%
    dplyr::left_join(dplyr::select(spd,varibale,spd1 = spd_theta),
                     by = c("variable1" = "varibale")) %>%
    dplyr::left_join(dplyr::select(spd,varibale,spd2 = spd_theta),
                     by = c("variable2" = "varibale")) %>%
    dplyr::mutate(spd = (spd1 + spd2), spd1 = spd1 / spd, spd2 = spd2 / spd,
                  `Variable1 SPD` = `Variable1 and Variable2 interact Q-statistics`*spd1,
                  `Variable2 SPD` = `Variable1 and Variable2 interact Q-statistics`*spd2) %>%
    dplyr::select(-dplyr::starts_with('spd'))
  res = list("interaction" = res)
  class(res) = "interaction_result_lesh"
  return(res)
}

#' @title print LESH model interaction result
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to format output for LESH model interaction result in `lesh()`.
#'
#' @param x Return by `lesh()`.
#' @param ... Other arguments.
#'
#' @return Formatted string output
#' @importFrom pander pander
#' @importFrom dplyr mutate select
#' @export
print.interaction_result_lesh = \(x, ...) {
  cat("\n    Spatial Interaction Association Detect    \n",
      "\n                   LESH Model                 \n")
  x = x$interaction %>%
    dplyr::mutate(`Interactive variable` = paste0(variable1,
                                                  rawToChar(as.raw(c(0x20, 0xE2, 0x88, 0xA9, 0x20))),
                                                  variable2)) %>%
    dplyr::select(`Interactive variable`,Interaction)
  pander::pander(x)
}