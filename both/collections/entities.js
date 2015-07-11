this.Entities = new Mongo.Collection("entities");

this.Entities.userCanInsert = function(userId, doc) {
	return Users.isInRoles(userId, ["drawer"]);
}

this.Entities.userCanUpdate = function(userId, doc) {
	return userId && Users.isInRoles(userId, ["drawer"]);
}

this.Entities.userCanRemove = function(userId, doc) {
	return userId && Users.isInRoles(userId, ["drawer"]);
}
