# Launches the seat projection app.
#   From R / Positron / RStudio:  source("run_app.R")
#   From a terminal:              Rscript run_app.R

# Folder of this script, whether it is sourced or run with Rscript.
script_dir <- function() {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(arg)) return(dirname(normalizePath(sub("^--file=", "", arg[1]))))
  for (f in rev(sys.frames())) {
    if (!is.null(f$ofile)) return(dirname(normalizePath(f$ofile)))
  }
  getwd()
}
app_dir <- script_dir()
if (!file.exists(file.path(app_dir, "app.R"))) {
  stop("app.R not found in ", app_dir, ". Set the working directory to the app folder first.")
}

needed <- c("shiny", "bslib", "leaflet", "sf", "readxl", "jsonlite", "httr2", "rvest", "xml2", "plotly")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)

# The map file is created once; this step also needs the mapSpain package.
if (!file.exists(file.path(app_dir, "data", "provinces.rds"))) {
  if (!requireNamespace("mapSpain", quietly = TRUE)) install.packages("mapSpain")
  old <- setwd(app_dir)
  source(file.path("scripts", "prepare_map.R"))
  setwd(old)
}

shiny::runApp(app_dir, launch.browser = TRUE)
