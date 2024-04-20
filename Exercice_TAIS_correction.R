###################################################################################################
#                                                                                                 #
#                             Geomatique avec R - Exercice appliqué                               #
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

library(sf)
library(mapsf)
library(mapview)
library(maptiles)
library(osrm)
library(tidygeocoder)




###################################################################################################
# A. Import des données
###################################################################################################

# Lister les couches géographiques d'un fichier GeoPackage
st_layers("data/GeoSenegal.gpkg")

## A.1 Import des données géographiques
pays <- st_read(dsn = "data/GeoSenegal.gpkg", layer = "Pays_voisins")
sen <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Senegal")
reg <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Regions")
dep <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Departements")
loc <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Localites")
USSEIN <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "USSEIN")
routes <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Routes")


## A.2 Reprojection des couches géographiques 
pays <- st_transform(pays,  "EPSG:3857")
sen <- st_transform(sen,  "EPSG:3857")
reg <- st_transform(reg,  "EPSG:3857")
dep <- st_transform(dep,  "EPSG:3857")
loc <- st_transform(loc,  "EPSG:3857")
USSEIN <- st_transform(USSEIN,  "EPSG:3857")
routes <- st_transform(routes,  "EPSG:3857")


###################################################################################################
# B. Géocadage d’une adresse 
###################################################################################################

## B.1 Récupération de coordonnées géographiques

# Construction d'un data.frame avec nom et adresse
Mosquee_Touba <- data.frame(name = "Grande Mosquée de Touba",
                            addresse = "Grande Mosquée de Touba, Sénégal")

# Géocodage de l'adresse à partir de la base de données OpenStreetMap
library(tidygeocoder)
Mosquee_Touba_loc <- geocode(.tbl = Mosquee_Touba, address =  addresse)


## B.2 Construisez un objet sf (couche géographique) à partir des coordonnées (WGS84) récupérées.
Mosquee_Touba_sf <- st_as_sf(Mosquee_Touba_loc, coords = c("long", "lat"), crs = 4326)


## B.3 Transformez cette nouvelle couche géographique en projection WGS 84 / UTM zone 28N (32628)
Mosquee_Touba_sf <- st_transform(Mosquee_Touba_sf, crs = "EPSG:3857")


## B.4 Affichez le point sur une carte interactive avec le package mapview
mapview(Mosquee_Touba_sf)



###################################################################################################
# C. Calcul de centroïdes (point de d’arrivée)
###################################################################################################


# Créez une couche de point en calculant les centroïdes de départements sénégalais.
dep_pt <- st_centroid(dep)




###################################################################################################
# D. Récupération de tuiles (fond de carte) OpenStreetMap
###################################################################################################


# En utilisant la librarie maptiles, récupérez une tuile OSM pour l’emprise du Sénégal. 
# Utilisez un buffer de plusieurs kilomètres autour des limites du sénégal 
osm_tiles <- get_tiles(x = st_buffer(sen, dist = 30000), zoom = 7, crop = TRUE)




###################################################################################################
# E. Affichage des données construites et récupérées
###################################################################################################

# mf_export(x = sen, filename = "img/carte_osm.png", width = 800)

# Affichage de la tuile
mf_raster(osm_tiles)

# Affichage des données vectorielles
mf_map(dep_pt, border = NA, col="blue" , cex = 2, pch = 20, add = TRUE)
mf_map(dep, border = "black", col=NA , add = TRUE)
mf_map(Mosquee_Touba_sf, border = NA, col="red" , cex = 3, pch = 20, add = TRUE)

# Sources
mf_credits(get_credit("OpenStreetMap"), cex = 1)

# dev.off()






###################################################################################################
# F. Calculez une matrice de distances
###################################################################################################

## F.1 Distance euclidienne
# Calculez une matrice de distance euclidienne (m) entre la grande Mosquée de Touba et l’ensemble des centroïdes des départements.
mat_eucli_km <- st_distance(x = Mosquee_Touba_sf, y = dep_pt) 

# Changement des noms de ligne et de colonne
rownames(mat_eucli_km) <- Mosquee_Touba_sf$name
colnames(mat_eucli_km) <- dep_pt$NAME_2




## F.2 Distance par la route (réseau routier d’OpenStreetMap)
dist <- osrmTable(src = Mosquee_Touba_sf, 
                  dst = dep_pt,
                  measure = c("distance", "duration"))



## F.3 Ajoutez les différentes distances calculées à la couche géographiques des centroïdes des départements
# mètres -> kilomètres
dep_pt$IRSP_eucli_dist <- as.numeric(mat_eucli_km) / 1000
# mètres -> kilomètres
dep_pt$IRSP_route_km <- as.numeric(dist$distances) / 1000
# Minutes -> heures
dep_pt$IRSP_route_hr <- as.numeric(dist$durations) / 60



###################################################################################################
# G. Calcul d'indicateurs 
###################################################################################################

## G.1 Calcul d’indicateurs globaux d’accessibilité

# Calculez la médianne et la moyenne pour les trois types de distances récupérés
mean(dep_pt$IRSP_eucli_dist)
max(dep_pt$IRSP_eucli_dist)

mean(dep_pt$IRSP_route_km)
max(dep_pt$IRSP_route_km)

mean(dep_pt$IRSP_route_hr)
max(dep_pt$IRSP_route_hr)



## G.2 Calcul d’indicateurs de performance routière

# Indice de sinuosité 
dep_pt$ind_sinuo <- round(dep_pt$IRSP_route_km / dep_pt$IRSP_eucli_dist, 2)
# Indice de vitesse sur route
dep_pt$ind_speed <- round(dep_pt$IRSP_route_km / dep_pt$IRSP_route_hr, 1)
# Indice global de performance
dep_pt$ind_perf <- round(dep_pt$ind_speed / dep_pt$ind_sinuo, 1)



## G.3 Cartographie de l’indice global de performance

# mf_export(x = st_buffer(sen, dist = 30000), filename = "img/carte_indice_perf.png", width = 800)

# Affichage de la tuile
mf_raster(osm_tiles)
# Cartographie de l'indice de performance
mf_map(x = dep_pt,
       var = "ind_perf",
       type = "choro",
       pal = "Peach",
       leg_pos = "right",
       leg_title = "Indice de\nperformance\nglobale",
       breaks = "jenks",
       nbreaks = 8, 
       leg_size = 1.1,
       leg_title_cex = 0.9,
       leg_val_cex = 0.8,
       leg_val_rnd = 0,
       border = "white",
       lwd = 1.5,
       cex = 2.5,
       add = TRUE)

# Affichage de la grande Mosquee de Touba
mf_map(Mosquee_Touba_sf, lwd = 4, pch = 24, col="green4" , cex = 2.1, add = TRUE)
# Titre
mf_title("Performance du réseau routier depuis le grande Mosquee de Touba, selon OpenStreetMap (OSRM), 2014", fg = "white")
# Sources
mf_credits(paste0(get_credit("OpenStreetMap"), " - OSRM, 2014"), cex = 0.8)

# dev.off()


## G.4 Itinéraire le plus performant ?
city_max_perf <- dep_pt[dep_pt$ind_perf == max(dep_pt$ind_perf),]




###################################################################################################
# H. Récupération d’itinéraire
###################################################################################################


## H.1 Récupération de l’ititnéraire “Mosquee Touba - Dakar”
route <- osrmRoute(src = Mosquee_Touba_sf, dst = city_max_perf)


## H.2 Cartographie de l’itinéraire récupéré

# mf_export(x = st_buffer(sen, dist = 30000), filename = "img/perf_itineraire.png", width = 800)

# Affichage de la tuile
mf_raster(osm_tiles)

# Affichage de l'itinéraire le plus performant
mf_map(route, col = "grey10", lwd = 6, add = TRUE)
mf_map(route, col = "grey90", lwd = 1, add = TRUE)

# Affichage de la grande mosquee de Touba
mf_map(Mosquee_Touba_sf, lwd = 4, pch = 24, col="green4" , cex = 2.1, add = TRUE)

# Affichage de Dakar
mf_map(city_max_perf, border = NA, col="red", pch = 20, cex = 3, add = TRUE)

# Titre
mf_title("Itinéraire le plus performant depuis la grand Mosquee de Touba, 2014", fg = "white")
# Sources
mf_credits(paste0(get_credit("OpenStreetMap"), " - OSRM, 2014"), cex = 0.8)

# dev.off()



