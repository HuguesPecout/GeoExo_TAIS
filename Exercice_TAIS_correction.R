###################################################################################################
#                                                                                                 #
#                             Geomatique  avec R - Exercice appliqué                              #
#                                                                                                 #
###################################################################################################


###################################################################################################
# Chargement des librairies
###################################################################################################

# install.packages("sf")
# install.packages("mapsf")
# install.packages("mapview")
# install.packages("maptiles")
# install.packages("osrm")
# install.packages("tidygeocoder")
# install.packages("spatstat")
# install.packages("osmdata")
# install.packages("terra")

library(sf)
library(maptiles)
library(osmdata)
library(tidygeocoder)
library(spatstat)
library(mapsf)
library(mapview)
library(terra)
library(osrm)





###################################################################################################
# A. Import des données IGN (BD CARTO)
###################################################################################################

# Lister les couches géographiques d'un fichier GeoPackage
st_layers("data/TAIS_workshop.gpkg")

## A.1 Import des données géographiques
mun <- st_read(dsn = "data/TAIS_workshop.gpkg", layer = "arrondissment")
road <-st_read(dsn = "data/TAIS_workshop.gpkg", layer = "troncon_routier")
railway <-st_read(dsn = "data/TAIS_workshop.gpkg", layer = "voie_ferree")
water <-st_read(dsn = "data/TAIS_workshop.gpkg", layer = "surface_hydro")

# Cartographie des données
library(mapsf)
mf_map(mun)
mf_map(railway, col = "grey10", add= TRUE)
mf_map(road, col = "grey50", add= TRUE)
mf_map(water, col = "blue", add= TRUE)
mf_map(mun, border = "red", col = NA, add= TRUE)


###################################################################################################
# B. Récupération données OSM
###################################################################################################

emprise <- mun |> 
            st_transform(crs = "EPSG:4326")|>
            st_buffer(dist = 200) |>
            st_bbox() 

###################################################################################################
# 1. Fond de carte 
###################################################################################################

library(maptiles)
tiles <- get_tiles(x = emprise, 
                   project = FALSE, 
                   crop = TRUE, 
                   zoom = 13, 
                   cachedir = "cache")


###################################################################################################
# 2. Données vectorielles 
###################################################################################################

# Définition d'une bounding box (emprise Paris)
q <- opq(bbox = emprise)

# Extraction des restaurants
req <- add_osm_feature(opq = q, key = 'amenity', value = "restaurant")
res <- osmdata_sf(req)

# Réduction du resultats :
# les points composant les polygones sont supprimés
res <- unique_osmdata(res)

resto_point <- res$osm_points

# extraire les centroïdes des polygones
resto_poly_point <- st_centroid(res$osm_polygons)

# identifier les champs en commun
chps <- intersect(names(resto_point), names(resto_poly_point))

# Union des deux couches
resto <- rbind(resto_point[, chps], resto_poly_point[, chps])

resto  <- st_transform(resto , crs = "EPSG:3857")



# Affciahge 

mf_raster(tiles)
mf_map(resto, cex= 0.2, add = TRUE)

###################################################################################################
# D. Géocodage d'adresse
###################################################################################################


etab <- data.frame(nom = c("EHESS", "SciencePo"),
                    rue = c("54 boulevard Raspail, 75006 Paris, France", 
                            "27 rue Saint-Guillaume, 75007 Paris, France"))

etab_geo <- geocode(.tbl = etab, address = "rue", quiet = TRUE)


etab_sf <- st_as_sf(etab_geo , coords = c("long", "lat"), crs = 'EPSG:4326')

mapview(etab_sf)


################
# AFFICHAGE
################

st_crs(resto)

tiles_2154 <- project(x = tiles, y = "EPSG:2154")
resto_2154 <- st_transform(resto , crs = "EPSG:2154")
etab_2154 <- st_transform(etab_sf , crs = "EPSG:2154")


mf_raster(tiles_2154)
mf_map(railway, col = "grey10", add= TRUE)
mf_map(road, col = "grey50", add= TRUE)
mf_map(water, col = "blue", add= TRUE)
mf_map(resto_2154, col = "green4", cex= 0.1, add= TRUE)
mf_map(etab_2154, col = "red4", cex=1, add= TRUE)
mf_map(mun, border = "red", col = NA, add= TRUE)




################
# EXPLORATION
################


###################################################################################################
# D. Nombre de restaurant  dans un rayon de 50Om ?
###################################################################################################

# Calcul d'un buffer de 50 kilomètres
EHESS_buff500m <- st_buffer(etab_2154[1,], 500)

## D.2. Séléctionnez les localités situées dans la zone tampon de 500m
# Intersection entre les localités et le buffer
inters_resto_buff <- st_intersection(resto_2154, EHESS_buff500m)

## D.3 Combien de ces localités abritent au moins une école ?
# Nombre de localités dans un rayon de 50km ?
nb_resto_500m_EHESS <- nrow(inters_resto_buff)

nb_resto_500m_EHESS


###################################################################################################
# E. Utilisation d’un maillage régulier
###################################################################################################

## E.1 Créez un maillage régulier de carreaux de 500m de côté sur l'ensemble de Paris
grid <- st_make_grid(mun, cellsize = 500, square = TRUE)
# Transformer la grille en objet sf avec st_sf()
grid <- st_sf(geometry = grid)
# Ajouter un identifiant unique, voir chapitre 3.7.6
grid$id_grid <- 1:nrow(grid)


## E.2 Récuperez le carreau d'appartenance (id) de chaque lrestaurants
grid_resto<- st_intersects(grid, resto_2154, sparse = TRUE)


## E.3 Comptez le nombre de localités dans chacun des carreaux.
grid$nb_resto <- sapply(grid_resto, FUN = length)

# E.4 Découpez la grille en fonction des limites de Paris (optionel)
grid_mun <- st_intersection(grid, st_union(mun))


###################################################################################################
# F. Enregistrez la grille régulière dans le fichier GeoSenegal.gpkg
###################################################################################################

# st_write(obj = grid_sen, dsn = "data/GeoSenegal.gpkg", layer = "grid_sen", delete_layer = TRUE)

mf_raster(tiles_2154)
mf_map(grid_mun, 
       var = "nb_resto", 
       type = "choro",
       border = "white",
       pal = "Teal", 
       alpha = .6,
       leg_pos = "topright",
       leg_val_rnd = 1,
       leg_title = paste0("Nombre de restaurants\n",
                          "Carroyage de 500m\n"), add = TRUE)


mf_raster(tiles_2154)
mf_map(grid_mun, add = TRUE, col = NA)
mf_map(grid_mun, 
       var = "nb_resto", 
       type = "prop",
       border = "white",
        inches = 0.1,
       leg_pos = "topright",
       leg_title = paste0("Nombre de restaurants\n",
                          "Carroyage de 500m\n"), add = TRUE)

mf_raster(tiles_2154)
mf_map(grid_mun, add = TRUE, col = NA)
mf_map(grid_mun, 
       var = c("nb_resto", "nb_resto"), 
       type = "prop_choro",
       pal = "Teal", 
       breaks = "quantile",
       border = "white",
       inches = 0.1,
       leg_pos = "topright",
       leg_title = paste0("Nombre de restaurants\n",
                          "Carroyage de 500m\n"), add = TRUE)

###################################################################################################
# E. Densité noyau kernel KDE
###################################################################################################

p <- as.ppp(X = st_coordinates(resto_2154), 
            W = as.owin(st_bbox(resto_2154)))
ds <- density.ppp(x = p, sigma = 150, eps = 10, positive = TRUE)
plot(ds)

library(terra)
r <- rast(ds) * 100 * 100
crs(r) <- st_crs(resto_2154)$wkt

library(mapiso)
# Limites des classes
maxval <- max(values(r))
bks <-  c(seq(0, floor(maxval), 1), maxval)
# Transformation du raster en polygones
iso_dens <- mapiso(r, breaks = bks)
# Suppression de la première classe ([0, 1[)
iso_dens <- iso_dens[-1, ]


mf_raster(tiles_2154)
mf_map(iso_dens, 
       var = "isomin", 
       type = "choro",
       breaks = bks[-1], 
       border = "white",
       pal = "Teal", 
       alpha = .6,
       leg_pos = "topright",
       leg_val_rnd = 1,
       leg_title = paste0("Densité de restaurants dans\n",
                          "un voisinage gaussien (σ = 150m),\n",
                          "en restaurants par hectare"), add = TRUE)

mf_map(etab_2154, cex = 1, add = TRUE)




mf_map(mun, col = "grey85")
mf_map(railway, col = "grey60", add= TRUE)
mf_map(road, col = "grey75", cex = .1, add= TRUE)
mf_map(water, col = "steelblue2", border = NA, add= TRUE)
mf_map(mun, col = NA, border = "grey20", lwd = 0.2, add= TRUE)
mf_map(iso_dens, 
       var = "isomin", 
       type = "choro",
       breaks = bks[-1], 
       border = "white", 
       lwd = 0.1,
       pal = "Teal", 
       alpha = .7,
       leg_pos = "topright", 
       leg_size = 0.8,
       leg_val_rnd = 1,
       leg_title_cex = 0.6,
       leg_title = paste0("Nombre de restaurants\npar hectare, voisinage\n",
                          "gaussien (σ = 150m)\n"), add = TRUE)
mf_map(etab_2154[1,], cex = 1, col = "red", add = TRUE)
mf_annotation(
  x = etab_2154[1,], 
  txt = "EHESS", 
  halo = TRUE, 
  cex = 0.5,pos = "topleft"
)
mf_legend(val_cex = 0.6, title = NA, size = 0.6,
  type = "typo", 
  val = c("railway", "road", "water"),
  pal = c("grey60", "grey75", "steelblue2"), 
  pos = "topleft"
)

mf_layout(
  title = "Densité de restaurants à Paris",
  credits = "",
  arrow = FALSE, 
  scale = TRUE
)

mf_credits("Auteurs : H. Pecout & T. Giraud\nSources : BD CARTO, IGN 2024 - OpenStreetMap 2024",
           cex = 0.5)

###################################################################################################
# E. Calcul accessibilité
###################################################################################################


# Extraction centroide zones denses
zone_dense <- iso_dens[iso_dens$isomax == max(iso_dens$isomax), ]
zones_denses <- st_cast(zone_dense, "POLYGON")
centres_denses <- st_centroid(zones_denses)

mat_dist_eucli <- st_distance(x = etab_2154, y = centres_denses)
rownames(mat_dist_eucli) <- etab_2154$nom


# Calcul de la matrice de distance entre les 2 adresses et les restaurants de Cahors
mat_dist_road <- osrmTable(src = etab_2154,
                           dst = centres_denses,
                           osrm.profile = "foot",
                           measure = c('duration', 'distance'))



# Itinéraire EHESS - Centre le plus proche
route <- osrmRoute(src = etab_2154[1,],
                   dst = centres_denses[1,])

# Récupération d'un fond de carte OSM
osm <- get_tiles(st_buffer(route, 500), zoom = 15, crop = TRUE)

# Affichage
mf_theme(mar = c(0,0,1.2,0))
mf_raster(osm)
mf_map(iso_dens, var = "isomin", type = "choro",
       breaks = bks[-1], border = "white",
       pal = "Teal", alpha = .5,
       leg_pos = NA, add = TRUE)
mf_map(route, col = "grey10", lwd = 6, add = T)
mf_map(route, col = "grey90", lwd = 1, add = T)
mf_map(etab_2154[1,], col = "red", cex= 3, add = T)
mf_annotation(
  x = etab_2154[1,], 
  txt = "EHESS", 
  halo = TRUE, 
  cex = 1
)
mf_title("Itineraire plus plus court vers l'offre de restauration la plus dense")




