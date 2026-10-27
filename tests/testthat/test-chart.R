# Uses fake_polls() from test-default.R's shape, rebuilt here so the file
# runs on its own: 12 polls by 4 pollsters, PP rising 0.1 points a day.
chart_polls <- function() {
  n <- 12
  shares <- matrix(NA_real_, n, length(PARTIES$code),
    dimnames = list(NULL, PARTIES$code)
  )
  days <- -3 * (seq_len(n) - 1)
  shares[, "PP"] <- 33 + 0.1 * days
  shares[, "SUMAR"] <- 7
  shares[1:3, "AA"] <- 0.8 # too few polls for a trend line
  firm <- rep(c("A", "B", "C", "D"), length.out = n)
  list(
    polls = data.frame(
      date = as.Date("2026-10-11") + days, firm = firm,
      n = c(NA, rep(1000, n - 1))
    ),
    shares = shares, pollster = tolower(firm), in_avg = !duplicated(firm)
  )
}

pl_chart <- chart_polls()
chart <- polls_chart_rows(pl_chart, base)

test_that("every poll figure is a dot, with its pollster", {
  dots <- chart[chart$series == "poll", ]
  expect_equal(sum(dots$party_code == "PP"), 12)
  expect_equal(sum(dots$party_code == "AA"), 3)
  pp <- dots[dots$party_code == "PP" & dots$date == "2026-10-11", ]
  expect_equal(pp$pct, 33)
  expect_equal(pp$pollster, "A")
  expect_true(pp$in_average)
})

test_that("trend curves are daily and end at the trend estimate", {
  pp <- chart[chart$series == "trend" & chart$party_code == "PP", ]
  expect_equal(nrow(pp), 34) # 2026-09-08 to 2026-10-11
  expect_equal(pp$date[nrow(pp)], "2026-10-11")
  est <- poll_estimates(pl_chart, base)
  expect_equal(pp$pct[nrow(pp)], round(est$trend[["PP"]], 3))
  expect_false(any(chart$series == "trend" & chart$party_code == "AA"))
})

test_that("names, colours and default visibility follow the chart", {
  expect_equal(
    unique(chart$party_name[chart$party_code == "SUMAR"]),
    "Frente Amplio + Compromís"
  )
  expect_equal(
    unique(chart$colour[chart$party_code == "PP"]),
    base$info["PP", "colour"]
  )
  expect_true(all(chart$shown_by_default[chart$party_code == "PP"]))
  expect_false(any(chart$shown_by_default[chart$party_code == "AA"]))
})

test_that("the CSV is written in UTF-8 and read back unchanged", {
  f <- tempfile(fileext = ".csv")
  expect_true(write_csv_utf8(chart, f))
  back <- utils::read.csv(f, encoding = "UTF-8")
  expect_equal(nrow(back), nrow(chart))
  expect_true("Frente Amplio + Compromís" %in% back$party_name)
  expect_false(write_csv_utf8(chart, file.path(tempfile(), "no", "x.csv")))
})
