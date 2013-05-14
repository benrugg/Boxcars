$(document).ready( ->
	
	# set the price of the table (in dollars), and the payout for a hard 12
	betAmount = 5
	oddsPayout = 30
	
	
		
	# keep track of our total winnings or losses accross all simulations
	runningTotal = 0
	
	
	
	
	# function for handling the roll results
	handleResults = (numRolls, numWins, rollResults) ->
		
		# determine our total winnings or losses
		losses = (numRolls - numWins) * betAmount
		winnings = numWins * betAmount * oddsPayout
		
		total = winnings - losses
		
		
		# update our running total
		updateRunningTotal(total)
		
		
		# if we want to display the roll results...
		if (rollResults != "")
			
			# create a new div and fill it with our results
			$newDiv = $("<div>").html(rollResults).appendTo("body")
			
			
			# add a label at the end of the results
			wonOrLost = formatWinOrLoss(total, "Won #{formatCurrency(total)}", "Lost #{formatCurrency(-total)}", "Broke even")
			
			$("<label>").text(wonOrLost.text).addClass(wonOrLost.result).appendTo($newDiv)
		
		
		
	
	
	
	# create a web worker that will actually run the craps simulation
	worker = new Worker("js/runCraps.js")
	
	
	# create a listener to handle the worker's response
	worker.addEventListener("message", (e) ->
		
		# display the results of this craps simulation
		handleResults e.data.numRolls, e.data.numWins, e.data.rollResults
		
	, false)
	
	
	# function to tell the worker to run the craps simulation once
	runCraps = -> 
		worker.postMessage {numRolls: 20, onceOrIndefinitely: "once"}
	
	
	# function to tell the worker to keep running the simulation indefinitely
	keepRunningCraps = ->
		worker.postMessage {numRolls: 1, onceOrIndefinitely: "indefinitely"}
	
	
	# listen for the escape key to stop running the simulation
	$(document).on("keyup", (e) ->
		
		if e.keyCode is 27 then worker.terminate()
	)
	
	
	
	
	
	# function for updating our running total
	updateRunningTotal = (newTotal) ->
		
		# add the newest winnings/losses to the running total
		runningTotal += newTotal
		
		
		# display the running total
		finalWinOrLoss = formatWinOrLoss(runningTotal, "You're up! You've won a total of #{formatCurrency(runningTotal)}", "There's always next time. You've lost a total of #{formatCurrency(-runningTotal)}", "Hey, you're even. Maybe you should keep betting.")
		
		$("footer").text(finalWinOrLoss.text).removeClass().addClass(finalWinOrLoss.result)
	
	
	
	
	
	
	# run the simulation a bunch of times to get us started
	for i in [1..10]
		runCraps()
	
	
	# after that, tell our web worker to just keep running
	keepRunningCraps()
)