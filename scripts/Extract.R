# EXTRACCIÓN DE LOS DATOS

# Abrir librerías
suppressPackageStartupMessages(library(worldfootballR))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(stringi))
suppressPackageStartupMessages(library(data.table))


# Extraer la ruta principal del PFM
PATH_DIR <- getwd()
PATH_DIR <- strsplit(PATH_DIR, '/')
PFM_DIR <- ""

for (c in PATH_DIR[[1]]){
  
  PFM_DIR <- paste0(PFM_DIR,c,'/')
  
  if (c == 'PFM') break
}


# Crear vector con las urls de FBref de las ligas
leagues_urls <- c(
  "https://fbref.com/en/comps/11/Serie-A-Stats",
  "https://fbref.com/en/comps/9/Premier-League-Stats",
  "https://fbref.com/en/comps/12/La-Liga-Stats",
  "https://fbref.com/en/comps/13/Ligue-1-Stats",
  "https://fbref.com/en/comps/20/Bundesliga-Stats",
  "https://fbref.com/en/comps/10/Championship-Stats",
  "https://fbref.com/en/comps/23/Eredivisie-Stats",
  "https://fbref.com/en/comps/32/Primeira-Liga-Stats",
  "https://fbref.com/en/comps/31/Liga-MX-Stats",
  "https://fbref.com/en/comps/24/2022/2022-Serie-A-Stats",
  "https://fbref.com/en/comps/22/2022/2022-Major-League-Soccer-Stats")


# https://fbref.com/en/comps/24/Serie-A-Stats



# Crear una función para extraer la estadísticas de los jugadores por tipo
getPlayerStats <- function (type) {

  player_df <- data.frame()

  for (league_url in leagues_urls){

    print(league_url)

    teams <- fb_teams_urls(league_url)


    if (league_url %in% c("https://fbref.com/en/comps/32/Primeira-Liga-Stats",
                          "https://fbref.com/en/comps/20/Bundesliga-Stats",
                          "https://fbref.com/en/comps/23/Eredivisie-Stats")){
      teams <- subset(teams, !teams %in% c("https://fbref.com/en/squads/0cb9f756/2022-2023/Estrela-Stats",
                                           "https://fbref.com/en/squads/26790c6a/Hamburger-SV-Stats",
                                           "https://fbref.com/en/squads/2b41acb5/Almere-City-Stats",
                                           "https://fbref.com/en/squads/534ac6d0/VVV-Venlo-Stats",
                                           "https://fbref.com/en/squads/8ed04be8/NAC-Breda-Stats"))

      print(teams)

    }

    temp_stat <- fb_team_player_stats(team_urls=teams, stat_type=type)

    player_df <- rbindlist(list(player_df, temp_stat),  fill = TRUE)

  }

  return(player_df)
}



# Extraer estadísticas standard para las diferentes competiciones
player_standard <- getPlayerStats(type = "standard")
write.csv(player_standard, paste0(PFM_DIR,'data/raw/raw/player_standard.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas de disparo para las diferentes competiciones
player_shooting <- getPlayerStats(type = "shooting")
write.csv(player_shooting, paste0(PFM_DIR,'data/raw/player_shooting.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas de pase para las diferentes competiciones
player_passing <- getPlayerStats(type = "passing")
write.csv(player_passing, paste0(PFM_DIR,'data/raw/player_passing.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas de tipos de pases para las diferentes competiciones
player_pass_types <- getPlayerStats(type = "passing_types")
write.csv(player_pass_types, paste0(PFM_DIR,'data/raw/player_pass_types.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas de acciones ofensivas para las diferentes competiciones
player_gca <- getPlayerStats(type = "gca")
write.csv(player_gca, paste0(PFM_DIR,'data/raw/player_gca.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas de defensa para las diferentes competiciones
player_defense <- getPlayerStats(type = "defense")
write.csv(player_defense, paste0(PFM_DIR,'data/raw/player_defense.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas de posesión para las diferentes competiciones
player_possession <- getPlayerStats(type = "possession")
write.csv(player_possession, paste0(PFM_DIR,'data/raw/player_possession.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas misceláneas para las diferentes competiciones
player_misc <- getPlayerStats(type = "misc")
write.csv(player_misc, paste0(PFM_DIR,'data/raw/player_misc.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# # Extraer estadísticas de porteros para las diferentes competiciones
player_keepers <- getPlayerStats(type = "keeper")
write.csv(player_keepers, paste0(PFM_DIR,'data/raw/player_keepers.csv'), fileEncoding = 'UTF-8', row.names = FALSE)


# Extraer estadísticas avanzadas de porteros para las diferentes competiciones
player_keepers_adv <- getPlayerStats(type = "keeper_adv")
write.csv(player_keepers_adv, paste0(PFM_DIR,'data/raw/player_keepers_adv.csv'), fileEncoding = 'UTF-8', row.names = FALSE)



# Extraer datos de los valores de mercado de Transfermarkt
market_values <- data.frame()

for (url in c(
  'https://www.transfermarkt.com/premier-league/startseite/wettbewerb/GB1',
  'https://www.transfermarkt.com/ligue-1/startseite/wettbewerb/FR1',
  'https://www.transfermarkt.com/bundesliga/startseite/wettbewerb/L1',
  'https://www.transfermarkt.com/serie-a/startseite/wettbewerb/IT1',
  'https://www.transfermarkt.com/laliga/startseite/wettbewerb/ES1',
  'https://www.transfermarkt.com/eredivisie/startseite/wettbewerb/NL1',
  'https://www.transfermarkt.com/liga-portugal/startseite/wettbewerb/PO1',
  'https://www.transfermarkt.com/championship/startseite/wettbewerb/GB2',
  'https://www.transfermarkt.com/campeonato-brasileiro-serie-a/startseite/wettbewerb/BRA1',
  'https://www.transfermarkt.com/liga-mx-clausura/startseite/wettbewerb/MEX1',
  'https://www.transfermarkt.com/major-league-soccer/startseite/wettbewerb/MLS1')){
  
  temp_df <- tm_player_market_values(
    league_url = url,
    start_year = 2022) 
  
  market_values <- rbind(market_values, temp_df)
  
  print(url)
  
}

write.csv(market_values, paste0(PFM_DIR,'data/raw/full_market_values.csv'), row.names = FALSE)


# Extraer el archivo de mapeo de FBref y Transfermark dado por worldfootballR
fbref_tfmarkt_map <- player_dictionary_mapping()
write.csv(fbref_tfmarkt_map, paste0(PFM_DIR,'data/raw/fbref_trmarkt_map.csv'), row.names = FALSE)
