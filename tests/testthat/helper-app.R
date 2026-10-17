# Loads the app's helpers and builds one small projection shared by the tests.
# Run from the project root with: testthat::test_dir("tests/testthat")

ROOT <- normalizePath(file.path(getwd(), "..", ".."))
for (f in list.files(file.path(ROOT, "R"), full.names = TRUE)) source(f, encoding = "UTF-8")

local({
  old <- setwd(ROOT)
  on.exit(setwd(old))
  base <<- build_baseline()
})

# A fixed scenario, so the tests do not depend on the polls of the day.
test_pct <- 100 * base$nat23[setdiff(PARTIES$code, names(INSIDE))]
test_pct[c("PP", "PSOE", "VOX", "SUMAR", "PODEMOS")] <- c(33, 27, 16, 7, 4)
test_sim <- simulate_election(base, build_target(test_pct, base)$target, n_poll = 10000,
                              sims = 200)
test_meta <- list(generated_at = "2026-10-17T12:00:00+0200", settings = list(simulations = 200))
test_ex <- build_export(test_sim, base, test_pct, test_meta)
