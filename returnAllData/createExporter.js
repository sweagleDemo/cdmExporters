var exporterName="returnAllData";
var exporterDescription="returns the full snapshot";
var exporterManager = new CdmExporterManager();

//create exporter
var exporter = exporterManager.createNewExporter(exporterName,exporterDescription);
var exporterId = exporter.getUniqueValue();
​
//create exporter version
var script = "(function (logger, primaryDeployable, additionalDeployables, args, output) {\r\n\toutput.result = new CdmQuery().snapshotId(primaryDeployable.snapshot_id).query().followIncludes(true).decryptPassword(true).useCache(true).getTree(true);\r\n\toutput.errors= [];\r\n\toutput.state = \"success\";\r\n\treturn output;\r\n})(logger, primaryDeployable, additionalDeployables, args, output);";
var exporterVersion = exporterManager.createExporterVersion(exporterId, "info", "description", "", script);
var exporterVersionId = exporterVersion.getUniqueValue();
​
//publish exporter
exporterManager.publishExporterVersion(exporterVersionId);