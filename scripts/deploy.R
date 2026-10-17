# Publishes the app to Posit Connect Cloud. Run from the project root:
#   Rscript scripts/deploy.R
# The first time it opens a browser window to log in to Connect Cloud.
library(rsconnect)

SERVER <- "connect.posit.cloud"

registered <- accounts()
if (is.null(registered) || !any(registered$server == SERVER)) {
  connectCloudUser(launch.browser = TRUE)
}

# Only what the app needs at run time: the 2019 results, the launcher and the
# helper scripts stay out of the bundle.
files <- c(
  "app.R",
  list.files("R", full.names = TRUE),
  list.files(pattern = "^(method|dhondt)_.*[.]md$"),
  file.path("data", c("provinces.rds", "aa_prior.csv", "polls_cache.json")),
  file.path("PROV_02_202307_1", "PROV_02_202307_1.xlsx")
)
stopifnot(all(file.exists(files)))

deployApp(
  appDir = ".",
  appFiles = files,
  appName = "eleccions-generals-2026",
  appTitle = "Eleccions generals 2026",
  server = SERVER,
  launch.browser = FALSE,
  forceUpdate = TRUE
)
