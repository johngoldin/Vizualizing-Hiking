# to get react log:     
# options(shiny.reactlog=TRUE) 

# error message:
# path[1]="/Library/Frameworks/R.framework/Versions/3.2/Resources/library/leaflet/htmlwidgets/lib/leaflet-providers": No such file or directory

# based on: https://rstudio.github.io/leaflet/shiny.html
library(shiny)
library(shinydashboard)
library(leaflet)
library(leaflet.providers)
#library("rgdal")
library("lubridate")
library("plyr")
library("dplyr")
#library("ggplot2")
library("stringr")
library("purrr")
#library("RColorBrewer")
#library("httr")
#library("jsonlite")

# when you publish, need to include these files, as well as trace and photo info for trips.RData
source("add_trips_to_map.R")
source("photoIcon.R")

# Other files that may be needed:
#  www stuff
#  stuff.jpg in www folder contains the heading image (of SW Coast)
#  trace and photo infor trips.RData
# 
# search for "Focus on trip" and specify which trip should come up by default

########################################################################################################################
#
# IMPORTANT!
# code in collect_gps_data_for_maps.Rmd is used to create these datasets. You must run it if you have
# changed the map data.
#save(trips_df, trips_list, trip_photos_df, other_photos_df, colors_list, file = "trace and photo info for trips.RData")
#
# Also important, if you make changes to the base maps,
# need to run:  file.remove("saved_map.RData") 
# Otherwise, won't see changes.
#

print("Loading trace and photo info")
print(system.time(load("trace and photo info for trips.RData")))
print("Starting...")
if (file.exists("saved_map.RData")) {
  print("Loading map from file. If problems, delete saved_map.RData.")
  print(system.time(load("saved_map.RData")))
  print("saved_map.RData was loaded.")
} else {
  print("Adding traces")
  # add a map here
  italy_map <- add_trips_to_map(NULL, trips_list, colors_list, pick_area = (trips_df$area == "Italy"))
  usa_map <- add_trips_to_map(NULL, trips_list, colors_list, pick_area = (trips_df$area == "USA"))
  england_map <- add_trips_to_map(NULL, trips_list, colors_list, pick_area = (trips_df$area == "England"))
  spain_map <- add_trips_to_map(NULL, trips_list, colors_list, pick_area = (trips_df$area == "Spain"))
  greece_map <- add_trips_to_map(NULL, trips_list, colors_list, pick_area = (trips_df$area == "Greece"))
  # add a map here
  usa_map <- add_photos_to_map(all_photos_df, usa_map, select_area = "USA")
  england_map <- add_photos_to_map(all_photos_df, england_map, select_area = "England")
  spain_map <- add_photos_to_map(all_photos_df, spain_map, select_area = "Spain")
  italy_map <- add_photos_to_map(all_photos_df, italy_map, select_area = "Italy")
  greece_map <- add_photos_to_map(all_photos_df, greece_map, select_area = "Greece")
  
  save(usa_map, england_map, spain_map,  italy_map,  greece_map, file = "saved_map.RData")     # add a map here
  # Use Command-Enter to execute this one bit to delte the saved_map.RData file
  # file.remove("saved_map.RData")       
}

# at this point, we need to add providers to each of these maps
# I rejiggered things because saved_map data didn't successfully save the providers with the map.
usa_map <- addMyProviders(usa_map)
england_map <- addMyProviders(england_map)
spain_map <- addMyProviders(spain_map)
italy_map <- addMyProviders(italy_map)
greece_map <- addMyProviders(greece_map)

# the_map <- add_trips_to_map(NULL, trips_list, colors_list)
# the_map <- add_photos_to_map(all_photos_df, the_map)

# hmmm, I wonder whether map_choices or map_area have any effect here. I don't think so. See collect_gps_data_for_maps.R
map_choices <- c("Pennine Way north", "Pennine Way south", "Coast to Coast",
                 "Grand Canyon", "Tucson", "Phoenix", "Bryce Canyon", "Florida", "California", "Texas", "South West Coast Path",
                 "Wales", "Costswolds", "Andorra", "Pyrenees", "Madrid", "Cabo de Gata", "Amalfi Coast", "Rome", "Greece", "Two Moors Way")
# add a map area here:
map_area <- c("England", "England", "England", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "England", "England", "England",
              "Spain", "Spain", "Spain", "Spain", "Italy", "Italy", "Greece", "England")
# add a map area here:
default_area <- c("USA" = "California 2020", "England" = "Cleveland Way 2019", 
                  "Spain" = "Pyrenees 2014", "Italy" = "Amalfi Coast 2016", "Greece" = "Greece 2018")


ui <- function(request) {
  dashboardPage(
    dashboardHeader(title = "Souvenirs of My Walks"),
    dashboardSidebar(
      selectInput("which_area", "Select map area:", unique(map_area), selected = "England"),
      selectInput("which_trip", "Focus on trip:",
                  paste(trips_df$trip[trips_df$area == "England"], trips_df$year[trips_df$area == "USA"]),
                  selected = "Pennine Way south 2013"),
      actionButton("focusButton", strong("Re-focus Map")),
      bookmarkButton()
    ),
    
    dashboardBody(
      # for centering image: https://github.com/rstudio/shiny/issues/555
      div(img(src = "stuff.jpg", height = 608 / 4, width = 2035 / 4), style = "text-align: center;"),
      # from https://stackoverflow.com/questions/54711365/shinydashboard-increase-size-of-dashboard-page
      # tags$head(tags$style(
      #   HTML('.wrapper {height: auto !important; position:relative; overflow-x:hidden; overflow-y:hidden}'))),
      
      # tags$style(type = "text/css", "#map {height: calc(100vh - ,) !important;}"),
      #
      #       height = .5, collapsible = TRUE),#, height = "95vh"
      # from https://stackoverflow.com/questions/36469631/how-to-get-leaflet-for-r-use-100-of-shiny-dashboard-height
      tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),
      fluidRow("     Click on photo icon to see photo and then click on the photo to open a new tab showing the photo in Flickr. For notes, click",
               a("here", href="https://johngoldin.github.io/2016/06/28/technical-note--shiny-souvenir-map-of-walks/", target="_blank"), "."),
      # https://stackoverflow.com/a/36471739/5828243
      leafletOutput("mymap", height = "80vh")
    )
  )
}

server <- function(input, output, session) {
  r_colors <- rgb(t(col2rgb(colors()) / 255))
  names(r_colors) <- colors()

  get_map_data <- reactive({
    print(paste("In get_map_data", input$which_area))
    if (input$which_area == "England") {england_map}
    else if (input$which_area == "USA") {usa_map}
    else if (input$which_area == "Spain") {spain_map}
    else if (input$which_area == "Italy") {italy_map}
    else if (input$which_area == "Greece") {greece_map}
    else {usa_map}
  })
  get_bounds <- reactive({
    # print(paste("Changing get_bounds", input$which_trip))
    # print(as.list(trips_df[input$which_trip == paste(trips_df$trip, trips_df$year), 
    #                        c("bbox11", "bbox21", "bbox12", "bbox22")]))
    as.list(trips_df[input$which_trip == paste(trips_df$trip, trips_df$year), 
                          c("bbox11", "bbox21", "bbox12", "bbox22")])
  })
  
  observeEvent(input$focusButton, {
    # print(paste("after running fitBounds in observeEvent.",  input$which_trip,
    #             get_bounds()$bbox11, get_bounds()$bbox21,
    #             get_bounds()$bbox12, get_bounds()$bbox22 ))
    leafletProxy("mymap", session) %>%
      #fitBounds(-112.057, 36.211, -111.9775, 36.3864)
      fitBounds(get_bounds()$bbox11, get_bounds()$bbox21,
                get_bounds()$bbox12, get_bounds()$bbox22)
    
  })
  observeEvent(input$notesButton, {
    
  })
  
  observe({
        # Change values for input$which_trip
        updateSelectInput(session, "which_trip", 
                          choices =  paste(trips_df$trip[trips_df$area == input$which_area], 
                                           trips_df$year[trips_df$area == input$which_area]),
                          selected = default_area[input$which_area])
      })

  output$mymap <- renderLeaflet({
    # If I put get_bounds() into a print statement here, it will cause
    # renderLeaflet to run whenever input$which_trip changes, which is not what I want.
    #get_map_data()  -- this was when I was doing separate map for three areas instead of loading the whole map
    # addLayersControl(get_map_data(), baseGroups = c("Topographical", "Satellite", "Road map"),    
    # # addLayersControl(get_map_data(), baseGroups = c("Terrain", "Satellite", "Open Topo", "Road Map"),
    #                                   overlayGroups = c("Hiking routes", "Photo markers"),
    #                options = layersControlOptions(collapsed = FALSE)) %>%
    #   addScaleBar(position = c("topleft"))
    get_map_data()
  })
  
  # from: https://rstudio.github.io/leaflet/shiny.html
  # Incremental changes to the map should be performed in
  # an observer. Each independent set of things that can change
  # should be managed in its own observer.
  observe({
    # print(paste("Running fitBounds in observe",  input$which_trip, get_bounds()$bbox11, get_bounds()$bbox21,
    #             get_bounds()$bbox12, get_bounds()$bbox22))
    leafletProxy("mymap", session) %>%
      fitBounds(get_bounds()$bbox11, get_bounds()$bbox21,
                get_bounds()$bbox12, get_bounds()$bbox22)
  })
  
  
}

shinyApp(ui, server, enableBookmarking = "url")
