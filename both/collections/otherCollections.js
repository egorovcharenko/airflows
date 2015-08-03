this.FlowsIns = new Mongo.Collection("flowsIns");
this.TasksIns = new Mongo.Collection("tasksIns");
this.Roles = new Mongo.Collection("accountRoles");
this.AccountsColl = new Mongo.Collection("accounts");
this.Invitations = new Mongo.Collection("invitations");
this.EntitiesIns = new Mongo.Collection("entitiesIns");

this.EntitiesIns.before.insert(function(userId, doc) {
	doc.createdAt = new Date();
	doc.createdBy = userId;
	doc.modifiedAt = doc.createdAt;
	doc.modifiedBy = doc.createdBy;
	if(!doc.owner_id) doc.owner_id = userId;
});

this.EntitiesIns.before.update(function(userId, doc, fieldNames, modifier, options) {
	modifier.$set = modifier.$set || {};
	modifier.$set.modifiedAt = new Date();
	modifier.$set.modifiedBy = userId;
});
