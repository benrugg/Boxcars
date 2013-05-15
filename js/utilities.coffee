window.formatCurrency = (amount) ->
	if (amount < 0) then "-$" + -amount else "$" + amount


window.formatWinOrLoss = (amountWonOrLost, wonText, lostText, evenText) ->
	switch
		when amountWonOrLost is 0
			{text: evenText, result: "even"}
			
		when amountWonOrLost > 0
			{text: wonText, result: "won"}
			
		when amountWonOrLost < 0
			{text: lostText, result: "lost"}