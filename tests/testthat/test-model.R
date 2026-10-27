test_that("the real 2023 vote and seat counts reproduce the official allocation", {
  b23 <- base
  b23$seats <- base$seats_2023
  b23$seed <- base$votes23
  s <- simulate_election(b23, build_target(100 * base$nat23[PARTIES$code], b23)$target,
                         sims = 20, nat_err = 0, sigma_prov = 0, lists_2026 = FALSE)
  expect_equal(max(abs(s$seats - base$seats23)), 0)
})

test_that("in Navarra UPN's votes go to PP", {
  t <- build_target(100 * base$nat23[PARTIES$code], base)$target
  s <- simulate_election(base, t, sims = 5, nat_err = 0, sigma_prov = 0)
  i <- match(NAVARRA_PROV, base$cpro)
  expect_equal(s$share[i, "UPN"], 0)
  expect_equal(sum(s$seats[, "UPN"]), 0)
  expect_gt(s$share[i, "PP"], base$votes23[i, "PP"] / base$valid[i])
})
