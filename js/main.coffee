$(document).ready( ->
	
	# set the price of the table (in dollars), and the payout for rolling boxcars
	betAmount = 5
	oddsPayout = 30
	
	
	# set the number of rolls per time at the table
	rollsPerTable = 20
	
	
	# set the odds of rolling a six (can be "normal" or a decimal percent from 0-1)
	oddsOfRollingASix = "normal"
	
	
	# set the number of rolls to play before we see if we've won or lost
	rollsUntilGameOver = 500
	
	
	
	
	
	
	# set variables to keep track of things
	numRollsPlayed = 0
	isGameOver = false
	allowIndefiniteRolls = false
	numVisitsToSite = 0
	lastStorySeen = 0
	lastEndingNumberSeen = 0
	currentEndingLastLineNumber = 0
	haveAllEndingsBeenCompleted = false
	runningTotal = 0
	lastNumWins = 0
	totalWins = 0
	wonFirstOrSecondRoll = false
	wonAtFirstTable = false
	instructionsTimeoutID = 0
	howToHandle = ""
	documentHeight = 0
	indefiniteWorkerMode = ""
	isWorkerPaused = false
	
	
	# instantiate Polyglot (without phrases, because we'll load them in a minute)
	polyglot = new Polyglot
	
	
	
	
	
	
	
	# if we've been to this site before, load up the values we have stored in local storage
	if localStorage && localStorage.getItem "boxcars"
		
		# parse the JSON object we previously stored
		storedObject = JSON.parse localStorage.getItem "boxcars"
		
		
		# overwrite our defaults with the stored amounts
		numVisitsToSite = storedObject.numVisitsToSite
		lastStorySeen = storedObject.lastStorySeen
		lastEndingNumberSeen = storedObject.lastEndingNumberSeen
		haveAllEndingsBeenCompleted = storedObject.haveAllEndingsBeenCompleted
	
	
	
	# function for storing data in local storage
	saveToLocalStorage = ->
		
		# if this browser doesn't support local storage, just stop here
		if !localStorage then return
		
		
		# create an object with all the values we want to store
		objectToStore = {
			numVisitsToSite: numVisitsToSite,
			lastStorySeen: lastStorySeen,
			lastEndingNumberSeen: lastEndingNumberSeen,
			haveAllEndingsBeenCompleted: haveAllEndingsBeenCompleted
		}
		
		
		# save the object in local storage
		localStorage.setItem "boxcars", JSON.stringify objectToStore
	
	
	# function for clearing location storage
	clearLocalStorage = ->
		
		# if this browser doesn't support local storage, just stop here
		if !localStorage then return
		
		
		# clear the boxcars data from local storage
		localStorage.removeItem "boxcars"
	
	
	
	
	
	
	
	# function for handling the roll results
	handleResults = (numRolls, numWins, rollResults, howToHandle) ->
		
		# ensure that our number variables are treated as numbers
		numRolls = parseInt numRolls
		numWins = parseInt numWins
		
		
		# store how many rolls we've played
		numRollsPlayed += numRolls
		
		
		# store how many wins we had
		lastNumWins = numWins
		totalWins += numWins
		
		
		# determine our total winnings or losses
		losses = (numRolls - numWins) * betAmount
		winnings = numWins * betAmount * oddsPayout
		
		total = winnings - losses
		
		
		# update our running total
		updateRunningTotal(total)
		
		
		# if this is our first roll or we're at a new table, create a new div
		if howToHandle in ["firstRoll", "newTable"]
			
			$div = $("<div>").appendTo("article")
			
			
		# otherwise, get the last div
		else
			
			$div = $("article div").last()
		
		
		
		# if we want to display the roll results...
		if (rollResults != "")
			
			# add our results to the div
			$div.append(rollResults)
			
			
			# if this is a new table, or we're finishing the first table, add a label at the end of the results
			if howToHandle in ["finishTable", "newTable"]
				
				tableTotal = if howToHandle is "finishTable" then runningTotal else total
				
				wonOrLost = formatWinOrLoss(tableTotal, "Won #{formatCurrency(tableTotal)}", "Lost #{formatCurrency(-tableTotal)}", "Broke even")
				
				$("<label>").text(wonOrLost.text).addClass(wonOrLost.result).appendTo($div)
				
			
			# if the height of the document has changed, scroll to the bottom of the page
			currentDocumentHeight = $(document).height()
			
			if documentHeight isnt currentDocumentHeight
				
				documentHeight = currentDocumentHeight
				
				$.scrollTo currentDocumentHeight, 500
		
		
		
		# if we've played more rolls than our limit, stop now
		if numRollsPlayed >= rollsUntilGameOver and !allowIndefiniteRolls
			
			isGameOver = true
			
			pauseWorker()
			
			handleFinalWinOrLoss()
	
	
	
	# function for updating our running total
	updateRunningTotal = (newTotal) ->
		
		# add the newest winnings/losses to the running total
		runningTotal += newTotal
		
		
		# determine a small win or loss by whether the total is within one win
		# or loss per 500 rolls
		smallWinOrLossThreshold = (rollsUntilGameOver / 500) * oddsPayout * betAmount
		
		
		# display the running total
		runningWinOrLoss = formatWinOrLoss(runningTotal, "You've won a total of #{formatCurrency(runningTotal)}", "You've lost a total of #{formatCurrency(-runningTotal)}", "You're even", smallWinOrLossThreshold)
		
		$("footer").text(runningWinOrLoss.text).removeClass().addClass(runningWinOrLoss.result)
	
	
	
	# function for handling the final win or loss
	handleFinalWinOrLoss = ->
		
		# determine a small win or loss by whether the total is within one win
		# or loss per 500 rolls
		smallWinOrLossThreshold = (rollsUntilGameOver / 500) * oddsPayout * betAmount
		
		
		# prepare our text and display it in the header
		finalWinOrLoss = formatWinOrLoss(runningTotal, "You won! After #{numRollsPlayed} rolls, you're up a total of #{formatCurrency(runningTotal)}.", "You lost. After #{numRollsPlayed} rolls, you're down a total of #{formatCurrency(-runningTotal)}.", "Wow, you broke even. After #{numRollsPlayed} rolls. How about that.", smallWinOrLossThreshold, "Not bad. You won a little bit of money. After #{numRollsPlayed} rolls, you're up a total of #{formatCurrency(runningTotal)}.", "Hey, it's not a disgrace. After #{numRollsPlayed} rolls, you're down a total of #{formatCurrency(-runningTotal)}.")
		
		$("header").text(finalWinOrLoss.text).removeClass().addClass(finalWinOrLoss.result)
	
	
	
	# function for updating the header (for our normal story text)
	updateHeader = (text) ->
		$("header").html(text).removeClass()
	
	
	# function for showing the instructions after a delay
	showInstructionsInAMoment = ->
		instructionsTimeoutID = setTimeout showInstructions, 3000
	
	
	# function for showing the instructions
	showInstructions = ->
		$(".instructions").fadeIn(500)
	
	
	# function for hiding the instructions
	hideInstructions = ->
		
		clearTimeout instructionsTimeoutID
		$(".instructions").fadeOut(250)
	
	
	# function for showing the footer (where the total is displayed)
	showTotal = ->
		$("footer").delay(1000).fadeIn(600)
	
	
	
	
	
	
	# create a web worker that will actually run the craps simulation
	worker = new Worker("js/playCrapsWorker.js")
	
	
	# create a listener to handle the worker's response
	worker.addEventListener("message", (e) ->
		
		# display the results of this craps simulation
		handleResults e.data.numRolls, e.data.numWins, e.data.rollResults, howToHandle
		
	, false)
	
	
	# function for playing craps without using the web worker (which we need
	# to do whenever we need the results immediately (in the normal "blocking" way))
	playCrapsAndHandleResults = (numRolls) ->
		
		results = playCraps numRolls, true, oddsOfRollingASix
		handleResults results.numRolls, results.numWins, results.rollResults, howToHandle
	
	
	
	
	
	
	
	# function for first roll
	firstRoll = ->
		howToHandle = "firstRoll"
		playCrapsAndHandleResults 1
	
	
	# function for second roll
	secondRoll = ->
		howToHandle = "secondRoll"
		playCrapsAndHandleResults 1
	
	
	# function for finishing first time at the table
	finishTable = ->
		howToHandle = "finishTable"
		playCrapsAndHandleResults rollsPerTable - 2
	
	
	# function to play another table
	newTable = ->
		howToHandle = "newTable"
		playCrapsAndHandleResults rollsPerTable
	
	
	# function to keep playing new tables (with the worker)
	newTableIndefinitely = (fastOrSlow) -> 
		howToHandle = "newTable"
		indefiniteWorkerMode = "newTable" + fastOrSlow.toTitleCase()
		worker.postMessage {command: "playCraps", numRolls: rollsPerTable, returnAllRolls: true, oddsOfRollingASix: oddsOfRollingASix, delay: if fastOrSlow is "fast" then 100 else 1000}
	
	
	# function to keep playing individual rolls indefinitely (with the worker)
	playIndefinitelyAtSuperHighSpeed = ->
		howToHandle = "playIndefinitelyAtSuperHighSpeed"
		indefiniteWorkerMode = "playIndefinitelyAtSuperHighSpeed"
		worker.postMessage {command: "playCraps", numRolls: 100, returnAllRolls: false, oddsOfRollingASix: oddsOfRollingASix, delay: 10}
	
	
	# function to pause the worker
	pauseWorker = ->
		isWorkerPaused = true
		worker.postMessage {command: "pause"}
	
	
	# function to toggle the paused/play state of the worker
	togglePause = ->
		
		# if the game is over or if we're not playing indefinitely, don't
		# pause or unpause. just quit here.
		if indefiniteWorkerMode is "" or isGameOver then return
		
		
		# if the game is paused, restart whatever we were doing before
		if isWorkerPaused
			
			isWorkerPaused = false
			
			if indefiniteWorkerMode is "newTableSlow"
				
				newTableIndefinitely "slow"
				
			else if indefiniteWorkerMode is "newTableFast"
				
				newTableIndefinitely "fast"
				
			else
				
				playIndefinitelyAtSuperHighSpeed()
			
			
		# else, pause now
		else
			
			pauseWorker() 
	
	
	# listen for the escape key to stop running the simulation
	$(document).on("keyup", (e) -> if e.keyCode is 27 then togglePause())
	
	
	
	
	
	
	# handle all the lines in the story (and the play that accompanies the lines)
	whichChapter = 1
	
	tellStory = ->
		
		# if the game is not over and we haven't unlocked indefinite play,
		# don't allow us to see the ending
		if whichChapter > 10 and !isGameOver and !allowIndefiniteRolls then return
		
		
		# if the game is over, but we never got to the fast play, just skip past
		# it to the ending
		if isGameOver and whichChapter is 10 then whichChapter = 12
		
		
		# if we're about to show the line about indefinite play, but we haven't
		# unlocked indefinite play, skip to the ending
		if whichChapter is 11 and !allowIndefiniteRolls then whichChapter = 12
		
		
		# otherwise, show whichever line we're on...
		switch whichChapter
			
			when 1
				
				# intro
				sayNextLine "intro.1"
				
				showInstructionsInAMoment()
				
			when 2
				
				# intro, part 2
				sayNextLine "intro.2", {betAmount: formatCurrency betAmount}
				
				hideInstructions()
				
			when 3
				
				# intro, part 3
				sayNextLine "intro.3"
				
			when 4
				
				# intro, part 4
				sayNextLine "intro.4"
				
			when 5
				
				# first roll
				firstRoll()
				
				if lastNumWins is 1
					
					wonFirstOrSecondRoll = true
					sayNextLine "firstRoll.won", {betAmount: formatCurrency(betAmount), oneBetWinnings: formatCurrency(betAmount * oddsPayout)}
					
				else
					sayNextLine "firstRoll.lost"
				
			when 6
				
				# second roll
				secondRoll()
				
				if lastNumWins is 1
					
					wonFirstOrSecondRoll = true
					
					if totalWins is 2
						sayNextLine "secondRoll.wonBoth"
					else
						sayNextLine "secondRoll.wonSecondLostFirst"
				
				else
					
					if totalWins is 1
						sayNextLine "secondRoll.wonFirstLostSecond"
					else
						sayNextLine "secondRoll.lostBoth"
				
			when 7
				
				# finish the table
				finishTable()
				
				switch
					when wonFirstOrSecondRoll and lastNumWins > 0
						sayNextLine "firstTable.wonFirstRollsAndWonAgain"
						
					when wonFirstOrSecondRoll and lastNumWins is 0
						sayNextLine "firstTable.wonFirstRollsButLostTheRest"
						
					when !wonFirstOrSecondRoll and lastNumWins > 1
						sayNextLine "firstTable.lostFirstRollsButWonMoreThanOne"
						
					when !wonFirstOrSecondRoll and lastNumWins is 1
						sayNextLine "firstTable.lostFirstRollsButWonOne"
						
					when !wonFirstOrSecondRoll and lastNumWins is 0
						sayNextLine "firstTable.lostAllRolls"
				
				# store whether or not we won at this first table
				wonAtFirstTable = totalWins > 0
				
				# show our total
				showTotal()
			
			when 8
				
				# second table
				newTable()
				
				switch
					when wonAtFirstTable and lastNumWins > 0
						sayNextLine "secondTable.wonBoth"
						
					when wonAtFirstTable and lastNumWins is 0
						sayNextLine "secondTable.wonFirstLostSecond"
						
					when !wonAtFirstTable and lastNumWins > 0
						sayNextLine "secondTable.wonSecondLostFirst"
						
					when !wonAtFirstTable and lastNumWins is 0
						sayNextLine "secondTable.lostBoth"
				
			when 9
				
				# keep playing tables indefinitely (slowly)
				newTableIndefinitely("slow")
				
				sayNextLine "keepPlaying.tablesSlow"
				
			when 10
				
				# keep playing tables indefinitely (fast)
				newTableIndefinitely("fast")
				
				sayNextLine "keepPlaying.tablesFast"
				
			when 11
				
				# play indefinitely at super high speed
				playIndefinitelyAtSuperHighSpeed()
				
				sayNextLine "keepPlaying.indefinitelyFast"
				
			else
				
				# keep saying stuff at the end (until we run out of things to say)
				endingPartNumber = whichChapter - 11
				
				if endingPartNumber <= currentEndingLastLineNumber then sayNextLine "ending." + endingPartNumber
				
				# once we've gotten to the second line of an ending, update our storage
				# so we'll see the next ending the next time
				if endingPartNumber is 2 then incrementlastEndingNumberSeen()
				
				
				# if we get to the end of the quirky ending, update our storage so we'll
				# see the very last ending
				if endingPartNumber is currentEndingLastLineNumber and endingFileForThisVisit is "quirky-ending" then allEndingsHaveBeenCompleted()
		
		
		# advance to the next chapter for the next time
		whichChapter++
	
	
	
	
	# function for telling the next line of the story (using polyglot)
	sayNextLine = (storyKey, extraValues) ->
		
		# set the default value for extraValues to be an empty object
		extraValues = extraValues ? {}
		
		#update the header with the next line of the story
		updateHeader polyglot.t storyKey, extraValues
	
	
	
	
	
	
	
	# advance the story when the header is clicked or when the right arrow key is clicked
	$(document).on("keyup", (e) ->
		
		tellStory() if e.keyCode in [13, 39, 32]
	)
	
	$(document).on("click", "header", tellStory)
	
	
	
	
	
	
	# get any values from our query string and overwrite the defaults
	if location.search
		
		# get the values from the query string
		queryString = if location.search.indexOf("?") is 0 then location.search.substring(1) else location.search
		queryStringValues = $.deserialize queryString
		
		
		# overwrite any defaults with values that are in the query string
		betAmount = queryStringValues.betAmount ? betAmount
		oddsPayout = queryStringValues.oddsPayout ? oddsPayout
		rollsPerTable = queryStringValues.rollsPerTable ? rollsPerTable
		rollsUntilGameOver = queryStringValues.rollsUntilGameOver ? rollsUntilGameOver
		oddsOfRollingASix = queryStringValues.oddsOfRollingASix ? oddsOfRollingASix
		allowIndefiniteRolls = queryStringValues.playIndefinitelyAtSuperHighSpeed ? false
		if allowIndefiniteRolls is not false then allowIndefiniteRolls = true
		
		
		# if we want to start over, reset the story counters, save to local storage, and then
		# redirect the page to the location without the query string
		startOver = queryStringValues.startOver ? false
		
		if startOver
			
			clearLocalStorage()
			
			location.replace location.protocol + "//" + location.hostname + location.pathname
			
			return
	
	
	
	
	
	
	# increment the counter for the number of times we've visited the site
	numVisitsToSite++
	
	
	# prepare to load a base story (with some of the lesser used lines) based on how many
	# times we've visited the site
	numBaseFiles = 2
	baseFileForThisVisit = "base" + (((numVisitsToSite - 1) % numBaseFiles) + 1)
	
	
	# prepare which story we're going to tell based on how many times we've visited the site
	# (showing all the stories in order first, and then going randomly, but making sure not
	# to show the same random story twice in a row)
	storyFiles = ["atlantic-city", "vegas", "chumash", "back-to-vegas", "river-boat", "online", "gambling-problem", "no-more"]
	
	if numVisitsToSite <= storyFiles.length
		
		storyIndex = (numVisitsToSite - 1) % storyFiles.length
		
	else
		
		storyIndex = lastStorySeen
		
		while storyIndex is lastStorySeen
			storyIndex = Math.floor(Math.random() * storyFiles.length)
	
	lastStorySeen = storyIndex
	storyFileForThisVisit = storyFiles[storyIndex]
	
	
	# prepare which ending we're going to show (showing each one in order, but once you've seen
	# all of them, but haven't finished the quirky ending, showing them at random)
	endingIndex = lastEndingNumberSeen
	
	endingFiles = ["first-ending", "change-num-rolls-per-table", "change-bet-amount", "change-roll-limit", "change-the-odds", "quirky-ending", "final-ending-all-options"]
	
	if lastEndingNumberSeen >= endingFiles.length - 1
		
		if haveAllEndingsBeenCompleted
			
			endingIndex = endingFiles.length - 1
			
		else
			
			endingIndex = Math.floor(Math.random() * (endingFiles.length - 1))
	
	endingFileForThisVisit = endingFiles[endingIndex]
	
	
	
	
	
	
	# function for incrementing the last ending that we've seen
	incrementlastEndingNumberSeen = ->
		
		lastEndingNumberSeen++
		
		saveToLocalStorage()
	
	
	# function for keeping track of the fact that all the endings have been
	# completed and we can now show the final ending
	allEndingsHaveBeenCompleted = ->
		
		haveAllEndingsBeenCompleted = true
		
		saveToLocalStorage()
	
	
	
	
	
	
	# store the most updated version of our data in local storage
	saveToLocalStorage()
	
	
	
	
	
	
	# load the base story text in from a json file
	$.getJSON("story/bases/" + baseFileForThisVisit + ".json", (data) ->
		
		# add the text for the base story lines to Polyglot
		polyglot.extend data
		
		
		# load the rest of the story text
		$.getJSON("story/stories/" + storyFileForThisVisit + ".json", (data) ->
			
			# add the text for the story to Polyglot (overwriting any base lines as necessary)
			polyglot.extend data
			
			
			# load the content for our ending
			$.getJSON("story/endings/" + endingFileForThisVisit + ".json", (data) ->
				
				# add the ending text to Polyglot
				polyglot.extend data
				
				
				# store what our last ending number is
				currentEndingLastLineNumber = data.lastLineNumber
				
				
				# now that all the json is all finished loading, start the story
				tellStory()
			)
		)
	)
)