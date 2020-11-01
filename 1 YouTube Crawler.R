
# ------------------------------------------------------------------------
# 리모트 브라우저 구동 (RSelenium)
# ------------------------------------------------------------------------

# 필요한 패키지를 불러옵니다.
library(tidyverse)
library(RSelenium)
library(binman)
library(wdman)

# 포트 설정
port <- 50001L

# 크롬 드라이버 버전 확인
vers <- list_versions(appname = 'chromedriver')
n <- length(x = vers$mac64)

# 웹 드라이버를 시작합니다.
driver <- chrome(port = port, version = vers$mac64[n-1])

# 크롬 브라우저 옵션을 설정합니다. (무음으로 실행)
# 헤드리스로 실행하려면 '--headless' 옵션을 추가합니다.
opts <- list(args = c('--window-size=1280,1440', '--mute-audio'))

# 리모트 드라이버를 설정합니다.
remote <- remoteDriver(port = port, 
                       extraCapabilities = list(chromeOptions = opts))

# 잠시 멈춥니다.
Sys.sleep(time = 1L)

# 리모트 웹 브라우저를 엽니다.
remote$open()


# ------------------------------------------------------------------------
# 유튜브 메인 페이지에서 검색어로 비디오 링크 수집 
# ------------------------------------------------------------------------

# 필요한 패키지를 불러옵니다.
library(httr)
library(rvest)

# 리모트 브라우저의 검색창에서 관심 있는 '검색어'를 입력하고, 
# '필터' 메뉴에서 '오늘', '동영상', '업로드 날짜'를 차례로 선택한 다음
# 주소창의 uri를 복사하여 아래와 같이 붙입니다.
# https://www.youtube.com/results?search_query=R+%EB%8D%B0%EC%9D%B4%ED%84%B0+%EB%B6%84%EC%84%9D&sp=CAISBAgDEAE%253D

# 오늘 업로드 한 동영상을 조회하는 `url`을 조립합니다.
url <- parse_url(url = 'https://www.youtube.com/results')
url$query <- list('search_query' = 'R 데이터 분석', 'sp' = 'CAISBAgDEAE%3D')
url <- build_url(url = url)
print(x = url)

# 유튜브 메인 페이지로 이동합니다.
remote$navigate(url = url)

# 잠시 멈춥니다.
Sys.sleep(time = 1L)

# 현재 페이지의 HTML을 읽어옵니다.
res <- remote$getPageSource()[[1]]

# 동영상 '제목'을 수집합니다.
title <- res %>% 
  read_html() %>% 
  html_nodes(css = 'h3.ytd-video-renderer > a') %>% 
  html_text(trim = TRUE)

# 동영상 '링크'를 수집합니다.
vlink <- res %>% 
  read_html() %>% 
  html_nodes(css = 'h3.ytd-video-renderer > a') %>% 
  html_attr(name = 'href')

# 데이터프레임으로 저장합니다.
df <- data.frame(vlink, title)

# `vlink`에 도메인을 추가합니다.
df$vlink <- str_glue('https://www.youtube.com{df$vlink}')


# ------------------------------------------------------------------------
# RSelenium을 이용하여 유튜브 동영상 링크별 상세 정보 수집 
# ------------------------------------------------------------------------

# 조회수, 등록일, 좋아요, 싫어요, 댓글수 등 추가 수집할 컬럼을 지정합니다.
col <- c('views', 'pdate', 'likes', 'hates', 'ccnts')
df[, col] <- NA

# 반복문을 실행할 횟수를 지정합니다.
# i <- 1
n <- nrow(x = df)

# 반복문을 실행합니다.
for (i in 1:n) {
  
  # 현재 진행상황을 출력합니다.
  cat('현재', i, '번째 링크에 접속을 시도합니다.\n')
  
  # 링크에 접속합니다.
  remote$navigate(url = df$vlink[i])
  
  # 잠시 멈춥니다.
  Sys.sleep(time = 1L)
  
  # 현재 페이지의 HTML을 읽습니다.
  html <- remote$getPageSource()[[1]] %>% read_html()
  
  # 비디오 멈춤을 클릭합니다.
  checkPlay <- html %>%
    html_node(css = 'button.ytp-play-button') %>%
    html_attr(name = 'aria-label')
  
  if(checkPlay %in% c('Pause (k)', '일시중지(k)')) {
    remote$findElement(
      using = 'css',
      value = 'button.ytp-play-button'
    )$clickElement()
  }
  
  # 현재 페이지의 HTML을 읽어옵니다.
  html <- remote$getPageSource()[[1]] %>% read_html()
  
  # 유튜브 정보 관련 HTML 요소만 선택합니다.
  info <- html %>% html_node(css = '#primary-inner > #info')
  
  # 동영상 '조회수'를 수집합니다.
  df$views[i] <- info %>% 
    html_node(css = '#count > yt-view-count-renderer > span') %>% 
    html_text(trim = TRUE) %>% 
    str_remove_all(pattern = ',') %>% 
    str_extract(pattern = '\\d+') %>% 
    as.numeric()
  
  # 동영상 '등록일'을 수집합니다.
  df$pdate[i] <- info %>% 
    html_node(css = '#date > yt-formatted-string') %>% 
    html_text(trim = TRUE) %>% 
    as.Date(format = '%Y. %m. %d.')
  
  # 만약 등록일이 NA이면, 전일 날짜로 대체합니다.
  if(is.na(x = df$pdate[i])) {
    df$pdate[i] <- Sys.Date() - 1
  }
  
  # 동영상 '좋아요'를 수집합니다.
  df$likes[i] <- info %>% 
    html_node(css = 'ytd-toggle-button-renderer:nth-child(1) > a > #text') %>% 
    html_attr(name = 'aria-label') %>% 
    str_remove_all(pattern = ',') %>% 
    str_extract(pattern = '\\d+') %>% 
    as.numeric()
  
  # 동영상 '싫어요'를 수집합니다.
  df$hates[i] <- info %>% 
    html_node(css = 'ytd-toggle-button-renderer:nth-child(2) > a > #text') %>% 
    html_attr(name = 'aria-label') %>% 
    str_remove_all(pattern = ',') %>% 
    str_extract(pattern = '\\d+') %>% 
    as.numeric()
  
  # 댓글 관련 HTML 요소만 선택합니다.
  comt <- html %>% html_node(css = '#primary-inner > ytd-comments')
  
  # 동영상 '댓글수'를 저장합니다.
  df$ccnts[i] <- comt %>% 
    html_node(css = '#count > yt-formatted-string') %>% 
    html_text(trim = TRUE) %>% 
    str_remove_all(pattern = ',') %>% 
    str_extract(pattern = '\\d+') %>% 
    as.numeric()
  
  # 일부 객체를 삭제합니다.
  rm(html, checkPlay, info, comt)
}

# `pdate` 컬럼을 날짜 속성으로 변경합니다.
df$pdate <- df$pdate %>% as.Date(origin = '1970-01-01') %>% as.character()

# 리모트 브라우저를 닫습니다.
remote$close()

# 크롬 드라이버를 중단합니다.
driver$stop()


# ------------------------------------------------------------------------
# SQLite DB로 저장 : 반드시 2번 R 파일을 먼저 실행하셔야 합니다!!!
# ------------------------------------------------------------------------

# 필요한 패키지를 불러옵니다.
library(DBI)
library(RSQLite)

# DB를 연결합니다.
conn <- dbConnect(drv = SQLite(), dbname = 'YouTube.sqlite')

# 테이블 생성 여부를 확인합니다. TRUE가 출력되면 정상입니다!
name <- 'YouTubeMagic'
dbExistsTable(conn = conn, name = name)

# SQLite에 저장된 데이터를 호출합니다.
db <- dbGetQuery(conn = conn, 
                 statement = str_glue('SELECT * FROM {name};'))

# SQLite에 저장된 기존 `vlink`와 중복되는 건을 삭제합니다.
df <- df %>% filter(!vlink %in% db$vlink)

# 새로운 데이터를 한 번에 추가합니다.
if(nrow(x = df) >= 1) {
  dbWriteTable(conn = conn, 
               name = name, 
               value = df, 
               row.names = FALSE, 
               append = TRUE)
}

# DB 연결을 해제합니다.
dbDisconnect(conn = conn)


# ------------------------------------------------------------------------
# Github에 Commit & Push : 반드시 3번 R 파일을 먼저 실행하셔야 합니다!!!
# ------------------------------------------------------------------------

# 필요한 패키지를 호출합니다.
library(git2r)

# 현재 폴더에 git을 설치합니다.
repo <- init(path = '.')

# push를 수행합니다.
push(object = repo, 
     name = 'YouTubeMagic', 
     refspec = 'refs/heads/master', 
     credentials = cred_user_pass(username = Sys.getenv('GITHUB_ID'),
                                  password = Sys.getenv('GITHUB_PW')))


## End of Document 
