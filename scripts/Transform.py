# Importar librerías
import warnings; warnings.filterwarnings('ignore')
import os
import pandas as pd
import numpy as np


# Obtener el directorio principal del proyecto
ROOT_DIR = os.path.abspath(os.curdir)
ROOT_DIR = ROOT_DIR.split('\\')
PFM_DIR = ''
for s in ROOT_DIR:
    PFM_DIR += s + '/'
    if 'PFM' in s:
        break


# Leer archivo excels sobre columnas a seleccionar o a calcular
definitve_columns_df = pd.read_excel(f"{PFM_DIR}Documents/PFM Columns.xlsx", sheet_name="Definitive Ones")
to_select_columns_df = pd.read_excel(f"{PFM_DIR}Documents/PFM Columns.xlsx", sheet_name="To Select")
to_calculate_columns_df = pd.read_excel(f"{PFM_DIR}Documents/PFM Columns.xlsx", sheet_name="To Calculate")
position_columns_df = pd.read_excel(f"{PFM_DIR}Documents/PFM Columns.xlsx", sheet_name="Position Columns")


# Obtener una lista con los nombres de los archivos csv a leer
files_list = list()
with os.scandir(f'{PFM_DIR}Data/') as files:
    for file in files:
        if 'market' in file.name or 'standard' in file.name or 'map' in file.name:
            pass
        else:
            files_list.append(file.name)

# ['player_defense.csv', 'player_gca.csv', 'player_keepers.csv', 'player_keepers_adv.csv', 'player_misc.csv', 
# 'player_passing.csv', 'player_pass_types.csv', 'player_possession.csv', 'player_shooting.csv']


# Lista con los tipos de columnas de FBref
types_list = [
    'Defense','GCA','Keeper','Keeper Advanced',
    'Miscellaneous','Passing','Pass Types','Possession','Shooting'
    ]


# Función para seleccionar y renombrar las columnas necesarias de cada archivo de datos
def selectRenameData(file_name, type):

    try:
        df = pd.read_csv(f"{PFM_DIR}Data/{file_name}")
    except:
        df = pd.read_csv(f"{PFM_DIR}Data/{file_name}", encoding='latin-1')
    
    if type == 'Mapping' or type == 'Transfermarkt':
        df = df[to_select_columns_df[to_select_columns_df['Type']==type]['worldfootballR'].unique().tolist()]
        df.columns = to_select_columns_df[to_select_columns_df['Type']==type]['PFM'].unique().tolist()
    else:
        df = df[to_select_columns_df[to_select_columns_df['Type'].isin(['General', type])]['worldfootballR'].unique().tolist()]
        df.columns = to_select_columns_df[to_select_columns_df['Type'].isin(['General', type])]['PFM'].unique().tolist()
    
    return df      


# Añadir datos de transfermarkt a los datos standard de FBref
actual_df = selectRenameData(file_name='player_standard.csv', type='Standard')
mapping_df = selectRenameData(file_name='fbref_trmarkt_map.csv', type='Mapping')
trfmarkt_df = selectRenameData(file_name='full_market_values.csv', type='Transfermarkt')


## Existen jugadores que tienen el nombre distinto en la Url de Trfmarkt en su propia tabla y  en la del mapping ...
## ... para ello se decide crear un ID ya que continúa siendo el mismo en la URL de ambas tablas ...
## ... ejemplo de ello es Federico Valverde ... 
## ... En mapping es https://www.transfermarkt.com/fede-valverde/profil/spieler/369081
## ... y en la de transfermark aparece https://www.transfermarkt.com/federico-valverde/profil/spieler/369081
mapping_df[['UrlTmarkt_ID']] = mapping_df['UrlTmarkt'].str.split("/", expand=True)[[6]]
trfmarkt_df[['UrlTmarkt_ID']] = trfmarkt_df['UrlTmarkt'].str.split("/", expand=True)[[6]]


# Unir el mapping a las estadísticas standard de los jugadores para después unir los datos de Transfermarkt
actual_df = pd.merge(actual_df, mapping_df, on='UrlFBref', how='left')
actual_df = pd.merge(actual_df, trfmarkt_df, on='UrlTmarkt', how='left')

# Añadir datos de transfermarkt para aquellos jugadores con urls distintas en la tabla de mapeo y en la propia
actual_df = pd.merge(actual_df, trfmarkt_df, left_on='UrlTmarkt_ID_x', right_on='UrlTmarkt_ID', how='left')

for trfmarkt_col in to_select_columns_df[to_select_columns_df['Type'] == 'Transfermarkt']['PFM'].unique().tolist():
    actual_df.loc[actual_df[f'{trfmarkt_col}_x'].isnull(), f'{trfmarkt_col}_x'] = actual_df[f'{trfmarkt_col}_y']
    actual_df = actual_df.drop(f'{trfmarkt_col}_y', axis=1)
    actual_df = actual_df.rename(columns={f'{trfmarkt_col}_x':trfmarkt_col})

actual_df = actual_df.drop(['UrlTmarkt', 'UrlTmarkt_ID_x', 'UrlTmarkt_ID_y', 'UrlTmarkt_ID'], axis=1)



# Unir las estadísticas de los jugadores de FBref con el dataset original creado anteriormente, renombrando nombres de columnas
for file_name, type in zip(files_list, types_list):

    df_temp = pd.read_csv(f"{PFM_DIR}Data/{file_name}")
    df_temp = df_temp[to_select_columns_df[to_select_columns_df['Type'].isin(['General', type])]['worldfootballR'].unique().tolist()]
    df_temp.columns = to_select_columns_df[to_select_columns_df['Type'].isin(['General', type])]['PFM'].unique().tolist()

    actual_df = pd.merge(actual_df, df_temp, on=to_select_columns_df[to_select_columns_df['Type'].isin(['General'])]['PFM'].tolist(), how='left')


# Filtrar todos aquellos jugadores que no han disputado minutos en la temporada con su respectivo club
actual_df = actual_df[actual_df['Minutes'].notnull()]


# Cuando hay valores faltantes en MP están en MP2
actual_df.loc[actual_df['MP'].isnull(), 'MP'] = actual_df['MP2']


# Calcular pases compelatados por el portero y saques de puerta para calcular posteriormente su % por jugador individual
actual_df['Cmp_Pass_Keeper'] = ((actual_df['Launch_percent_Passes_Keeper'] / 100) * actual_df['Att_Passes_Keeper']).round(0)
actual_df['Cmp_Goal_Kicks_Keeper'] = ((actual_df['Launch_percent_Goal_Kicks_Keeper'] / 100) * actual_df['Att_Goal_Kicks_Keeper']).round(0)


# Seleccionar las columnas de las estadísticas cuantitativas de cada jugador de FBref y ...
# ... agrupar por la URL sumando está para tener el total de cada jugador individualmente
fbref_stats_cols = to_select_columns_df[to_select_columns_df['Type'].isin(['Standard'] + types_list)]['PFM'].tolist()
temp_actual_df = actual_df[['UrlFBref'] + fbref_stats_cols + ['Cmp_Pass_Keeper', 'Cmp_Goal_Kicks_Keeper']]
grouped_stats_df = temp_actual_df.groupby(['UrlFBref']).sum().reset_index()


# Crear una columna 'Count' que cuente las veces que un jugador aperece por la URL, para calcular aquellas metricas que son la media 'Avg'
count_fbref_url = pd.DataFrame(actual_df['UrlFBref'].value_counts().reset_index()).rename(columns={'index':'UrlFBref', 'UrlFBref':'Count'})
grouped_stats_df = pd.merge(grouped_stats_df, count_fbref_url, on = 'UrlFBref', how = 'left')


# Calcular columnas para valores agregados por jugador único
grouped_stats_df['Min/90'] = (grouped_stats_df['Minutes'] / 90).round(2)
grouped_stats_df['Gls/90'] = (grouped_stats_df['Gls'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['Ast/90'] = (grouped_stats_df['Ast'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['G+A/90'] = (grouped_stats_df['G+A'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['G-PK/90'] = (grouped_stats_df['G-PK'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['G+A-PK'] = grouped_stats_df['G+A'] - grouped_stats_df['PK'] 
grouped_stats_df['G+A-PK/90'] = (grouped_stats_df['G+A-PK'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['xG/90'] = (grouped_stats_df['xG'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['xAG/90'] = (grouped_stats_df['xAG'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['xG+xAG'] = grouped_stats_df['xG'] + grouped_stats_df['xAG']
grouped_stats_df['xG+xAG/90'] = (grouped_stats_df['xG+xAG'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['npxG/90'] = (grouped_stats_df['npxG'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['npxG+xAG/90'] = (grouped_stats_df['npxG+xAG'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['SoT%'] = ((grouped_stats_df['SoT'] / grouped_stats_df['Sh']) * 100).round(2)
grouped_stats_df['Sh/90'] = (grouped_stats_df['Sh'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['SoT/90'] = (grouped_stats_df['SoT'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['G/Sh'] = (grouped_stats_df['Gls'] / grouped_stats_df['Sh']).round(2)
grouped_stats_df['G/SoT'] = (grouped_stats_df['Gls'] / grouped_stats_df['SoT']).round(2)
grouped_stats_df['npxG/Sh'] = (grouped_stats_df['npxG'] / grouped_stats_df['Sh']).round(2)
grouped_stats_df['Succ%_Take_Ons'] = ((grouped_stats_df['Succ_Take_Ons'] / grouped_stats_df['Att_Take_Ons']) * 100).round(2)
grouped_stats_df['Tkld%_Take_Ons'] = ((grouped_stats_df['Tkld_Take_Ons'] / grouped_stats_df['Att_Take_Ons']) * 100).round(2)
grouped_stats_df['Cmp%_Pass'] = ((grouped_stats_df['Cmp_Pass'] / grouped_stats_df['Att_Pass']) * 100).round(2)
grouped_stats_df['Cmp%_Short_Pass'] = ((grouped_stats_df['Cmp_Short_Pass'] / grouped_stats_df['Att_Short_Pass']) * 100).round(2)
grouped_stats_df['Cmp%_Medium_Pass'] = ((grouped_stats_df['Cmp_Medium_Pass'] / grouped_stats_df['Att_Medium_Pass']) * 100).round(2)
grouped_stats_df['Cmp%_Long_Pass'] = ((grouped_stats_df['Cmp_Long_Pass'] / grouped_stats_df['Att_Long_Pass']) * 100).round(2)
grouped_stats_df['Tkl%_Challenges'] = ((grouped_stats_df['Tkl_Challenges'] / grouped_stats_df['Att_Challenges']) * 100).round(2)
grouped_stats_df['SCA/90'] = (grouped_stats_df['SCA'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['GCA/90'] = (grouped_stats_df['GCA'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['GA/90_Keeper'] = (grouped_stats_df['GA_Keeper'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['Saves%_Keeper'] = (((grouped_stats_df['SoTA_Keeper'] - grouped_stats_df['GA_Keeper']) / grouped_stats_df['SoTA_Keeper']) * 100).round(2)
grouped_stats_df['CleanSheets%_Keeper'] = ((grouped_stats_df['CleanSheets_Keeper'] / grouped_stats_df['MP']) * 100).round(2)
grouped_stats_df['Pksaved%_Keeper'] = ((grouped_stats_df['Pksaved_Keeper'] / grouped_stats_df['PKatt_Keeper']) * 100).round(2)
grouped_stats_df['PSxG/SoT_Keeper'] = (grouped_stats_df['PSxG_Keeper'] / grouped_stats_df['SoTA_Keeper']).round(2)
grouped_stats_df['PSxG-GA/90_Keeper'] = (grouped_stats_df['PSxG-GA_Keeper'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['Cmp%_Launched_Keeper'] = ((grouped_stats_df['Cmp_Launched_Keeper'] / grouped_stats_df['Att_Launched_Keeper']) * 100).round(2)
grouped_stats_df['Stp%_Crosses_Keeper'] = ((grouped_stats_df['Stp_Crosses_Keeper'] / grouped_stats_df['Opp_Crosses_Keeper']) * 100).round(2)
grouped_stats_df['NumOPA/90_Sweeper_Keeper'] = (grouped_stats_df['NumOPA_Sweeper_Keeper'] / grouped_stats_df['Min/90']).round(2)
grouped_stats_df['Won%_Aerial_Duels'] = ((grouped_stats_df['Won_Aerial_Duels'] / (grouped_stats_df['Won_Aerial_Duels'] + grouped_stats_df['Lost_Aerial_Duels'])) * 100).round(2)
grouped_stats_df['Launch_percent_Passes_Keeper'] = ((grouped_stats_df['Cmp_Pass_Keeper'] / grouped_stats_df['Att_Passes_Keeper']) * 100).round(2)
grouped_stats_df['Launch_percent_Goal_Kicks_Keeper'] = ((grouped_stats_df['Cmp_Goal_Kicks_Keeper'] / grouped_stats_df['Att_Goal_Kicks_Keeper']) * 100).round(2)

## Valores medios para los porteros
grouped_stats_df['AvgLen_Passes_Keeper'] = (grouped_stats_df['AvgLen_Passes_Keeper'] / grouped_stats_df['Count']).round(2)
grouped_stats_df['AvgDist_Sweeper_Keeper'] = (grouped_stats_df['AvgDist_Sweeper_Keeper'] / grouped_stats_df['Count']).round(2)
grouped_stats_df['AvgLen_Goal_Kicks_Keeper'] = (grouped_stats_df['AvgLen_Goal_Kicks_Keeper'] / grouped_stats_df['Count']).round(2)


# Existen algunos jugadores que han marcado gol sin disparar a puerta, se entiende que es por un rebote o rechace...
# ... por tanto el resultado de la variable G/SoT es Inf, dado que no han disparado a puerta se considera que el valor ...
# ... para esta debe ser 0.
grouped_stats_df.loc[grouped_stats_df['G/SoT'] == np.inf, 'G/SoT'] = 0


# Filtrar jugadores duplicados por cambio de club en la temporada
## Seleccionar columnas necesarias en dataset a filtrar (actual_df)
actual_df = actual_df[to_select_columns_df[to_select_columns_df['Type'].isin(['General', 'Transfermarkt'])]['PFM'].tolist()[:-1] + ['MP', 'Minutes']]
actual_df = actual_df.sort_values(['Minutes'], ascending=[True])
actual_df = actual_df.drop_duplicates(['UrlFBref'], keep='first')
actual_df = actual_df.drop(['MP', 'Minutes'], axis=1)
actual_df = pd.merge(actual_df, grouped_stats_df, on = 'UrlFBref', how = 'inner')


# Seleccionar solo los años del jugador en la edad
actual_df[['Age', 'Days']] = actual_df['Age'].str.split('-', expand=True)
actual_df = actual_df.drop('Days', axis=1)


# Obtener lista con columnas definitivas
definitve_columns_list = definitve_columns_df['PFM'].unique().tolist()


# Seleccionar columnas definitivas para el dataset
actual_df = actual_df[definitve_columns_list]


# Cambiar Nombre a esas dos variables de los porteros calculadas anteriormente
actual_df = actual_df.rename(columns={
    'Launch_percent_Passes_Keeper': 'Launch%_Passes_Keeper',
    'Launch_percent_Goal_Kicks_Keeper': 'Launch%_Goal_Kicks_Keeper'
    })



# Corregir errores de temporada y nombres de equipo y liga para la Série A de Brasil y la MLS de EEUU
usa_brasil_teams = actual_df[actual_df['Squad'].str.contains('2022 ')]
usa_brasil_teams[['Year', 'Squad_Name']] = usa_brasil_teams['Squad'].str.split(' ', 1, expand=True)
usa_brasil_teams.loc[usa_brasil_teams['Season'].isnull(), 'Season'] = '2021-2022'
usa_brasil_teams.loc[usa_brasil_teams['Squad'].str.contains('2022 '), 'Squad'] = usa_brasil_teams['Squad_Name']


brasil_serie_a_teams = [
    'Goiás', 'Atlético Goianiense', 'Juventude', 'Flamengo', 'Atlético Paranaense',
    'Palmeiras', 'Botafogo (RJ)', 'Corinthians', 'Avaí', 'Coritiba', 'Cuiabá',
    'Ceará', 'Internacional','América (MG)','Atlético Mineiro','Santos',
    'São Paulo', 'Bragantino', 'Fortaleza',  'Fluminense']

mls_teams = [ 
     'New England Revolution','Chicago Fire','Orlando City','Vancouver Whitecaps FC',
     'Philadelphia Union','D.C. United','Portland Timbers','Real Salt Lake','Inter Miami',
     'LA Galaxy','New York City FC','Nashville SC','Toronto FC','FC Dallas','Minnesota United',
     'Sporting KC','Houston Dynamo','FC Cincinnati','Colorado Rapids','Charlotte FC',
     'Los Angeles FC','New York Red Bulls','San Jose Earthquakes','Atlanta United',
     'Seattle Sounders FC','Austin FC','Columbus Crew','CF Montréal']


# Corregir errores de nombres de liga para equipos de la Série A de Brasil y MLS
for team in brasil_serie_a_teams:
    usa_brasil_teams.loc[usa_brasil_teams['Squad'] == team, 'Comp'] = 'Série A'
for team in mls_teams:
    usa_brasil_teams.loc[usa_brasil_teams['Squad'] == team, 'Comp'] = 'MLS'

usa_brasil_teams = usa_brasil_teams.drop(['Year', 'Squad_Name'], axis=1)


# Elimnar liga brasileña del dataset para concatenar los cambios hechos 
actual_df = actual_df[~actual_df['Squad'].str.contains('2022 ')]
actual_df = pd.concat([actual_df, usa_brasil_teams], axis=0)


# Equipos sin liga
eredivisie_list = [
    'Heerenveen', 'Go Ahead Eagles', 'Excelsior', 
    'Sparta Rotterdam', 'Vitesse', 'Utrecht',  'RKC Waalwijk', 
    'Volendam', 'Cambuur', 'Groningen', 'NEC Nijmegen',
     'Fortuna Sittard', 'Emmen']
primeira_list = [
    'Portimonense', 'Marítimo', 'Paços de Ferreira', 'Famalicão', 
    'Vizela', 'Chaves', 'Estoril', 'Boavista', 'Arouca', 'Casa Pia',
    'Santa Clara', 'Rio Ave']
liga_mx_list = [
    'Monterrey', 'Toluca', 'León','UNAM', 'Necaxa', 
    'Tijuana', 'América', 'Atlético', 'Santos Laguna',
    'Cruz Azul', 'Atlas', 'Querétaro', 'Mazatlán',
    'Guadalajara', 'Puebla', 'FC Juárez', 'Pachuca', 'UANL']


# Añadir la liga que es a cada equipo sin liga
for squad in eredivisie_list:
    actual_df.loc[actual_df['Squad'] == squad, 'Comp'] = 'Eredivisie'

for squad in primeira_list:
    actual_df.loc[actual_df['Squad'] == squad, 'Comp'] = 'Primeira Liga'

for squad in liga_mx_list:
    actual_df.loc[actual_df['Squad'] == squad, 'Comp'] = 'Liga MX'


# Ordenar dataset y reindexar para guardar
actual_df = actual_df.sort_values(['Comp', 'Squad'], ascending=[True, True])
actual_df = actual_df.reset_index(drop=True)


# Para las estadísticas de los jugadores rellenar valores nulos con ceros porque aperece debido a que divide 0.0/0.0
actual_df[actual_df.columns.tolist()[15:]] = actual_df[actual_df.columns.tolist()[15:]].fillna(0)


# Transformar la edad a entero
actual_df['Age'] = actual_df['Age'].astype(float)


# Eliminar valores nulos en equipo y competición transfermarkt
actual_df = actual_df[~actual_df["Comp_TM"].isnull()]
actual_df = actual_df[~actual_df["Squad_TM"].isnull()]


# Filtrar jugadores con más de 30% de los partidos disputados por competición
week_comp_df = actual_df.groupby('Comp_TM')['Minutes'].max().reset_index()
week_comp_df['1/3 Total Season Mins'] = 0.3 * week_comp_df['Minutes']
week_comp_df = week_comp_df.drop('Minutes', axis=1)

actual_df = pd.merge(actual_df, week_comp_df, on='Comp_TM', how='left')

actual_df = actual_df[actual_df['Minutes'] >= actual_df['1/3 Total Season Mins']]
actual_df = actual_df.drop('1/3 Total Season Mins', axis=1)


# Eliminar equipos y competiciones FBref
actual_df = actual_df.drop(["Squad", "Comp"], axis=1)

# Renombrar los de transfermarkt
actual_df = actual_df.rename(columns={"Squad_TM": "Squad", "Comp_TM": "Comp"})


# Renombrar ligas
for old_name, new_name in [("Major League Soccer", "MLS"),
                            ("LaLiga", "La Liga"),
                            ("Liga Portugal", "Primeira Liga"),
                            ("Liga MX Clausura", "Liga MX"),
                            ("Campeonato Brasileiro Série A", "Série A")]:
    actual_df.loc[actual_df["Comp"] == old_name, "Comp"] = new_name


# Para saber el nº de jugadores por equipo que quedan
team_players = actual_df['Squad'].value_counts().reset_index()


# Tipo de columna, valores nulos y descripción estadistica de las numericas
#col_types_df = actual_df.dtypes.reset_index()
#null_values_df = pd.DataFrame(actual_df.isnull().sum())
#describe_actual_df = actual_df.describe().T


# Guardar el df principal en la carpeta Results
actual_df.to_csv(f'{PFM_DIR}Results/PFM_Dataset.csv', index=False)


# Crear dataframes principales por columnas de información general y tipo de posición
## Función para crear los dataframes y guardarlos en formato csv en la carpeta Results
def datasetType(df=actual_df, type=list(), pos=list(), name=str()):

    cols_list = position_columns_df[position_columns_df['Column Dataset'].isin(['ID', 'FILTER'] + type)]['PFM'].tolist()

    if 'GENERAL' in type and len(type):
        filtered_df = df[cols_list]
    else:
        filtered_df = df[df['Pos'].isin(pos)][cols_list]

    filtered_df.to_csv(f'{PFM_DIR}Results/{name}_Dataset.csv', index=False)

    return filtered_df


## Tabla para columnas de carácter general
general_df = datasetType(type=['GENERAL'], name='General')


## Tabla para los porteros
keepers_df = datasetType(
    type=['ALL', 'GK', 'GK,DF'], 
    pos=['GK'], 
    name='Keepers')



## Tabla para los defensores
defenders_df = datasetType(
    type=['ALL','DF','DF,MF','DF,MF,FW','GK,DF'], 
    pos=['DF', 'DF,MF', 'MF,DF', 'DF,FW','FW,DF'], 
    name='Defenders')



## Tabla para los centrocampistas
midfilders_df = datasetType(
    type=['ALL','DF,MF','DF,MF,FW', 'MF,FW'], 
    pos=['MF','FW,MF','MF,FW','DF,MF','MF,DF'], 
    name='Midfilders')



## Tabla para los delanteros
attackers_df = datasetType(
    type=['ALL','DF,MF,FW','FW','MF,FW'], 
    pos=['FW','FW,MF','MF,FW','DF,FW','FW,DF'], 
    name='Attackers')