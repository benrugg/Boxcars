
# set the context for where to store these functions (to make them accessible 
# to both the rest of our scrips and to the web worker)
context = window ? self





# function for rolling one die
context.rollDie = -> Math.floor(Math.random() * 6) + 1


# function for rolling a pair of dice
context.rollPairOfDice = ->
	for i in [0..1]
		rollDie()





# function for running the craps simulation
context.playCraps = (numRolls, returnAllRolls) ->
	
	# initialize our variables
	numWins = 0
	rollResults = ""
	
	
	# roll the dice and keep track of our results
	for i in [1..numRolls] by 1
		
		# reset our flag for whether or not this roll won
		thisRollWon = false
		
		
		# roll the dice
		newRoll = rollPairOfDice()
		
		
		# if we just rolled a hard 12, add it to the wins!
		if newRoll[0] + newRoll[1] is 12
			
			thisRollWon = true
			numWins++
		
		
		# if we want to return all the rolls, add this roll to the fake DOM string
		if returnAllRolls then rollResults += "<span" + (if thisRollWon then " class='boxcars'" else "") + "> #{ newRoll.join() } </span>"
	
	
	# return the results
	return {numRolls: numRolls, numWins: numWins, rollResults: rollResults}