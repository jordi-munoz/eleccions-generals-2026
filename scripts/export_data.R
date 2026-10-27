# Writes the default projection as data files, without the app. Run from the
# project root:
#   Rscript scripts/export_data.R [output folder, default _site]
# The daily GitHub Action (.github/workflows/publish-data.yml) runs this and
# publishes the folder on GitHub Pages. Needs readxl, httr2, rvest, xml2 and
# jsonlite; Shiny and the map packages are not used.

out <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(out)) out <- "_site"

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  source(f, encoding = "UTF-8")
}

REPO_URL <- "https://github.com/jordi-munoz/eleccions-generals-2026"

base <- build_baseline()
pl <- load_polls()
# With no polls there is nothing new to publish: stop, so that the files
# already online (the last good run) stay in place.
if (nrow(pl$polls) == 0) stop("No polls in the last ", WINDOW_DAYS, " days")

proj <- default_projection(base, pl)
dir.create(out, showWarnings = FALSE, recursive = TRUE)
if (!write_export(proj$bytes, out)) stop("Could not write the files to ", out)
chart <- polls_chart_rows(pl, base)
if (!write_csv_utf8(chart, file.path(out, "polls_chart.csv"))) {
  stop("Could not write polls_chart.csv to ", out)
}

# A small landing page listing the files.
meta <- jsonlite::fromJSON(rawToChar(proj$bytes$json))$meta
page <- sprintf(
  '<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Seat projection data</title>
<style>
  body { font: 16px/1.5 system-ui, sans-serif; max-width: 40rem;
         margin: 2rem auto; padding: 0 1rem; color: #222; background: #fff; }
  a { color: #0073CF; }
  code { background: #f2f2f2; padding: .1rem .3rem; border-radius: 3px; }
</style></head><body>
<h1>Spanish general election 2026: seat projection data</h1>
<p>Default projection of the <a href="%s">seat projection app</a>, rebuilt every
morning from the latest polls.</p>
<ul>
  <li><a href="projection.json">projection.json</a>: national and provincial
      results, seat probabilities, and a description of every field
      (<code>meta.fields</code>)</li>
  <li><a href="projection.csv">projection.csv</a>: one row per party, nationally
      and in each province</li>
  <li><a href="polls_chart.csv">polls_chart.csv</a>: the poll chart of the
      app, with each poll (series <code>poll</code>) and the daily trend curve
      of each party (series <code>trend</code>)</li>
</ul>
<p>Last update: %s. Polls: %s (%d polls, fieldwork up to %s).</p>
<p>Code and method: <a href="%s">%s</a>.
Jordi Muñoz, Universitat de Barcelona.</p>
</body></html>
', APP_URL, meta$generated_at, meta$polls$source, meta$polls$n_polls,
  meta$polls$last_fieldwork_end, REPO_URL, sub("^https://", "", REPO_URL)
)
writeLines(enc2utf8(page), file.path(out, "index.html"), useBytes = TRUE)

written <- paste(c(EXPORT_FILES, "polls_chart.csv", "index.html"),
                 collapse = ", ")
cat("Wrote", written, "to", out, "\n")
cat(
  "Polls:", meta$polls$source, "-", meta$polls$n_polls, "polls, up to",
  meta$polls$last_fieldwork_end, "\n"
)
