$(document).ready( ->
	
	# set the price of the table (in dollars), and the payout for a hard 12
	betAmount = 5
	oddsPayout = 30
	
	
	# function for rolling one die
	rollDie = -> Math.floor(Math.random() * 6) + 1
	
	
	# function for rolling a pair of dice
	rollPairOfDice = -> for i in [0..1]
		rollDie()
	
	
	# function for running a craps simultion
	runCraps = (numTimes) ->
		
		# start with some variables
		numWins = 0
		
		
		# create a new div to contain our results
		$newDiv = $("<div>").appendTo("body")
		
		
		# roll the dice and keep track of our results
		rolls = for i in [1..numTimes] by 1
			
			# roll the dice and add them to our div
			newRoll = rollPairOfDice()
			$newSpan = $("<span>").text(newRoll.join()).appendTo($newDiv)
			
			
			# if the roll is a 12, highlight it!
			if newRoll[0] + newRoll[1] is 12
				
				# highlight the roll
				$newSpan.addClass("hard_12")
				
				
				# keep track of our win
				numWins++
		
		
		# show our total winnings or losses
		losses = (numTimes - numWins) * betAmount
		winnings = numWins * betAmount * oddsPayout
		
		total = winnings - losses
		
		wonOrLost = formatWinOrLoss(total, "Won #{formatCurrency(total)}", "Lost #{formatCurrency(-total)}", "Broke even")
		
		$("<label>").text(wonOrLost.text).addClass(wonOrLost.result).appendTo($newDiv)
		
		
		# return the total winnings or losses
		return total
	
	
	
	# keep track of our total winnings or losses accross all simulations
	finalTotal = 0
	
	
	# run the simulation a bunch of times
	for i in [1..10]
		finalTotal += runCraps(20)
	
	
	# display our final total
	finalWinOrLoss = formatWinOrLoss(finalTotal, "You're up! You've won a total of #{formatCurrency(finalTotal)}", "There's always next time. You've lost a total of #{formatCurrency(-finalTotal)}", "Hey, you're even. Maybe you should keep betting.")
	
	$("<footer>").text(finalWinOrLoss.text).addClass(finalWinOrLoss.result).appendTo("body")
)