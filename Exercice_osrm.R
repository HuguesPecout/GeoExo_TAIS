###################################################################################################
#                                                                                                 #
#                             Geomatique avec R - Exercice appliqué                               #
#                                                                                                 #
###################################################################################################


###################################################################################################
# Chargement des librairies
###################################################################################################

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

## A.1 Import des données géographiques


## A.2 Reprojection des couches géographiques 





###################################################################################################
# B. Géocadage d’une adresse 
###################################################################################################

## B.1 Récupération de coordonnées géographiques

# Construction d'un data.frame avec nom et adresse


# Géocodage de l'adresse à partir de la base de données OpenStreetMap



## B.2 Construisez un objet sf (couche géographique) à partir des coordonnées (WGS84) récupérées.



## B.3 Transformez cette nouvelle couche géographique en projection WGS 84 / UTM zone 28N (32628)



## B.4 Affichez le point sur une carte interactive avec le package mapview






###################################################################################################
# C. Calcul de centroïdes 
###################################################################################################

# Créez une couche de point en calculant les centroïdes de départements sénégalais.






###################################################################################################
# D. Récupération de tuiles (fond de carte) OpenStreetMap
###################################################################################################

# En utilisant la librarie maptiles, récupérez une tuile OSM pour l’emprise du Sénégal. 
# Utilisez un buffer de plusieurs kilomètres autour des limites du sénégal 







###################################################################################################
# E. Affichage des données construites et récupérées
###################################################################################################






###################################################################################################
# F. Calculez une matrice de distances
###################################################################################################

## F.1 Distance euclidienne
# Calculez une matrice de distance euclidienne (m) entre la grande Mosquée de Touba et l’ensemble des centroïdes des départements.



## F.2 Distance par la route (réseau routier d’OpenStreetMap)



## F.3 Ajoutez les différentes distances calculées à la couche géographiques des centroïdes des départements




###################################################################################################
# G. Calcul d'indicateurs 
###################################################################################################

## G.1 Calcul d’indicateurs globaux d’accessibilité
# Calculez la médianne et la moyenne pour les trois types de distance récupérés



## G.2 Calcul d’indicateurs de performance routière

# Indice de sinuosité 

# Indice de vitesse sur route

# Indice global de performance




## G.3 Cartographie de l’indice global de performance



## G.4 Itinéraire le plus performant ?






###################################################################################################
# H. Récupération d’itinéraire
###################################################################################################


## H.1 Récupération de l’ititnéraire “Mosquee Touba - Dakar”



## H.2 Cartographie de l’itinéraire récupéré





