library(sf)

# Lister les couches géographiques d'un fichier GeoPackage
st_layers("data/BDC_5-0_GPKG_LAMB93_D075-ED2023-03-15.gpkg")

## A.1 Import des données géographiques
paris <-st_read(dsn = "data/BDC_5-0_GPKG_LAMB93_D075-ED2023-03-15.gpkg", layer = "arrondissement_municipal")
eau <-st_read(dsn = "data/BDC_5-0_GPKG_LAMB93_D075-ED2023-03-15.gpkg", layer = "surface_hydrographique")
ferr <-st_read(dsn = "data/BDC_5-0_GPKG_LAMB93_D075-ED2023-03-15.gpkg", layer = "troncon_de_voie_ferree")
road <-st_read(dsn = "data/BDC_5-0_GPKG_LAMB93_D075-ED2023-03-15.gpkg", layer = "troncon_de_route")

road_P <- st_filter(x = road, y = paris, .predicate = st_intersects)
ferr_P <-  st_filter(x = ferr, y = paris, .predicate = st_intersects)
eau_P <-  st_filter(x = eau, y = paris, .predicate = st_intersects)


st_write(obj = paris, dsn = "data/TAIS_workshop.gpkg", layer = "arrondissment")
st_write(obj = road_P, dsn = "data/TAIS_workshop.gpkg", layer = "troncon_routier")
st_write(obj = ferr_P, dsn = "data/TAIS_workshop.gpkg", layer = "voie_ferree")
st_write(obj = eau_P, dsn = "data/TAIS_workshop.gpkg", layer = "surface_hydro")
st_write(obj = resto_2154, dsn = "data/TAIS_workshop.gpkg", layer = "restaurant_osm")
st_write(obj = etab_2154, dsn = "data/TAIS_workshop.gpkg", layer = "etab_esr")


library(mapsf)
mf_map(paris)
mf_map(ferr_P, col = "grey10", add= TRUE)
mf_map(road_P, col = "grey50", add= TRUE)
mf_map(eau_P, col = "blue", add= TRUE)
mf_map(paris, border = "red", col = NA, add= TRUE)



mf_map(occ, var= "nature", type = "typo", add = TRUE )
