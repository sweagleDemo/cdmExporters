#!/usr/local/bin/bash
clear #start by cleaning the terminal window
echo $BASH_VERSION

function checkJqInstalled() {
	response=$(jq --version)
	if [[ $response == "jq*" ]]; then
		echo -e "jq version is $response"
	else
		echo -e "\e[41m!!error\e[49m install jq with the command \"homebrew jq install\""
	fi
}

function askQuestionToContinue() {
	read -p "${1} press y to continue or n to exit : " cnt
	if [[ $cnt != "y" ]]; then 
		echo -e "exit script upon user request \n"
		exit
	fi
}

function compareResultNotContain() {
  	if [[ "$1" != *"$2"* ]]; then  #this checks that $2 is included in $1
  		#echo -e "response ok - continue to next step "
  		: #response ok, continue
	else
		echo -e $response
	    echo -e "\e[41m!!FAILURE!!\e[49m - the response contains $2\n"
		exit
	fi
}

function loopUntilRequestStateComplete() {
    for i in `eval echo {0..${1}}` 
        do
            response=$(curl -s "${sncUrl}/api/sn_cdm/response/${requestId}" --request GET --header 'Accept:application/json' --user ${sncUser}:${sncPwd})
			outputState=$(echo $response | jq --raw-output '.result.state')
            echo "after $(( ${i} )) seconds status $outputState"
            if [[ "${outputState}" == *"completed"* || "${outputState}" == *"error"*  ]];
            then
                echo -e "request $requestId has state completed"
                break
            fi
            sleep 1
        done

        #check validations finished after exit the loop. If not, throw error
        if [[ "${outputState}" != *"completed"* ]];
            then
                echo -e "\e[41m!!error\e[49m: the requestId $requestId did not finish successfully"
                outputFull=$(echo $response | jq '.result')
                echo $outputFull; echo " ";
                exit
        fi
}

function checkCLArgumentAppname() {
	#check if the application name was provided as input. If not ask for the application name
	
	if [ ! -z $1 ] 
	then 
	    appName=$1 
	else
	    read -p "enter the application name: " appName
	fi
	echo -e "this script will run with appName \e[92m${appName}\e[39m"

}

function checkCLArgumentDeployableName() {
	#check if the deployable name was provided as input. If not ask for it	
	if [ ! -z $1 ] 
	then 
	    deployableName=$1 
	else
	    read -p "enter the deployable name: " deployableName
	fi
	echo -e "this script will run with deployableName \e[92m${deployableName}\e[39m"
}

function checkCLArgumentFormat() {
	#check if the deployable name was provided as input. If not ask for it	
	if [ ! -z $1 ] 
	then 
	    expFormat=$1 
	else
	    read -p "enter the format in which the data will be exported yaml,json,prop,ini,xml: " expFormat; echo " "
	fi
	echo -e "this script will run with expFormat \e[92m${expFormat}\e[39m"
}

function checkCLArgumentExporter() {
	#check if the deployable name was provided as input. If not ask for it	
	if [ ! -z $1 ] 
	then 
	    expName=$1 
	else
	    read -p "enter the exporterName to be used for the export: " expName; echo " "
	fi
	echo -e "this script will run with exporter \e[92m${expName}\e[39m"
}

function checkCLArgumentValueKeyName() {
	#check if the deployable name was provided as input. If not ask for it	
	if [ ! -z $1 ] 
	then 
	    argValueKeyName=$1 
	else
	    read -p "enter the value for the argument to be used for the export: " argValueKeyName; echo " "
	fi
	echo -e "this script will run with argument value \e[92m${argValueKeyName}\e[39m"
}

function checkCLArgumentValueNodeName() {
	#check if the deployable name was provided as input. If not ask for it	
	if [ ! -z $1 ] 
	then 
	    argValueNodeName=$1 
	else
	    read -p "enter the value for the argument to be used for the export: " argValueNodeName; echo " "
	fi
	echo -e "this script will run with argument value \e[92m${argValueNodeName}\e[39m"
}

function checkSettings() {
	#first read the URL and connectionDetails from the mySettings.conf file. If the file does not exist, exit with error
	if [ -e mySettings.conf ]; then
	    source mySettings.conf
	    #check if the url ends with a /
	    if [[ ${sncUrl} == */ ]]; then 
		    echo -e "this script will run against \e[92m${sncUrl}\e[39m with user \e[92m${sncUser}\e[39m \n"
		    if [[ ${sncUrl} != *"http://localhost:8080"* ]]; then
		    	askQuestionToContinue "Is this the instance you want to use?"
		    fi
		else
			echo -e "\e[41m${sncUrl} is not a valid url\e[49m - it must end with / please update the mySettings.conf content"
			exit
		fi
	else
		echo -e "\e[41m!!error - the mySettings file is required in the local folder with connection details and credentials\e[49m \n"
		echo -e "exit script \n"
		exit
	fi
}

function checkJq() {
	response=$(jq --version)
	compareResultNotContain $response "command not found"
}



#==========
#   MAIN
#==========

clear #start by cleaning the terminal window
curDTstamp="$(date -u +%s)" 

checkSettings
checkJq

#== collect settings
checkCLArgumentAppname $1
checkCLArgumentDeployableName $2
checkCLArgumentFormat $3
checkCLArgumentExporter $4
checkCLArgumentValueKeyName $5
checkCLArgumentValueNodeName $6
#appName="app-demo-1615796194"
#deployableName="PRD"
expName="${expName}&args=%7B%22keyName%22%3A%22${argValueKeyName}%22%2C%22nodeName%22%3A%22${argValueNodeName}%22%7D"

#== run the exporter and collect the response
echo "${sncUrl}/api/sn_cdm/request/export?deployableName=${deployableName}&exporterName=${expName}&appName=${appName}&dataFormat=json" --request POST --header 'Accept:application/json' --user ${sncUser}:${sncPwd}

echo " ";echo -e "the snapshot content of the \e[92m$deployableName\e[39m deployable for application \e[92m${appName}\e[39m will be downloaded using the exporter \e[92m${expName}\e[39m in \e[92m${expFormat}\e[39m "
#echo "${sncUrl}/api/sn_cdm/request/export?deployableName=${deployableName}&exporterName=${expName}&appName=${appName}&dataFormat=${expFormat}${sncUrl}/api/sn_cdm/request/export?deployableName=${deployableName}&exporterName=${expName}&appName=${appName}&dataFormat=${expFormat} --request POST --header Accept:application/json --user ${sncUser}:${sncPwd}"
response=$(curl -s "${sncUrl}/api/sn_cdm/request/export?deployableName=${deployableName}&exporterName=${expName}&appName=${appName}&dataFormat=${expFormat}" --request POST --header 'Accept:application/json' --user ${sncUser}:${sncPwd})

#== check if the exporter worked properly.
requestId=$(echo $response | jq --raw-output '.result.request_id')

#== check there is a valid requestId
if [[ $requestId == "null" ]]; then
	echo -e "\e[41m!!error\e[49m - no request_id received"
	echo -e "$response"; echo " ";
	exit
else 
	echo -e "the snapshot content of the \e[92m${requestId}\e[39m "
fi

#== loop until result.state=completed
loopUntilRequestStateComplete "30"

#== get the response
sleep 1
response=$(curl -s "${sncUrl}/api/sn_cdm/response/${requestId}" --request GET --header 'Accept:application/json' --user ${sncUser}:${sncPwd})
outputState=$(echo $response | jq --raw-output '.result.output.state')
if [[ $outputState == "failure" ]]; then
	echo -e "\e[41m!!error\e[49m - output state = failure"
	echo $response | jq .result; echo " ";
	resultError=$(echo $response | jq .result.output.errors)
	if [[ "${resultError}" == *"is not found"* ]];
        then
            echo " "; echo -e "execute the following commands as script include in the \e[33msn_cdm\e[39m scope to create the exporter ${expName}:"; echo " "
			echo -e "\e[33m$(loadDemoData_createExporterScript)\e[39m"; echo " "
            break
    fi
	exit
else
	#== print the result on screen
	if [[ $expStatus != "failure" ]]; then
		echo " "; echo -e "== the response metadata : "
		#echo $response
		
		expExecId=$(echo $response | jq .result.request_id)
		expStatus=$(echo $response | jq .result.state)
		echo " "; echo -e "the exporter execution id is $expExecId and finished with status $expStatus."

		echo " "; echo -e "== the pretty print response  is : "
		if [[ $expFormat == "ini" ]]; then
			echo $response | jq .result.output.exporter_result > exportData.ini
			cat exportData.ini
		fi
		if [[ $expFormat == "json" ]]; then
			echo $response | jq .result.output.exporter_result
			echo $response | jq .result.output.exporter_result > exportData.json
			cat exportData.json
		fi
		if [[ $expFormat == "xml" ]]; then
			echo $response | jq .result.output.exporter_result > exportData.xml
			cat exportData.xml
		fi
		if [[ $expFormat == "yaml" ]]; then
			echo $response | jq .result.output.exporter_result > exportData.yaml
			cat exportData.yaml
		fi
	fi
fi
