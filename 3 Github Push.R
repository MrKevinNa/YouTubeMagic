
# ------------------------------------------------------------------------
# 로컬 폴더에 Git 생성 및 Github Remote Repository 연결
# ------------------------------------------------------------------------

# 필요한 패키지를 호출합니다.
library(tidyverse)
library(git2r)

# 현재 폴더에 git을 생성합니다. [Initialization]
repo <- init(path = '.')

# git에 sqlite 파일을 추가합니다. [Staging]
add(repo = repo, path = 'YouTube.sqlite')

# git에 변경사항을 적용합니다. [Commit]
commit(repo = repo, message = str_glue('DB update at {Sys.time()}'))

# github로 이동하여 새로운 원격 저장소(remote repository)를 생성하고, 
# 로컬 컴퓨터에 추가합니다.
remote_add(repo = repo, 
           name = 'YouTubeMagic',
           url = 'https://github.com/MrKevinNa/YouTubeMagic')

# github 정보를 추가합니다.
config(repo = repo, 
       user.name = 'MrKevinNa',
       user.email = 'drkevin2022@gmail.com')

# 원격 저장소 정보와 브랜치를 확인합니다.
remotes(repo = repo)
branches(repo = repo)


# 아래 함수를 실행하면 스크립트 창에서 .Renviron 파일이 열립니다.
usethis::edit_r_environ()

# 열려 있는 .Renviron 파일에 github ID와 PW를 추가하고 저장합니다. 
# 그리고 R Session을 다시 시작합니다.
# 아래 코드를 실행했을 때 값이 콘솔에 출력되면 정상 추가된 것입니다.
Sys.getenv('GITHUB_ID')

# 로컬 폴더의 커밋 정보를 원격 저장소로 등록합니다. [Push]
push(object = repo, 
     name = 'YouTubeMagic', 
     refspec = 'refs/heads/master', 
     credentials = cred_user_pass(username = Sys.getenv('GITHUB_ID'),
                                  password = Sys.getenv('GITHUB_PW')))


## End of Document 
