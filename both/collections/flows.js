this.Flows = new Mongo.Collection("flows");

this.Flows.userCanInsert = function(userId, doc) {
	return Users.isInRoles(userId, ["executer"]);
}

this.Flows.userCanUpdate = function(userId, doc) {
	return userId && Users.isInRoles(userId, ["executer"]);
}

this.Flows.userCanRemove = function(userId, doc) {
	return userId && Users.isInRoles(userId, ["executer"]);
}
