test_that("the real 2023 vote and seat counts reproduce the official allocation", {
  b23 <- base
  b23$seats <- base$seats_2023
  b23$seed <- base$votes23
  s <- simulate_election(b23, build_target(100 * base$nat23[PARTIES$code], b23)$target,
                         sims = 20, nat_err = 0, sigma_prov = 0)
  expect_equal(max(abs(s$seats - base$seats23)), 0)
})
