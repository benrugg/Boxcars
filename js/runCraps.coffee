# function for rolling one die
rollDie = -> Math.floor(Math.random() * 6) + 1


# function for rolling a pair of dice
rollPairOfDice = -> for i in [0..1]
	rollDie()



# listen for the message from our parent
self.addEventListener("message", (e) ->
	
	# get our parameters:
	#  - the number of times we should roll the dice
	#  - whether we should run once or keep running indefinitely
	numRolls = e.data.numRolls
	onceOrIndefinitely = e.data.onceOrIndefinitely
	
	
	
	
	
	# function for running the craps simulation
	runCraps = (numRolls, returnAllRolls) ->
		
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
			if returnAllRolls then rollResults += "<span" + (if thisRollWon then " class='hard_12'" else "") + "> #{ newRoll.join() } </span>"
		
		
		# send back the results
		self.postMessage({numRolls: numRolls, numWins: numWins, rollResults: rollResults})
	
	
	
	
	
	# if we just want to run once, call the function now and tell it to return the roll results
	if (onceOrIndefinitely is "once")
		
		runCraps numRolls, true
		
		
	# else, keep calling the function indefinitely (just returning the number of wins)
	else
		
		setInterval( ->
			runCraps numRolls, false
		, 10)
	
	
, false)