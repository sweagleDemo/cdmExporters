 /**
    creator     Benny Van de Sompele, ServiceNow    
 **/
 
 (function (logger, primaryDeployable, additionalDeployables, args, output) {
   var snapshotId = primaryDeployable.snapshot_id;
    //gs.info("snapshotId is " + snapshotId );
    
    //check if a proper keyName was provided in the input argument. If not, exit with state error
    if (gs.nil(args.keyName) || gs.nil(args.nodeName)) { //first check if any arg value is not null as you cannot check length or trim a null object
        gs.info("!!error: empty argument value: keyName [" + args.keyName + "]");
        output.errors = [];
        output.state = "failure";
        return output;       
    } else { //next check the length of the trimmed value. If 0 it means only spaces were provided as input
        var filterKeyName = args.keyName.trim(); //trim spaces from input
        var filterNodeName = args.nodeName.trim();
        gs.info("nodeName value is " + filterNodeName + " for keyName " + filterKeyName);
        if (filterKeyName.length === 0 || filterNodeName.length === 0) {         
            output.result={};
            if (filterKeyName.length === 0) {errorMsg="provided keyName argument is empty or contains only spaces - check input values "};
            if (filterNodeName.length === 0) {errorMsg+="provided nodeName argument is empty or contains only spaces - check input values "};
            output.errors = {"error":errorMsg};
            output.state = "failure";  
            gs.info(JSON.stringify(output.errors));
            return output;         
        }
      }​

    //internal variables to tracks how often the object was found in the snapshot
    var keyFoundCount = 0; 
    var nodeFoundCount = 0; 
    ​
    //loop through the snapshot datamodel and find the requested nodeName
    var cdmQ = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapshotId).followIncludes(true).decryptPassword(true).useCache(true).query();​
    while (node = cdmQ.next()) {
        if (cdmQ.getValue("sys_class_name") != "sg_cdm_node_cdi" ) { //look for any type of node except CDIs       
            if (node.getValue("name") === filterNodeName) {
              nodeFoundCount++;
              var encodedNodePath = sn_cmdb_ci_class.CdmUtil.getNodePath(node);
              gs.info("filterNodeName " + cdmQ.getValue("name") + " found on path " + encodedNodePath);
              
              //if the nodeName has been found, run the CdmQuery for only that path and check if we find the keyName 
              var cdmQnode = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapshotId).encodedPath(encodedNodePath).followIncludes(true).decryptPassword(true).useCache(true).query();​
              
              while (key = cdmQnode.next()) {
                if (cdmQnode.getValue("sys_class_name") == "sg_cdm_node_cdi" && cdmQnode.getValue("name") == filterKeyName) { //only compare the keyName for object with the CDI class name
                  //gs.info("scanning " + cdmQnode.getValue("name") + " with class " + cdmQnode.getValue("sys_class_name"));
                  //this exporter expects a unique keyName in the snapshot in order to work correctly. If found more than once, exit with error
                  if (keyFoundCount == 0) { 
                      keyFoundCount++;
                      var keyValue = sn_cmdb_ci_class.CdmUtil.getEffectiveValue(key);
                      output.result={"value":keyValue};
                      output.errors = {};
                      output.state = "success";  
                      //gs.info(JSON.stringify(output.result));
                  } else {
                      output.result={};
                      errorMsg=filterKeyName + " was found more than once at or within the node " + filterNodeName;
                      output.errors = {"error":errorMsg};
                      output.state = "failure";  
                      gs.info(JSON.stringify(output.errors));
                      return output; 
                  }
                }
              }
            }
        }​
    }
    //in case the keyName was not found set the result to an empty JSON and set the state to failure.
    gs.info("nodes found " + nodeFoundCount);
    if (nodeFoundCount === 0) {
        output.state="failure";
        output.result = {}; //set empty object for output.result
        errorMsg="provided nodeName ["+filterNodeName + "] was not found in the snapshot";
        output.errors = {"error":errorMsg};
        gs.info(JSON.stringify(output.errors));
        return output;
    }​

    if (keyFoundCount === 0) {
        output.state="failure";
        output.result = {}; //set empty object for output.result
        errorMsg="provided keyName [" + filterKeyName + "] was not found at or within nodeName [" + filterNodeName + "] in the snapshot";
        output.errors = {"error":errorMsg};
        gs.info(JSON.stringify(output.errors));
        return output;
    }

    //in case the keyName was found once, return a normal response.
   return output;
  
   
 
 })(logger, primaryDeployable, additionalDeployables, args, output);