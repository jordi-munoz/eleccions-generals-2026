wiki_rows <- data.frame(
  date = as.Date(c(
    "2026-10-17", "2026-10-11", "2026-10-10", "2026-10-10",
    "2026-10-08", "2026-10-03"
  )),
  firm = c(
    "EM-Analytics/Electomanía", "SocioMétrica/El Español",
    "CIS (Target Point)", "Electomanía", "GAD3/Vocento",
    "EM-Analytics/Electomanía"
  ),
  PP = c(31.8, 32.6, 30.0, 31.5, 31.4, 31.2)
)

test_that("only Electomanía's latest estimate is kept", {
  d <- select_wiki_polls(wiki_rows)
  em <- d[grepl("Electoman|EM-Analytics", d$firm), ]
  expect_equal(nrow(em), 1)
  expect_equal(em$date, as.Date("2026-10-17"))
  expect_equal(em$PP, 31.8)
})

test_that("other pollsters are kept and CIS re-estimates dropped", {
  d <- select_wiki_polls(wiki_rows)
  expect_setequal(d$firm, c(
    "EM-Analytics/Electomanía", "SocioMétrica/El Español", "GAD3/Vocento"
  ))
  expect_false(any(grepl("^CIS [(]", d$firm)))
})

test_that("polls commissioned by a party are dropped", {
  firms <- c("PSOE", "Sumar", "Sondea/PP", "GAD3/Vocento", "PSOE Research", "CIS",
             "Sigma Dos/El Mundo")
  expect_equal(party_commissioned(firms), c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE))
  d <- select_wiki_polls(rbind(wiki_rows, data.frame(
    date = as.Date("2026-10-25"), firm = "PSOE", PP = 29.0
  )))
  expect_false("PSOE" %in% d$firm)
  expect_equal(nrow(d), 3)
})

test_that("a tie on the newest date keeps the first row listed", {
  tie <- wiki_rows
  tie$date[6] <- as.Date("2026-10-17")
  d <- select_wiki_polls(tie)
  expect_equal(d$PP[grepl("Electoman|EM-Analytics", d$firm)], 31.8)
})

test_that("with zero or one Electomanía row nothing else changes", {
  none <- wiki_rows[!grepl("Electoman|EM-Analytics", wiki_rows$firm), ]
  expect_equal(nrow(select_wiki_polls(none)), 2)
  one <- wiki_rows[-c(4, 6), ]
  expect_equal(nrow(select_wiki_polls(one)), 3)
  expect_equal(nrow(select_wiki_polls(wiki_rows[0, ])), 0)
})
