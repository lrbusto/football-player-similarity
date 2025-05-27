
### APLICACIÓN DE TODAS LAS TECNICAS DE ANALISIS NO SUPERVISADO DENTRO DEL PFM
#### EXPLICADAS EN LA MEMORIA DENTRO DE LOS APARTADOS 3 A 5 INCLUIDOS
# 1. Apertura de librerías y extracción del path del PFM


## 1.1. Abrir librerías
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(stringi))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(GGally))
suppressPackageStartupMessages(library(corrplot))
suppressPackageStartupMessages(library(factoextra))
suppressPackageStartupMessages(library(gridExtra))
suppressPackageStartupMessages(library(lsa))
suppressPackageStartupMessages(library(ggrepel))
suppressPackageStartupMessages(library(cluster))
suppressPackageStartupMessages(library(kableExtra))

## 1.2. Extraer la ruta principal del PFM
PATH_DIR <- getwd()
PATH_DIR <- strsplit(PATH_DIR, '/')
PFM_DIR <- ""

for (c in PATH_DIR[[1]]){
  
  PFM_DIR <- paste0(PFM_DIR,c,'/')
  
  if (c == 'PFM') break
}


knitr::opts_chunk$set(echo = TRUE)
knitr::opts_knit$set(root.dir = PFM_DIR)



# 2. Lectura de los ficheros por posiciones

## 2.1. Lectura de los ficheros por posiciones
df_keepers <- read.csv("Results/Keepers_Dataset.csv", sep=",", encoding="UTF-8", check.names = F)
df_defenders <- read.csv("Results/Defenders_Dataset.csv", sep=",", encoding="UTF-8", check.names = F)
df_midfilders <- read.csv("Results/Midfilders_Dataset.csv", sep=",", encoding="UTF-8", check.names = F)
df_attackers <- read.csv("Results/Attackers_Dataset.csv", sep=",", encoding="UTF-8", check.names = F)



## 2.2. Establecer nombres de jugadores como índice de los datasets
set_name_as_index <- function(data){
  data <- data %>% 
    separate(
      col = UrlFBref, 
      into = c("E1","E2","E3","E4","E5","E6","Player"),
      sep = "/",
      remove = FALSE) %>%
    select(-c("E1","E2","E3","E4","E5","E6"))
  row.names(data) <- make.names(data$Player, unique = TRUE)
  data <- data %>% select(-Player)
  
  return(data)
}

df_keepers <- set_name_as_index(df_keepers)
df_defenders <- set_name_as_index(df_defenders)
df_midfilders <- set_name_as_index(df_midfilders)
df_attackers <- set_name_as_index(df_attackers)



# 3. Análisis de Componentes Principales (PCA)

## 3.1. Cálculo de la mátriz de correlación y su determinante

### 3.1.1. Cálculo de la matriz de correlación por puestos
R_keepers <- cor(df_keepers[,-c(1,2)]) 
R_defenders <- cor(df_defenders[,-c(1,2)]) 
R_midfilders <- cor(df_midfilders[,-c(1,2)]) 
R_attackers <- cor(df_attackers[,-c(1,2)]) 


### 3.1.2. Determinante de la matriz de correlación por puestos
paste0("Determinante de (R) para Porteros: ", det(R_keepers))
paste0("Determinante de (R) para Defensores: ", det(R_defenders))
paste0("Determinante de (R) para Centrocampistas: ", det(R_midfilders))
paste0("Determinante de (R) para Atacantes: ", det(R_attackers))


## 3.2. Aplicación del Análisis de Componentes Principales

### 3.2.1. Cálculo del PCA para cada puesto
pca_keepers <- prcomp(df_keepers[,-c(1,2)], scale=TRUE) 
pca_defenders <- prcomp(df_defenders[,-c(1,2)], scale=TRUE)
pca_midfilders <- prcomp(df_midfilders[,-c(1,2)], scale=TRUE)
pca_attackers <- prcomp(df_attackers[,-c(1,2)], scale=TRUE)


## 3.3. Selección del número óptimo de componentes


### 3.3.1 Función para obtener resumen de variabilidad y ... 
### ... visualizar el número de componentes óptimo
prop_variance <- function(pca, pos){
  resumen <- matrix(NA, nrow = length(pca$sdev), ncol=3)
  resumen[,1] <- pca$sdev^2 # autovalores
  # % de variabilidad por cada CP
  resumen[,2] <- 100*resumen[,1]/sum(resumen[,1])
  resumen[,3] <- cumsum(resumen[,2])/100
  colnames(resumen) <- c("Autovalor", "Porcentaje", paste0("% Acumulado (", pos, ")"))
  #n <- length(resumen[,3][resumen[,3] < max_pct])+1
  #print(paste0("El número óptimo de CPs para los ", pos, " es: ", n))
  return (resumen)
}



### 3.3.2. Obtención de la proporción de varianza explicada acumulada por puesto
prop_var_keepers <- prop_variance(
  pca = pca_keepers,
  pos = "Porteros")

prop_var_defenders <- prop_variance(
  pca = pca_defenders,
  pos = "Defensores")

prop_var_midfilders <- prop_variance(
  pca = pca_midfilders,
  pos = "Centrocampistas")

prop_var_attackers <- prop_variance(
  pca = pca_attackers,
  pos = "Delanteros")



### 3.3.3. Representar proporción de varianza explicada para autovalores superiores a la media
plot_autoval_greater_than_avg <- function(R, prop_var, pos){
  autoval <- eigen(R)$values
  nopt <- length(which(autoval > mean(autoval)))
  colors_opt <- rep("royalblue", length(autoval))
  colors_opt[nopt] <- "indianred"
  plot(autoval, type ="h",  ylab = "Autovalores",
       xlab = "Componentes principales",
       main = pos,
       sub = paste0("(Varianza Explicada ", 
                   round(prop_var[[nopt,3]]*100, 2), "%)"),
       col = colors_opt)
  abline(h=mean(autoval),col="firebrick",lty=2)
  text(nopt+3, autoval[nopt]+1.5,
       paste0("(", nopt, ", ", round(autoval[nopt], 3), ")"),cex = 0.9)
}
par(mfrow=c(2,2))
plot_autoval_greater_than_avg(R_keepers, prop_var_keepers, "Porteros")
plot_autoval_greater_than_avg(R_defenders, prop_var_defenders, "Defensores")
plot_autoval_greater_than_avg(R_midfilders, prop_var_midfilders, "Centrocampistas")
plot_autoval_greater_than_avg(R_attackers, prop_var_attackers, "Atacantes")


## 3.4. Correlación y contribución de las variables con las componentes

### 3.4.1. Representar las correlaciones de las componentes ...
### ... con las variables originales
autoval <- eigen(R_keepers)$values
nopt <- length(which(autoval > mean(autoval)))
correlaciones <- pca_keepers$rotation %*% diag(pca_keepers$sdev)
corrplot(t(correlaciones[,1:nopt]),
         method="color", tl.cex = 0.8)
mtext(expression(bold("Porteros")), at=35, line=-2, cex=1.5)

autoval <- eigen(R_defenders)$values
nopt <- length(which(autoval > mean(autoval)))
correlaciones <- pca_defenders$rotation %*% diag(pca_defenders$sdev)
corrplot(t(correlaciones[,1:nopt]),
         method="color", tl.cex = 0.8)
mtext(expression(bold("Defensores")), at=40, line=-2, cex=1.5)

autoval <- eigen(R_midfilders)$values
nopt <- length(which(autoval > mean(autoval)))
correlaciones <- pca_midfilders$rotation %*% diag(pca_midfilders$sdev)
corrplot(t(correlaciones[,1:nopt]),
         method="color", tl.cex = 0.8)
mtext(expression(bold("Centrocampistas")), at=55, line=-2, cex=1.5)

autoval <- eigen(R_attackers)$values
nopt <- length(which(autoval > mean(autoval)))
correlaciones <- pca_attackers$rotation %*% diag(pca_attackers$sdev)
corrplot(t(correlaciones[,1:nopt]),
         method="color", tl.cex = 0.7)
mtext(expression(bold("Atacantes")), at=67, line=-2, cex=1.5)


### 3.4.2. Representación de las contribuciones de las variables sobre ...
### ... las dos componentes más importantes
plot_variable_contrib <- function(pca, pos){
  fviz_pca_var(pca, col.var = "contrib",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             geom = c("point", "text"),
             repel = T,
             pointsize = 0.5, labelsize = 3, 
             ggtheme = theme_classic()) +
  labs(title = pos) +
  theme(plot.title = element_text(size = 15, face = "bold", hjust = 0.5))
}

plot_variable_contrib(pca_keepers, "Porteros")
plot_variable_contrib(pca_defenders, "Defensores")
plot_variable_contrib(pca_midfilders, "Centrocampistas")
plot_variable_contrib(pca_attackers, "Atacantes")



## 3.5. Puntuaciones de los jugadores sobre las componentes



### 3.5.1. Creación de datasets por puesto con las puntuaciones individuales ...
### ... de los jugadores en las respectivas componentes
dataset_PCA_scores <- function(R, pca){
  autoval <- eigen(R)$values
  nopt <- length(which(autoval > mean(autoval)))
  scores <- as.data.frame(pca$x[,1:nopt])
  
  return(scores)
}

df_pca_keepers <- dataset_PCA_scores(R_keepers, pca_keepers)
df_pca_defenders <- dataset_PCA_scores(R_defenders, pca_defenders)
df_pca_midfilders <- dataset_PCA_scores(R_midfilders, pca_midfilders)
df_pca_attackers <- dataset_PCA_scores(R_attackers, pca_attackers)



kbl(head(df_pca_keepers , 20),
align = "c") %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(df_pca_defenders , 20),
align = "c") %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(df_pca_midfilders , 20),
align = "c") %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(df_pca_attackers , 20),
align = "c") %>%
kable_classic(full_width = F,
latex_options=c("striped"))



### 3.5.2. Representación de las contribuciones de los jugadores ...
### ... a las dos principales componentes
plot_ind_contrib <- function(pca, pos){
  
  subset_df <- pca$x[sample(row.names(pca$x), size = 75, replace = FALSE),]
  fviz_pca_ind(pca,
             col.ind = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             geom = c("point", "text"),
             pointsize = 0.5, labelsize = 3, repel = TRUE ,
             select.ind = list(names = row.names(subset_df)),
             ggtheme = theme_minimal()) + 
  theme(plot.title = element_text(size = 15, face = "bold", hjust = 0.5)) +
  labs(title = pos)}

plot_ind_contrib(pca_keepers, "Porteros")
plot_ind_contrib(pca_defenders, "Defensores")
plot_ind_contrib(pca_midfilders, "Centrocampistas")
plot_ind_contrib(pca_attackers, "Atacantes")



### 3.5.3. Cálculo de los scores de similitud entre jugadores mediante ...
### ... el coeficiente de correlación de Pearson sobre las puntuaciones ... 
### ... de los individuos del PCA
similarity_PCA_scores <- function(df_pca){
  PCA_scores_t <- cor(t(df_pca), method = "pearson")
  
  PCA_scores_t <- as.data.frame(
    cbind(Player = rownames(PCA_scores_t), PCA_scores_t))
  row.names(PCA_scores_t) <- 1:nrow(PCA_scores_t)
  
  PCA_scores_t <- PCA_scores_t %>%
    gather(Player_Comp, PCA_Score, -Player)
  
  PCA_scores_t$PCA_Score <- round(as.numeric(PCA_scores_t$PCA_Score), 4)
  
  return(PCA_scores_t)
}

sim_PCA_scores_keepers <- similarity_PCA_scores(df_pca_keepers)
sim_PCA_scores_defenders <- similarity_PCA_scores(df_pca_defenders)
sim_PCA_scores_midfilders <- similarity_PCA_scores(df_pca_midfilders)
sim_PCA_scores_attackers <- similarity_PCA_scores(df_pca_attackers)




kbl(head(sim_PCA_scores_keepers %>% 
       filter(Player == "Manuel.Neuer") %>%
       arrange(desc(PCA_Score)), 10),
align = "l") %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(sim_PCA_scores_defenders %>% 
       filter(Player == "Alejandro.Balde") %>%
       arrange(desc(PCA_Score)), 10),
align = "l") %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(sim_PCA_scores_midfilders %>% 
       filter(Player == "Sergio.Busquets") %>%
       arrange(desc(PCA_Score)), 10),
align = "l") %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(sim_PCA_scores_attackers %>% 
       filter(Player == "Rayan.Cherki") %>%
       arrange(desc(PCA_Score)), 10),
align = "l") %>%
kable_classic(full_width = F,
latex_options=c("striped"))



# 4.  Algoritmo de clusterización no jerárquico: K-medias

## 4.1. Evaluación de la tendencia de agrupamiento por puesto

### 4.1.1. método del codo por puesto
plot_elbow_method <- function(df_pca, pos){ 
  dist_eucl <- dist(df_pca, method="euclidean")
  fviz_nbclust(x = df_pca, FUNcluster = kmeans, 
               method = "wss",diss = dist_eucl) + 
    labs(title = pos) + theme_classic() + 
    theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))
}

grid.arrange(
  plot_elbow_method(df_pca_keepers, "Porteros"),
  plot_elbow_method(df_pca_defenders, "Defensores"),
  plot_elbow_method(df_pca_midfilders, "Centrocampistas"),
  plot_elbow_method(df_pca_attackers, "Atacantes"),
  ncol = 2)




# 4.2. Ejecución K-Medias: Evaluación y creación de las particiones por puesto

eval_kmeans <- function(df_pca, n_clusters, pos){
  res_kmeans_pos <- eclust(df_pca, FUNcluster="kmeans", k = n_clusters, graph = F)
  avg_width <- round(res_kmeans_pos$silinfo$avg.width, 2)

  print(fviz_silhouette(res_kmeans_pos) +
    theme_classic() + labs(title = pos, 
                           subtitle = paste("Average Width: ", avg_width)) + 
    theme(plot.title = element_text(size = 17, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 14, face = "italic", hjust = 0.5),
          axis.text.x=element_blank(), 
          axis.ticks.x=element_blank()))
  
  res_kmeans_pos <- as.data.frame(res_kmeans_pos$silinfo$widths)
  res_kmeans_pos <- cbind(Player = rownames(res_kmeans_pos), res_kmeans_pos)
  rownames(res_kmeans_pos) <- 1:nrow(res_kmeans_pos)
  res_kmeans_pos <- res_kmeans_pos %>% rename(
    Cluster = cluster,
    Neighbor = neighbor,
    Sil_Score = sil_width)
  
  return(res_kmeans_pos)
} 

df_kmeans_keepers <- eval_kmeans(df_pca_keepers, 4, "Porteros")
df_kmeans_defenders <- eval_kmeans(df_pca_defenders, 4, "Defensas")
df_kmeans_midfilders <- eval_kmeans(df_pca_midfilders, 4, "Centrocampistas")
df_kmeans_attackers <-eval_kmeans(df_pca_attackers, 4, "Atacantes")



kbl(head(df_kmeans_keepers , 15),
align = c("l", "c", "c", "c")) %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(df_kmeans_defenders  , 15),
align = c("l", "c", "c", "c")) %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(df_kmeans_midfilders   , 15),
align = c("l", "c", "c", "c")) %>%
kable_classic(full_width = F,
latex_options=c("striped"))

kbl(head(df_kmeans_attackers , 15),
align = c("l", "c", "c", "c")) %>%
kable_classic(full_width = F,
latex_options=c("striped"))



# 4.4. Visualizar clusters

## Función para representar puntos jugadores y sus clusters sobre PC1 y PC2 del ACP
plot_clusters <- function(df_cluster, df_pca, pos){

  #df_pca_cluster <- cbind(df_cluster, subset(df_pca, select = c("PC1", "PC2")))
  
  df_pca <- cbind(Player = rownames(df_pca), df_pca)
  df_pca <- subset(df_pca, select=c("Player", "PC1", "PC2"))
  
  
  df_pca_cluster <- left_join(df_cluster, df_pca, by=c("Player"="Player"))
  
  set.seed(123)
  players_subset <- sample(df_pca_cluster$Player, 150, replace = FALSE)
  df_pca_cluster$show_label <- ifelse(df_pca_cluster$Player %in% players_subset, TRUE, FALSE)
  
  ggplot(df_pca_cluster, aes(x=PC1, y=PC2, color=as.character(Cluster))) +
    geom_point(size=1, alpha=0.5) +
    geom_text_repel(data=subset(df_pca_cluster, show_label), 
                    aes(label=Player, color=as.character(Cluster)), size=2, max.overlaps = 25) +
    labs(title = pos, color="Cluster") + 
    theme_minimal() +
    theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)) 
}

plot_clusters(df_kmeans_keepers, df_pca_keepers, "Porteros")
plot_clusters(df_kmeans_defenders, df_pca_defenders, "Defensores")
plot_clusters(df_kmeans_midfilders, df_pca_midfilders, "Centrocampistas")
plot_clusters(df_kmeans_attackers, df_pca_attackers, "Atacantes")


# 5. Algoritmos de simlitud con distancia euclídea y coseno


## Función normalizar los datos para convertir [0,1]
normalize <- function(x, na.rm = TRUE) {
  return((x- min(x)) /(max(x)-min(x)))}


similarity_algorithm <- function(df_pca, player, distance){
  # DISTANCIA COSENO
  if (distance %in% c("cosine", "Cosine", "coseno", "Coseno")){
  ## Transposición de la matriz
    df_pca_trans <- t(df_pca[, -c(1)])
    ## Similitud coseno
    sim_cosine <- cosine(df_pca_trans)
    ## Accedemos al jugador del análisis
    player_sim <- sim_cosine[, player]
    ## Convertir las distancias a porcentajes
    ## Normalizar los valores a una escala [0,1] - Min-Max
    df_player_sim <- as.data.frame(player_sim)
    colnames(df_player_sim) <- "Similarity"
    df_player_sim$Similarity <- normalize(df_player_sim$Similarity)
    ## Multiplicar por 100 para obtener una escala [0,100]
    df_player_sim$Similarity <- round(100*df_player_sim$Similarity, 3)
    ## Ordenamos por similitud
    df_player_sim <- cbind(Player_Comp = rownames(df_player_sim), 
                                 df_player_sim)
    final_df <- df_player_sim %>% arrange(desc(Similarity))
    ## Preparamos el DF resultante
    row.names(final_df) <- 1:nrow(final_df)
    return(final_df)
  }
  # DISTANCIA EUCLÍDEA
  if (distance %in% c("euclidean", "euclidiana", "Euclidean", "Euclidiana")){
    ## Distancia euclidiana: dist(method='euclidean')
    mat_dist <- as.matrix(dist(x = df_pca[, -c(1)], method = "euclidean"))
    ## Quedarse con el jugador de análisis y sus similitudes
    player_sim <- mat_dist[, player]
    df_player_sim <- as.data.frame(player_sim)
    colnames(df_player_sim) <- "Distance"
    df_player_sim <- cbind(Player_Comp = rownames(df_player_sim), 
                          df_player_sim)
    ## Convertimos las distancias en %
    d95 <- quantile(df_player_sim$Distance, 0.95) ## Percentil 95
    df_player_sim$Similarity <- (1 - (df_player_sim$Distance / d95))*100
    ## Ordenar y preparar DF resultante
    final_df <- df_player_sim %>% select(-Distance) %>%
      arrange(desc(Similarity))
    ## Preparamos el DF resultante
    row.names(final_df) <- 1:nrow(final_df)
    return(final_df)
  }
  else {
    cat("ERROR: No distance called:", distance)
  }
}


## Los algoritmos de similitud se basan en los resultados del PCA, por tanto...
## ... se necesita una columna con el nombre del jugador en el df del PCA
df_pca_keepers <- cbind(Player = rownames(df_pca_keepers), df_pca_keepers)
df_pca_defenders <- cbind(Player = rownames(df_pca_defenders), df_pca_defenders)
df_pca_midfilders <- cbind(Player = rownames(df_pca_midfilders), df_pca_midfilders)
df_pca_attackers<- cbind(Player = rownames(df_pca_attackers), df_pca_attackers)



## Vector con los nombres de los jugadores por puesto para hacer el bucle
keepers <- df_pca_keepers$Player
defenders <- df_pca_defenders$Player
midfilders <- df_pca_midfilders$Player
attackers <- df_pca_attackers$Player


## Crear una función que aplique uno de los dos algoritmos para cualquier puesto
dataset_similarity <- function(df_pca, players, similarity){
  
  df_player_sim <- data.frame()
  for (player in players){
    df_player_sim_temp <- similarity_algorithm(df_pca, player, similarity)
    df_player_sim_temp$Player <- player
    df_player_sim <- rbind(df_player_sim, df_player_sim_temp) %>%
      select(Player, Player_Comp, Similarity)
  }
  
  if (similarity  %in% c("cosine", "Cosine", "coseno", "Coseno")){
    df_player_sim <- df_player_sim %>% rename(Cos_Similarity = Similarity)
  }
  else{
    df_player_sim <- df_player_sim %>% rename(Euc_Similarity = Similarity)
  }
  
  return(df_player_sim)
}



## Similitud por distancia coseno para porteros
cos_sim_keepers <- dataset_similarity(df_pca_keepers, keepers, "cosine")
cos_sim_keepers


## Similitud por distancia euclidiana para porteros
eucl_sim_keepers <- dataset_similarity(df_pca_keepers, keepers, "euclidean")
eucl_sim_keepers



## Similitud por distancia coseno para defensas
cos_sim_defenders <- dataset_similarity(df_pca_defenders, defenders, "cosine")
cos_sim_defenders


# PARA MOSTRAR RESULTADOS EN MEMORIA DEL PFM
# kbl(head(eucl_sim_midfilders %>% filter(Player == "Ilkay.Gundogan") %>%
#            arrange(desc(Euc_Similarity)), 15),
# align = c("l", "c", "c", "c")) %>%
# kable_classic(full_width = F,
# latex_options=c("striped"))



## Similitud por distancia euclidiana para defensas
eucl_sim_defenders <- dataset_similarity(df_pca_defenders, defenders, "euclidean")
eucl_sim_defenders



## Similitud por distancia coseno para centrocampistas
cos_sim_midfilders <- dataset_similarity(df_pca_midfilders, midfilders, "cosine")
cos_sim_midfilders


## Similitud por distancia euclidiana para centrocampistas
eucl_sim_midfilders <- dataset_similarity(df_pca_midfilders, midfilders, "euclidean")
eucl_sim_midfilders



## Similitud por distancia coseno para atacantes
cos_sim_attackers <- dataset_similarity(df_pca_attackers, attackers, "cosine")
cos_sim_attackers



## Similitud por distancia euclidiana para atacantes
eucl_sim_attackers <- dataset_similarity(df_pca_attackers, attackers, "euclidean")
eucl_sim_attackers



# PARA MOSTRAR RESULTADOS EN MEMORIA DEL PFM
# kbl(head(cos_sim_attackers %>% filter(Player == "Karim.Benzema") %>%
#            arrange(desc(Cos_Similarity)), 15),
# align = c("l", "c", "c", "c")) %>%
# kable_classic(full_width = F,
# latex_options=c("striped"))



# 6. Caso de Uso (Aplicación)

df_general <- read.csv("Results/General_Dataset.csv", sep=",", encoding="UTF-8", check.names = F)
df_squad <- df_general %>% select(UrlFBref, Squad)



# Función para unir los scores de similitudes por puesto
join_sim_general_data <- function(df_pos, df_cluster, df_pca, df_eucl, df_cos){
  
  # Unir similitudes de PCA, Eucl, Coseno
  sims_df <- list(df_pca, df_eucl, df_cos) %>% 
    reduce(left_join, by=c("Player"="Player", "Player_Comp"="Player_Comp"))
  
  # Crear dataframe Url nombre jugador
  urls_df <- cbind(Player = rownames(df_pos), df_pos) %>% 
    select(Player, UrlFBref)
  
  # Añadir resultados cluster
  sims_df <- left_join(sims_df, df_cluster, by=c("Player_Comp"="Player"))
  
  # Añadir URLS al nombre del jugador objetivo para añadir el equipo luego
  df <- left_join(sims_df, urls_df, by=c("Player"="Player"))
  df <- left_join(df, df_squad, by=c("UrlFBref" = "UrlFBref"))
  
  # Eliminar la url del jugador objetivo
  df <- df %>% select(-UrlFBref)

  # Añadir url jugador a comparar
  df <- left_join(df, urls_df, by=c("Player_Comp"="Player"))
  
  # Reemplazar el punto y algunos nºs por un espacio en la columnas Players
  df$Player <- str_replace_all(df$Player, "[0-9.]", " ")
  df$Player_Comp <- str_replace_all(df$Player_Comp, "[0-9.]", " ")

  # Nomalizar valores de la distancia euclidiana y PCA y redondear
  df$Sil_Score <- round(df$Sil_Score, 3)
  df$PCA_Score <- round(normalize(as.numeric(df$PCA_Score)) * 100, 2)
  df$Euc_Similarity <- round(normalize(df$Euc_Similarity) * 100, 2)
  df$Cos_Similarity <- round(df$Cos_Similarity, 2)

  # Calcular Similarity Score como media de los tres algoritmos aplicados
  df$Sim_Score <- round((df$PCA_Score + df$Euc_Similarity + df$Cos_Similarity) / 3, 2)
  
  # Añadir a la columna Player el nombre del equipo entre parentesis
  df$Player <- paste(df$Player, paste0("(", df$Squad, ")"), sep = " ")
  
  # Eliminar columna equipo
  df <- df %>% select(-Squad)
  
  # Seleccionar orden de las columnas
  df <- df %>%
    select(UrlFBref, Player, Player_Comp, Sim_Score, PCA_Score,
           Euc_Similarity, Cos_Similarity, Cluster, Neighbor, Sil_Score)
  
  return(df)
}




# Preparar datset finales para la herramienta por puesto
final_keepers_df <- join_sim_general_data(
  df_keepers, 
  df_kmeans_keepers,
  sim_PCA_scores_keepers,
  eucl_sim_keepers,
  cos_sim_keepers)
final_keepers_df



final_defenders_df <- join_sim_general_data(
  df_defenders, 
  df_kmeans_defenders,
  sim_PCA_scores_defenders,
  eucl_sim_defenders,
  cos_sim_defenders)
final_defenders_df



### Ejemplo con datos de Sergio Ramos para la memoria
# kbl(head(final_defenders_df %>% filter(Player == "Sergio Ramos (Paris Saint-Germain)") %>%
#            arrange(desc(Sim_Score)), 10),
# align = c("l", "c", "c", "c")) %>%
# kable_classic(full_width = F,
# latex_options=c("striped"))



final_midfilders_df <- join_sim_general_data(
  df_midfilders, 
  df_kmeans_midfilders,
  sim_PCA_scores_midfilders,
  eucl_sim_midfilders,
  cos_sim_midfilders)
final_midfilders_df



final_attackers_df <- join_sim_general_data(
  df_attackers, 
  df_kmeans_attackers,
  sim_PCA_scores_attackers,
  eucl_sim_attackers,
  cos_sim_attackers)
final_attackers_df



# Guardarlos en formato csv para leerlo en Power BI
write.csv(final_keepers_df, paste0(PFM_DIR,'Results/Keepers_Final_Dataset.csv'), fileEncoding = 'UTF-8', row.names = FALSE)
write.csv(final_defenders_df, paste0(PFM_DIR,'Results/Defenders_Final_Dataset.csv'), fileEncoding = 'UTF-8', row.names = FALSE)
write.csv(final_midfilders_df, paste0(PFM_DIR,'Results/Midfilders_Final_Dataset.csv'), fileEncoding = 'UTF-8', row.names = FALSE)
write.csv(final_attackers_df, paste0(PFM_DIR,'Results/Attackers_Final_Dataset.csv'), fileEncoding = 'UTF-8', row.names = FALSE)