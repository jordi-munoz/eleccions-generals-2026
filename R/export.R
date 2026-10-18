# Machine-readable copy of the default projection, for other interfaces.
# Built by default_projection() in two places, with the same result for the
# same polls: app.R at start-up (serves it at /export/projection.json and
# /export/projection.csv), and scripts/export_data.R, which the daily GitHub
# Action runs to publish it on GitHub Pages. It always uses the default
# uncertainty settings.

EXPORT_FILES <- c(json = "projection.json", csv = "projection.csv")
APP_URL      <- "https://01a134f6-f370-5588-3fa4-78361b68e2a7.share.connect.posit.cloud/"
EXPORT_LANG  <- "es"  # language of the party names in the rows

# What each field of a row means; copied into the JSON so that it documents
# itself.
EXPORT_FIELDS <- list(
  level          = "\"national\" or \"province\"",
  cpro           = "INE province code (two digits); empty for national rows",
  province       = "province name as in the Ministry of the Interior files",
  ccaa           = "autonomous community",
  district_seats = "seats at stake (350 for national rows)",
  party_code     = "model code of the party (SUMAR is Frente Amplio, COMPROMIS is Compromís-Front Valencià)",
  party_name     = "party name; in the Canary Islands SUMAR is Unidad del Pueblo Canario",
  vote_pct       = "projected share of the valid vote (blank votes included), central projection",
  vote_pct_2023  = "share of the valid vote in July 2023 (for the joint lists, that of the Sumar list)",
  votes_2023     = "votes in July 2023",
  seats          = "seats in the central projection (the run without noise)",
  seats_2023     = "seats in July 2023",
  seats_lo90     = "5th percentile of simulated seats",
  seats_hi90     = "95th percentile of simulated seats",
  seats_mean     = "mean of simulated seats",
  p_seat         = "share of simulations in which the party wins at least one seat",
  p_at_least     = "JSON only: share of simulations with at least 1, 2, 3, ... seats in the province"
)

# One row per party nationally, then one per party and province. A party is
# listed where it gets votes in the projection or had seats in 2023.
export_rows <- function(sim, base) {
  one_level <- function(i = NULL) {
    df <- summarise_seats(sim, base, i)
    df <- df[df$share > 0 | df$seats23 > 0, ]
    national <- is.null(i)
    cpro <- if (national) NA_character_ else base$cpro[i]
    votes23 <- if (national) colSums(base$votes23)[df$code] else base$votes23[i, df$code]
    data.frame(
      level          = if (national) "national" else "province",
      cpro           = cpro,
      province       = if (national) NA_character_ else base$name[i],
      ccaa           = if (national) NA_character_ else base$ccaa[i],
      district_seats = if (national) sum(base$seats) else base$seats[[i]],
      party_code     = df$code,
      party_name     = party_label(base$info, df$code, EXPORT_LANG, if (national) NULL else cpro),
      vote_pct       = round(100 * df$share, 3),
      vote_pct_2023  = round(100 * df$share23, 3),
      votes_2023     = unname(votes23),
      seats          = df$seats,
      seats_2023     = df$seats23,
      seats_lo90     = df$lo,
      seats_hi90     = df$hi,
      seats_mean     = round(df$mean, 2),
      p_seat         = round(df$p_any, 3),
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, c(list(one_level()), lapply(seq_along(base$cpro), one_level)))
  rownames(out) <- NULL
  out
}

# Everything the export holds. `estimate` is the national figure per polled
# party (percent) that the projection starts from; `meta` describes the polls
# and settings (see app.R).
build_export <- function(sim, base, estimate, meta) {
  rows <- export_rows(sim, base)
  place <- c("level", "cpro", "province", "ccaa", "district_seats")
  party_fields <- setdiff(names(rows), place)

  provinces <- lapply(seq_along(base$cpro), function(i) {
    r <- rows[rows$level == "province" & rows$cpro == base$cpro[i], party_fields]
    probs <- seat_probs(sim, i)
    r$p_at_least <- lapply(r$party_code, function(p) {
      x <- round(unname(probs[p, ]), 3)
      x[seq_len(max(c(0, which(x > 0))))]
    })
    rownames(r) <- NULL
    ls <- last_seat(sim, base, i)
    list(
      cpro = base$cpro[i], name = base$name[i], ccaa = base$ccaa[i],
      seats = base$seats[[i]], seats_2023 = base$seats_2023[[i]],
      valid_votes_2023 = base$valid[i],
      others_blank_pct = round(100 * sim$share[i, OTHERS], 3),
      others_blank_pct_2023 = round(100 * base$votes23[i, OTHERS] / base$valid[i], 3),
      last_seat = list(party = ls$winner, next_in_line = ls$runner,
                       gap_pct = round(ls$gap, 3)),
      parties = r
    )
  })

  codes <- unique(rows$party_code)
  parties <- data.frame(
    code = codes,
    name_en = party_label(base$info, codes, "en"),
    name_ca = party_label(base$info, codes, "ca"),
    name_es = party_label(base$info, codes, "es"),
    colour = base$info[codes, "colour"],
    poll_estimate_pct = round(unname(estimate[codes]), 3),
    stringsAsFactors = FALSE
  )

  national <- rows[rows$level == "national", party_fields]
  rownames(national) <- NULL
  list(
    meta = c(meta, list(fields = EXPORT_FIELDS)),
    parties = parties,
    national = national,
    provinces = provinces,
    rows = rows
  )
}

# The default projection for the polls in `pl` (see load_polls): trend
# estimate (or the 2023 result with no polls) and default uncertainty. Returns
# the choice it stands for (`poll`), the national estimate, the simulation and
# the export files as bytes.
default_projection <- function(base, pl, est = poll_estimates(pl, base),
                               now = Sys.time()) {
  poll <- if (est$has_polls) "trend" else "avg"
  estimate <- if (est$has_polls) est$trend else est$avg
  n <- if (est$has_polls) sum(est$poll_n[pl$in_avg]) else NA_real_
  target <- build_target(estimate, base)$target
  sim <- simulate_election(base, target, n_poll = n)
  stamp <- function(t) format(t, "%Y-%m-%dT%H:%M:%S%z", tz = TIME_ZONE)
  dates <- function(f) if (est$has_polls) format(f(pl$polls$date)) else NA
  meta <- list(
    generated_at = stamp(now),
    election_date = format(ELECTION_DATE),
    polls = list(
      source = pl$source,
      source_url = if (pl$source == "wikipedia") WIKI_URL else POLLS_URL,
      downloaded_live = pl$live,
      retrieved_at = stamp(pl$retrieved),
      estimate = if (est$has_polls) "trend" else "2023 result (no polls)",
      window_days = WINDOW_DAYS,
      n_polls = nrow(pl$polls),
      n_pollsters = sum(pl$in_avg),
      first_fieldwork_end = dates(min),
      last_fieldwork_end = dates(max)
    ),
    settings = list(
      simulations = DEFAULT_SIMS,
      national_error_points_at_30pct = DEFAULT_NAT_ERR,
      provincial_deviation_pct = 100 * DEFAULT_SIGMA,
      seed = SIM_SEED,
      interval = "90%: 5th to 95th percentile of simulated seats",
      threshold_pct = 100 * THRESHOLD,
      total_seats = sum(base$seats),
      majority = MAJORITY
    )
  )
  list(poll = poll, estimate = estimate, sim = sim,
       bytes = serialise_export(build_export(sim, base, estimate, meta)))
}

# The two files as bytes: JSON (nested) and CSV (the flat rows).
serialise_export <- function(ex) {
  json <- jsonlite::toJSON(
    ex[c("meta", "parties", "national", "provinces")],
    auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null"
  )
  tf <- tempfile(fileext = ".csv")
  on.exit(unlink(tf))
  utils::write.csv(ex$rows, tf, row.names = FALSE, na = "",
                   fileEncoding = "UTF-8")
  list(json = charToRaw(enc2utf8(as.character(json))),
       csv = readBin(tf, "raw", file.size(tf)))
}

# Folder for the files: export/ next to the app, or a temporary folder if that
# cannot be written (the copy the app serves is kept in memory anyway).
export_dir <- function(dir = "export") {
  dir.create(dir, showWarnings = FALSE)
  if (dir.exists(dir) && file.access(dir, 2) == 0) dir else {
    d <- file.path(tempdir(), "export")
    dir.create(d, showWarnings = FALSE)
    d
  }
}

# Writes both files. A locked file (OneDrive syncing) must not stop the app.
write_export <- function(bytes, dir) {
  ok <- vapply(names(EXPORT_FILES), function(k) {
    !inherits(try(writeBin(bytes[[k]], file.path(dir, EXPORT_FILES[[k]])), silent = TRUE),
              "try-error")
  }, logical(1))
  all(ok)
}

# HTTP response for a request path, or NULL if the path is not an export file.
# Open to any origin, so that a page on another site can fetch it.
export_response <- function(bytes, path) {
  if (!is.character(path) || length(path) != 1) return(NULL)
  hit <- names(EXPORT_FILES)[endsWith(path, paste0("/export/", EXPORT_FILES))]
  if (!length(hit)) return(NULL)
  shiny::httpResponse(
    200,
    content_type = if (hit == "json") "application/json; charset=utf-8" else "text/csv; charset=utf-8",
    content = bytes[[hit]],
    headers = list("Access-Control-Allow-Origin" = "*", "Cache-Control" = "no-cache")
  )
}
