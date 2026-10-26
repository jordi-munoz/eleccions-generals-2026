# Data loading: past results (xlsx), polls (Wikipedia, with POLITICO Poll of
# Polls as fallback) and map.

WIKI_URL    <- "https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election"
POLLS_URL   <- "https://www.politico.eu/wp-json/politico/v1/poll-of-polls/ES-parliament"
POLLS_CACHE <- file.path("data", "polls_cache.json")
MAP_FILE    <- file.path("data", "provinces.rds")
AA_PRIOR    <- file.path("data", "aa_prior.csv")
RESULTS_2023 <- file.path("PROV_02_202307_1", "PROV_02_202307_1.xlsx")

ELECTION_DATE <- as.Date("2026-11-29")
WINDOW_DAYS   <- 92   # "last 3 months"
THRESHOLD     <- 0.03 # share of valid votes (blank included) needed in a province
MAJORITY      <- 176
DEFAULT_N     <- 1000 # sample size assumed when a poll does not publish it

# Seats that change with respect to July 2023 (province INE code -> change).
SEAT_CHANGES <- c("28" = +1L, "11" = -1L)

# Parties modelled individually.
#   col23  list in the July 2023 file: its provincial distribution is the
#          territorial profile, and its result is the 2023 reference
#   wiki   pattern matching the party's column header on Wikipedia
#   poll   key in the POLITICO JSON (NA: not published there)
# SUMAR is the list that ran as Sumar in 2023 and runs as Frente Amplio in
# 2026 (the name shown comes from PARTY_NAMES).
# Podemos ran inside Sumar in 2023 and SALF did not exist, so both borrow the
# profile of the closest list. Adelante Andalucía takes its profile from the
# Andalusian regional election (AA_PRIOR) and only runs in Andalusia.
# Compromís is the Sumar list of the three Valencian provinces: polls publish
# both together (see INSIDE), so it has no poll column of its own. In 2026 it
# is the joint list Compromís-Front Valencià there.
PARTIES <- data.frame(
  code   = c("PP", "PSOE", "VOX", "SUMAR", "PODEMOS", "SALF", "ERC", "JUNTS",
             "PNV", "BILDU", "BNG", "CC", "UPN", "AA", "COMPROMIS"),
  label  = c("PP", "PSOE", "Vox", "Sumar", "Podemos", "SALF", "ERC", "Junts",
             "EAJ-PNV", "EH Bildu", "BNG", "CC", "UPN", "Adelante And.", "Compromís"),
  col23  = c("PP", "PSOE", "VOX", "SUMAR", "SUMAR", "VOX", "ERC", "JxCAT - JUNTS",
             "EAJ-PNV", "EH Bildu", "B.N.G.", "CCa", "U.P.N.", "ADELANTE ANDALUCÍA", "SUMAR"),
  wiki   = c("^PP$", "^PSOE$", "^Vox$", "^(Sumar|Frente Amplio|FA)$", "^Podemos$", "^(SALF|Se Acabó)", "^ERC$",
             "^Junts$", "^PNV$", "^EH Bildu$", "^BNG$", "^CCa$", "^UPN$", "^Adelante Andaluc", NA),
  poll   = c("PP", "PSOE", "VOX", "Sumar", "Podemos", "SALF", "ERC", "JuntsxCat",
             "PNVEAJ", "EHBildu", "BNG", "CC", "UPN", NA, NA),
  colour = c("#1D84CE", "#E30613", "#63BE21", "#E51C55", "#6B2E68", "#8A6A3B",
             "#FFB232", "#00C3B2", "#2F7D46", "#A3BE0A", "#76B3DD", "#E8C400",
             "#0B3C7C", "#0E6E63", "#E2620E"),
  stringsAsFactors = FALSE
)
# Wikipedia columns added to a party's figure when present. The tables before
# the Frente Amplio agreement give Sumar with Compromís; the later ones split
# FA and FV (Front Valencià), so both are added up to keep one comparable
# series.
WIKI_ADD <- c(SUMAR = "^(FV|Front Valenci.*)$")
BORROWED <- c("PODEMOS", "SALF")  # no 2023 result of their own
INSIDE <- c(COMPROMIS = "SUMAR")  # polled inside another party's figure
POLLED <- setdiff(PARTIES$code, names(INSIDE))  # parties with a poll figure
COMPROMIS_PROV <- c("03", "12", "46")  # Alacant, Castelló, València

CANARIAS_PROV <- c("35", "38")  # Las Palmas, Santa Cruz de Tenerife

# Podemos runs on its own except in these provinces (see simulate_election):
# - in Catalonia it does not run, and its votes go half to ERC, half to
#   Frente Amplio;
# - in the Valencian provinces it runs inside Compromís-Front Valencià, and in
#   the Canary Islands inside a joint list with Frente Amplio: its votes are
#   added to that list (the COMPROMIS and SUMAR columns there).
PODEMOS_ABSENT <- c("08", "17", "25", "43")  # Barcelona, Girona, Lleida, Tarragona
PODEMOS_TO_ERC <- 0.5
PODEMOS_JOINED <- list(COMPROMIS = COMPROMIS_PROV, SUMAR = CANARIAS_PROV)
NOT_RUNNING <- c("CUP-PR")        # 2023 lists that do not run in 2026
OTHERS <- "OTHERS"

# Readable names for the lists that are kept but not polled.
LOCAL_LABELS <- c("NC-bc" = "Nueva Canarias", "U.P.L." = "UPL", "EXISTE" = "Teruel Existe",
                  "SY" = "Soria ¡Ya!", "XAV" = "Por Ávila",
                  "CpM" = "Coalición por Melilla")

# Reads one "PROV_02" file from the Ministry of the Interior: one row per
# province, a pair of columns (votes, seats) per list.
read_results <- function(path) {
  raw <- suppressMessages(readxl::read_excel(path, col_names = FALSE, .name_repair = "minimal"))
  raw <- as.data.frame(raw, stringsAsFactors = FALSE)
  hdr <- which(raw[[1]] == "Nombre de Comunidad")[1]
  heads <- unlist(raw[hdr, ])
  lists <- unlist(raw[hdr - 1, ])
  rows <- which(!is.na(raw[[2]]) & seq_len(nrow(raw)) > hdr)
  vcol <- which(heads == "Votos")
  num <- function(j) matrix(as.numeric(unlist(raw[rows, j])), nrow = length(rows))

  cpro <- sprintf("%02d", as.integer(raw[rows, 2]))
  votes <- num(vcol)
  seats <- num(vcol + 1)
  dimnames(votes) <- dimnames(seats) <- list(cpro, trimws(lists[vcol]))
  ord <- order(cpro)
  list(
    cpro  = cpro[ord],
    name  = raw[rows, 3][ord],
    ccaa  = raw[rows, 1][ord],
    valid = as.numeric(raw[rows, which(heads == "Votos válidos")])[ord],
    votes = votes[ord, , drop = FALSE],
    seats = seats[ord, , drop = FALSE]
  )
}

# Baseline for the projection: July 2023 collapsed to the modelled parties,
# every other list that reached the threshold somewhere, and a residual
# "others + blank" column that can never win seats.
build_baseline <- function(path = RESULTS_2023) {
  r <- read_results(path)
  share <- r$votes / r$valid
  own <- unique(PARTIES$col23)
  local <- setdiff(colnames(share)[apply(share, 2, max) >= THRESHOLD], c(own, NOT_RUNNING))

  # Actual 2023 result on the model's columns.
  votes23 <- cbind(r$votes[, PARTIES$col23, drop = FALSE], r$votes[, local, drop = FALSE])
  colnames(votes23) <- c(PARTIES$code, local)
  votes23[, BORROWED] <- 0
  votes23[COMPROMIS_PROV, "SUMAR"] <- 0
  votes23[setdiff(r$cpro, COMPROMIS_PROV), "COMPROMIS"] <- 0
  votes23 <- cbind(votes23, r$valid - rowSums(votes23))
  colnames(votes23)[ncol(votes23)] <- OTHERS
  seats23 <- cbind(r$seats[, PARTIES$col23, drop = FALSE], r$seats[, local, drop = FALSE], 0)
  colnames(seats23) <- colnames(votes23)
  seats23[, BORROWED] <- 0
  seats23[COMPROMIS_PROV, "SUMAR"] <- 0
  seats23[setdiff(r$cpro, COMPROMIS_PROV), "COMPROMIS"] <- 0

  # Territorial profiles that the swing is applied to.
  seed <- votes23
  seed[, BORROWED] <- r$votes[, PARTIES$col23[match(BORROWED, PARTIES$code)]]
  aa <- utils::read.csv(AA_PRIOR, colClasses = c(cpro = "character"))
  seed[, "AA"] <- 0
  seed[aa$cpro, "AA"] <- aa$aa / 100 * r$valid[match(aa$cpro, r$cpro)]

  n_seats <- rowSums(r$seats)
  n_seats[names(SEAT_CHANGES)] <- n_seats[names(SEAT_CHANGES)] + SEAT_CHANGES

  grey <- grDevices::gray.colors(max(length(local), 1), start = 0.35, end = 0.6)
  info <- rbind(
    PARTIES[, c("code", "label", "colour")],
    data.frame(code = local,
               label = ifelse(local %in% names(LOCAL_LABELS), LOCAL_LABELS[local], local),
               colour = grey[seq_along(local)],
               stringsAsFactors = FALSE),
    data.frame(code = OTHERS, label = "Others + blank", colour = "#C9C9C9",
               stringsAsFactors = FALSE)
  )
  rownames(info) <- info$code

  list(
    cpro = r$cpro, name = r$name, ccaa = r$ccaa, valid = r$valid,
    seed = seed, votes23 = votes23, seats23 = seats23,
    seats = n_seats, seats_2023 = rowSums(r$seats),
    nat23 = colSums(votes23) / sum(r$valid),
    local = local, info = info
  )
}

# --- Polls: Wikipedia --------------------------------------------------------

# The table lists these next to genuine polls. "CIS (firm)" rows are
# re-estimates of CIS fieldwork and are left out. Electomanía publishes a
# weekly running estimate: only its latest one is kept, so that it counts as
# one pollster like the others (Jordi, 2026-10-18).
WIKI_EXCLUDE <- "^CIS\\s*\\("
WIKI_LATEST_ONLY <- "Electoman|EM-Analytics"
# Polls commissioned by a party appear with the party's name as pollster or
# commissioner (e.g. "PSOE"); they are left out.
PARTY_NAMES_WIKI <- c(
  "PP", "PSOE", "Vox", "VOX", "Sumar", "Frente Amplio", "FA", "Podemos", "ERC",
  "Junts", "PNV", "EAJ-PNV", "EH Bildu", "BNG", "CC", "UPN", "SALF", "Compromís",
  "Adelante Andalucía", "Más Madrid", "IU"
)
party_commissioned <- function(firm) {
  vapply(strsplit(firm, "/", fixed = TRUE), function(p) any(trimws(p) %in% PARTY_NAMES_WIKI),
         logical(1))
}

# Rows of the Wikipedia table that the app uses (see above).
select_wiki_polls <- function(d) {
  d <- d[!grepl(WIKI_EXCLUDE, d$firm) & !party_commissioned(d$firm), , drop = FALSE]
  weekly <- which(grepl(WIKI_LATEST_ONLY, d$firm))
  if (length(weekly) < 2) return(d)
  # The newest one; on a tie, the first listed (which.max takes the first).
  newest <- weekly[which.max(d$date[weekly])]
  d[-setdiff(weekly, newest), , drop = FALSE]
}

wiki_end_date <- function(x, year) {
  months <- c(Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8,
              Sep = 9, Oct = 10, Nov = 11, Dec = 12)
  pat <- "(\\d{1,2})\\s+([A-Z][a-z]{2})\\s*$"
  ok <- grepl(pat, x)
  m <- trimws(regmatches(x, regexpr(pat, x)))
  out <- rep(as.Date(NA), length(x))
  out[ok] <- as.Date(sprintf("%d-%02d-%02d", year, months[sub("^\\d+\\s+", "", m)],
                             as.integer(sub("\\s.*$", "", m))))
  out
}

# First figure of a cell ("32.6 | 141" is share | seats; "?" and dashes are NA).
wiki_number <- function(x) {
  first <- trimws(sub("\\|.*$", "", x))
  suppressWarnings(as.numeric(gsub(",", "", ifelse(grepl("^[0-9.,]+$", first), first, NA))))
}

# All polls in the yearly "Voting intention estimates" tables: one row per
# poll with end of fieldwork, pollster, sample size and a share per party.
read_wikipedia_polls <- function(url = WIKI_URL) {
  # A local file is read directly; the page is fetched with a timeout so that
  # a slow connection cannot hang the start of the app.
  doc <- if (file.exists(url)) xml2::read_html(url) else {
    httr2::request(url) |>
      httr2::req_user_agent("Mozilla/5.0 (R shiny; election projection app)") |>
      httr2::req_timeout(15) |>
      httr2::req_perform() |>
      httr2::resp_body_html()
  }
  # Footnote markers out; line breaks become a visible separator.
  xml2::xml_remove(xml2::xml_find_all(doc, "//sup"))
  breaks <- xml2::xml_find_all(doc, "//br")
  xml2::xml_text(breaks) <- " | "

  out <- list()
  for (tb in xml2::xml_find_all(doc, "//table[contains(@class, 'wikitable')]")) {
    # These tables follow a heading whose id is the year, possibly with a
    # note in brackets ("2026_(after_FA)", "2026_(before_FA)"). Later
    # sections get ids such as 2026_2 and are skipped.
    id <- xml2::xml_attr(xml2::xml_find_first(tb, "preceding::*[self::h4 or self::h5 or self::h6][1]"), "id")
    if (is.na(id) || !grepl("^20\\d\\d(_\\(.*\\))?$", id)) next
    year <- as.integer(substr(id, 1, 4))

    head <- xml2::xml_find_all(xml2::xml_find_first(tb, ".//tr"), "./th")
    if (!any(grepl("Fieldwork", xml2::xml_text(head)))) next
    # Party headers are logos: name them by image alt, cell text or link title
    # before html_table() flattens the cell.
    for (th in head) {
      name <- c(xml2::xml_attr(xml2::xml_find_first(th, ".//img"), "alt"),
                trimws(xml2::xml_text(th)),
                xml2::xml_attr(xml2::xml_find_first(th, ".//a"), "title"))
      name <- name[!is.na(name) & nzchar(name)]
      if (length(name)) xml2::xml_text(th) <- name[1]
    }
    raw <- as.data.frame(rvest::html_table(tb, header = FALSE, convert = FALSE),
                         stringsAsFactors = FALSE)
    cols <- trimws(unlist(raw[1, ]))
    body <- raw[-(1:2), , drop = FALSE]
    if (nrow(body) == 0) next  # a new table with no polls yet

    shares <- vapply(PARTIES$wiki, function(pat) {
      j <- if (is.na(pat)) integer(0) else grep(pat, cols)
      if (length(j)) wiki_number(body[[j[1]]]) else rep(NA_real_, nrow(body))
    }, numeric(nrow(body)))
    shares <- matrix(shares, nrow(body), dimnames = list(NULL, PARTIES$code))
    for (p in names(WIKI_ADD)) {
      j <- grep(WIKI_ADD[[p]], cols)
      if (!length(j)) next
      extra <- wiki_number(body[[j[1]]])
      both <- cbind(shares[, p], extra)
      any_value <- rowSums(!is.na(both)) > 0
      shares[, p] <- ifelse(any_value, rowSums(both, na.rm = TRUE), NA)
    }
    df <- data.frame(
      date = wiki_end_date(trimws(body[[grep("Fieldwork", cols)[1]]]), year),
      firm = trimws(body[[1]]),
      n    = wiki_number(body[[grep("Sample", cols)[1]]]),
      shares, check.names = FALSE, stringsAsFactors = FALSE
    )
    # Election results and event rows have no date or no PP figure.
    out[[id]] <- df[!is.na(df$date) & !is.na(df$PP) &
                      !grepl("election", df$firm, ignore.case = TRUE), ]
  }
  if (!length(out)) stop("No voting-intention table found on ", url)
  res <- do.call(rbind, out)
  rownames(res) <- NULL
  res
}

# --- Polls: POLITICO (fallback) ----------------------------------------------

fetch_polls_json <- function(url = POLLS_URL, cache = POLLS_CACHE) {
  txt <- tryCatch({
    resp <- httr2::request(url) |>
      httr2::req_user_agent("Mozilla/5.0 (R shiny; election projection app)") |>
      httr2::req_timeout(20) |>
      httr2::req_perform()
    httr2::resp_body_string(resp)
  }, error = function(e) NULL)

  live <- !is.null(txt) && nchar(txt) > 1000
  if (live) {
    # The copy is only a fallback: a locked file (OneDrive syncing, another
    # session) must not stop the app.
    dir.create(dirname(cache), showWarnings = FALSE)
    try(suppressWarnings(writeLines(txt, cache, useBytes = TRUE)), silent = TRUE)
  } else if (file.exists(cache)) {
    txt <- paste(readLines(cache, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  } else {
    stop("Polls could not be downloaded and there is no local copy in ", cache)
  }
  list(json = jsonlite::fromJSON(txt, simplifyVector = FALSE), live = live,
       retrieved = if (live) Sys.time() else file.mtime(cache))
}

read_politico_polls <- function() {
  src <- fetch_polls_json()
  polls <- src$json$polls
  shares <- t(vapply(polls, function(p) {
    v <- unlist(p$parties)
    suppressWarnings(as.numeric(v[PARTIES$poll]))
  }, numeric(nrow(PARTIES))))
  colnames(shares) <- PARTIES$code
  df <- data.frame(
    date = as.Date(vapply(polls, function(p) p$date, "")),
    firm = vapply(polls, function(p) if (is.null(p$firm)) "?" else p$firm, ""),
    n    = vapply(polls, function(p) if (is.null(p$sample_size)) NA_real_ else as.numeric(p$sample_size), 0),
    shares, check.names = FALSE, stringsAsFactors = FALSE
  )
  list(polls = df, live = src$live, retrieved = src$retrieved)
}

# --- Polls: what the app uses --------------------------------------------------

# Polls of the last `days` days, newest first: `polls` (date, firm, n),
# `shares` (percent, NA where the party is not published), `pollster` (a key
# that groups the polls of one firm) and `in_avg`, which marks the latest poll
# of each pollster. Wikipedia first; POLITICO if the
# page cannot be read or yields nothing recent.
load_polls <- function(days = WINDOW_DAYS, today = Sys.Date()) {
  recent <- function(d) d[d$date >= today - days & d$date <= today, , drop = FALSE]

  wiki <- tryCatch(recent(read_wikipedia_polls()), error = function(e) NULL)
  if (!is.null(wiki)) wiki <- select_wiki_polls(wiki)
  if (!is.null(wiki) && nrow(wiki) > 0) {
    src <- list(polls = wiki, source = "wikipedia", live = TRUE, retrieved = Sys.time())
  } else {
    src <- read_politico_polls()
    src$polls <- recent(src$polls)
    src$source <- "politico"
  }

  d <- src$polls[order(src$polls$date, decreasing = TRUE), , drop = FALSE]
  rownames(d) <- NULL
  pollster <- tolower(iconv(trimws(sub("/.*$", "", d$firm)), to = "ASCII//TRANSLIT"))
  list(
    polls = d[c("date", "firm", "n")],
    shares = as.matrix(d[PARTIES$code]),
    pollster = pollster,
    in_avg = !duplicated(pollster),
    source = src$source, live = src$live, retrieved = src$retrieved
  )
}

# --- Map -------------------------------------------------------------------

load_map <- function(path = MAP_FILE) {
  if (!file.exists(path)) {
    stop("Missing ", path, ". Run scripts/prepare_map.R once to create it.")
  }
  readRDS(path)
}
