polled <- setdiff(PARTIES$code, names(INSIDE))

test_that("targets cover every column and add up to one", {
  tg <- build_target(test_pct, base)
  expect_named(tg$target, colnames(base$seed))
  expect_equal(sum(tg$target), 1)
  expect_false(tg$rescaled)
  expect_true(all(base$local %in% tg$held))
})

test_that("Compromís takes its 2023 part of the joint Sumar figure", {
  tg <- build_target(test_pct, base)$target
  expect_equal(tg[["SUMAR"]] + tg[["COMPROMIS"]], test_pct[["SUMAR"]] / 100)
  n23 <- base$nat23
  k <- n23[["COMPROMIS"]] / (n23[["COMPROMIS"]] + n23[["SUMAR"]])
  expect_equal(tg[["COMPROMIS"]], k * test_pct[["SUMAR"]] / 100)
})

test_that("missing figures are filled from the fallback, or from 2023", {
  pct <- test_pct
  pct[c("ERC", "BNG")] <- NA
  fallback <- test_pct
  fallback["BNG"] <- NA
  fallback["ERC"] <- 2.5
  tg <- build_target(pct, base, fallback = fallback)
  expect_equal(tg$imputed, "ERC")
  expect_equal(tg$target[["ERC"]], 0.025)
  expect_equal(tg$target[["BNG"]], base$nat23[["BNG"]])
  expect_true("BNG" %in% tg$held)
})

test_that("figures adding up to more than 99% are scaled down", {
  pct <- test_pct
  pct["PP"] <- 80
  tg <- build_target(pct, base)
  expect_true(tg$rescaled)
  expect_equal(tg$target[[OTHERS]], MIN_REST)
  expect_equal(sum(tg$target), 1)
})
