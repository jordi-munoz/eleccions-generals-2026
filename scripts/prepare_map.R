# Builds data/provinces.rds (province polygons with the Canary Islands moved
# next to the peninsula). Run once from the project root:
#   Rscript scripts/prepare_map.R
library(sf)
library(mapSpain)

prov <- esp_get_prov(moveCAN = TRUE, epsg = "4326")
prov <- prov[, c("cpro", "ine.prov.name")]
names(prov)[2] <- "name"
prov <- st_simplify(prov, dTolerance = 800, preserveTopology = TRUE)
prov <- prov[order(prov$cpro), ]

dir.create("data", showWarnings = FALSE)
saveRDS(list(prov = prov, can_box = esp_get_can_box(epsg = "4326")),
        file.path("data", "provinces.rds"))
