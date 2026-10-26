# Seat projection for the Spanish general election of 29 November 2026.
# Run with shiny::runApp() from this folder. Helpers live in R/ (sourced by shiny).

library(shiny)
library(bslib)
library(leaflet)
library(plotly)
library(sf)

base <- build_baseline()
geo  <- load_map()
pl   <- load_polls()

info <- base$info
# Party names (see party_label; `cpro` is the province, if any).
lab <- function(code, lang, cpro = NULL) party_label(info, code, lang, cpro)
party_choices <- function(lang) setNames(PARTIES$code, lab(PARTIES$code, lang))
# Label of a poll figure: it names the parties it contains (plain "Compromís",
# not the name of the 2026 joint list).
poll_lab <- function(code, lang) {
  inside <- vapply(code, function(p) {
    paste(c("", info[names(INSIDE)[INSIDE == p], "label"]), collapse = " + ")
  }, "")
  paste0(lab(code, lang), inside)
}
col <- function(code) info[code, "colour"]

# Poll average, trend estimate and sample sizes (see poll_estimates).
est <- poll_estimates(pl, base)
has_polls <- est$has_polls
avg <- est$avg
trend <- est$trend
poll_n <- est$poll_n
start_value <- round(ifelse(is.na(trend), 100 * base$nat23[POLLED], trend), 1)
names(start_value) <- POLLED
rest23 <- 100 * (1 - sum(base$nat23[PARTIES$code]))

# Default projection: what the app shows on opening. It is computed once here
# and also published as data files (R/export.R), so the files change exactly
# when the polls do, at the start of the R process.
default <- default_projection(base, pl, est)
DEFAULT_POLL <- default$poll
default_sim <- default$sim
export_bytes <- default$bytes
write_export(export_bytes, export_dir())

SOURCE_LINK <- as.character(
  if (pl$source == "wikipedia") {
    tags$a(href = WIKI_URL, target = "_blank", rel = "noopener", "Wikipedia")
  } else {
    tags$a(href = "https://www.politico.eu/europe-poll-of-polls/spain/", target = "_blank",
           rel = "noopener", "POLITICO Poll of Polls")
  }
)

poll_choices <- function(lang) {
  if (!has_polls) return(setNames("avg", tr("no_polls", lang)))
  c(
    setNames("trend", tr("poll_trend", lang, nrow(pl$polls),
                         fmt_date(min(pl$polls$date)), fmt_date(max(pl$polls$date)))),
    setNames("avg", tr("poll_avg", lang, sum(pl$in_avg),
                       fmt_date(min(pl$polls$date)), fmt_date(max(pl$polls$date)))),
    setNames(as.character(seq_len(nrow(pl$polls))),
             sprintf("%s · %s (n = %s)", fmt_date(pl$polls$date), pl$polls$firm,
                     ifelse(is.na(pl$polls$n), "?", fmt_int(pl$polls$n, lang))))
  )
}

# --- Small HTML builders -----------------------------------------------------

chip <- function(code, lang, size = 12, cpro = NULL) {
  tags$span(class = "sq", title = lab(code, lang, cpro),
            style = sprintf("background:%s;width:%dpx;height:%dpx", col(code), size, size))
}
squares <- function(code, n, size, lang) {
  if (n <= 0) return(NULL)
  lapply(seq_len(n), function(k) chip(code, lang, size))
}
signed <- function(x, lang, digits = 1) {
  s <- fmt_num(abs(x), lang, digits)
  ifelse(round(x, digits) > 0, paste0("+", s), ifelse(round(x, digits) < 0, paste0("−", s), s))
}
# One square per seat the party wins in at least 10% of simulations, shaded by
# how often it wins it. `p` is P(at least k seats) for k = 1, 2, ...
TIERS <- c(safe = "FF", likely = "8C", possible = "2E")  # fill opacity (hex alpha)
tier <- function(p) ifelse(p >= 0.9, "safe", ifelse(p >= 0.5, "likely", "possible"))
tier_square <- function(colour, tier, title = NULL) {
  tags$span(class = "sq tier", title = title,
            style = sprintf("background:%s%s;border-color:%s", colour, TIERS[[tier]], colour))
}
prob_squares <- function(code, p, lang, cpro = NULL) {
  lapply(which(p >= 0.1), function(k) {
    tier_square(col(code), tier(p[k]), tr("tier_tip", lang, lab(code, lang, cpro), k, prob(p[k])))
  })
}
tier_legend <- function(lang) {
  div(class = "small text-muted mt-3", lapply(names(TIERS), function(t) {
    tags$span(class = "me-3 text-nowrap", tier_square("#555555", t), " ", tr(paste0("tier_", t), lang))
  }))
}

interval <- function(lo, hi) ifelse(lo == hi, as.character(lo), paste0(lo, "–", hi))
prob <- function(p) {
  ifelse(p > 0 & p < 0.01, "<1%", ifelse(p < 1 & p > 0.99, ">99%", sprintf("%.0f%%", 100 * p)))
}

# Table with one row per party. With `probs` (see seat_probs) each party's
# seats are drawn as squares shaded by probability. `cpro` is the province the
# table is about, if any.
party_table <- function(df, lang, probs = NULL, show_p = FALSE, cpro = NULL) {
  row_squares <- !is.null(probs)
  df <- df[df$seats > 0 | df$seats23 > 0 | df$hi > 0 | df$share >= 0.01, ]
  head <- tags$tr(
    tags$th(tr("th_party", lang)), tags$th(class = "num", tr("th_vote", lang)),
    tags$th(class = "num", tr("th_vs23", lang)),
    if (row_squares) tags$th(tr("th_projected", lang)),
    tags$th(class = "num", tr("th_seats", lang)), tags$th(class = "num", "2023"),
    tags$th(class = "num", tr("th_interval", lang)),
    if (show_p) tags$th(class = "num", tr("th_pseat", lang))
  )
  rows <- lapply(seq_len(nrow(df)), function(k) {
    r <- df[k, ]
    tags$tr(
      tags$td(chip(r$code, lang, cpro = cpro), " ", lab(r$code, lang, cpro)),
      tags$td(class = "num", fmt_num(100 * r$share, lang)),
      tags$td(class = "num muted", signed(100 * (r$share - r$share23), lang)),
      if (row_squares) tags$td(class = "sqcell", prob_squares(r$code, probs[r$code, ], lang, cpro)),
      tags$td(class = "num strong", r$seats),
      tags$td(class = "num muted", r$seats23),
      tags$td(class = "num", interval(r$lo, r$hi)),
      if (show_p) tags$td(class = "num", prob(r$p_any))
    )
  })
  tags$table(class = "seat-table", tags$thead(head), tags$tbody(rows))
}

# --- UI ----------------------------------------------------------------------

sidebar_ui <- function(lang) sidebar(
  width = 340,
  radioButtons("source", tr("source", lang),
               setNames(c("polls", "custom"), c(tr("src_polls", lang), tr("src_custom", lang)))),
  conditionalPanel(
    "input.source == 'polls'",
    selectInput("poll", tr("poll", lang), poll_choices(lang))
  ),
  conditionalPanel(
    "input.source == 'custom'",
    div(class = "hyp-grid", lapply(POLLED, function(p) {
      numericInput(paste0("h_", p), poll_lab(p, lang), value = start_value[[p]],
                   min = 0, max = 100, step = 0.1)
    })),
    actionButton("reset", tr("reset", lang), class = "btn-sm btn-outline-secondary")
  ),
  uiOutput("scenario_note"),
  accordion(
    open = FALSE,
    accordion_panel(
      tr("uncertainty", lang),
      selectInput("sims", tr("sims", lang), c(500, 1000, 2000), selected = DEFAULT_SIMS),
      p(class = "param-help", tr("help_sims", lang)),
      sliderInput("nat_err", tr("nat_err", lang), min = 0, max = 4, value = DEFAULT_NAT_ERR,
                  step = 0.25),
      p(class = "param-help", tr("help_nat_err", lang)),
      sliderInput("sigma", tr("sigma", lang), min = 0, max = 25,
                  value = round(100 * DEFAULT_SIGMA), step = 1),
      p(class = "param-help", tr("help_sigma", lang))
    )
  ),
  div(
    class = "small text-muted",
    p(HTML(tr(if (pl$live) "polls_live" else "polls_cached", lang,
              SOURCE_LINK, fmt_date(pl$retrieved, time = TRUE)))),
    p(HTML(sprintf(
      "%s: Jordi Muñoz, Universitat de Barcelona (<a href='https://www.jordimunoz.cat' target='_blank' rel='noopener'>www.jordimunoz.cat</a>)",
      tr("author", lang)
    )))
  )
)

# The language selector reloads the page with ?lang=xx.
lang_picker <- function(lang) {
  tags$select(
    class = "form-select form-select-sm", style = "width:auto",
    `aria-label` = tr("language", lang),
    onchange = "window.location.search = '?lang=' + this.value;",
    lapply(names(LANGS), function(n) {
      tags$option(value = LANGS[[n]], selected = if (LANGS[[n]] == lang) NA, n)
    })
  )
}

ui <- function(req) {
  # The data files are answered here (see uiPattern at the end of the file).
  file <- export_response(export_bytes, req$PATH_INFO)
  if (!is.null(file)) return(file)
  lang <- pick_lang(req$QUERY_STRING, req$HTTP_ACCEPT_LANGUAGE)
  page_navbar(
    title = tr("title", lang),
    lang = lang,
    theme = bs_theme(version = 5, bootswatch = "flatly"),
    sidebar = sidebar_ui(lang),
    fillable = FALSE,
    header = tags$head(tags$style(HTML("
      /* Header in the corporate blue of the Universitat de Barcelona (Pantone 285 C) */
      .navbar { background-color:#0073CF !important; }
      .navbar .nav-link { color:rgba(255,255,255,.85) !important; }
      .navbar .nav-link.active, .navbar .nav-link:hover { color:#fff !important; }
      .navbar .nav-link.active { font-weight:700; border-bottom-color:#fff !important; }
      .sq { display:inline-block; margin:1px; border-radius:3px; vertical-align:middle; }
      .sq.tier { width:15px; height:15px; border:1.5px solid; }
      .param-help { font-size:.8rem; color:#6c757d; margin-top:-.5rem; }
      .seat-table { width:100%; font-size:.9rem; }
      .seat-table th { font-weight:600; font-size:.75rem; color:#6c757d; padding:.2rem .35rem;
                       border-bottom:1px solid #dee2e6; white-space:nowrap; }
      .seat-table td { padding:.25rem .35rem; vertical-align:middle; border-bottom:1px solid #f0f0f0; }
      .seat-table .num { text-align:right; font-variant-numeric:tabular-nums; white-space:nowrap; }
      .seat-table td:first-child { white-space:nowrap; }
      .seat-table .strong { font-weight:700; }
      .seat-table .muted { color:#6c757d; }
      .seat-table .sqcell { line-height:1; min-width:120px; }
      .strip { line-height:0; margin-bottom:.75rem; }
      .hyp-grid { display:grid; grid-template-columns:1fr 1fr; column-gap:.75rem; }
      .hyp-grid .form-group { margin-bottom:.5rem; }
      .leaflet-container { background:#fff; }
      .map-tip { font-size:.8rem; line-height:1.5; }
      .method { max-width:820px; }
      .method table { margin:1rem 0; font-variant-numeric:tabular-nums; }
      .method th, .method td { padding:.3rem .8rem; border-bottom:1px solid #dee2e6; text-align:right; }
      .method th:first-child, .method td:first-child { text-align:left; }
      .method h2 { font-size:1.6rem; } .method h3 { font-size:1.15rem; margin-top:1.5rem; }
      #polls_tbl { overflow-x:auto; font-size:.9rem; }
      #polls_tbl td:nth-child(2) { white-space:nowrap; }
    "))),
    nav_panel(
      tr("tab_proj", lang), value = "projection",
      layout_columns(
        col_widths = c(7, 5),
        div(
          card(
            card_header(
              class = "d-flex justify-content-between align-items-center",
              tr("map_title", lang),
              div(style = "width:230px", selectInput(
                "map_view", NULL, width = "100%",
                c(setNames("lead", tr("map_lead", lang)),
                  setNames(PARTIES$code, tr("map_seats_of", lang, lab(PARTIES$code, lang))))
              ))
            ),
            leafletOutput("map", height = 430),
            card_footer(class = "small text-muted", tr("map_hint", lang))
          ),
          card(
            card_header(textOutput("prov_title", inline = TRUE)),
            uiOutput("province")
          )
        ),
        card(
          card_header(tr("congress", lang, MAJORITY)),
          uiOutput("national"),
          hr(),
          checkboxGroupInput("coal", tr("coalition", lang), inline = TRUE,
                             choices = party_choices(lang),
                             selected = c("PP", "VOX")),
          uiOutput("coal_out")
        )
      )
    ),
    nav_panel(
      tr("tab_polls", lang), value = "polls",
      card(
        card_header(tr("plot_head", lang)),
        plotlyOutput("polls_plot", height = 480),
        card_footer(class = "small text-muted", tr("plot_foot", lang))
      ),
      card(
        card_header(tr("polls_head", lang)),
        tableOutput("polls_tbl"),
        card_footer(class = "small text-muted", HTML(tr("polls_foot", lang, SOURCE_LINK)),
                    if (pl$source == "wikipedia") tr("polls_excl", lang))
      )
    ),
    nav_panel(
      tr("tab_dhondt", lang), value = "dhondt",
      div(class = "method",
          markdown(readLines(sprintf("dhondt_%s.md", lang), encoding = "UTF-8")))
    ),
    nav_panel(
      tr("tab_method", lang), value = "method",
      div(class = "method",
          markdown(readLines(sprintf("method_%s.md", lang), encoding = "UTF-8")))
    ),
    nav_spacer(),
    nav_item(lang_picker(lang))
  )
}

# --- Server ------------------------------------------------------------------

server <- function(input, output, session) {

  lang <- pick_lang(isolate(session$clientData$url_search), session$request$HTTP_ACCEPT_LANGUAGE)

  observeEvent(input$reset, {
    for (p in POLLED) {
      updateNumericInput(session, paste0("h_", p), value = start_value[[p]])
    }
  })

  # Scenario figure of each party.
  box_value <- function(id) {
    v <- input[[paste0("h_", id)]]
    if (is.null(v) || is.na(v)) 0 else max(v, 0)
  }
  scenario_pct <- function() vapply(POLLED, box_value, numeric(1))

  scenario <- reactive({
    if (input$source == "custom") {
      c(build_target(scenario_pct(), base), list(n = NA_real_, custom = TRUE, default = FALSE))
    } else if (input$poll %in% c("trend", "avg")) {
      n <- if (has_polls) sum(poll_n[pl$in_avg]) else NA_real_
      c(build_target(if (input$poll == "trend") trend else avg, base),
        list(n = n, custom = FALSE, default = input$poll == DEFAULT_POLL))
    } else {
      k <- as.integer(input$poll)
      c(build_target(pl$shares[k, POLLED], base, fallback = avg),
        list(n = poll_n[k], custom = FALSE, default = FALSE))
    }
  }) |> debounce(500)

  # The default view reuses the run computed at start-up (the exported one).
  sim <- reactive({
    sc <- scenario()
    if (sc$default && as.integer(input$sims) == DEFAULT_SIMS &&
        isTRUE(all.equal(input$nat_err, DEFAULT_NAT_ERR)) &&
        isTRUE(all.equal(input$sigma / 100, DEFAULT_SIGMA))) {
      return(default_sim)
    }
    simulate_election(base, sc$target, n_poll = sc$n, sims = as.integer(input$sims),
                      nat_err = input$nat_err, sigma_prov = input$sigma / 100)
  })

  output$scenario_note <- renderUI({
    sc <- scenario()
    msg <- character(0)
    if (sc$custom) {
      msg <- tr("note_custom", lang, fmt_num(100 * sc$entered, lang), fmt_num(rest23, lang))
    } else if (length(sc$imputed)) {
      msg <- tr("note_imputed", lang, paste(lab(sc$imputed, lang), collapse = ", "))
    }
    if (sc$rescaled) msg <- c(msg, tr("note_rescaled", lang))
    if (length(msg)) div(class = "small text-muted", lapply(msg, tags$p))
  })

  # Map -----------------------------------------------------------------------

  selected <- reactiveVal(NULL)
  observeEvent(input$map_shape_click, selected(input$map_shape_click$id))

  output$map <- renderLeaflet({
    bb <- unname(st_bbox(geo$prov))
    leaflet(options = leafletOptions(zoomSnap = 0.25, minZoom = 5, maxZoom = 9,
                                     attributionControl = FALSE)) |>
      fitBounds(bb[1], bb[2], bb[3], bb[4])
  })

  observe({
    s <- sim()
    view <- input$map_view
    eligible <- setdiff(s$cols, OTHERS)
    idx <- match(geo$prov$cpro, base$cpro)

    tips <- vapply(idx, function(i) {
      st <- s$seats[i, ]
      st <- sort(st[st > 0], decreasing = TRUE)
      sprintf(
        "<div class='map-tip'><b>%s</b> · %d %s<br>%s</div>", base$name[i], base$seats[i],
        tr("seats_word", lang),
        paste(sprintf("<span class='sq' style='background:%s;width:10px;height:10px'></span> %s %d",
                      col(names(st)), lab(names(st), lang, base$cpro[i]), st), collapse = "<br>")
      )
    }, "")

    proxy <- leafletProxy("map") |> clearShapes() |> clearControls()
    if (view == "lead") {
      lead <- eligible[max.col(s$share[idx, eligible], ties.method = "first")]
      fill <- col(lead)
      shown <- intersect(info$code, lead)
      proxy <- proxy |> addLegend("bottomright", colors = col(shown), labels = lab(shown, lang),
                                  opacity = 0.9, title = tr("most_voted", lang))
    } else {
      st <- s$seats[idx, view]
      pal <- colorNumeric(c("#F2F2F2", col(view)), c(0, max(st, 1)))
      fill <- pal(st)
      brk <- unique(round(seq(0, max(st, 1), length.out = min(max(st, 1) + 1, 5))))
      proxy <- proxy |> addLegend("bottomright", colors = pal(brk), labels = brk,
                                  opacity = 0.9, title = tr("legend_seats", lang, lab(view, lang)))
    }
    is_sel <- geo$prov$cpro %in% selected()
    proxy |>
      addPolygons(
        data = geo$prov, layerId = geo$prov$cpro, fillColor = fill, fillOpacity = 0.85,
        color = "#ffffff", weight = 1, opacity = 1,
        label = lapply(tips, HTML),
        highlightOptions = highlightOptions(weight = 2.5, color = "#333333", bringToFront = TRUE)
      ) |>
      addPolygons(data = geo$prov[is_sel, ], fill = FALSE, color = "#111111", weight = 3,
                  opacity = 1, options = pathOptions(interactive = FALSE)) |>
      addPolylines(data = geo$can_box, color = "#999999", weight = 1,
                   options = pathOptions(interactive = FALSE))
  })

  # National panel --------------------------------------------------------------

  national <- reactive(summarise_seats(sim(), base))

  output$national <- renderUI({
    df <- national()
    won <- df[df$seats > 0, ]
    tagList(
      div(class = "strip", lapply(seq_len(nrow(won)), function(k) squares(won$code[k], won$seats[k], 9, lang))),
      party_table(df, lang)
    )
  })

  output$coal_out <- renderUI({
    req(length(input$coal) > 0)
    s <- sim()
    k <- match(input$coal, s$cols)
    draws <- rowSums(apply(s$sim_seats[, , k, drop = FALSE], c(1, 3), sum))
    q <- quantile(draws, c(0.05, 0.95), type = 1, names = FALSE)
    p(
      tags$b(tr("coal_head", lang, paste(lab(input$coal, lang), collapse = " + "), sum(s$seats[, k]))),
      tr("coal_body", lang, interval(q[1], q[2]), MAJORITY, prob(mean(draws >= MAJORITY)))
    )
  })

  # Province panel ----------------------------------------------------------------

  output$prov_title <- renderText({
    if (is.null(selected())) return(tr("prov_default", lang))
    i <- match(selected(), base$cpro)
    paste0(
      tr("prov_head", lang, base$name[i], base$seats[i]),
      if (base$seats[i] != base$seats_2023[i]) tr("prov_was", lang, base$seats_2023[i])
    )
  })

  output$province <- renderUI({
    if (is.null(selected())) return(p(class = "text-muted", tr("prov_empty", lang)))
    i <- match(selected(), base$cpro)
    s <- sim()
    ls <- last_seat(s, base, i)
    tagList(
      party_table(summarise_seats(s, base, i), lang, probs = seat_probs(s, i),
                  show_p = TRUE, cpro = selected()),
      tier_legend(lang),
      p(class = "small text-muted mt-2", tr("tier_note", lang)),
      p(class = "small text-muted",
        tr("last_seat", lang, lab(ls$winner, lang, selected()), lab(ls$runner, lang, selected()),
           fmt_num(ls$gap, lang, 2)))
    )
  })

  # Polls tab -----------------------------------------------------------------------

  output$polls_plot <- renderPlotly({
    validate(need(has_polls, tr("polls_none", lang)))
    dates <- pl$polls$date
    span <- range(dates)
    grid <- seq(span[1], span[2], by = 1)
    curves <- trend_curve(dates, pl$pollster, pl$shares[, POLLED, drop = FALSE], grid)
    fig <- plot_ly()
    for (p in POLLED[order(-ifelse(is.na(trend), 0, trend))]) {
      y <- pl$shares[, p]
      if (all(is.na(y))) next
      name <- poll_lab(p, lang)
      # Parties around 1% or less crowd the bottom of the chart: off until asked for.
      show <- if (isTRUE(trend[[p]] >= 1)) TRUE else "legendonly"
      has_line <- any(!is.na(curves[, p]))
      fig <- add_markers(
        fig, x = dates[!is.na(y)], y = y[!is.na(y)], name = name, legendgroup = p,
        showlegend = !has_line, visible = show, hoverinfo = "text",
        text = sprintf("%s · %s<br>%s: %s%%", fmt_date(dates), pl$polls$firm, name,
                       fmt_num(y, lang))[!is.na(y)],
        marker = list(color = col(p), size = 8, opacity = 0.5,
                      line = list(color = "#ffffff", width = 1))
      )
      if (has_line) {
        line_y <- curves[, p]
        fig <- add_lines(
          fig, x = grid, y = line_y, name = name, legendgroup = p, visible = show,
          hoverinfo = "text", connectgaps = FALSE,
          text = tr("plot_trend", lang, name, fmt_date(grid), fmt_num(line_y, lang)),
          line = list(color = col(p), width = 2)
        )
      }
    }
    fig |>
      layout(
        xaxis = list(title = "", showgrid = FALSE, tickformat = "%d-%m",
                     range = as.character(span + c(-3, 3))),
        yaxis = list(title = "", ticksuffix = "%", rangemode = "tozero", gridcolor = "#eeeeee",
                     zeroline = FALSE),
        legend = list(orientation = "h", y = -0.12), hovermode = "closest",
        margin = list(l = 40, r = 20, t = 10, b = 10),
        separators = if (lang == "en") ".," else ",."
      ) |>
      config(displayModeBar = FALSE)
  })

  output$polls_tbl <- renderTable({
    validate(need(has_polls, tr("polls_none", lang)))
    sh <- rbind(trend, avg, pl$shares[, POLLED, drop = FALSE])
    sh <- matrix(ifelse(is.na(sh), "", fmt_num(sh, lang)), nrow(sh),
                 dimnames = list(NULL, poll_lab(POLLED, lang)))
    out <- data.frame(c("", "", ifelse(pl$in_avg, "●", "")),
                      c(tr("trend", lang), tr("average", lang), fmt_date(pl$polls$date)),
                      c("", "", pl$polls$firm),
                      c("", "", fmt_int(pl$polls$n, lang)),
                      sh, check.names = FALSE)
    names(out)[1:4] <- c(" ", tr("col_date", lang), tr("col_firm", lang), tr("col_sample", lang))
    out
  }, striped = TRUE, spacing = "s", align = paste0("lll", strrep("r", length(POLLED) + 1)))
}

# ui() also answers the two data files (Shiny matches the whole path).
shinyApp(ui, server, uiPattern = "/(export/projection[.](json|csv))?")
