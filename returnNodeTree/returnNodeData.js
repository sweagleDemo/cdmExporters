(function (logger, primaryDeployable, additionalDeployables, args, output) {
    //Get Snapshot from the primary deployable
    var snapshotId = primaryDeployable.snapshot_id;
    gs.info("snapshotId is " + snapshotId );
    
    //check if a proper nodeName was provided in the input argument. If not, exit with state error
    if (gs.nil(args.nodeName)) { //first check nodeName is not null as you cannot check length or trim a null object
        gs.info("!!error: empty nodeName provided");
        output.errors = [];
        output.state = "failure";
        return output;       
    } else { //next check the length of the trimmed value. If 0 it means only spaces were provided as input
        var filterNodeName = args.nodeName.trim(); //trim spaces from input
        if (filterNodeName.length === 0) {         
            gs.info("!!error: nodeName only contain spaces");
            output.errors = [];
            output.state = "failure";  
            return output;         
        }
    }​
    
    //internal variables
    var nameFoundCount = 0; //tracks how often the nodeName was found in the snapshot
    ​
    //loop through the snapshot datamodel and find the requested nodeName
    var cdmQ = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapshotId).followIncludes(true).decryptPassword(true).useCache(true).query();​
    while (node = cdmQ.next()) {
        if (cdmQ.getValue("sys_class_name") == "sg_cdm_node_component" | cdmQ.getValue("sys_class_name") == "sg_cdm_node_linked") { //only look for nodes with that name       
            //if the nodeName has been found, run the CdmQuery for only that path and store result in output.result 
            if (node.getValue("name") === filterNodeName) {
                nameFoundCount++;
                //this exporter expects a unique nodeName in the snapshot in order to work correctly. If found more than once, exit with error
                if (nameFoundCount > 1) { 
                    gs.info("!! error: [" + filterNodeName + "]" + " was found " + nameFoundCount + " times");
                    output.result={};
                    errorMsg=filterNodeName + " was found multiple times";
                    output.errors = {"error":errorMsg};
                    output.state = "failure";  
                    return output; 
                }
                var encodedNodePath = cdmQ.getValue("node_path"); //this returns the encoded path which can be used in CdmQuery to get the subtree for that path
                //nodePath = sn_cmdb_ci_class.CdmUtil.nodePath(node);
                gs.info("filterNodeName " + cdmQ.getValue("name") + " found on encoded path " + encodedNodePath);
                
                //TODO : the next call does NOT work when the nodeName is both an overwrite and an include --> check how to solve this !!​
                output.result = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapshotId).encodedPath(encodedNodePath).decryptPassword(true).followIncludes(true).substituteVariable(true).useCache(true).query().getTree(true);
                gs.info(JSON.stringify(output.result));
            }
        }
    }​

    //in case the nodeName was not found set the result to an empty JSON and set the state to error.
    if (typeof output.result === 'undefined') {
        output.state="error";
        output.result = {}; //set empty object for output.result
        errorMsg=filterNodeName + " was not found in the snapshot";
        output.errors = {"error":errorMsg};
        return output;
    }​

    //in case the nodeName was found once, return a normal response.
    output.errors = [];
    output.state = "success";
    return output;
})(logger, primaryDeployable, additionalDeployables, args, output);
