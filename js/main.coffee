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
	isWorkerRunningIndefinitely = false
	isWorkerPaused = false
	
	
	
	
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
	
	
	
	
	
	
	
	# function for updating the header
	updateHeader = (text) ->
		$("header").text(text)
	
	
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
				updateHeader("So you're on your way from Charleston to Raleigh when you decide to make a quick stop in Atlantic City.")
				
			when 2
				
				# intro, part 2
				updateHeader("You sit down at a $5 craps table and the dealer tells you to place your bet.")
				
			when 3
				
				# intro, part 3
				updateHeader("You don't know anything about craps, so you bet on 12.")
				
			when 4
				
				# intro, part 4
				updateHeader("The shooter throws the dice, and...")
				
			when 5
				
				# first roll
				firstRoll()
				
				if lastNumWins is 1
					
					wonFirstOrSecondRoll = true
					updateHeader("Lucky you. Boxcars on the first roll. You snatch up your winnings but leave your #{ formatCurrency betAmount } bet to play.")
					
				else
					updateHeader("Crap, you lost your first bet. It's ok, you knew this wouldn't be easy. You make another bet on 12.")
				
			when 6
				
				# second roll
				secondRoll()
				
				if lastNumWins is 1
					
					wonFirstOrSecondRoll = true
					
					if totalWins is 2
						updateHeader("What are the odds? Two boxcars in a row, and suddenly you're a gambling addict. You keep playing.")
					else
						updateHeader("Hey, second time's the charm. Now you're hooked. Maybe you can hit boxcars again.")
				
				else
					
					if totalWins is 1
						updateHeader("What did you expect? Two wins in a row? But since you're up, you decide to keep playing for a while.")
					else
						updateHeader("Lost again. But now you're invested. You decide to play an even 20 rolls before walking away.")
				
			when 7
				
				# finish the table
				finishTable()
				
				switch
					when wonFirstOrSecondRoll and lastNumWins > 0
						updateHeader("Seriously, you've found your calling. You cancel your pedicure appointment and play another 20 rolls.")
						
					when wonFirstOrSecondRoll and lastNumWins is 0
						updateHeader("\"You can't win 'em all\", you tell yourself. But you're still up, so you decide to go for another 20 rolls.")
						
					when !wonFirstOrSecondRoll and lastNumWins > 1
						updateHeader("Aren't you glad you stuck this out? Your parents would finally be so proud. You'd be an idiot not to go for another 20 rolls.")
						
					when !wonFirstOrSecondRoll and lastNumWins is 1
						updateHeader("Hey, you did it. Boxcars. Since you're up, you might as well try another 20 rolls.")
						
					when !wonFirstOrSecondRoll and lastNumWins is 0
						updateHeader("Nothin'. It must be the table. You slide over to another one and stand next to a man with a white hat and a cane.")
				
				# store whether or not we won at this first table
				wonAtFirstTable = totalWins > 0
				
				# show our total
				showTotal()
			
			when 8
				
				# second table
				newTable()
				
				switch
					when wonAtFirstTable and lastNumWins > 0
						updateHeader("This is like printing money. \"Drinks all around!\", you say. The dealer reminds you that drinks are free, but you don't even hear him. You just keep playing.")
						
					when wonAtFirstTable and lastNumWins is 0
						updateHeader("Maybe this table just isn't hot anymore. You've tasted what it's like to win, and it's too late to turn back now. You try another table.")
						
					when !wonAtFirstTable and lastNumWins > 0
						updateHeader("Yes. It was definitely just that last table. The thrill of vicory compells you on.")
						
					when !wonAtFirstTable and lastNumWins is 0
						updateHeader("Ok, seriously. Two crap tables in a row. What are you going to tell your friends? You've got to win at least once.")
				
			when 9
				
				# keep playing tables indefinitely (slowly)
				newTableIndefinitely("slow")
				
				updateHeader("This is going to be a good investment.")
				
			when 10
				
				# keep playing tables indefinitely (fast)
				newTableIndefinitely("fast")
				
				updateHeader("Maybe you're more hooked than you thought.")
				
			when 11
				
				# just keep playing (individual roles)
				justKeepPlaying()
				
				updateHeader("You're right, let's skip the pleasantries and just see how this plays out.")
		
		
		# advance to the next chapter for the next time
		whichChapter++
	
	
	
	
	
	
	# advance the story when the header is clicked or when the right arrow key is clicked
	$(document).on("keyup", (e) ->
		
		tellStory() if e.keyCode in [13, 39, 32]
	)
	
	$(document).on("click", "header", tellStory)
	
	
	
	
	
	
	# start the story
	tellStory()
)