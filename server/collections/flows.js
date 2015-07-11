Flows.allow({
	insert: function (userId, doc) {
		return Flows.userCanInsert(userId, doc);
	},

	update: function (userId, doc, fields, modifier) {
		return Flows.userCanUpdate(userId, doc);
	},

	remove: function (userId, doc) {
		return Flows.userCanRemove(userId, doc);
	}
});

Flows.before.insert(function(userId, doc) {
	doc.createdAt = new Date();
	doc.createdBy = userId;
	doc.modifiedAt = doc.createdAt;
	doc.modifiedBy = doc.createdBy;

	
	if(!doc.owner_id) doc.owner_id = userId;
});

Flows.before.update(function(userId, doc, fieldNames, modifier, options) {
	modifier.$set = modifier.$set || {};
	modifier.$set.modifiedAt = new Date();
	modifier.$set.modifiedBy = userId;

	
});

Flows.before.remove(function(userId, doc) {
	
});

Flows.after.insert(function(userId, doc) {
	
});

Flows.after.update(function(userId, doc, fieldNames, modifier, options) {
	
});

Flows.after.remove(function(userId, doc) {
	
});
