@QuestionList = new Meteor.Collection("questionlist")


Session.set('showSearch', true)
Session.set('showResults', false)
Session.set('showNewQuestion', false)

Template.navigation.showSearch = ->
	Session.equals('showSearch', true)

Template.navigation.showResults = ->
	Session.equals('showResults', true)

Template.navigation.showNewQuestion = ->
	Session.equals('showNewQuestion', true)

Template.navigation.events {
	'click #newQuestionBtn': (e,t) ->
		Session.set('showResults', false)
		Session.set('showNewQuestion', true)
}

Template.searchBox.events {
	'click #searchBtn, keyup #searchInput': (e,t) ->
		if (e.type is "click") or (e.type is "keyup" and e.which is 13)
			searchText = $('#searchInput').val().trim()
			console.log(searchText)
			if searchText.length isnt 0
				Session.set('showResults', true)
				Session.set('searchText', searchText)
				# console.log('do search')
}

Template.searchResults.Match = ->
	searchText = Session.get('searchText')
	searchKeyword = searchText.split(" ")
	searchRegex = new RegExp(searchText, 'i');
	# console.log searchKeyword
	tmp = QuestionList.find {
		$or: [
			{title: {$in: searchKeyword}} 
			{descr: searchRegex}
			{tags: {$in: searchKeyword}}
		]
	}
	console.log(tmp.count())
	tmp

Template.searchResults.ztitle = ->
	this.title.toString().replace(/,/g , " ")

Template.searchResults.ztags = ->
	this.tags.toString()

Template.searchResults.events {
	'click .qtitle': (e,t) ->
		console.log this._id
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
		}

	'click #cancelNewQuestion': (e,t) ->
		$('#newQuestionTitle').val('')
		$('#newQuestionDescr').val('')
		$('#newQuestionTags').val('')
		Session.set 'showNewQuestion', false

}

