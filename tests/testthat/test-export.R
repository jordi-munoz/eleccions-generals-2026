rows <- test_ex$rows
nat <- rows[rows$level == "national", ]
prov <- rows[rows$level == "province", ]

test_that("seats add up nationally and in every province", {
  expect_equal(sum(nat$seats), 350)
  expect_equal(sum(nat$seats_2023), 350)
  by_prov <- tapply(prov$seats, prov$cpro, sum)
  expect_equal(as.vector(by_prov[base$cpro]), unname(base$seats))
  expect_equal(as.vector(tapply(prov$district_seats, prov$cpro, unique)[base$cpro]),
               unname(base$seats))
  expect_equal(length(unique(prov$cpro)), 52)
})

test_that("national rows agree with the province rows and with 2023", {
  prov_seats <- tapply(prov$seats, prov$party_code, sum)
  expect_equal(as.vector(prov_seats[nat$party_code]), nat$seats)
  expect_equal(nat$votes_2023, unname(colSums(base$votes23)[nat$party_code]))
  expect_equal(nat$seats_2023, unname(colSums(base$seats23)[nat$party_code]))
})

test_that("intervals and probabilities are well formed", {
  expect_true(all(rows$seats_lo90 <= rows$seats_hi90))
  expect_true(all(rows$p_seat >= 0 & rows$p_seat <= 1))
  expect_true(all(rows$vote_pct >= 0 & rows$vote_pct <= 100))
  for (p in test_ex$provinces) {
    for (k in seq_len(nrow(p$parties))) {
      x <- p$parties$p_at_least[[k]]
      if (length(x)) {
        expect_equal(x[1], p$parties$p_seat[k])
        expect_true(all(diff(x) <= 0))
      } else {
        expect_equal(p$parties$p_seat[k], 0)
      }
    }
  }
})

test_that("province vote shares and the residual add up to 100", {
  for (p in test_ex$provinces) {
    expect_equal(sum(p$parties$vote_pct) + p$others_blank_pct, 100, tolerance = 0.01)
  }
})

test_that("Podemos has no list where it runs inside another one or not at all", {
  where <- c(PODEMOS_ABSENT, COMPROMIS_PROV, CANARIAS_PROV)
  expect_false(any(prov$party_code == "PODEMOS" & prov$cpro %in% where))
  expect_true(any(prov$party_code == "PODEMOS" & prov$cpro == "28"))
})

test_that("joint lists carry their own names", {
  name_of <- function(code, cpro) prov$party_name[prov$party_code == code & prov$cpro == cpro]
  expect_equal(name_of("SUMAR", "35"), "Unidad del Pueblo Canario")
  expect_equal(name_of("SUMAR", "28"), "Frente Amplio")
  expect_equal(name_of("COMPROMIS", "46"), "Compromís-Front Valencià")
  expect_equal(nat$party_name[nat$party_code == "SUMAR"], "Frente Amplio")
})

test_that("the JSON and CSV files hold the same data", {
  bytes <- serialise_export(test_ex)
  js <- jsonlite::fromJSON(rawToChar(bytes$json))
  expect_named(js, c("meta", "parties", "national", "provinces"))
  expect_true("p_seat" %in% names(js$meta$fields))
  expect_equal(nrow(js$provinces), 52)
  expect_equal(js$national$seats, nat$seats)

  tf <- tempfile(fileext = ".csv")
  writeBin(bytes$csv, tf)
  csv <- utils::read.csv(tf, colClasses = c(cpro = "character"), encoding = "UTF-8")
  expect_equal(nrow(csv), nrow(rows))
  expect_named(csv, names(rows))
  expect_equal(csv$seats, rows$seats)
  expect_true("Compromís-Front Valencià" %in% csv$party_name)
  expect_true(all(nchar(csv$cpro[csv$level == "province"]) == 2))
})

test_that("both files are written to the folder", {
  d <- tempfile("export")
  dir.create(d)
  expect_true(write_export(serialise_export(test_ex), d))
  expect_true(all(file.exists(file.path(d, EXPORT_FILES))))
})

test_that("only the two export paths are answered, open to any origin", {
  bytes <- list(json = charToRaw("{}"), csv = charToRaw("a\n"))
  r <- export_response(bytes, "/export/projection.json")
  expect_equal(r$status, 200)
  expect_match(r$content_type, "application/json")
  expect_equal(r$headers[["Access-Control-Allow-Origin"]], "*")
  expect_match(export_response(bytes, "/export/projection.csv")$content_type, "text/csv")
  expect_null(export_response(bytes, "/"))
  expect_null(export_response(bytes, "/export/other.json"))
  expect_null(export_response(bytes, NULL))
})
