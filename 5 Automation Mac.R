
# ------------------------------------------------------------
# Mac 사용자를 위한 cronR 사용법
# ------------------------------------------------------------

# 필요한 패키지를 불러옵니다.
library(tidyverse)
library(cronR)

# 현재 등록된 cronjob의 개수를 확인합니다.
cron_njobs()

# 현재 등록된 cronjob의 목록을 확인합니다.
cron_ls()

# 등록된 cronjob의 id로 지웁니다.
# cron_rm(id = 'MyTask')


# ------------------------------------------------------------

# 정기 작업 파일을 `task`로 설정합니다.
task <- cron_rscript(rscript = '1 YouTube Crawler.R')

# `task`를 출력합니다.
print(x = task)

# 정기 작업을 설정합니다.
cron_add(command = task, 
         frequency = '0 */2 * * *', 
         id = 'MyTask', 
         description = 'Every 2 Hours')


## End of Document
