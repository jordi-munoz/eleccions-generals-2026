test_that("every interface text exists in the three languages", {
  for (key in names(TR)) expect_setequal(names(TR[[key]]), LANGS)
  expect_equal(tr("tab_proj", "ca"), "Projecció")
  expect_equal(tr("coal_head", "en", "PP", 140L), "PP: 140 seats")
})

test_that("the language comes from the URL, then the browser, then English", {
  expect_equal(pick_lang("?lang=ca", "es-ES,es;q=0.9"), "ca")
  expect_equal(pick_lang("?lang=xx", "es-ES,es;q=0.9"), "es")
  expect_equal(pick_lang("", "fr-FR, ca;q=0.8"), "ca")
  expect_equal(pick_lang("", "fr-FR"), "en")
  expect_equal(pick_lang("", NULL), "en")
})

test_that("numbers use the decimal and thousands marks of the language", {
  expect_equal(fmt_num(12.345, "en"), "12.3")
  expect_equal(fmt_num(12.345, "ca", 2), "12,35")
  expect_equal(fmt_int(c(1234567, NA), "en"), c("1,234,567", ""))
  expect_equal(fmt_int(1234567, "es"), "1.234.567")
})

test_that("dates are DD-MM-YYYY and times are in Madrid time", {
  expect_equal(fmt_date(as.Date("2026-10-11")), "11-10-2026")
  summer <- as.POSIXct("2026-10-17 18:37:00", tz = "UTC")
  winter <- as.POSIXct("2026-12-01 12:00:00", tz = "UTC")
  expect_equal(fmt_date(summer, time = TRUE), "17-10-2026 20:37")
  expect_equal(fmt_date(winter, time = TRUE), "01-12-2026 13:00")
})
