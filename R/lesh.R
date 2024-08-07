#' @title locally explained heterogeneity(LESH) model
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' Function for locally explained heterogeneity model.
#'
#' @note
#' The LESH model requires at least \eqn{2^n-1} calculations when has \eqn{n} explanatory variables.
#' When there are more than 10 explanatory variables, carefully consider the computational burden of this model.
#' When there are a large number of explanatory variables, the data dimensionality reduction method can be used
#' to ensure the trade-off between analysis results and calculation speed.
#'
#' @references
#' Li, Y., Luo, P., Song, Y., Zhang, L., Qu, Y., & Hou, Z. (2023). A locally explained heterogeneity model for
#' examining wetland disparity. International Journal of Digital Earth, 16(2), 4533–4552.
#' https://doi.org/10.1080/17538947.2023.2271883
#'
#' @param formula A formula of LESH model.
#' @param data A data.frame or tibble of observation data.
#' @param cores (optional) A positive integer(default is 1). If cores > 1, a 'parallel' package
#' cluster with that many cores is created and used. You can also supply a cluster object.
#' @param ... (optional) Other arguments passed to `rpart_disc()`.
#'
#' @return A list of LESH model result.
#' \describe{
#' \item{\code{interaction}}{the interaction result of LESH model}
#' \item{\code{spd_lesh}}{a tibble of the SHAP power of determinants}
#' }
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
  res = list("interaction" = res, "spd_lesh" = spd)
  class(res) = "lesh_result"
  return(res)
}

#' @title print LESH model interaction result
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to format output for LESH model interaction result in `lesh()`.
#'
#' @param x Return by `lesh()`.
#' @param ... (optional) Other arguments passed to `knitr::kable()`.
#'
#' @return Formatted string output
#' @method print lesh_result
#' @export
#'
print.lesh_result = \(x, ...) {
  cat("***    Spatial Interaction Association Detector      \n",
      "                    LESH Model                     ")
  IntersectionSymbol = rawToChar(as.raw(c(0x20, 0xE2, 0x88, 0xA9, 0x20)))
  x = x$interaction %>%
    dplyr::mutate(`Interactive variable` = paste0(variable1,
                                                  IntersectionSymbol,
                                                  variable2)) %>%
    dplyr::select(`Interactive variable`,Interaction)
  print(knitr::kable(x,format = "markdown",digits = 12,align = 'c',...))
}

#' @title plot LESH model result
#' @author Wenbo Lv \email{lyu.geosocial@gmail.com}
#' @description
#' S3 method to plot output for LESH model interaction result in `lesh()`.
#' @note
#' When both `scatter` and `pie` are set to `TRUE` in RStudio, enlarge the drawing frame
#' for normal display.
#'
#' @param x x Return by `lesh()`.
#' @param pie (optional) Whether to draw the interaction contributions. Default is `TRUE`.
#' @param scatter (optional) Whether to draw the interaction direction diagram. Default is `FALSE`.
#' @param scatter_alpha (optional) Picture transparency. Default is `1`.
#' @param n_pielegend (optional) The number of interaction contributions pie plot legend. Default is `3`.
#' @param ... (optional) Other arguments passed to `ggplot2::theme()`.
#'
#' @return A ggplot2 layer.
#' @method plot lesh_result
#' @export
#'
#' @examples
#' \dontrun{
#' data('ndvi')
#' g = lesh(NDVIchange ~ ., data = ndvi, cores = 6)
#' plot(g)
#' }
plot.lesh_result = \(x, pie = TRUE,
					 scatter = FALSE,
                     scatter_alpha = 1,
                     n_pielegend = 3,...) {
  fig_scatter = NULL
  fig_pie = NULL
  if (scatter) {
    g_scatter = list("interaction" = dplyr::select(x$interaction,1:6))
    class(g_scatter) = 'interaction_detector'
    fig_scatter = plot.interaction_detector(g_scatter,scatter_alpha,...)
  }
  if (pie) {
    g_pie = x$interaction %>%
      dplyr::select(interactv = `Variable1 and Variable2 interact Q-statistics`,
                    spd1 = `Variable1 SPD`, spd2 = `Variable2 SPD`,
                    dplyr::everything())
    gv1 = dplyr::count(g_pie,variable1)
    gv2 = dplyr::count(g_pie,variable2)
    gv = gv1 %>%
      dplyr::left_join(gv2,by = 'n') %>%
      dplyr::arrange(dplyr::desc(n))
    g_pie = g_pie %>%
      dplyr::mutate(variable1 = factor(variable1,levels = gv$variable1),
                    variable2 = factor(variable2,levels = rev(gv$variable2))) %>%
      dplyr::mutate(v1 = rescale_vector(as.numeric(variable1),-80,80),
                    v2 = rescale_vector(as.numeric(variable2),-80,80))
    #--- use scatterpie package ---
    fig_pie = ggplot2::ggplot(data = g_pie,
                              ggplot2::aes(x = v1, y = v2)) +
      scatterpie::geom_scatterpie(ggplot2::aes(x = v1, y = v2, r = 15 * interactv),
                                  data = g_pie, cols = c('spd1', 'spd2'),
                                  color = NA, show.legend = FALSE) +
      ggplot2::scale_fill_manual(values = c('#75c7af','#fb9872')) +
      suppressWarnings(scatterpie::geom_scatterpie_legend(g_pie$interactv * 15, n = n_pielegend,
                                         x = stats::quantile(g_pie$v1,0.99),
                                         y = stats::quantile(g_pie$v1,0.1),
                                         label_position = 'left',
                                         labeller = \(.x) round(.x/15,1))) +
      ggplot2::scale_x_continuous(name = "",
                                  breaks = g_pie$v1,
                                  labels = g_pie$variable1) +
      ggplot2::scale_y_continuous(name = "",
                                  breaks = g_pie$v2,
                                  labels = g_pie$variable2) +
      ggplot2::coord_equal() +
      ggplot2::theme_bw() +
      ggplot2::theme(axis.text.x = ggplot2::element_text(color = '#75c7af'),
                     axis.text.y = ggplot2::element_text(color = '#fb9872'),
                     ...)
    #--- use PieGlyph package ---
  #   fig_pie = ggplot2::ggplot(data = g_pie,
  #                             ggplot2::aes(x = variable1, y = variable2)) +
  #     PieGlyph::geom_pie_glyph(ggplot2::aes(radius = interactv),
  #                              slices = c('spd1', 'spd2'),
  #                              show.legend = TRUE) +
  #     ggplot2::scale_fill_manual(name = "", values = c('#75c7af','#fb9872'),
  #                                labels = c('Variable-Xaxis','Variable-Yaxis')) +
  #     PieGlyph::scale_radius_continuous(name = '', range = c(0.25, 0.75)) +
  #     ggplot2::guides(size = ggplot2::guide_legend(
  #       override.aes = list(shape = 21,
  #                           fill = "transparent",
  #                           color = "black"))) +
  #     ggplot2::labs(x = "", y = "") +
  #     ggplot2::coord_equal() +
  #     ggplot2::theme_bw() +
  #     ggplot2::theme(axis.text.x = ggplot2::element_text(color = '#75c7af'),
  #                    axis.text.y = ggplot2::element_text(color = '#fb9872'),
  #                    ...)

  }

  if (is.null(fig_scatter) | is.null(fig_pie)){
    if (is.null(fig_pie) & is.null(fig_scatter)) {
      stop("One or more of `pie` and `scatter` must be `TRUE`!")
    } else if (is.null(fig_pie)) {
      return(fig_scatter)
    } else {
      return(fig_pie)
    }
  } else {
    # fig_p = cowplot::plot_grid(fig_scatter, fig_pie, nrow = 1,
    #                            label_fontfamily = 'serif',
    #                            labels = paste0('(',letters[1:2],')'),
    #                            label_fontface = 'plain')
    fig_p = patchwork::wrap_plots(fig_scatter, fig_pie, nrow = 1)
    return(fig_p)
  }
}
