# Made-up polls in the shape load_polls() returns: 12 polls by 4 pollsters.
fake_polls <- function(n = 12) {
  shares <- matrix(NA_real_, n, length(PARTIES$code),
    dimnames = list(NULL, PARTIES$code)
  )
  shares[, c("PP", "PSOE", "VOX", "SUMAR", "PODEMOS")] <- rep(
    c(33, 27, 16, 7, 4),
    each = n
  )
  firm <- rep(c("A", "B", "C", "D"), length.out = n)
  list(
    polls = data.frame(
      date = as.Date("2026-10-11") - 3 * (seq_len(n) - 1),
      firm = firm, n = c(NA, rep(1000, n - 1))
    ),
    shares = shares, pollster = tolower(firm), in_avg = !duplicated(firm),
    source = "wikipedia", live = TRUE,
    retrieved = as.POSIXct("2026-10-18 05:30:00", tz = "UTC")
  )
}

test_that("poll estimates: average, trend and sample sizes", {
  est <- poll_estimates(fake_polls(), base)
  expect_true(est$has_polls)
  expect_named(est$avg, POLLED)
  expect_equal(est$avg[["PP"]], 33)
  expect_equal(est$trend[["PP"]], 33)
  # Unpublished parties have no average, and the trend falls back to it.
  expect_true(is.na(est$avg[["ERC"]]))
  expect_true(is.na(est$trend[["ERC"]]))
  expect_equal(est$poll_n, c(DEFAULT_N, rep(1000, 11)))
})

test_that("with no polls the estimates are the 2023 result", {
  pl <- fake_polls()
  pl$polls <- pl$polls[0, ]
  pl$shares <- pl$shares[0, , drop = FALSE]
  pl$in_avg <- logical(0)
  est <- poll_estimates(pl, base)
  expect_false(est$has_polls)
  expect_equal(est$trend, 100 * base$nat23[POLLED])
})

test_that("the default projection is the trend run with default settings", {
  proj <- default_projection(base, fake_polls(),
    now = as.POSIXct("2026-10-18 05:31:00", tz = "UTC")
  )
  expect_equal(proj$poll, "trend")
  expect_equal(sum(proj$sim$seats), 350)
  expect_equal(dim(proj$sim$sim_seats)[1], DEFAULT_SIMS)
  js <- jsonlite::fromJSON(rawToChar(proj$bytes$json))
  expect_equal(js$meta$generated_at, "2026-10-18T07:31:00+0200")
  expect_equal(js$meta$polls$n_polls, 12)
  expect_equal(js$meta$polls$n_pollsters, 4)
  expect_equal(js$meta$polls$last_fieldwork_end, "2026-10-11")
  expect_equal(js$meta$settings$simulations, DEFAULT_SIMS)
  expect_equal(sum(js$national$seats), 350)
})
