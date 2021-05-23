var exporterManager = new CdmExporterManager();

//create exporter
var exporter = exporterManager.createNewExporter("returnNodeTree","returns the node subtree from the snapshot");
var exporterId = exporter.getUniqueValue();
​
//create exporter version
var script = "(function (logger, primaryDeployable, additionalDeployables, args, output) {\r\n    \/\/Get Snapshot from the primary deployable\r\n    var snapshotId = primaryDeployable.snapshot_id;\r\n    \/\/var filterNodeName=\"logonService-V2.1\";\r\n    var filterNodeName = args.nodeName;\r\n    gs.info(\"snapshotId is \" + snapshotId);\u200B\r\n    \/\/internal variables\r\n    var nameFoundCount = 0; \/\/tracks how often the nodeName was found in the snapshot\r\n    \u200B\r\n    var cdmQ = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapshotId).followIncludes(true).decryptPassword(true).useCache(true).query();\u200B\r\n    while (node = cdmQ.next()) {\r\n        if (cdmQ.getValue(\"sys_class_name\") == \"sg_cdm_node_component\" | cdmQ.getValue(\"sys_class_name\") == \"sg_cdm_node_linked\") { \/\/only look for nodes with that name       \r\n            if (node.getValue(\"name\") === filterNodeName) {\r\n                nameFoundCount++;\r\n                nodePath = cdmQ.getValue(\"node_path\"); \/\/this returns the encoded path\r\n                gs.info(\"filterNodeName \" + cdmQ.getValue(\"name\") + \" found on encoded path \" + nodePath);\u200B\r\n                output.result = new sn_cmdb_ci_class.CdmQuery().snapshotId(snapshotId).encodedPath(nodePath).decryptPassword(true).followIncludes(true).substituteVariable(true).useCache(true).query().getTree(true);\r\n                gs.info(JSON.stringify(output.result));\r\n            }\r\n        }\r\n    }\u200B\r\n    gs.info(filterNodeName + \" was found \" + nameFoundCount + \" times\");\r\n    if (typeof output.result === \'undefined\') {\r\n        gs.info(\"no output.result found\");\r\n        output.result = [];\r\n    } else {\r\n        gs.info(\"output.result found \" + typeof (output.result));\r\n    }\u200B\r\n    \/\/output.result=[];\r\n    output.errors = [];\r\n    output.state = \"success\";\r\n\r\n    return output;\r\n})(logger, primaryDeployable, additionalDeployables, args, output);\r\n";
var exporterVersion = exporterManager.createExporterVersion(exporterId, "info", "description", "", script);
var exporterVersionId = exporterVersion.getUniqueValue();
​
//create exporter argument
var exporterArgument = exporterManager.createExporterArgument(exporterVersionId, "nodeName", null, false);

//publish exporter
exporterManager.publishExporterVersion(exporterVersionId);