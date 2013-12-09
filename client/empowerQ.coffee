@QuestionList = new Meteor.Collection("questionlist")
@ResponseList = new Meteor.Collection("responselist")
Meteor.subscribe('userData')

Session.set('showSearch', true)
Session.set('showResults', true)
Session.set('showNewQuestion', false)
Session.set('showDetails', false)
Session.set('thisQuestion', null)
Session.set('tagSearch', null)
Session.set('sortBy',{date:-1})

Deps.autorun ->
	if Session.equals('showResults', true)
		Session.set('showNewQuestion', false)
		Session.set('showDetails', false)
	if Session.equals('showNewQuestion', true)
		Session.set('showResults', false)
		Session.set('showDetails', false)
	if Session.equals('showDetails', true)
		Session.set('showResults', false)
		Session.set('showNewQuestion', false)
	
	if Meteor.user()
		Session.set('userId', Meteor.userId())
	else 
		Session.set('userId', null)

Template.navigation.showSearch = ->
	Session.equals('showSearch', true)

Template.navigation.showResults = ->
	Session.equals('showResults', true)

Template.navigation.showNewQuestion = ->
	Session.equals('showNewQuestion', true)

Template.navigation.showDetails = ->
	Session.equals('showDetails', true)

Template.navigation.events {
	'click #newQuestionBtn': (e,t) ->
		Session.set('showResults', false)
		Session.set('showNewQuestion', true)
}

Template.searchBox.events {
	'click #searchBtn, keyup #searchInput': (e,t) ->
		if (e.type is "click") or (e.type is "keyup" and e.which is 13)
			searchText = $('#searchInput').val().trim()
			# console.log(searchText)
			Session.set('searchText', searchText)
			Session.set('showDetails', false)
			Session.set('tagSearch', null)
			Session.set('showResults', true)
}

Template.searchResults.QuestionListHeader = ->
	if Session.equals('tagSearch', null)
		searchText = Session.get('searchText')
		if searchText and (searchText.length > 0)
			'> Search: ' + searchText
		else 
			''
	else 
		'> Tag: ' + Session.get('tagSearch').toString()


Template.searchResults.Match = ->
	sortBy = Session.get('sortBy')
	if Session.equals('tagSearch', null)
		searchText = Session.get('searchText')
		if searchText and (searchText.length > 0)
			searchKeyword = searchText.split(" ")
			searchRegex = new RegExp(searchText, 'i');
			# console.log searchKeyword
			QuestionList.find {
				$or: [
					{title: {$in: searchKeyword}} 
					{descr: searchRegex}
					{tags: {$in: searchKeyword}}
				]
			}, {sort: sortBy}
		else 
			QuestionList.find {}, {sort: sortBy}
	else 
		tagText = Session.get('tagSearch')
		QuestionList.find {
			tags: tagText
		}, {sort: sortBy}
	
Template.searchResults.answers = ->
	qid = this._id
	ResponseList.find({qid:qid}).count()

Template.searchResults.relatedQuestion = ->
	searchText = Session.get('searchText')
	if searchText and (searchText.length > 0)
		searchKeyword = searchText.split(" ")
		searchRegex = new RegExp(searchText, 'i');
		# console.log searchKeyword
		QuestionList.find({
			$or: [
				{title: {$in: searchKeyword}} 
				{descr: searchRegex}
				{tags: {$in: searchKeyword}}
			]
		}, {sort:{votes:-1}, limit:5})
	else 
		QuestionList.find({}, {sort:{votes:-1}, limit:5})

Template.searchResults.relatedTag = ->
	taglist = [];
	searchText = Session.get('searchText')
	if searchText and (searchText.length > 0)
		searchKeyword = searchText.split(" ")
		searchRegex = new RegExp(searchText, 'i');
		# console.log searchKeyword
		tmp = QuestionList.find({
			$or: [
				{title: {$in: searchKeyword}} 
				{descr: searchRegex}
				{tags: {$in: searchKeyword}}
			]
		}, {sort:{votes:-1}, fields:{tags:1},limit:5}).fetch()
		for x in tmp
			for y in x.tags 
				if y.toString() in taglist 
					continue
				else 
					taglist.push y.toString()
		taglist
	else 
		tmp = QuestionList.find({}, {sort:{votes:-1}, fields:{tags:1}, limit:5}).fetch()
		for x in tmp
			for y in x.tags 
				if y.toString() in taglist 
					continue
				else 
					taglist.push y.toString()
		taglist

Template.searchResults.sortPopular = ->
	if Session.get('sortBy').votes
		'active'

Template.searchResults.sortRecent = ->
	if Session.get('sortBy').date
		'active'

Template.searchResults.events {
	'click .qtitle': (e,t) ->
		# console.log this._id
		e.preventDefault()
		window.history.pushState("","","")
		Session.set('thisQuestion', this._id)
		Session.set('showResults',false)
		Session.set('showDetails', true)

	'click .relatedTag': (e,t) ->
		e.preventDefault()
		Session.set('tagSearch', this.toString())
		Session.set('showResults',true)

	'click #backToAll' : (e,t) ->
		e.preventDefault()
		Session.set('searchText', null)
		Session.set('tagSearch', null)

	'click #sortRecent': (e,t) ->
		e.preventDefault()
		Session.set('sortBy', {date:-1})

	'click #sortPopular': (e,t) ->
		e.preventDefault()
		Session.set('sortBy', {votes:-1})
}

Template.newQuestion.events {
	'click #askQuestionBtn': (e,t) ->
		console.log('askQuestionBtn clicked')
		title = $('#newQuestionTitle').val().trim().split(" ")
		descr = $('#newQuestionDescr').val().trim()
		tags = $('#newQuestionTags').val().trim().replace(/\s/g, "").split(",")
		# console.log (title + ': ' + descr + ". " + tags)
		QuestionList.insert {
			title: title
			descr: descr
			tags: tags
			votes: 0
			date: Date.parse(new Date())
		}
		$('#newQuestionTitle').val('')
		$('#newQuestionDescr').val('')
		$('#newQuestionTags').val('')
		Session.set 'showNewQuestion', false
		Session.set 'showResults', true

	'click #cancelNewQuestion': (e,t) ->
		$('#newQuestionTitle').val('')
		$('#newQuestionDescr').val('')
		$('#newQuestionTags').val('')
		Session.set 'showNewQuestion', false
		Session.set 'showResults', true
}

Template.details.backSearch = ->
	if Session.equals('tagSearch', null)
		searchText = Session.get('searchText')
		if searchText and (searchText.length > 0)
			'<< Search: ' + searchText
		else 
			'All Questions'
	else 
		'<< Tag: ' + Session.get('tagSearch')

Template.details.uplist = ->
	if Meteor.user() 
		uplist = Meteor.users.findOne({_id:Meteor.userId()}).uplist
		qid = this._id
		if uplist and (qid in uplist)
			'active-up'

Template.details.downlist = ->
	if Meteor.user() 
		downlist = Meteor.users.findOne({_id:Meteor.userId()}).downlist
		qid = this._id
		if downlist and (qid in downlist)
			'active-down'

Template.details.thisQuestion = ->
	id = Session.get('thisQuestion')
	QuestionList.findOne(_id: id)

Template.details.responses = ->
	qid = Session.get('thisQuestion')
	ResponseList.find({qid:qid},{sort:{votes:-1}})

Template.details.relatedQuestion = ->
	searchText = Session.get('searchText')
	if searchText and (searchText.length > 0)
		searchKeyword = searchText.split(" ")
		searchRegex = new RegExp(searchText, 'i');
		# console.log searchKeyword
		QuestionList.find({
			$or: [
				{title: {$in: searchKeyword}} 
				{descr: searchRegex}
				{tags: {$in: searchKeyword}}
			]
		}, {sort:{votes:-1}, limit:5})
	else 
		QuestionList.find({}, {sort:{votes:-1}, limit:5})

Template.details.relatedTag = ->
	taglist = [];
	searchText = Session.get('searchText')
	if searchText and (searchText.length > 0)
		searchKeyword = searchText.split(" ")
		searchRegex = new RegExp(searchText, 'i');
		# console.log searchKeyword
		tmp = QuestionList.find({
			$or: [
				{title: {$in: searchKeyword}} 
				{descr: searchRegex}
				{tags: {$in: searchKeyword}}
			]
		}, {sort:{votes:-1}, fields:{tags:1},limit:5}).fetch()
		for x in tmp
			for y in x.tags 
				if y.toString() in taglist 
					continue
				else 
					taglist.push y.toString()
		taglist
	else 
		tmp = QuestionList.find({}, {sort:{votes:-1}, fields:{tags:1}, limit:5}).fetch()
		for x in tmp
			for y in x.tags 
				if y.toString() in taglist 
					continue
				else 
					taglist.push y.toString()
		taglist

Template.details.events {
	'click #respondBtn, keyup #respondText': (e,t) ->
		if (e.type is 'click') or (e.type is 'keyup' and e.whitch is 13)
			respondText = $('#respondText').val().trim()
			qid = Session.get('thisQuestion')
			ResponseList.insert {
				qid: qid
				text: respondText
				votes: 0
				user: "steve"
				date: Date.parse(new Date())
			}
			$('#respondText').val('');

	'click #upvote': (e,t)->
		if Meteor.user()
			userId = Session.get('userId')
			qid = Session.get 'thisQuestion'
			if $('#upvote').hasClass('active-up')
				QuestionList.update({_id:qid},{
					$inc: {votes: -1}
				})
				Deps.flush()
				Meteor.call('upvoteDel', userId, qid)
			else 
				QuestionList.update({_id:qid},{
					$inc: {votes: 1}
				})
				Deps.flush()
				Meteor.call('upvote', userId, qid)
		else 
			alert('please login or sign-up to vote')

	'click #downvote': (e,t) ->
		if Meteor.user()
			userId = Session.get('userId')
			qid = Session.get 'thisQuestion'
			if $('#downvote').hasClass('active-down')
				QuestionList.update({_id:qid},{
					$inc: {votes: 1}
				})
				userId = Session.get('userId')
				Meteor.call('downvoteDel', userId, qid)
			else 
				QuestionList.update({_id:qid},{
					$inc: {votes: -1}
				})
				userId = Session.get('userId')
				Meteor.call('downvote', userId, qid)
		else 
			alert('please login or sign-up to vote')		

	'click .tri-up-sm': (e,t) ->
		if Meteor.user()
			userId = Session.get('userId')
			zid = this._id
			if $(e.target).hasClass('active-up')
				ResponseList.update({_id:zid}, {
					$inc: {votes: -1}
				})
				Deps.flush()
				Meteor.call('upvoteDel', userId, zid)
			else 
				ResponseList.update({_id:zid}, {
					$inc: {votes: 1}
				})
				Deps.flush()
				Meteor.call('upvote', userId, zid)
		else
			alert('please login or sign-up to vote')

	'click .tri-down-sm': (e,t) ->
		if Meteor.user()
			userId = Session.get('userId')
			zid = this._id
			if $(e.target).hasClass('active-down')
				ResponseList.update({_id:zid}, {
					$inc: {votes: 1}
				})
				Deps.flush()
				Meteor.call('downvoteDel', userId, zid)
			else 
				ResponseList.update({_id:zid}, {
					$inc: {votes: -1}
				})
				Deps.flush()
				Meteor.call('downvote', userId, zid)
		else 
			alert('please login or sign-up to vote')

	'click .relatedQ': (e,t) ->
		e.preventDefault()
		zid = this._id
		Session.set('thisQuestion', zid)

	'click .relatedTag': (e,t) ->
		# console.log(this)
		e.preventDefault()
		Session.set('tagSearch', this.toString())
		Session.set('showResults',true)

	'click .tagged': (e,t) ->
		e.preventDefault()
		Session.set('tagSearch', this.toString())
		Session.set('showResults',true)

	'click #backSearch': (e,t) ->
		e.preventDefault()
		Session.set('showResults', true)
}



Template.test.events {
	'click #resetDB': (e,t) ->
		Meteor.call('reset')
	'click #resetUsers': (e,t) ->
		Meteor.call('resetUsers')
}














Handlebars.registerHelper('full', (item)->
	item.toString().replace(/,/g , " "))

Handlebars.registerHelper('descriptive', (item)->
	if item.length > 250
		item.substring(0, 250)+"..."
	else 
		item
	)





