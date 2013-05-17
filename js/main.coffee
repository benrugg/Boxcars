$(document).ready( ->
	
	# set the price of the table (in dollars), and the payout for rolling boxcars
	betAmount = 5
	oddsPayout = 30
	
	
	# set the number of rolls per time at the table
	rollsPerTable = 20
	
	
		
	# set variables to keep track of things
	runningTotal = 0
	lastNumWins = 0
	totalWins = 0
	wonFirstOrSecondRoll = false
	wonAtFirstTable = false
	howToHandle = ""
	documentHeight = 0
	isWorkerRunningIndefinitely = false
	isWorkerPaused = false
	
	
	# instantiate Polyglot (without phrases, because we'll load them in a minute)
	polyglot = new Polyglot
	
	
	
	
	
	
	# function for handling the roll results
	handleResults = (numRolls, numWins, rollResults, howToHandle) ->
		
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
				
			
			# if the height of the document has changed, scroll to the newest div
			if documentHeight isnt $(document).height()
				
				documentHeight = $(document).height()
				
				$.scrollTo($div, 500, {offset: -$("header").outerHeight()})
	
	
	
	
	
	
	
	# function for updating the header
	updateHeader = (text) ->
		$("header").html(text)
	
	
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
		
		results = playCraps numRolls, true
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
		worker.postMessage {command: "playCraps", numRolls: rollsPerTable, returnAllRolls: true, delay: if fastOrSlow is "fast" then 100 else 1000}
	
	
	# function to keep playing individual rolls indefinitely (with the worker)
	justKeepPlaying = ->
		howToHandle = "justKeepPlaying"
		isWorkerPaused = false
		isWorkerRunningIndefinitely = true
		worker.postMessage {command: "playCraps", numRolls: 1, returnAllRolls: false, delay: 10}
	
	
	# function to pause the worker
	pauseWorker = ->
		isWorkerPaused = true
		isWorkerRunningIndefinitely = false
		worker.postMessage {command: "pause"}
	
	
	# listen for the escape key to stop running the simulation
	$(document).on("keyup", (e) ->
		
		if e.keyCode is 27
			
			if isWorkerRunningIndefinitely
				pauseWorker()
			else if isWorkerPaused
				justKeepPlaying()
	)
	
	
	
	
	
	
	# function for updating our running total
	updateRunningTotal = (newTotal) ->
		
		# add the newest winnings/losses to the running total
		runningTotal += newTotal
		
		
		# display the running total
		runningWinOrLoss = formatWinOrLoss(runningTotal, "You've won a total of #{formatCurrency(runningTotal)}", "You've lost a total of #{formatCurrency(-runningTotal)}", "You're even")
		
		$("footer").text(runningWinOrLoss.text).removeClass().addClass(runningWinOrLoss.result)
	
	
	
	
	
	
	# prepare all the chapters in the story...
	whichChapter = 1
	
	tellStory = ->
		
		switch whichChapter
			
			when 1
				
				# intro
				tellNextLine "intro.1"
				
			when 2
				
				# intro, part 2
				tellNextLine "intro.2", {betAmount: formatCurrency betAmount}
				
			when 3
				
				# intro, part 3
				tellNextLine "intro.3"
				
			when 4
				
				# intro, part 4
				tellNextLine "intro.4"
				
			when 5
				
				# first roll
				firstRoll()
				
				if lastNumWins is 1
					
					wonFirstOrSecondRoll = true
					tellNextLine "firstRoll.won", {betAmount: formatCurrency(betAmount), oneBetWinnings: formatCurrency(betAmount * oddsPayout)}
					
				else
					tellNextLine "firstRoll.lost"
				
			when 6
				
				# second roll
				secondRoll()
				
				if lastNumWins is 1
					
					wonFirstOrSecondRoll = true
					
					if totalWins is 2
						tellNextLine "secondRoll.wonBoth"
					else
						tellNextLine "secondRoll.wonSecondLostFirst"
				
				else
					
					if totalWins is 1
						tellNextLine "secondRoll.wonFirstLostSecond"
					else
						tellNextLine "secondRoll.lostBoth"
				
			when 7
				
				# finish the table
				finishTable()
				
				switch
					when wonFirstOrSecondRoll and lastNumWins > 0
						tellNextLine "firstTable.wonFirstRollsAndWonAgain"
						
					when wonFirstOrSecondRoll and lastNumWins is 0
						tellNextLine "firstTable.wonFirstRollsButLostTheRest"
						
					when !wonFirstOrSecondRoll and lastNumWins > 1
						tellNextLine "firstTable.lostFirstRollsButWonMoreThanOne"
						
					when !wonFirstOrSecondRoll and lastNumWins is 1
						tellNextLine "firstTable.lostFirstRollsButWonOne"
						
					when !wonFirstOrSecondRoll and lastNumWins is 0
						tellNextLine "firstTable.lostAllRolls"
				
				# store whether or not we won at this first table
				wonAtFirstTable = totalWins > 0
				
				# show our total
				showTotal()
			
			when 8
				
				# second table
				newTable()
				
				switch
					when wonAtFirstTable and lastNumWins > 0
						tellNextLine "secondTable.wonBoth"
						
					when wonAtFirstTable and lastNumWins is 0
						tellNextLine "secondTable.wonFirstLostSecond"
						
					when !wonAtFirstTable and lastNumWins > 0
						tellNextLine "secondTable.wonSecondLostFirst"
						
					when !wonAtFirstTable and lastNumWins is 0
						tellNextLine "secondTable.lostBoth"
				
			when 9
				
				# keep playing tables indefinitely (slowly)
				newTableIndefinitely("slow")
				
				tellNextLine "keepPlaying.tablesSlow"
				
			when 10
				
				# keep playing tables indefinitely (fast)
				newTableIndefinitely("fast")
				
				tellNextLine "keepPlaying.tablesFast"
				
			when 11
				
				# just keep playing (individual roles)
				justKeepPlaying()
				
				tellNextLine "keepPlaying.rolls"
				
			else
				
				# keep saying stuff at the end (until we run out of things to say)
				if whichChapter in [11..58]
					
					noEndingPartNumber = whichChapter - 11
					
					tellNextLine "noEnding." + noEndingPartNumber
		
		
		# advance to the next chapter for the next time
		whichChapter++
	
	
	
	
	# function for telling the next line of the story (using polyglot)
	tellNextLine = (storyKey, extraValues) ->
		
		# set the default value for extraValues to be an empty object
		extraValues = extraValues ? {}
		
		#update the header with the next line of the story
		updateHeader polyglot.t storyKey, extraValues
	
	
	
	
	
	
	
	# advance the story when the header is clicked or when the right arrow key is clicked
	$(document).on("keyup", (e) ->
		
		tellStory() if e.keyCode in [13, 39, 32]
	)
	
	$(document).on("click", "header", tellStory)
	
	
	
	
	
	
	# load the story text in from a json file
	$.getJSON("story/vegas.json", (data) ->
		
		# add the text for the story to Polyglot
		polyglot.extend data
		
		
		# when the first story is loaded, load the content for our ending (or lack thereof)
		$.getJSON("story/no-ending.json", (data) ->
			
			# add the additional text to Polyglot
			polyglot.extend data
			
			
			# when the json is all finished loading, start the story
			tellStory()
		)
	)
)