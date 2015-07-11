Entities.allow({
	insert: function (userId, doc) {
		return Entities.userCanInsert(userId, doc);
	},

	update: function (userId, doc, fields, modifier) {
		return Entities.userCanUpdate(userId, doc);
	},

	remove: function (userId, doc) {
		return Entities.userCanRemove(userId, doc);
	}
});

Entities.before.insert(function(userId, doc) {
	doc.createdAt = new Date();
	doc.createdBy = userId;
	doc.modifiedAt = doc.createdAt;
	doc.modifiedBy = doc.createdBy;

	
	if(!doc.owner_id) doc.owner_id = userId;
});

Entities.before.update(function(userId, doc, fieldNames, modifier, options) {
	modifier.$set = modifier.$set || {};
	modifier.$set.modifiedAt = new Date();
	modifier.$set.modifiedBy = userId;

	
});

Entities.before.remove(function(userId, doc) {
	
});

Entities.after.insert(function(userId, doc) {
	
});

Entities.after.update(function(userId, doc, fieldNames, modifier, options) {
	
});

Entities.after.remove(function(userId, doc) {
	
});
