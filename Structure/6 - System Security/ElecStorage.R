require(readxl)
require(plotly)
require(dygraphs)
require(png)
require("DT")
###### UI Function ######



ElecStorageOutput <- function(id) {
  ns <- NS(id)
  tagList(
    tabsetPanel(
      tabPanel("Capacity",
               fluidRow(column(8,
                               h3("Electricity storage capacity", style = "color: #5d8be1;  font-weight:bold"),
                               h4(textOutput(ns('ElecStorageCapSubtitle')), style = "color: #5d8be1;")
               ),
               column(
                 4, style = 'padding:15px;',
                 downloadButton(ns('ElecStorageCap.png'), 'Download Graph', style="float:right")
               )),
               
               tags$hr(style = "height:3px;border:none;color:#5d8be1;background-color:#5d8be1;"),
               #dygraphOutput(ns("ElecStorageCapPlot")),
               plotlyOutput(ns("ElecStorageCapPlot"), height = "500px")%>% withSpinner(color="#5d8be1"),
               tags$hr(style = "height:3px;border:none;color:#5d8be1;background-color:#5d8be1;")
               ),
      tabPanel("Pipeline",
               fluidRow(column(8,
                               h3("Pipeline storage capacity by planning stage", style = "color: #5d8be1;  font-weight:bold"),
                               h4(textOutput(ns('ElecStorageSubtitle')), style = "color: #5d8be1;")
               ),
               column(
                 4, style = 'padding:15px;',
                 downloadButton(ns('ElecStorage.png'), 'Download Graph', style="float:right")
               )),
               
               tags$hr(style = "height:3px;border:none;color:#5d8be1;background-color:#5d8be1;"),
               #dygraphOutput(ns("ElecStoragePlot")),
               plotlyOutput(ns("ElecStoragePlot"), height = "500px")%>% withSpinner(color="#5d8be1"),
               tags$hr(style = "height:3px;border:none;color:#5d8be1;background-color:#5d8be1;")
               )),

    fluidRow(
    column(10,h3("Commentary", style = "color: #5d8be1;  font-weight:bold")),
    column(2,style = "padding:15px",actionButton(ns("ToggleText"), "Show/Hide Text", style = "float:right; "))),
    
    fluidRow(
    uiOutput(ns("Text"))
    ),
    tags$hr(style = "height:3px;border:none;color:#5d8be1;background-color:#5d8be1;"),
    tabsetPanel(
      tabPanel("Capacity",
               fluidRow(
                 column(10, h3("Data- Electricity storage capacity by technology (MW)", style = "color: #5d8be1;  font-weight:bold")),
                 column(2, style = "padding:15px",  actionButton(ns("ToggleTable1"), "Show/Hide Table", style = "float:right; "))
               ),
               fluidRow(
                 column(12, dataTableOutput(ns("ElecStorageCapTable"))%>% withSpinner(color="#5d8be1"))),
               tags$hr(style = "height:3px;border:none;color:#5d8be1;background-color:#5d8be1;")
      ),
      tabPanel("Pipeline",
               fluidRow(
                 column(10, h3("Data - Pipeline storage capacity by technology (MW)", style = "color: #5d8be1;  font-weight:bold")),
                 column(2, style = "padding:15px",  actionButton(ns("ToggleTable2"), "Show/Hide Table", style = "float:right; "))
               ),
               fluidRow(
                 column(12, dataTableOutput(ns("ElecStorageTable"))%>% withSpinner(color="#5d8be1"))),
               tags$hr(style = "height:3px;border:none;color:#5d8be1;background-color:#5d8be1;")
      )
    ),
     
               
    fluidRow(
      column(2, HTML("<p><strong>Last Updated:</strong></p>")),
      column(2,
             UpdatedLookup(c("BEISREPD"))),
      column(1, align = "right",
             HTML("<p><strong>Reason:</strong></p>")),
      column(7, align = "right", 
             p("Regular updates")
      )),
    fluidRow(p(" ")),
    fluidRow(
      column(2, HTML("<p><strong>Update Expected:</strong></p>")),
      column(2,
             DateLookup(c("BEISREPD"))),
      column(1, align = "right",
             HTML("<p><strong>Sources:</strong></p>")),
      column(7, align = "right",
        SourceLookup("BEISREPD")
        
      )
    )
  )
}

###### Server ######
ElecStorage <- function(input, output, session) {

  
  if (exists("PackageHeader") == 0) {
    source("Structure/PackageHeader.R")
  }
  
  print("ElecStorage.R")
  ###### Renewable Energy ###### ######
  
  ### From ESD ###
  
  output$ElecStorageSubtitle <- renderText({
    
    Data <- read_excel("Structure/CurrentWorking.xlsx", 
                       sheet = "Renewable elec pipeline", col_names = TRUE,
                       skip = 26, n_max = 1)
    Quarter <- substr(Data[1,1], 8,8)
    
    Quarter <- as.numeric(Quarter)*3
    
    Year <- substr(Data[1,1], 1,4)
    
    #paste("Scotland,", month.name[Quarter], Year)
    paste("Scotland, March 2023")
  })

  output$ElecStoragePlot <- renderPlotly  ({
    
    ElecStorage <- read_csv("Processed Data/Output/Renewable Capacity/Storage.csv")
    
    ElecStorage$Operational <- NULL
    
    names(ElecStorage)[2] <- "Type"
    
    names(ElecStorage)[6] <- "Total"
    
    ElecStorage <- ElecStorage[2:6]
    
    ElecStorage <- ElecStorage[which(ElecStorage$Total > 0),]
    
    ElecStorage <- arrange(ElecStorage, ElecStorage$Total)
    
    rownames(ElecStorage) <- NULL
    
    
    ElecStorage$Type <- paste0("<b>", str_wrap(ElecStorage$Type, 6), "</b>")
    
    ChartColours <- c("#5d8be1", "#FF8500")
    BarColours <-
      c(
        "#31a354",
        "#0868ac",
        "#43a2ca",
        "#7bccc4",
        "#a6bddb",
        "#d0d1e6",
        "#bdbdbd",
        "#969696"
      )
    
    
    p <- plot_ly(data = ElecStorage, y = ~ Type) %>%
      add_trace(
        data = ElecStorage,
        x = ~ `Under Construction`,
        type = 'bar',
        width = 0.7,
        orientation = 'h',
        name = "Under Construction",
        text = paste0("Under Construction: ", format(round(ElecStorage$`Under Construction`, digits = 0), big.mark = ","), " MW"),
        hoverinfo = 'text',
        marker = list(color = BarColours[2]),
        legendgroup = 2
      ) %>%
      add_trace(
        data = ElecStorage,
        x = ~ `Awaiting Construction`,
        type = 'bar',
        width = 0.7,
        orientation = 'h',
        name = "Awaiting Construction",
        text = paste0("Awaiting Construction: ", format(round(ElecStorage$`Awaiting Construction`, digits = 0), big.mark = ","), " MW"),
        hoverinfo = 'text',
        marker = list(color = BarColours[3]),
        legendgroup = 3
      ) %>%
      
      add_trace(
        data = ElecStorage,
        x = ~ `Application Submitted`,
        type = 'bar',
        width = 0.7,
        orientation = 'h',
        name = "Application Submitted",
        text = paste0("Application Submitted: ", format(round(ElecStorage$`Application Submitted`, digits = 0), big.mark = ","), " MW"),
        hoverinfo = 'text',
        marker = list(color = BarColours[4]),
        legendgroup = 4
      ) %>%
      add_trace(
        data = ElecStorage,
        y = ~ Type,
        x = ~ (ElecStorage$`Total`) + 0.1,
        showlegend = FALSE,
        type = 'scatter',
        mode = 'text',
        text = paste("<b>",format(round((ElecStorage$`Total`), digits = 0), big.mark = ","),"MW</b>"),
        textposition = 'middle right',
        textfont = list(color = ChartColours[1]),
        hoverinfo = 'skip',
        marker = list(
          size = 0.00001
        )
      ) %>%
      layout(
        barmode = 'stack',
        legend = list(font = list(color = "#1A5D38"),
                      orientation = 'h'),
        hoverlabel = list(font = list(color = "white"),
                          hovername = 'text'),
        hovername = 'text',
        yaxis = list(
          title = "",
          showgrid = FALSE,
          tickvals = list(0,1,2,3,4,5,6,7,8,9),
          tickmode = "array"
        ),
        xaxis = list(
          title = "",
          tickformat = "%",
          showgrid = FALSE,
          showticklabels = FALSE,
          range = c(0,13000),
          zeroline = FALSE,
          zerolinecolor = ChartColours[1],
          zerolinewidth = 2,
          rangemode = "tozero"
        )
      ) %>%
      config(displayModeBar = F)
    
    p
  })
  
  
  output$ElecStorageTable = renderDataTable({
    
    ElecStorage <- read_csv("Processed Data/Output/Renewable Capacity/Storage.csv")
    
    ElecStorage$Operational <- NULL
    
    names(ElecStorage)[2] <- "Type"
    
    names(ElecStorage)[6] <- "Total"
    
    ElecStorage <- ElecStorage[2:6]
    
    ElecStorage <- ElecStorage[which(ElecStorage$Total > 0),]
    
    ElecStorage <- arrange(ElecStorage, ElecStorage$Total)
    
    rownames(ElecStorage) <- NULL
    
    datatable(
      ElecStorage[c(1,2:5)],
      extensions = 'Buttons',
      
      rownames = FALSE,
      options = list(
        paging = TRUE,
        pageLength = -1,
        searching = TRUE,
        fixedColumns = FALSE,
        autoWidth = TRUE,
        ordering = TRUE,
        order = list(list(ncol(ElecStorage)-1, 'desc')),
        title = "Pipeline storage capacity (MW)",
        dom = 'ltBp',
        buttons = list(
          list(extend = 'copy'),
          list(
            extend = 'excel',
            title = 'Pipeline storage capacity (MW)',
            header = TRUE
          ),
          list(extend = 'csv',
               title = 'Pipeline storage capacity (MW)')
        ),
        
        # customize the length menu
        lengthMenu = list( c(10, 20, -1) # declare values
                           , c(10, 20, "All") # declare titles
        ), # end of lengthMenu customization
        pageLength = 10
      )
    ) %>%
      formatRound(2:ncol(ElecStorage), 0)
  })

 output$Text <- renderUI({
   tagList(column(12,
                  HTML(
                    paste(readtext("Structure/6 - System Security/ElecStorage.txt")[2])
                    
                  )))
 })
 
 
  observeEvent(input$ToggleTable1, {
    toggle("ElecStorageCapTable")
  })
  
  observeEvent(input$ToggleTable2, {
    toggle("ElecStorageTable")
  })
  
  
  observeEvent(input$ToggleText, {
    toggle("Text")
  })
  
  
  output$ElecStorage.png <- downloadHandler(
    filename = "ElecStorage.png",
    content = function(file) {
      
      EnergyStorageTech <- read_csv("Processed Data/Output/Renewable Capacity/Storage.csv")
      
      EnergyStorageTech$Operational <- NULL
      
      names(EnergyStorageTech)[2] <- "Type"
      
      names(EnergyStorageTech)[6] <- "Total"
      
      EnergyStorageTech <- EnergyStorageTech[2:6]
      
      EnergyStorageTech <- EnergyStorageTech[which(EnergyStorageTech$Total > 0),]
      
      EnergyStorageTech <- arrange(EnergyStorageTech, EnergyStorageTech$Total)
      
      rownames(EnergyStorageTech) <- NULL
      
      EnergyStorageTech$Total <- NULL
      
      EnergyStorageTech$Type <-
        factor(EnergyStorageTech$Type,
               levels = unique(EnergyStorageTech$Type),
               ordered = TRUE)
      
      EnergyStorageTech <- melt(EnergyStorageTech, id.vars = "Type")
      
      
      EnergyStorageTech$variable <-
        factor(EnergyStorageTech$variable,
               levels = unique(EnergyStorageTech$variable),
               ordered = TRUE)
      
      EnergyStorageTech <- EnergyStorageTech %>%
        group_by(Type) %>%
        mutate(pos = cumsum(value) - value / 2) %>%
        mutate(top = sum(value))
      
      plottitle <-
        "Pipeline storage capacity by planning stage"
      sourcecaption <- "Source: BEIS"
      
      ChartColours <- c("#5d8be1", "#FF8500")
      BarColours <-
        c(
          "#31a354",
          "#0868ac",
          "#43a2ca",
          "#7bccc4",
          "#a6bddb",
          "#d0d1e6",
          "#bdbdbd",
          "#969696"
        )
      
      
      EnergyStorageTechChart <- EnergyStorageTech %>%
        ggplot(aes(x = Type, y = value, fill = variable), family = "Century Gothic") +
        scale_fill_manual(
          "variable",
          values = c(
            "Operational" = BarColours[1],
            "Under Construction" = BarColours[2],
            "Awaiting Construction" = BarColours[3],
            "Application Submitted" = BarColours[4]
          )
        ) +
        geom_bar(stat = "identity", width = .8) +
        geom_text(
          aes(
            x = Type,
            y = -600,
            label = str_wrap(Type, 10),
            fontface = 2
          ),
          colour = ChartColours[1],
          family = "Century Gothic",
        ) +
        geom_text(
          aes(
            x = Type,
            y = top+100  ,
            label = paste(format(round(top,digits = 0),big.mark = ","), "MW"),
            fontface = 2
          ),
          colour = ChartColours[1],
          family = "Century Gothic",
          hjust = 0
        ) +
        geom_text(
          aes(
            x = 3.8,
            y = ((.5/3) *4000) - 500,
            label = "Under\nconstruction",
            fontface = 2
          ),
          colour = BarColours[2],
          family = "Century Gothic"
        ) +
        geom_text(
          aes(
            x = 3.8,
            y = ((1.5/3) *4000)-500,
            label = "Awaiting\nconstruction",
            fontface = 2
          ),
          colour = BarColours[3],
          family = "Century Gothic"
        ) +
        geom_text(
          aes(
            x = 3.8,
            y = ((2.5/3) *4000)-500,
            label = "Application\nsubmitted",
            fontface = 2
          ),
          colour = BarColours[4],
          family = "Century Gothic"
        ) +
        geom_text(
          aes(
            x = 4,
            y = (3.5/3) *4500,
            label = " ",
            fontface = 2
          ),
          colour = BarColours[4],
          family = "Century Gothic"
        ) +
        
        geom_text(
          aes(
            x = Type,
            y = top -pos,
            label = ifelse(value > 500, paste0(format(round(value, digits = 0), big.mark = ",", trim = TRUE), "\nMW"),""),
            fontface = 2
          ),
          colour = "white",
          family = "Century Gothic"
        )
      
     
      EnergyStorageTechChart
      
      
      EnergyStorageTechChart <-
        StackedBars(EnergyStorageTechChart,
                    EnergyStorageTech,
                    plottitle,
                    sourcecaption,
                    ChartColours)
      
      EnergyStorageTechChart <-
        EnergyStorageTechChart +
        #labs(subtitle = paste("Scotland,", month.name[Quarter], Year)) +
        labs(subtitle = paste("Scotland, March 2023")) +
        ylim(-1000, max(EnergyStorageTech$top)+800)+
        coord_flip()
      
      EnergyStorageTechChart
      
      ggsave(
        file,
        plot = EnergyStorageTechChart,
        width = 17.5,
        height = 12,
        units = "cm",
        dpi = 300
      )
    }
  )
  
  output$ElecStorageCapSubtitle <- renderText({
    
    Data <- read_excel("Structure/CurrentWorking.xlsx", 
                       sheet = "Renewable elec pipeline", col_names = TRUE,
                       skip = 26, n_max = 1)
    Quarter <- substr(Data[1,1], 8,8)
    
    Quarter <- as.numeric(Quarter)*3
    
    Year <- substr(Data[1,1], 1,4)
    
    #paste("Scotland,", month.name[Quarter], Year)
    paste("Scotland, March 2023") 
  })
  
  output$ElecStorageCapPlot <- renderPlotly  ({
    
    ElecStorageCap <- read_csv("Processed Data/Output/Renewable Capacity/Storage.csv")[c(2,5)]
    
    names(ElecStorageCap)[1] <- "Type"
    
    ElecStorageCap <- ElecStorageCap[which(ElecStorageCap$Operational > 0),]
    
    ElecStorageCap <- arrange(ElecStorageCap, ElecStorageCap$Operational)
    
    rownames(ElecStorageCap) <- NULL
    
    
    ElecStorageCap$Type <- paste0("<b>", str_wrap(ElecStorageCap$Type, 6), "</b>")
    #ElecStorageCap$Type <- as.numeric(rownames(ElecStorageCap))
    
    ChartColours <- c("#5d8be1", "#FF8500")
    BarColours <-
      c(
        "#31a354",
        "#0868ac",
        "#43a2ca",
        "#7bccc4",
        "#a6bddb",
        "#d0d1e6",
        "#bdbdbd",
        "#969696"
      )
    
    
    p <- plot_ly(data = ElecStorageCap, y = ~ Type) %>%
      add_trace(
        data = ElecStorageCap,
        x = ~ `Operational`,
        type = 'bar',
        width = 0.7,
        orientation = 'h',
        name = "Operational",
        text = paste0("Operational: ", format(round(ElecStorageCap$`Operational`, digits = 0), big.mark = ","), " MW"),
        hoverinfo = 'text',
        marker = list(color = BarColours[1]),
        legendgroup = 2
      ) %>%
      add_trace(
        data = ElecStorageCap,
        y = ~ Type,
        x = ~ (ElecStorageCap$`Operational`) + 0.1,
        showlegend = FALSE,
        type = 'scatter',
        mode = 'text',
        text = paste("<b>",format(round((ElecStorageCap$`Operational`), digits = 0), big.mark = ","),"MW</b>"),
        textposition = 'middle right',
        textfont = list(color = ChartColours[1]),
        hoverinfo = 'skip',
        marker = list(
          size = 0.00001
        )
      ) %>%
      layout(
        barmode = 'stack',
        legend = list(font = list(color = "#1A5D38"),
                      orientation = 'h'),
        hoverlabel = list(font = list(color = "white"),
                          hovername = 'text'),
        hovername = 'text',
        yaxis = list(
          title = "",
          showgrid = FALSE,
          tickvals = list(0,1,2,3,4,5,6,7,8,9),
          tickmode = "array"
        ),
        xaxis = list(
          title = "",
          tickformat = "%",
          showgrid = FALSE,
          showticklabels = FALSE,
          range = c(0,1000),
          zeroline = FALSE,
          zerolinecolor = ChartColours[1],
          zerolinewidth = 2,
          rangemode = "tozero"
        )
      ) %>%
      config(displayModeBar = F)
    
    p
  })
  
  output$ElecStorageCapTable = renderDataTable({
    
    ElecStorageCap <- read_csv("Processed Data/Output/Renewable Capacity/Storage.csv")[c(2,5)]
    
    names(ElecStorageCap)[1] <- "Type"
    
    datatable(
      ElecStorageCap,
      extensions = 'Buttons',
      
      rownames = FALSE,
      options = list(
        paging = TRUE,
        pageLength = -1,
        searching = TRUE,
        fixedColumns = FALSE,
        autoWidth = TRUE,
        ordering = TRUE,
        order = list(list(ncol(ElecStorageCap)-1, 'desc')),
        title = "Electricity storage capacity (MW)",
        dom = 'ltBp',
        buttons = list(
          list(extend = 'copy'),
          list(
            extend = 'excel',
            title = 'Electricity storage capacity (MW)',
            header = TRUE
          ),
          list(extend = 'csv',
               title = 'Electricity storage capacity (MW)')
        ),
        
        # customize the length menu
        lengthMenu = list( c(10, 20, -1) # declare values
                           , c(10, 20, "All") # declare titles
        ), # end of lengthMenu customization
        pageLength = 10
      )
    ) %>%
      formatRound(2:ncol(ElecStorageCap), 0)
  })
  
  observeEvent(input$ToggleTable2, {
    toggle("ElecStorageCapTable")
  })
  
  output$ElecStorageCap.png <- downloadHandler(
    filename = "ElecStorageCap.png",
    content = function(file) {
      
      Data <- read_excel("Structure/CurrentWorking.xlsx", 
                         sheet = "Renewable elec pipeline", col_names = TRUE,
                         skip = 26, n_max = 1)
      Quarter <- substr(Data[1,1], 8,8)
      
      Quarter <- as.numeric(Quarter)*3
      
      Year <- substr(Data[1,1], 1,4)
      
      paste("Scotland,", month.name[Quarter], Year)
      
      ### Load Packages and Functions
      EnergyStorageTech  <- read_csv("Processed Data/Output/Renewable Capacity/Storage.csv")[c(2,5)]
      
      names(EnergyStorageTech )[1] <- "Type"
      
      EnergyStorageTech <- arrange(EnergyStorageTech,row_number())
      
      EnergyStorageTech$Type <-
        factor(EnergyStorageTech$Type,
               levels = unique(EnergyStorageTech$Type),
               ordered = TRUE)
      
      EnergyStorageTech <- melt(EnergyStorageTech, id.vars = "Type")
      
      
      EnergyStorageTech$variable <-
        factor(EnergyStorageTech$variable,
               levels = rev(unique(EnergyStorageTech$variable)),
               ordered = TRUE)
      
      EnergyStorageTech <- EnergyStorageTech %>%
        group_by(Type) %>%
        mutate(pos = cumsum(value) - value / 2) %>%
        mutate(top = sum(value))
      
      plottitle <-
        "Electricity storage capacity"
      sourcecaption <- "Source: BEIS"
      
      ChartColours <- c("#5d8be1", "#FF8500")
      BarColours <-
        c(
          "#31a354",
          "#0868ac",
          "#43a2ca",
          "#7bccc4",
          "#a6bddb",
          "#d0d1e6",
          "#bdbdbd",
          "#969696"
        )
      
      
      EnergyStorageTechChart <- EnergyStorageTech %>%
        ggplot(aes(x = Type, y = value, fill = variable), family = "Century Gothic") +
        scale_fill_manual(
          "variable",
          values = c(
            "Operational" = BarColours[1],
            "Under construction" = BarColours[2],
            "Awaiting construction" = BarColours[3],
            "Application submitted" = BarColours[4]
          )
        ) +
        geom_bar(stat = "identity", width = .8) +
        geom_text(
          aes(
            x = Type,
            y = -100,
            label = str_wrap(Type, 10),
            fontface = 2
          ),
          colour = ChartColours[1],
          family = "Century Gothic",
        ) +
        geom_text(
          aes(
            x = Type,
            y = top+30  ,
            label = ifelse(top < 500, paste(format(round(top,digits = 0),big.mark = ","), "MW"), ""),
            fontface = 2
          ),
          colour = ChartColours[1],
          family = "Century Gothic",
          hjust = 0
        ) +
        
        geom_text(
          aes(
            x = Type,
            y = pos,
            label = ifelse(value > 500, paste0(format(round(value, digits = 0), big.mark = ",", trim = TRUE), "\nMW"),""),
            fontface = 2
          ),
          colour = "white",
          family = "Century Gothic"
        )
      
      
      EnergyStorageTechChart
      
      
      EnergyStorageTechChart <-
        StackedBars(EnergyStorageTechChart,
                    EnergyStorageTech,
                    plottitle,
                    sourcecaption,
                    ChartColours)
      
      EnergyStorageTechChart <-
        EnergyStorageTechChart +
        labs(subtitle = paste("Scotland, March 2023")) +
        ylim(-150, max(EnergyStorageTech$top))+
        coord_flip()
      
      EnergyStorageTechChart
      
      ggsave(
        file,
        plot = EnergyStorageTechChart,
        width = 17.5,
        height = 12,
        units = "cm",
        dpi = 300
      )
    }
  )
  
}
