fixture <- file.path(ROOT, "tests", "testthat", "fixtures", "wiki_polls.html")

test_that("yearly tables are read, including ones with a note in the heading", {
  polls <- suppressWarnings(read_wikipedia_polls(fixture))
  expect_equal(nrow(polls), 2)
  expect_setequal(polls$firm, c("SocioMétrica/El Español", "Sigma Dos/El Mundo"))
  s <- polls[polls$firm == "SocioMétrica/El Español", ]
  expect_equal(s$date, as.Date("2026-10-11"))
  expect_equal(s$n, 1000)
  expect_equal(c(s$PP, s$SUMAR), c(32.6, 5.8))
  expect_equal(polls$date[polls$firm == "Sigma Dos/El Mundo"], as.Date("2025-12-29"))
})

test_that("empty tables, election rows and later sections are skipped", {
  polls <- suppressWarnings(read_wikipedia_polls(fixture))
  expect_false(any(grepl("election|skipped", polls$firm)))
})
