
# ------------------------------------------------------------
# Windows 사용자를 위한 taskscheduleR 사용법
# ------------------------------------------------------------

# 필요한 패키지를 불러옵니다.
library(tidyverse)
library(taskscheduleR)

# 현재 등록된 정기 작업의 개수을 확인합니다.
taskscheduler_ls() %>% filter(TaskName == 'MyTask') %>% nrow()

# 현재 등록된 정기 작업의 목록을 확인합니다.
taskscheduler_ls() %>% filter(TaskName == 'MyTask') %>% View()

# 등록된 taskname으로 삭제합니다.
# taskscheduler_delete(taskname = 'MyTask')


# ------------------------------------------------------------

# 정기 작업 파일을 `task`로 설정합니다.
task <- file.path(str_glue('{getwd()}/1 YouTube Crawler.R'))

# `task`를 출력합니다.
print(x = task)

# 정기 작업을 설정합니다.
taskscheduler_create(taskname = 'MyTask',
                     rscript = task,
                     schedule = 'HOURLY',
                     modifier = 2)


## End of Document
