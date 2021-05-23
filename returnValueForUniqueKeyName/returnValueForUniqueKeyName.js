 /**
     @param logger: Logger to log (info, debug, error, warning) messages 
     @param primaryDeployable: primary deployable object with the following structure
         {'app_name': 'app1', 'deployable_name': 'deployable1', 'snapshot_name': 'snapshot1', 'snapshot_id': 'f707bd813bf7'}
     @param additionalDeployables: array of additional deployables (in the same order as submitted) with the following structure
     [
         {'app_name': 'app1', 'deployable_name': 'deployable2', 'snapshot_name': 'snapshot1', 'snapshot_id': 'f708bddsdsff'},
         {'app_name': 'app1', 'deployable_name': 'deployable3', 'snapshot_name': 'snapshot1', 'snapshot_id': 'f708dfdbddsd'}
     ]
     @param args: map of arguments where argument name is the key
     @param output: object to store output with the following structure
     output: {
       errors: [],
       warnings: []
       state 'success' | 'failure',
       result: 'exported data'
       disableCaching: false
     }
 **/
 (function (logger, primaryDeployable, additionalDeployables, args, output) {
 
    var snapshotId = primaryDeployable.snapshot_id;
    gs.info("snapshotId is " + snapshotId );
    
    //check if a proper keyName was provided in the input argument. If not, exit with state error
    if (gs.nil(args.keyName)) { //first check keyName is not null as you cannot check length or trim a null object
        gs.info("!!error: empty keyName provided");
        output.errors = [];
        output.state = "failure";
        return output;       
    } else { //next check the length of the trimmed value. If 0 it means only spaces were provided as input
        var filterKeyName = args.keyName.trim(); //trim spaces from input
        if (filterKeyName.length === 0) {         
            gs.info("!!error: keyName only contain spaces");
            output.errors = [];
            output.state = "failure";  
            return output;         
        }
    }​

    //internal variables
    var keyFoundCount = 0; //tracks how often the keyName was found in the snapshot
    ​
    //loop through the snapshot datamodel and find the requested keyName
    var cdmQ = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapshotId).followIncludes(true).decryptPassword(true).useCache(true).query();​
    while (node = cdmQ.next()) {
        if (cdmQ.getValue("sys_class_name") == "sg_cdm_node_cdi" ) { //only look for CDIs       
            //if the keyName has been found, run the CdmQuery for only that path and store result in output.result 
            if (node.getValue("name") === filterKeyName) {
                keyFoundCount++;
                //this exporter expects a unique keyName in the snapshot in order to work correctly. If found more than once, exit with error
                if (keyFoundCount > 1) { 
                    gs.info("!! error: [" + filterKeyName + "]" + " was found " + keyFoundCount + " times");
                    output.result={};
                    errorMsg=filterKeyName + " was found multiple times";
                    output.errors = {"error":errorMsg};
                    output.state = "failure";  
                    return output; 
                }
                var filterKeyValue= sn_cmdb_ci_class.CdmUtil.getEffectiveValue(node);              
                gs.info("filterKeyName " + cdmQ.getValue("name") + " found with value " + filterKeyValue);
                
                output.result = {"keyValue":filterKeyValue};
                gs.info(JSON.stringify(output.result));
            }
        }
    }​

    //in case the keyName was not found set the result to an empty JSON and set the state to failure.
    if (typeof output.result === 'undefined') {
        output.state="failure";
        output.result = {}; //set empty object for output.result
        errorMsg=filterKeyName + " was not found in the snapshot";
        output.errors = {"error":errorMsg};
        return output;
    }​

    //in case the keyName was found once, return a normal response.

   //output.result = {};
   output.state = 'success';
   return output;
   
 
 })(logger, primaryDeployable, additionalDeployables, args, output);