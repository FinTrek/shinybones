#' Preview a shiny module in a shinydashboard
#'
#' @param module The server function of a module or its name.
#' @param name The id to pass to callModule while calling it.
#' @param use_box A boolean indicating if the ui should be wrapped in a
#'   box
#' @param title The dashboard title to display.
#' @param titleWidth The width of the dashboard title.
#' @param preview A boolean indicating if the return value should be a shinyApp
#'   object (default) or a named list with ui and server.
#' @param ... Additional parameters to pass to the module
#' @import shinydashboard
#' @importFrom purrr possibly
#' @export
#' @family preview
#' @examples
#' \dontrun{
#'   library(shiny)
#'   slider_text_ui <- function(id){
#'     ns <- NS(id)
#'     tagList(
#'       sliderInput(ns('num'), 'Enter Number', 0, 1, 0.5),
#'       textOutput(ns('num_text'))
#'     )
#'   }
#'   slider_text <- function(input, output, session){
#'      output$num_text <- renderText({input$num})
#'   }
#'   preview_module(slider_text, title = 'Slider Text')
#'   preview_module(slider_text, title = 'Slider Text', use_box = TRUE)
#' }
preview_module <- function(module, name = 'module',
                           use_box = FALSE,
                           title = name,
                           titleWidth = NULL,
                           preview = TRUE,
                           ...){
  if (is.character(module)){
    name <- module
    module_name <- module
    module <- match.fun(name)
  } else {
    module_name <- deparse(substitute(module))
  }
  ui_name <- paste(module_name, 'ui', sep = "_")
  ui_fun <- get(ui_name, mode = "function", envir = environment(module))
  sidebar_ui_fun <- purrr::possibly(match.fun, function(x, ...){NULL})(
    paste0(module_name, '_ui_sidebar')
  )
  # ui_fun <- match.fun(paste(module_name, 'ui', sep = "_"))
  my_ui <- if (use_box){
    shiny::fluidRow(
      shinydashboard::box(width = 12,
        ui_fun(name, ...)
      )
    )
  } else {
    ui_fun(name, ...)
  }
  mod_fun <- match.fun(module_name)
  ui <- shinydashboard::dashboardPage(skin = 'purple',
    shinydashboard::dashboardHeader(
      title = title,
      titleWidth = titleWidth
    ),
    shinydashboard::dashboardSidebar(
      width = titleWidth,
      sidebar_ui_fun(name, ...)
    ),
    shinydashboard::dashboardBody(
      my_ui
    )
  )
  server <- function(input, output, session){
    module_output <- shiny::callModule(
      mod_fun, name, ...
    )
  }
  if (!preview){
    list(ui = ui, server = server)
  } else {
    shiny::shinyApp(ui = ui, server = server)
  }

}


#' Preview a UI component in a ShinyDashboard
#'
#'
#' @export
#' @param component A UI component to display in a shinydashboard.
#' @param title A string indicating the title to display.
#' @param use_box A boolean indicating if the component should be wrapped
#'   inside a box.
#' @param ... Additional arguments to pass on to \code{preview_module}
#' @family preview
#' @examples
#' \dontrun{
#'  ui <- DT::datatable(mtcars, width = '100%', extension = 'Responsive')
#'  preview_component(ui)
#' }
preview_component <- function (component,
                               title = "Preview",
                               use_box = TRUE,
                               ...){
  module_ui <- function(id){component}
  module <- function(input, output, session, ...){}
  preview_module('module', title = title, use_box = use_box, ...)
}

#' Preview data in a datatable
#'
#'
#' @export
#' @param data A data frame object.
#' @param fun A function that transforms the data into a datatable. It defaults
#'   to \code{\link[DT]{datatable}}.
#' @param ui A \code{shiny.tag} object to include in the UI function.
#' @param ... Additional parameters to pass to \code{fun}.
#' @family preview
#' @examples
#' \dontrun{
#'  preview_datatable(mtcars,
#'    style = 'bootstrap',
#'    width = '100%',
#'    extension = 'Responsive'
#'  )
#' }
preview_datatable <- function(data, fun = DT::datatable, ui = NULL, ...){
  if (!requireNamespace("DT", quietly = TRUE)){
    stop(
      "You need the DT package installed to use preview_datatable",
      call. = FALSE
    )
  }
  mod_ui <- function(id){
    ns <- shiny::NS(id)
    shiny::fluidRow(box(
      width = 12,
      DT::DTOutput(ns('dt')),
      ui
    ))
  }

  mod <- function(input, output, session){
    output$dt <- DT::renderDT({
      fun(data, ...)
    })
  }
  preview_module(mod)
}
