(function (logger, primaryDeployable, additionalDeployables, args, output) {

snapId=primaryDeployable.snapshot_id;
//var filterNodeName="logonService-V2.1";
var filterNodeName=args.nodeName;
gs.info("snapshotId is "+ snapId);

//internal variables
nbrFound=0; //tracks how often the nodeName was found in the snapshot

var cdmQ = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapId).followIncludes(true).decryptPassword(true).useCache(true).query();

while (node = cdmQ.next()) {
    if(cdmQ.getValue("sys_class_name") == "sg_cdm_node_component" | cdmQ.getValue("sys_class_name") == "sg_cdm_node_linked"){ //only look for nodes with that name       
        if (node.getValue("name") === filterNodeName ) {
            nbrFound++;
            nodePath = cdmQ.getValue("node_path"); //this returns the encoded path
            gs.info("filterNodeName "+ cdmQ.getValue("name")+" found on encoded path "+nodePath);

            output.result = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapId).encodedPath(nodePath).decryptPassword(true).followIncludes(true).substituteVariable(true).useCache(true).query().getTree(true);
            gs.info(JSON.stringify(output.result)); 
        }
    }
}

gs.info(filterNodeName+" was found " +nbrFound + " times");
if (typeof output.result === 'undefined'){
    gs.info("no output.result found");
    output.result=[];
} else {
    gs.info("output.result found " + typeof(output.result) );
}

//output.result=[];
output.errors= [];
output.state = "success";
    
return output;
})(logger, primaryDeployable, additionalDeployables, args, output);