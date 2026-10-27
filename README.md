# Spanish general election 2026: seat projection

A Shiny app that turns national polls into a seat projection, province by province, for the Spanish general election of 29 November 2026. Interface in English, Catalan and Spanish.

**Live app:** https://01a134f6-f370-5588-3fa4-78361b68e2a7.share.connect.posit.cloud/

## How it works

1. **National vote.** Polls are read when the app starts from the [Wikipedia poll table](https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election), falling back to [POLITICO Poll of Polls](https://www.politico.eu/europe-poll-of-polls/spain/). The default estimate is a trend line over the last three months, with a level per pollster and more weight on recent polls. A simple average, a single poll or your own figures can be used instead.
2. **Provinces.** Proportional swing from the July 2023 result, made consistent by raking: every province keeps its 2023 weight and every party hits its national figure.
3. **Seats.** D'Hondt in each of the 52 constituencies with the 3% threshold, using the 2026 seat distribution (Madrid 38, Cádiz 8).
4. **Uncertainty.** 1,000 Monte Carlo draws with national polling error and provincial deviation from swing. Intervals are the 5th–95th percentiles.

Party lists for 2026: Frente Amplio and Podemos run separately, except as Compromís-Front Valencià in the three Valencian provinces and as Unidad del Pueblo Canario in the Canary Islands. Podemos does not run in Catalonia, where its votes are split equally between ERC and Frente Amplio.

The full method, with its assumptions and limits, is in the app's Method tab ([English](method_en.md), [Català](method_ca.md), [Español](method_es.md)). Fed the real 2023 vote, the code reproduces the official 2023 seat allocation exactly.

## Data files

The default projection is published as data for use in other interfaces. A GitHub Action ([publish-data.yml](.github/workflows/publish-data.yml)) rebuilds it every morning with the latest polls and publishes it on GitHub Pages. These are the permanent addresses:

- JSON: https://jordi-munoz.github.io/eleccions-generals-2026/projection.json
- CSV: https://jordi-munoz.github.io/eleccions-generals-2026/projection.csv
- Poll chart (the dots and trend curves of the app's Polls tab): https://jordi-munoz.github.io/eleccions-generals-2026/polls_chart.csv

The app also serves the same files, as of its last start, at `/export/projection.json` and `/export/projection.csv` on its own address. To rebuild the files locally: `Rscript scripts/export_data.R [folder]`.

Both cover national and provincial results: projected vote share, seats, the 90% interval, P(seat), and the 2023 vote and seats. The JSON also has the probability of each successive seat in every province, the poll source and settings, and a description of every field (`meta.fields`).

## Running it locally

Requires R 4.1 or later. On Linux, the `sf` package needs the GDAL, GEOS and PROJ system libraries.

```r
source("run_app.R")   # installs missing packages and opens the app in the browser
```

Tests:

```r
testthat::test_dir("tests/testthat")
```

## Files

| Path | Contents |
|---|---|
| `app.R` | interface and server |
| `R/data.R` | parties, 2023 baseline, poll readers |
| `R/model.R` | trend estimate, raking, D'Hondt, Monte Carlo |
| `R/export.R` | JSON and CSV export |
| `R/i18n.R` | interface texts in three languages |
| `method_*.md`, `dhondt_*.md` | Method and D'Hondt tabs |
| `data/provinces.rds` | province map, built by `scripts/prepare_map.R` |
| `data/aa_prior.csv` | provincial distribution of Adelante Andalucía (Andalusian regional election) |
| `PROV_02_*/` | results by province, Ministerio del Interior (2023 is used by the app; 2019 for calibration) |
| `scripts/deploy.R` | publishes to Posit Connect Cloud |
| `scripts/export_data.R` | writes the data files without the app (run daily by the GitHub Action) |
| `scripts/export_polls_chart.R` | writes the poll chart data to `export/polls_chart.csv` locally |
| `tests/` | testthat tests |

## Sources

Election results: Ministerio del Interior. Polls: Wikipedia contributors and POLITICO Europe. Map: [`mapSpain`](https://ropenspain.github.io/mapSpain/), from Eurostat GISCO boundaries.

## Author

Jordi Muñoz, Universitat de Barcelona ([www.jordimunoz.cat](https://www.jordimunoz.cat)). Code under the [MIT licence](LICENSE).
