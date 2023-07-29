#!/usr/bin/env bash

ssh-add -D
ssh-add ~/.ssh/id_ed25519

USERNAME="bearddan2000"
TOKEN="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"

PROJECT_PATH="test"

REPO_NAME="test"

DESCRIPTION="automation test"

UPGRADE=0
TOTAL=0

function create_desc() {
  #statements
  if [[ -e "README.md" ]]; then
    #statements
    echo "creating description"
    #reads first paragraph under description in README file
    DESCRIPTION=`head -n 4 README.md | tail -n 1`
    #`cat README.md | perl -0777 -ne '/## Description\n([^#]*)/ && print +(split /[\n]{2,}/, $1)[0];'`
    REPO_NAME=`head -n 1 README.md | sed 's/# //g'`
  fi
}

function create_repo() {
  #statements
  read -r -d '' PAYLOAD <<EOP
  {
    "name": "$REPO_NAME",
    "description": "$DESCRIPTION",
    "homepage": "https://github.com/$USERNAME/$REPO_NAME",
    "private": false
  }
EOP

  shopt -s lastpipe
  curl -H "Authorization: token $TOKEN" --data "$PAYLOAD" https://api.github.com/user/repos | readarray output
}


function create_topics() {
  #statements
  local data_file=README.md

  # read first line
  local first_line=`cat ${data_file} | perl -e '@arr = <STDIN>; $line = $arr[0]; $line =~ s/[# |-]/ /g; print $line;'`

  # read the tech stack
  local first_pass=`cat ${data_file} | perl -0777 -ne '/## Tech stack\n([^#]*)/ && print +(split /[\n]{2,}/, $1)[0];' | awk -F '- ' '{I=sprintf("%s %s", I, $NF);}END{print I;}' | sed -e 's/^ //'`

  # read project title
  local second_pass=`echo $REPO_NAME | sed 's/-/ /g' `

  local third_pass=`echo ${first_line} ${first_pass} ${second_pass} | ruby -e 'puts gets.split.uniq.map { |e| %Q[ "#{e}", ]}'`

  third_pass=`echo $third_pass  | sed 's/,$//g'`

    read -r -d '' PAYLOAD <<EOP
    {
      "names": [$third_pass]
    }
EOP

    shopt -s lastpipe
    curl -X PUT -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $TOKEN" --data "$PAYLOAD" \
        https://api.github.com/repos/${USERNAME}/${REPO_NAME}/topics | readarray output

  echo $third_pass

}

for d in `ls -la | grep ^d | awk '{print $NF}' | egrep -v '^\.'`; do

  # step 3 : go to path
  cd "$d"
  REPO_NAME=`head -n 1 README.md | sed 's/# //g'`
  git ls-remote git@github.com:${USERNAME}/${REPO_NAME}.git
    if [[ $? -eq 0 ]]; then
      echo "${REPO_NAME} already exist"
      curl \
        -X DELETE \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${TOKEN}" \
         https://api.github.com/repos/${USERNAME}/${REPO_NAME}
      echo "old ${REPO_NAME} deleted"
    let  UPGRADE=UPGRADE+1
    fi

    let TOTAL=TOTAL+1

    create_desc
    create_repo

    git config core.sshCommand "ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -F /dev/null"

    # step 4: initialise the repo locally, create blank README, add and commit
    git init
    git add .
    git commit -m 'initial commit'
    git branch -M main

    #  step 6 add the remote github repo to local repo and push
    git remote set-url origin git@github.com:${USERNAME}/${REPO_NAME}.git
    git remote add origin git@github.com:${USERNAME}/${REPO_NAME}.git
    git push -u origin main

    create_topics

    ssh-add -D
    ssh-add ~/.ssh/id_ed25519

    cd ../

#    rm -Rf $d
done
NEW=$((TOTAL-UPGRADE))
echo "---------------------"
echo "--------SUMMARY------"
echo "NEW...............${NEW}"
echo "UPDATE............${UPGRADE}"
echo "---------------------"
echo "TOTAL.............${TOTAL}"
