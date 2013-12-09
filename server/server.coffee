QuestionList = new Meteor.Collection("questionlist")
ResponseList = new Meteor.Collection("responselist")

`Meteor.publish("userData", function () {
	return Meteor.users.find({_id: this.userId},
	   {fields: {'uplist': 1, 'downlist':1}});
});`

Meteor.methods {
	reset: ()->
		QuestionList.remove {}
	resetUsers:()->
		Meteor.users.remove {}
	'upvote': (userId, qid) ->
		Meteor.users.update(
			{_id:userId},{$addToSet: {uplist:qid}}
		)
	'upvoteDel': (userId, qid) ->
		Meteor.users.update(
			{_id:userId},{$pull: {uplist:qid}}
		)
	'downvote': (userId, qid) ->
		Meteor.users.update(
			{_id:userId},{$addToSet: {downlist:qid}}
		)
	'downvoteDel': (userId, qid) ->
		Meteor.users.update(
			{_id:userId},{$pull: {downlist:qid}}
		)
}

`Accounts.onCreateUser(function(options, user) {
	user.uplist = [];
	user.downlist = [];
	return user;
});`