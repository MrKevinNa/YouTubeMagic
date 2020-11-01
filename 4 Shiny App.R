
# ------------------------------------------------------------------------
# YouTube에서 수집한 동영상 정보 대시보드 App
# ------------------------------------------------------------------------

# 필요한 패키지를 호출합니다.
library(shiny)
library(shinythemes)
library(tidyverse)
library(DBI)
library(RSQLite)
options(warn = -1)
options(shiny.maxRequestSize = 30*1024^2)

# ui 객체를 생성합니다.
ui <- navbarPage(
  title = HTML('<b>YouTube Dashborad</b>'),
  theme = shinytheme(theme = 'spacelab'),
  
  tabPanel(
    title = 'Data',
    fluidRow(
      column(width = 4,
             dateRangeInput(inputId = 'dates',
                            label = 'ㅁ 검색기간을 선택하세요.',
                            start = Sys.Date() - 7,
                            end = Sys.Date() - 1,
                            format = 'yyyy-mm-dd')),
      column(width = 2,
             br(),
             submitButton(text = '변경사항 적용',
                          icon = icon(name = 'refresh')))
    ),
    
    fluidRow(
      column(width = 12,
             HTML('<hr style="border:solid 1px black">'))
    ),
    
    fluidRow(
      column(width = 12,
             uiOutput(outputId = 'mainUI1'))
    )
  ),
  
  tabPanel(
    title = 'Graph',
    fluidRow(
      column(width = 12,
             uiOutput(outputId = 'mainUI2'))
    )
  )
)

# server 객체를 생성합니다.
server <- function(input, output, session) {
  
  # DB를 데이터프레임으로 불러옵니다.
  df <- reactive({
    
    # DB가 저장되어 있는 Github URL을 설정합니다.
    url <- 'https://github.com/MrKevinNa/YouTubeMagic/raw/master/YouTube.sqlite'
    
    # 임시로 저장할 파일명을 설정합니다.
    dbfile <- tempfile(fileext = '.sqlite')
    
    # DB를 다운로드합니다.
    download.file(url = url, destfile = dbfile)
    
    # SQLite DB를 연결합니다.
    conn <- dbConnect(drv = SQLite(), dbname = dbfile)
    
    # DB에 저장된 데이터를 읽어옵니다.
    dbGetQuery(conn = conn,
               statement = 'SELECT * FROM YouTubeMagic;') %>% 
      mutate(pdate = as.Date(x = pdate)) %>% 
      filter(between(x = pdate,
                     left = input$dates[1],
                     right = input$dates[2])) %>% 
      arrange(desc(x = pdate), desc(x = views))
  })
  
  # 데이터테이블을 생성합니다.
  output$table <- DT::renderDataTable({
    df() %>% 
      rename(등록일 = pdate, 
             타이틀 = title, 
             웹주소 = vlink,
             조회수 = views,
             댓글수 = ccnts,
             좋아요 = likes,
             싫어요 = hates) %>% 
      select(등록일, 타이틀, 웹주소, 조회수, 댓글수, 좋아요, 싫어요)
  })
  
  # ggplot2 사용자 테마를 설정합니다.
  mytheme <- theme_bw() +
    theme(text = element_text(family = 'AppleGothic'),
          plot.title = element_text(size = 12, hjust = 0.5, face = 'bold'),
          # axis.text.x = element_text(angle = 90),
          legend.title = element_blank(),
          legend.position = 'top')
  
  # 조회수와 댓글수로 선그래프를 그립니다.
  output$graph1 <- renderPlot({
    daily <- df() %>% 
      group_by(pdate) %>% 
      summarise(Views = sum(views, na.rm = TRUE),
                Ccnts = sum(ccnts, na.rm = TRUE))
    
    ggplot(data = daily,
           mapping = aes(x = pdate, group = TRUE)) +
      geom_line(mapping = aes(y = Views, color = 'Views')) +
      geom_line(mapping = aes(y = Ccnts*100, color = 'Comments')) +
      scale_y_continuous(sec.axis = sec_axis(trans = ~ ./100, 
                                             name = 'Comments')) +
      labs(title = 'Daily Views and Comments',
           x = 'Posting Date',
           y = 'Views',
           colour = '') +
      mytheme
  })
  
  # 좋아요와 싫어요로 선그래프를 그립니다.
  output$graph2 <- renderPlot({
    daily <- df() %>% 
      group_by(pdate) %>% 
      summarise(Likes = sum(likes, na.rm = TRUE),
                Hates = sum(hates, na.rm = TRUE))
    
    ggplot(data = daily,
           mapping = aes(x = pdate, group = TRUE)) +
      geom_line(mapping = aes(y = Likes, color = 'Likes')) +
      geom_line(mapping = aes(y = Hates*10, color = 'Dislikes')) +
      scale_y_continuous(sec.axis = sec_axis(trans = ~ ./10,
                                             name = 'Dislikes')) +
      labs(title = 'Daily Likes and Dislikes',
           x = 'Posting Date',
           y = 'Likes',
           colour = '') + 
      mytheme
  })
  
  # 대시보드에 출력할 내용을 설정합니다.
  output$mainUI1 <- renderUI({
    tagList(
      br(),
      br(),
      DT::dataTableOutput(outputId = 'table'),
      br()
    )
  })
  
  output$mainUI2 <- renderUI({
    tagList(
      br(),
      br(),
      plotOutput(outputId = 'graph1'),
      hr(), 
      plotOutput(outputId = 'graph2'),
      br()
    )
  })
}

# shiny app을 실행합니다.
shinyApp(ui = ui, server = server)

# shinyapps.io로 배포하려면 깃허브 저장소(YouTubeMagic)에 올려 놓은
# pdf 파일을 참고하시기 바랍니다.


## End of Document
