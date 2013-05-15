# import the functions for playing craps
importScripts("playCraps.js")


# store an interval id so we can stop running later
intervalID = 0



# listen for the message from our parent
self.addEventListener("message", (e) ->
	
	# clear the interval from the last time if we have one
	if intervalID then clearInterval intervalID 
	
	
	# get our parameters
	command = e.data.command
	numRolls = e.data.numRolls ? 0
	returnAllRolls = e.data.returnAllRolls ? false
	delay = e.data.delay ? 10
	
	
	# if our is to play craps, call the function immediately and then keep calling
	# the function indefinitely with the delay time we want
	if command is "playCraps"
		
		# call the function now
		self.postMessage playCraps numRolls, returnAllRolls
		
		
		# set an interval to keep processing
		intervalID = setInterval( ->
			self.postMessage playCraps numRolls, returnAllRolls
		, delay)
	
, false)