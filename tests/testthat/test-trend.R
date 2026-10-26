# Synthetic polls: 20 polls over 57 days by two pollsters, one 1 point above
# and one 1 point below the truth, for a party rising 0.05 points a day.
days <- seq(-57, 0, by = 3)
dates <- as.Date("2026-10-11") + days
pollster <- rep(c("a", "b"), length.out = length(days))
house <- ifelse(pollster == "a", 1, -1)

test_that("the trend recovers a known line for an average pollster", {
  shares <- cbind(P = 30 + 0.05 * days + house)
  fit <- trend_fit(dates, pollster, shares)
  expect_equal(fit[["level", "P"]], 30)
  expect_equal(fit[["slope", "P"]], 0.05)
  expect_equal(trend_estimate(dates, pollster, shares, c(P = 99)), c(P = 30))
})

test_that("a single pollster is fitted without pollster levels", {
  shares <- cbind(P = 20 - 0.02 * days)
  fit <- trend_fit(dates, rep("a", length(days)), shares)
  expect_equal(fit[["level", "P"]], 20)
  expect_equal(fit[["slope", "P"]], -0.02)
})

test_that("recent polls weigh more: an outlier long ago moves the level less", {
  base_y <- 30 + house
  old <- recent <- cbind(P = base_y)
  n <- length(days)
  old[1, "P"] <- old[1, "P"] + 5 # oldest poll
  recent[n - 1, "P"] <- recent[n - 1, "P"] + 5 # second newest
  shift <- function(s) abs(trend_fit(dates, pollster, s)[["level", "P"]] - 30)
  expect_lt(shift(old), shift(recent))
})

test_that("the trend falls back to the given value when it cannot be trusted", {
  n <- length(days)
  shares <- cbind(
    FEW = c(rep(NA, n - 5), 5:9), # fewer than 8 polls
    OUT = c(10 + 0.5 * (0:9), rep(NA, n - 10)), # line runs past its polls
    OK = 30 + house
  )
  fit <- trend_fit(dates, pollster, shares)
  expect_true(is.na(fit[["level", "FEW"]]))
  expect_true(is.na(fit[["level", "OUT"]]))
  expect_equal(fit[["level", "OK"]], 30)

  est <- trend_estimate(dates, pollster, shares, c(FEW = 1, OUT = 3, OK = 4))
  expect_equal(est, c(FEW = 1, OUT = 3, OK = 30))

  # One poll per pollster: pollster levels absorb everything (rank-deficient).
  own <- paste0("p", seq_len(n))
  rank <- cbind(RANK = 10 + seq_len(n))
  expect_true(is.na(trend_fit(dates, own, rank)[["level", "RANK"]]))
})

test_that("the chart curve ends exactly at the trend estimate", {
  shares <- cbind(P = 30 + 0.05 * days + house + sin(days / 9))
  fit <- trend_fit(dates, pollster, shares)
  curve <- trend_curve(dates, pollster, shares)
  expect_equal(nrow(curve), as.numeric(diff(range(dates))) + 1)
  expect_equal(curve[nrow(curve), "P"], fit[["level", "P"]])
})

test_that("the chart curve recovers a straight line and follows a bend", {
  straight <- cbind(P = 30 + 0.05 * days + house)
  curve <- trend_curve(dates, pollster, straight)
  grid <- seq(min(dates), max(dates), by = 1)
  expect_equal(unname(curve[, "P"]), 30 + 0.05 * as.numeric(grid - max(dates)))
  # A party that rose and then fell: the curve peaks in the middle.
  bent <- cbind(P = 30 - 0.004 * (days + 28)^2 + house)
  bc <- trend_curve(dates, pollster, bent)[, "P"]
  peak <- as.numeric(as.Date(names(which.max(bc))) - max(dates))
  expect_true(peak > -40 && peak < -15)
})

test_that("parties without a trend line get no curve", {
  shares <- cbind(P = 30 + house, Q = c(rep(NA, length(days) - 5), rep(2, 5)))
  curve <- trend_curve(dates, pollster, shares)
  expect_true(all(!is.na(curve[, "P"])))
  expect_true(all(is.na(curve[, "Q"])))
})
