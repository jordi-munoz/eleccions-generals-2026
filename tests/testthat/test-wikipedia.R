fixture <- file.path(ROOT, "tests", "testthat", "fixtures", "wiki_polls.html")
polls <- suppressWarnings(read_wikipedia_polls(fixture))
row_of <- function(firm) polls[polls$firm == firm, ]

test_that("the tables before and after the FA agreement are merged", {
  expect_setequal(polls$firm, c(
    "GAD3/Vocento", "Hypothetical/No FV", "Joint/FA+FV",
    "SocioMétrica/El Español", "Sigma Dos/El Mundo"
  ))
  s <- row_of("SocioMétrica/El Español")
  expect_equal(s$date, as.Date("2026-10-11"))
  expect_equal(s$n, 1000)
  expect_equal(c(s$PP, s$SUMAR), c(32.6, 5.8))
  expect_equal(row_of("GAD3/Vocento")$date, as.Date("2026-10-17"))
  expect_equal(row_of("Sigma Dos/El Mundo")$date, as.Date("2025-12-29"))
})

test_that("FA is read as Sumar, with FV added as Compromís was before", {
  g <- row_of("GAD3/Vocento")
  expect_equal(g$SUMAR, 4.9 + 1.3)
  expect_equal(g$PODEMOS, 2.0)
  expect_equal(row_of("Hypothetical/No FV")$SUMAR, 5.5) # FV blank: FA alone
  expect_true(is.na(row_of("SocioMétrica/El Español")$PODEMOS)) # no column
})

test_that("a joint FA+FV figure spanning both columns is counted once", {
  j <- row_of("Joint/FA+FV")
  expect_equal(j$SUMAR, 6.8)
  expect_equal(j$PODEMOS, 2.7) # the columns after the span stay aligned
  expect_equal(j$PP, 31.1)
})

test_that("empty tables, election rows and later sections are skipped", {
  expect_false(any(grepl("election|skipped", polls$firm)))
  expect_equal(nrow(polls), 5)
})
