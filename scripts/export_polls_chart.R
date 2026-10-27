# Writes the data behind the chart in the Polls tab (see polls_chart_rows in
# R/export.R) to a local file. Run from the project root:
#   Rscript scripts/export_polls_chart.R [output file]
# The default, export/polls_chart.csv, is in .gitignore. The same file is
# published every morning on GitHub Pages by scripts/export_data.R.

out <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(out)) out <- file.path("export", "polls_chart.csv")

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

base <- build_baseline()
pl <- load_polls()
if (nrow(pl$polls) == 0) stop("No polls in the last ", WINDOW_DAYS, " days")

d <- polls_chart_rows(pl, base)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
if (!write_csv_utf8(d, out)) stop("Could not write ", out)
cat("Wrote", nrow(d), "rows to", out, "\n")
