
# ------------------------------------------------------------------------
# SQLite DB 생성
# ------------------------------------------------------------------------

# 필요한 패키지를 불러옵니다.
library(tidyverse)
library(DBI)
library(RSQLite)

# DB를 연결합니다. 만약 해당 DB가 없으면 새로 생성합니다.
conn <- dbConnect(drv = SQLite(), dbname = 'YouTube.sqlite')

# 새로운 테이블을 생성합니다. 맨 처음 한 번만 실행해야 합니다!
dbSendQuery(
  conn = conn,
  statement = 'CREATE TABLE IF NOT EXISTS YouTubeMagic
               (ID INTEGER PRIMARY KEY AUTOINCREMENT,
                vlink TEXT,
                title TEXT,
                views INTEGER,
                pdate TEXT,
                likes INTEGER,
                hates INTEGER,
                ccnts INTEGER);') %>%
  dbClearResult()  # 전송한 쿼리의 처리 결과 제거

# 테이블 생성 여부를 확인합니다. TRUE가 출력되면 정상입니다!
name <- 'YouTubeMagic'
dbExistsTable(conn = conn, name = name)

# 새로운 데이터를 한 번에 추가합니다.
dbWriteTable(conn = conn, 
             name = name, 
             value = df, 
             row.names = FALSE, 
             append = TRUE)

# SQLite에 저장된 데이터를 호출합니다.
db <- dbGetQuery(conn = conn, 
                 statement = str_glue('SELECT * FROM {name};'))

# DB 연결을 해제합니다.
dbDisconnect(conn = conn)


## End of Document 
