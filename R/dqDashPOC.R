#' <Add Title>
#'
#' <Add Description>
#'
#' @import htmlwidgets
#'
#' @export
dqDashPOC <- function(data, width = NULL, height = NULL, elementId = NULL) {
  htmlwidgets::createWidget(
    name = 'dqDashPOC',
    data,
    width = width,
    height = height,
    package = 'DataQualityDashboard',
    elementId = elementId
  )
}

#' Shiny bindings for dqDashPOC
#'
#' Output and render functions for using dqDashPOC within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a dqDashPOC
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name dqDashPOC-shiny
#'
#' @export
dqDashPOCOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'dqDashPOC', width, height, package = 'DataQualityDashboard')
}

#' @rdname dqDashPOC-shiny
#' @export
renderDqDashPOC <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, dqDashPOCOutput, env, quoted = TRUE)
}
