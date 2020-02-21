library(shiny)
library(ggplot2)

#NIPS18corticaltypes.shiny.io
dataset <- read.csv("dat.csv", header = TRUE, stringsAsFactors = FALSE)
setNames(dataset$celltype, dataset$hexcol)

ui<-fluidPage(
  titlePanel("Learning from disagreements: application to cortical cell type analysis"),
  
  p("A 2d embedding of the gene expression dataset obtained with the coupled autoencoder architecture is shown below. Cell types identified in [1] can be selectively viewed using the checkboxes. This embedding reflects the hierarchical organization of classes, subclasses, and finally the homogeneous cell types (see Fig. 6 in [1]). Potential splits identified in this embedding support emerging evidence for additional cell types e.g. VisP L4 Rspo1, VisP L5 Endou."),
  h4("References:"),
  p("1. Tasic, B., Yao, Z., Smith, K.A., Graybuck, L., Nguyen, T.N., Bertagnolli, D., Goldy, J., Garren, E., Economo, M.N., Viswanathan, S. and Penn, O., 2017. Shared and distinct transcriptomic cell types across neocortical areas. BioRxiv, p.229542."),
  p("2. Zeng, H. and Sanes, J.R., 2017. Neuronal cell-type classification: challenges, opportunities and the path forward. Nature Reviews Neuroscience, 18(9), p.530."),
  
  
  mainPanel(
    fluidRow(
      # Figure -----------------------------------------------
      column(12, align="center",offset = 0, 
             plotOutput('plot',width = "100%", height = 600,
                        click = "plot_click",
                        dblclick = "plt_dblclk",
                        brush = brushOpts(
                          id = "plt_brush",
                          resetOnNew = TRUE)))
    ),
    fluidRow(
      column(width = 12,align="center",
             verbatimTextOutput("plot_clickinfo")
      )),
    code("- Click on any point to display its cell type"),
    br(),
    code("- Select one or more cell types using checkboxes below"),
    br(),
    code("- Drag to select an area followed by a double click to zoom in"),
    br(),
    code("- Double click without a selection to return to default zoom"),
    
      fluidRow(
      # Selection panel---------------------------------------
      column(4, 
             checkboxGroupInput("ExcTypes", 
                                h4("Excitatory"), 
                                choices = sort(unique(dataset$celltype[dataset$cellclass==0])),
                                selected = NULL)),
      column(4, 
             checkboxGroupInput("InhTypes", 
                                h4("Inhibitory"), 
                                choices = sort(unique(dataset$celltype[dataset$cellclass==1])),
                                selected = NULL)),
      
      column(4, 
             checkboxGroupInput("NNTypes", 
                                h4("Non-neuronal"), 
                                choices = sort(unique(dataset$celltype[dataset$cellclass==2])),
                                selected = NULL)))
    #textOutput("print")
    
  )
)
server <- function(input, output) {
  #output$print <- renderPrint({
  #  c(input$ExcTypes,input$InhTypes,input$NNTypes)
  #})
  #output$print <- renderPrint(allsel)
  
  def_lims_x = c(-2.5, 2.5)
  def_lims_y = c(-3, 2)
  ranges <- reactiveValues(x = def_lims_x, y = def_lims_y)
  
  output$plot <- renderPlot({
    show_celltypes <- c(input$ExcTypes,input$InhTypes,input$NNTypes)

    colorlist <- dataset$hexcol
    colorlist[!(dataset$celltype %in% show_celltypes)] = "grey"
    
    typelabels <- dataset$celltype
    typelabels[!(dataset$celltype %in% show_celltypes)] = "Others"
    
    #Show subset chosen in their own color and rest in grey-----------------------
    ggplot(dataset, aes(x=z1, y=z2)) +
      geom_point(aes(colour = colorlist), size = 0.2) +
      scale_color_identity(guide = "legend",labels = setNames(typelabels,colorlist)) +
      guides(colour = guide_legend(override.aes = list(size = 3))) +
      coord_cartesian(xlim = ranges$x, ylim = ranges$y, expand = FALSE) +
      theme(axis.title = element_text(size = 15), axis.text = element_blank(), axis.ticks = element_blank(), aspect.ratio = 1) +
      theme(legend.position="top",legend.title = element_text(size = 12, face="bold"), legend.text = element_text(size = 11)) +
      labs(x = '', y = '', colour = "Selected cell types:")
  })
  
  output$plot_clickinfo <- renderPrint({
    ctype <- nearPoints(dataset, input$plot_click, maxpoints = 1)
    cat("Cell Type for clicked point: ")
    if (!is.null(ctype)){
      cat(ctype$celltype[1])
    }else{
      cat("--")
    }
    
  })
    
  # Zoom logic (drag to select area, double click to zoom in)
  observeEvent(input$plt_dblclk, {
    brush <- input$plt_brush
    if (!is.null(brush)) {
      ranges$x <- c(brush$xmin, brush$xmax)
      ranges$y <- c(brush$ymin, brush$ymax)
    } else {
      ranges$x <- def_lims_x 
      ranges$y <- def_lims_y
    }
  })
}
shinyApp(ui = ui, server = server)