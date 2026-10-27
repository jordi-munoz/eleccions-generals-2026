# Interface texts in English, Catalan and Spanish. The language comes from the
# `?lang=` query parameter (set by the selector in the navbar) or, failing
# that, from the browser. The method note lives in method_<lang>.md.

LANGS <- c("English" = "en", "Català" = "ca", "Español" = "es")

# Party names that change with the language. SUMAR is the model's code for the
# list that ran as Sumar in 2023 and runs as Frente Amplio in 2026; in the
# Canary Islands it runs with Podemos as SUMAR_CANARIAS. COMPROMIS is the joint
# list of the three Valencian provinces. Proper names: the same in every language.
PARTY_NAMES <- list(
  SUMAR = c(en = "Frente Amplio", ca = "Front Ampli", es = "Frente Amplio"),
  COMPROMIS = c(en = "Compromís-Front Valencià", ca = "Compromís-Front Valencià",
                es = "Compromís-Front Valencià")
)
SUMAR_CANARIAS <- "Unidad del Pueblo Canario"
PP_NAVARRA <- "UPN-PP"  # joint list of UPN and PP in Navarra

# Name of each party code in `lang`; `info` is base$info and `cpro` the
# province, if any (Frente Amplio has another name in the Canary Islands, and
# PP in Navarra).
party_label <- function(info, code, lang, cpro = NULL) {
  out <- info[code, "label"]
  translated <- code %in% names(PARTY_NAMES)
  out[translated] <- vapply(code[translated], function(p) PARTY_NAMES[[p]][[lang]], "")
  if (!is.null(cpro) && cpro %in% CANARIAS_PROV) out[code == "SUMAR"] <- SUMAR_CANARIAS
  if (!is.null(cpro) && cpro %in% NAVARRA_PROV) out[code == "PP"] <- PP_NAVARRA
  out
}

TR <- list(
  title         = c(en = "General election 2026", ca = "Eleccions generals 2026",
                    es = "Elecciones generales 2026"),
  tab_proj      = c(en = "Projection", ca = "Projecció", es = "Proyección"),
  tab_polls     = c(en = "Polls", ca = "Enquestes", es = "Encuestas"),
  tab_method    = c(en = "Method", ca = "Mètode", es = "Método"),
  tab_dhondt    = c(en = "How D'Hondt works", ca = "Com funciona D'Hondt",
                    es = "Cómo funciona D'Hondt"),
  language      = c(en = "Language", ca = "Llengua", es = "Idioma"),

  source        = c(en = "National vote estimate", ca = "Estimació de vot estatal",
                    es = "Estimación de voto nacional"),
  src_polls     = c(en = "Polls", ca = "Enquestes", es = "Encuestas"),
  src_custom    = c(en = "My own scenario", ca = "El meu escenari", es = "Mi propio escenario"),
  poll          = c(en = "Poll to project", ca = "Enquesta a projectar", es = "Encuesta a proyectar"),
  poll_trend    = c(en = "Trend estimate (%d polls, %s to %s)",
                    ca = "Estimació de tendència (%d enquestes, %s a %s)",
                    es = "Estimación de tendencia (%d encuestas, %s a %s)"),
  poll_avg      = c(en = "Average of %d pollsters, latest poll of each (%s to %s)",
                    ca = "Mitjana de %d empreses, última enquesta de cadascuna (%s a %s)",
                    es = "Media de %d empresas, última encuesta de cada una (%s a %s)"),
  no_polls      = c(en = "No polls in the last 3 months: 2023 result",
                    ca = "Cap enquesta en els últims 3 mesos: resultat de 2023",
                    es = "Ninguna encuesta en los últimos 3 meses: resultado de 2023"),
  reset         = c(en = "Reset to the trend estimate", ca = "Torna a l'estimació de tendència",
                    es = "Volver a la estimación de tendencia"),
  uncertainty   = c(en = "Uncertainty settings", ca = "Paràmetres d'incertesa",
                    es = "Parámetros de incertidumbre"),
  sims          = c(en = "Simulations", ca = "Simulacions", es = "Simulaciones"),
  nat_err       = c(en = "National polling error (points, party at 30%)",
                    ca = "Error estatal de les enquestes (punts, partit al 30%)",
                    es = "Error nacional de las encuestas (puntos, partido al 30%)"),
  sigma         = c(en = "Provincial deviation from swing (%)",
                    ca = "Desviació provincial respecte al swing (%)",
                    es = "Desviación provincial respecto al swing (%)"),
  help_sims     = c(en = "How many times the election is simulated. More simulations give steadier intervals and probabilities, and take a little longer to compute.",
                    ca = "Nombre de vegades que se simulen les eleccions. Amb més simulacions, els intervals i les probabilitats són més estables, però el càlcul triga una mica més.",
                    es = "Número de veces que se simulan las elecciones. Con más simulaciones, los intervalos y las probabilidades son más estables, pero el cálculo tarda algo más."),
  help_nat_err  = c(en = "How far the national result may fall from the polls for reasons other than sample size (late swing, turnout, pollster bias). It is the standard deviation, in percentage points, for a party at 30% of the vote; smaller parties get a proportionally smaller error. With 2 points, a party polling 30% ends between about 27% and 33% in nine out of ten simulations. Set it to 0 to keep only sampling error (none in your own scenario).",
                    ca = "Fins on es pot allunyar el resultat estatal de les enquestes per motius diferents de la mida de la mostra (canvis d'última hora, participació, biaixos de les empreses). És la desviació típica, en punts percentuals, per a un partit amb el 30% del vot; als partits més petits els correspon un error proporcionalment menor. Amb 2 punts, un partit al 30% acaba entre el 27% i el 33%, aproximadament, en nou de cada deu simulacions. Amb 0 només queda l'error mostral (cap en el teu propi escenari).",
                    es = "Hasta dónde puede alejarse el resultado nacional de las encuestas por motivos distintos del tamaño de la muestra (cambios de última hora, participación, sesgos de las empresas). Es la desviación típica, en puntos porcentuales, para un partido con el 30% del voto; a los partidos más pequeños les corresponde un error proporcionalmente menor. Con 2 puntos, un partido al 30% acaba entre el 27% y el 33%, aproximadamente, en nueve de cada diez simulaciones. Con 0 solo queda el error muestral (ninguno en tu propio escenario)."),
  help_sigma    = c(en = "How much a party's result in each province may depart from what the national swing implies. With 12%, a party projected at 20% in a province ends between about 16% and 24% there in nine out of ten simulations. The default of 12% is what this method missed by, province by province, between the 2019 and 2023 elections. Set it to 0 to assume every province moves exactly with the national swing.",
                    ca = "Fins on es pot desviar el resultat d'un partit a cada província del que implica el swing estatal. Amb un 12%, un partit projectat al 20% en una província hi acaba entre el 16% i el 24%, aproximadament, en nou de cada deu simulacions. El valor per defecte, 12%, és l'error que va cometre aquest mètode, província a província, entre les eleccions de 2019 i 2023. Amb 0 se suposa que totes les províncies es mouen exactament com el conjunt de l'Estat.",
                    es = "Hasta dónde puede desviarse el resultado de un partido en cada provincia de lo que implica el swing nacional. Con un 12%, un partido proyectado al 20% en una provincia acaba entre el 16% y el 24%, aproximadamente, en nueve de cada diez simulaciones. El valor por defecto, 12%, es el error que cometió este método, provincia a provincia, entre las elecciones de 2019 y 2023. Con 0 se supone que todas las provincias se mueven exactamente como el conjunto de España."),
  polls_live    = c(en = "Polls: %s, downloaded %s.",
                    ca = "Enquestes: %s, descarregades el %s.",
                    es = "Encuestas: %s, descargadas el %s."),
  polls_cached  = c(en = "Polls: %s, saved copy from %s.",
                    ca = "Enquestes: %s, còpia desada del %s.",
                    es = "Encuestas: %s, copia guardada del %s."),
  author        = c(en = "Author", ca = "Autor", es = "Autor"),

  note_custom   = c(en = "Your figures add up to %s%%. Other lists and blank votes take the rest (%s%% in 2023).",
                    ca = "Les teves xifres sumen %s%%. La resta és per a altres candidatures i vot en blanc (%s%% el 2023).",
                    es = "Tus cifras suman %s%%. El resto es para otras candidaturas y voto en blanco (%s%% en 2023)."),
  note_imputed  = c(en = "Not published in this poll, taken from the average: %s.",
                    ca = "No publicats en aquesta enquesta, presos de la mitjana: %s.",
                    es = "No publicados en esta encuesta, tomados de la media: %s."),
  note_rescaled = c(en = "The total exceeds 99%, so all parties were scaled down proportionally.",
                    ca = "El total supera el 99%, de manera que tots els partits s'han reduït proporcionalment.",
                    es = "El total supera el 99%, así que todos los partidos se han reducido proporcionalmente."),

  map_title     = c(en = "Projection by province", ca = "Projecció per província",
                    es = "Proyección por provincia"),
  map_lead      = c(en = "Leading party", ca = "Partit més votat", es = "Partido más votado"),
  map_seats_of  = c(en = "Seats: %s", ca = "Escons: %s", es = "Escaños: %s"),
  map_hint      = c(en = "Hover for the allocation, click a province for the detail below.",
                    ca = "Passa el ratolí per veure el repartiment; clica una província per veure'n el detall a sota.",
                    es = "Pasa el ratón para ver el reparto; haz clic en una provincia para ver el detalle debajo."),
  most_voted    = c(en = "Most voted", ca = "Més votat", es = "Más votado"),
  seats_word    = c(en = "seats", ca = "escons", es = "escaños"),
  legend_seats  = c(en = "%s seats", ca = "Escons %s", es = "Escaños %s"),

  congress      = c(en = "Congress of Deputies: 350 seats, majority %d",
                    ca = "Congrés dels Diputats: 350 escons, majoria %d",
                    es = "Congreso de los Diputados: 350 escaños, mayoría %d"),
  coalition     = c(en = "Majority check: add up parties", ca = "Comprovació de majories: suma partits",
                    es = "Comprobación de mayorías: suma partidos"),
  coal_head     = c(en = "%s: %d seats", ca = "%s: %d escons", es = "%s: %d escaños"),
  coal_body     = c(en = " in the central projection (90%% interval %s). Reaches %d seats in %s of simulations.",
                    ca = " a la projecció central (interval del 90%%: %s). Arriba als %d escons en el %s de les simulacions.",
                    es = " en la proyección central (intervalo del 90%%: %s). Alcanza los %d escaños en el %s de las simulaciones."),

  th_party      = c(en = "Party", ca = "Partit", es = "Partido"),
  th_vote       = c(en = "Vote %", ca = "% vot", es = "% voto"),
  th_vs23       = c(en = "vs 2023", ca = "vs. 2023", es = "vs. 2023"),
  th_projected  = c(en = "Seats by probability", ca = "Escons segons probabilitat",
                    es = "Escaños según probabilidad"),
  tier_safe     = c(en = "Safe (won in 90% of simulations or more)",
                    ca = "Segur (obtingut en el 90% de les simulacions o més)",
                    es = "Seguro (obtenido en el 90% de las simulaciones o más)"),
  tier_likely   = c(en = "Likely (50–90%)", ca = "Probable (50–90%)", es = "Probable (50–90%)"),
  tier_possible = c(en = "Possible (10–50%)", ca = "Possible (10–50%)", es = "Posible (10–50%)"),
  tier_tip      = c(en = "%s, seat %d: won in %s of simulations",
                    ca = "%s, escó %d: obtingut en el %s de les simulacions",
                    es = "%s, escaño %d: obtenido en el %s de las simulaciones"),
  tier_note     = c(en = "Each square is one seat, shaded by the share of simulations in which the party wins it. The Seats column is the central projection, so it can differ by one from the number of safe and likely squares.",
                    ca = "Cada quadrat és un escó, amb la intensitat segons la proporció de simulacions en què el partit l'obté. La columna Escons és la projecció central, i per tant pot diferir en un del nombre de quadrats segurs i probables.",
                    es = "Cada cuadrado es un escaño, con la intensidad según la proporción de simulaciones en las que el partido lo obtiene. La columna Escaños es la proyección central, así que puede diferir en uno del número de cuadrados seguros y probables."),
  th_seats      = c(en = "Seats", ca = "Escons", es = "Escaños"),
  th_interval   = c(en = "90% interval", ca = "Interval 90%", es = "Intervalo 90%"),
  th_pseat      = c(en = "P(seat)", ca = "P(escó)", es = "P(escaño)"),

  prov_default  = c(en = "Province detail", ca = "Detall de la província", es = "Detalle de la provincia"),
  prov_head     = c(en = "%s: %d seats", ca = "%s: %d escons", es = "%s: %d escaños"),
  prov_was      = c(en = " (%d in 2023)", ca = " (%d el 2023)", es = " (%d en 2023)"),
  prov_empty    = c(en = "Click a province on the map to see its seat distribution.",
                    ca = "Clica una província al mapa per veure'n la distribució d'escons.",
                    es = "Haz clic en una provincia del mapa para ver su distribución de escaños."),
  last_seat     = c(en = "The last seat goes to %s. Next in line is %s, %s points of the valid vote short of taking it. P(seat) is the share of simulations in which the party wins at least one seat here.",
                    ca = "L'últim escó és per a %s. El següent a la cua és %s, a qui falten %s punts del vot vàlid per aconseguir-lo. P(escó) és la proporció de simulacions en què el partit obté almenys un escó aquí.",
                    es = "El último escaño es para %s. El siguiente en la cola es %s, al que le faltan %s puntos del voto válido para conseguirlo. P(escaño) es la proporción de simulaciones en las que el partido obtiene al menos un escaño aquí."),

  plot_head     = c(en = "Poll trend, last three months (% of valid vote)",
                    ca = "Tendència de les enquestes, últims tres mesos (% del vot vàlid)",
                    es = "Tendencia de las encuestas, últimos tres meses (% del voto válido)"),
  plot_foot     = c(en = "Each dot is a poll. Lines are the trend for an average pollster, estimated at each date from the polls around it; at the right-hand end they reach the trend estimate the projection uses. Where polls are sparse the lines can wobble. Parties with too few polls have no line. Click a party in the legend to show or hide it; the smallest ones start hidden.",
                    ca = "Cada punt és una enquesta. Les línies són la tendència per a una empresa mitjana, estimada a cada data amb les enquestes del voltant; a l'extrem dret arriben a l'estimació de tendència que fa servir la projecció. On hi ha poques enquestes, les línies poden oscil·lar. Els partits amb massa poques enquestes no tenen línia. Clica un partit a la llegenda per mostrar-lo o amagar-lo; els més petits comencen amagats.",
                    es = "Cada punto es una encuesta. Las líneas son la tendencia para una empresa media, estimada en cada fecha con las encuestas de alrededor; en el extremo derecho llegan a la estimación de tendencia que usa la proyección. Donde hay pocas encuestas, las líneas pueden oscilar. Los partidos con muy pocas encuestas no tienen línea. Haz clic en un partido de la leyenda para mostrarlo u ocultarlo; los más pequeños empiezan ocultos."),
  plot_trend    = c(en = "%s, trend on %s: %s%%", ca = "%s, tendència el %s: %s%%",
                    es = "%s, tendencia el %s: %s%%"),
  polls_head    = c(en = "Polls of the last three months (% of valid vote)",
                    ca = "Enquestes dels últims tres mesos (% del vot vàlid)",
                    es = "Encuestas de los últimos tres meses (% del voto válido)"),
  polls_foot    = c(en = "● Included in the average (the latest poll of each pollster). Blank cells: party not published by the pollster. Source: %s.",
                    ca = "● Inclosa a la mitjana (l'última enquesta de cada empresa). Cel·les buides: partit no publicat per l'empresa. Font: %s.",
                    es = "● Incluida en la media (la última encuesta de cada empresa). Celdas vacías: partido no publicado por la empresa. Fuente: %s."),
  polls_excl    = c(en = "Re-estimates of CIS data by other firms and polls commissioned by a party are left out. Electomanía publishes a weekly estimate; only its latest one is used.",
                    ca = "Se n'exclouen les reestimacions de dades del CIS fetes per altres empreses i les enquestes encarregades per un partit. Electomanía publica una estimació setmanal; només se n'utilitza l'última.",
                    es = "Se excluyen las reestimaciones de datos del CIS hechas por otras empresas y las encuestas encargadas por un partido. Electomanía publica una estimación semanal; solo se usa la última."),
  polls_none    = c(en = "No polls dated in the last three months.",
                    ca = "No hi ha enquestes dels últims tres mesos.",
                    es = "No hay encuestas de los últimos tres meses."),
  col_date      = c(en = "Date", ca = "Data", es = "Fecha"),
  col_firm      = c(en = "Pollster", ca = "Empresa", es = "Empresa"),
  col_sample    = c(en = "Sample", ca = "Mostra", es = "Muestra"),
  average       = c(en = "Average", ca = "Mitjana", es = "Media"),
  trend         = c(en = "Trend estimate", ca = "Estimació de tendència",
                    es = "Estimación de tendencia")
)

# Text for `key` in language `lang`; extra arguments are passed to sprintf().
tr <- function(key, lang, ...) {
  txt <- TR[[key]][[lang]]
  if (...length()) sprintf(txt, ...) else txt
}

# Language asked for in the URL, else the first supported one the browser
# accepts, else English.
pick_lang <- function(query_string, accept = "") {
  q <- shiny::parseQueryString(query_string)$lang
  if (!is.null(q) && q %in% LANGS) return(q)
  prefs <- substr(trimws(strsplit(tolower(if (is.null(accept)) "" else accept), ",")[[1]]), 1, 2)
  hit <- prefs[prefs %in% LANGS]
  if (length(hit)) hit[1] else "en"
}

# Times are shown in Spanish peninsular time, whatever the server's time zone.
TIME_ZONE <- "Europe/Madrid"
fmt_date <- function(d, time = FALSE) {
  if (time) format(d, "%d-%m-%Y %H:%M", tz = TIME_ZONE) else format(d, "%d-%m-%Y")
}

# Numbers with the decimal and thousands marks of the language.
fmt_num <- function(x, lang, digits = 1) {
  formatC(x, format = "f", digits = digits, decimal.mark = if (lang == "en") "." else ",")
}
fmt_int <- function(x, lang) {
  en <- lang == "en"
  ifelse(is.na(x), "", formatC(x, format = "d", big.mark = if (en) "," else ".",
                               decimal.mark = if (en) "." else ","))
}
