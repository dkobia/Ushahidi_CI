#!/bin/sh
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# License GPLv2+: GNU GPL version 2 or later <http://gnu.org/licenses/gpl.html>
#
# AUTHOR: DAVID KOBIA - 2011-05-24
#
# WHAT THIS SCRIPT DOES
# As we developed Ushahidi we needed some kind of continous integration 
# system. Custom because a lot of the great CI apps other didn't quite
# satisfy our needs... maybe I was too lazy to finish setting them up.
# So here's what this does:
# 1. Pulls from the GIT repo at GitHub.com
# 2. Builds Ushahidi
# 3. Runs Selenium Tests
# 4. Runs PHPUnit Tests
# 5. Sends an email with results to the dev team
#
# SERVER REQUIREMENTS/PREREQUISITES
# 1. Git
# 2. Selenium Server
# 3. PHPUnit
#
# EMAIL TO:
EMAIL="myemail@address.com"
#
# EMAIL SUBJECT:
SUBJECT="Git Commit & Test Results"
#
# TEMP FILE
EMAILMESSAGE="/tmp/emailmessage.txt"
#
# LOCAL GIT REPO LOCATION
REPO="/home/repo/"
#
# SELENIUM SERVER LOCATION
# This is the location of the selenium-server.jar file
SELENIUM="/home/selenium-server.jar"
# Location of the base test location
TESTS_HOME="http://trunk.ushahidi.com/"
# Path of the test files
TESTS_DIR="/home/.sites/ushahidi/web/tests/selenium"
# Path of where to place logs
TESTS_LOG="/home/.sites/ushahidi/web/selenium/logs"
#
TESTS_PHPUNIT="/home/.sites/ushahidi/web/tests/phpunit"


cd $REPO/

function changes_in_git_repo () {
  latestlocal=`git rev-parse HEAD`;
  # echo $latestlocal
  gitrepourl=`git remote -v | grep fetch | awk '{print $2}'`;
  # echo $gitrepourl;

  latestremote=`git ls-remote --heads $gitrepourl master| awk '{print $1}'`;
  # echo $latestremote;

  if [ $latestlocal != $latestremote ]
  then
    echo "true"
  else
    echo "false"
  fi
}

# echo $(changes_in_git_repo)

if [[ $(changes_in_git_repo) == true ]]
then
  echo "Changes since last build!";
        
  # THERE'S NEW STUFF IN GIT ... PULL IT!
  git pull origin master >/dev/null 2>&1

  # GET LAST 5 COMMITS
  COMMITS=$(git log --pretty=format:'- %h was %an, %ar %n  message: %s' -n 5)

  # UPDATE THE INSTALLATION
  sh /home/reset/reset.sh >/dev/null 2>&1
  sh /home/reset/reset_haiti.sh >/dev/null 2>&1
  echo "UPDATED TRUNK SITE"

  # RUN TESTS
  echo "Repo Updated : $(date)"> $EMAILMESSAGE
  echo " ">> $EMAILMESSAGE
  echo "~~~~~~~~~~~~~~~~~~~~~~~~">> $EMAILMESSAGE
  echo "Last 5 Commit Messages: ">> $EMAILMESSAGE
  echo "~~~~~~~~~~~~~~~~~~~~~~~~">> $EMAILMESSAGE
  echo "$COMMITS">> $EMAILMESSAGE
  echo " ">> $EMAILMESSAGE
  echo " ">> $EMAILMESSAGE
  echo "~~~~~~~~~~~~~~~~~~~~~~~~">> $EMAILMESSAGE
  echo "Selenium Tests: ">> $EMAILMESSAGE
  echo "~~~~~~~~~~~~~~~~~~~~~~~~">> $EMAILMESSAGE

  # TEST LINKS FOR EMAIL
  cd $TESTS_DIR/
  echo "Running Selenium Tests..."
  for file in *.html
  do
    PASS="Received posted results"
    FAIL="Tests failed"
    PASSFAIL="[ ? ]"
    RESULTS=$(export DISPLAY=":99" && java -jar $SELENIUM -htmlsuite *firefox http://trunk.ushahidi.com/ $TESTS_DIR/$file $TESTS_LOG/$file 2>&1)
    
    if echo "$RESULTS" | grep -q "$PASS"
    then
      PASSFAIL="[PASS]"
    fi
    
    if echo "$RESULTS" | grep -q "$FAIL"
    then
      PASSFAIL="[FAIL]"
    fi
    
    echo "$PASSFAIL - http://trunk.ushahidi.com/selenium/logs/$file" >>$EMAILMESSAGE
  done
  
  echo "Running PHPUnit Tests..."
  echo " ">> $EMAILMESSAGE
  echo " ">> $EMAILMESSAGE
  echo "~~~~~~~~~~~~~~~~~~~~~~~~">> $EMAILMESSAGE
  echo "PHPUnit Tests: ">> $EMAILMESSAGE
  echo "~~~~~~~~~~~~~~~~~~~~~~~~">> $EMAILMESSAGE
  cd $TESTS_PHPUNIT/
  PHPUNIT=$(phpunit classes 2>&1)
  echo "$PHPUNIT" >>$EMAILMESSAGE

  # send an email using /bin/mail
  /bin/mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE

else  
  echo "No changes since last build";

fi
