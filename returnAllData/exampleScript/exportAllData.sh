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

function loadDemoData_createExporterScript() {
cat <<EOF
var exporter = new CdmExporterManager().createNewExporter("${expName}");
var exporterId = CdmUtil.getSysId(exporter);
var sourceVersionId = null;
var logLevel = "none";
var description = null;
var comments = null;
var script = "(function (logger, primaryDeployable, additionalDeployables, args, output) {output.result = new CdmQuery().snapshotId(primaryDeployable.snapshot_id).query().decryptPassword(true).getTree(true);output.errors= [];output.state = \"success\";return output;})(logger, primaryDeployable, additionalDeployables, args, output);";
var exporterVersion = new CdmExporterManager().createExporterVersion(exporterId, logLevel, description, comments, script);
new CdmExporterManager().publishExporterVersion(CdmUtil.getSysId(exporterVersion));
EOF
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
            echo "after $(( ${i} )) seconds"
            response=$(curl -s "${sncUrl}/api/sn_cdm/response/${requestId}" --request GET --header 'Accept:application/json' --user ${sncUser}:${sncPwd})
			outputState=$(echo $response | jq --raw-output '.result.state')
            if [[ "${outputState}" == *"completed"* ]];
            then
                echo -e "request $requestId has state completed"
                break
            fi
            sleep 1
        done

        #check validations finished after exit the loop. If not, throw error
        if [[ "${outputState}" != *"completed"* ]];
            then
                echo -e "\e[41m!!error\e[49m: the requestId $requestId did not finish in timely manner (max ${1} seconds)"
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
#appName="app-demo-1615796194"
#deployableName="PRD"
#expName="exp05-all"

#== run the exporter and collect the response
echo "${sncUrl}/api/sn_cdm/request/export?deployableName=${deployableName}&exporterName=${expName}&appName=${appName}&dataFormat=json" --request POST --header 'Accept:application/json' --user ${sncUser}:${sncPwd}

echo " ";echo -e "the snapshot content of the \e[92m$deployableName\e[39m deployable for application \e[92m${appName}\e[39m will be downloaded using the exporter \e[92m${expName}\e[39m in \e[92m${expFormat}\e[39m "
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
		echo " "; echo -e "== the response metadata is : "
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
			#cat exportData.json
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
