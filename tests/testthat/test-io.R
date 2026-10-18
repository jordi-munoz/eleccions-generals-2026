test_that("the export folder is used when writable, else a temporary one", {
  d <- tempfile("exp")
  expect_equal(export_dir(d), d)
  expect_true(dir.exists(d))
  nowhere <- file.path(tempfile("missing"), "deeper", "export")
  expect_equal(export_dir(nowhere), file.path(tempdir(), "export"))
})

test_that("the saved POLITICO copy is used when the download fails", {
  cache <- tempfile(fileext = ".json")
  writeLines('{"polls": []}', cache)
  dead <- "http://127.0.0.1:9/nothing" # nothing listens on port 9
  res <- fetch_polls_json(dead, cache)
  expect_false(res$live)
  expect_equal(res$json$polls, list())
  expect_error(fetch_polls_json(dead, tempfile()), "no local copy")
})

test_that("the map loads, and a missing map file says how to build it", {
  m <- load_map(file.path(ROOT, MAP_FILE))
  expect_true(all(c("prov", "can_box") %in% names(m)))
  expect_equal(nrow(m$prov), 52)
  expect_error(load_map(tempfile()), "prepare_map")
})
