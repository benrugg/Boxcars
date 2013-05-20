window.formatCurrency = (amount) ->
	if (amount < 0) then "-$" + -amount else "$" + amount


window.formatWinOrLoss = (amountWonOrLost, wonText, lostText, evenText, smallWinOrLossThreshold, wonALittleText, lostALittleText) ->
	
	# provide default values for the last three parameters (because they're optional)
	smallWinOrLossThreshold = smallWinOrLossThreshold ? 0
	wonALittleText = wonALittleText ? wonText
	lostALittleText = lostALittleText ? lostText
	
	
	# return the text and class that corresponds to our situation
	switch
		when amountWonOrLost is 0
			{text: evenText, result: "even"}
			
		when amountWonOrLost > 0
			
			if amountWonOrLost > smallWinOrLossThreshold
				{text: wonText, result: "won"}
			else
				{text: wonALittleText, result: "wonALittle"}
			
		when amountWonOrLost < 0
			
			if amountWonOrLost < -smallWinOrLossThreshold
				{text: lostText, result: "lost"}
			else
				{text: lostALittleText, result: "lostALittle"}