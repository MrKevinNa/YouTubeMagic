
# ------------------------------------------------------------------------
# Git 생성 및 Github Remote Repository 연결
# ------------------------------------------------------------------------

# 필요한 패키지를 호출합니다.
library(git2r)

# 현재 폴더에 git을 설치합니다.
repo <- init(path = '.')

# github 정보를 추가합니다.
config(repo = repo, 
       user.name = 'MrKevinNa',
       user.email = 'drkevin2022@gmail.com')

# sqlite 파일을 staging 합니다.
add(repo = repo, path = 'YouTube.sqlite')

# commit을 수행합니다.
commit(repo = repo, message = str_glue('DB update at {Sys.time()}'))

# github에서 remote repository를 생성한 다음, 로컬 폴더에 연결합니다.
remote_add(repo = repo, 
           name = 'YouTubeMagic',
           url = 'https://github.com/MrKevinNa/YouTubeMagic')

remotes(repo = repo)
branches(repo = repo)

# push를 수행합니다.
# github ID와 PW는 Renviron에 미리 등록해놓은 것입니다.
push(object = repo, 
     name = 'YouTubeMagic', 
     refspec = 'refs/heads/master', 
     credentials = cred_user_pass(username = Sys.getenv('GITHUB_ID'),
                                  password = Sys.getenv('GITHUB_PW')))


## End of Document 
