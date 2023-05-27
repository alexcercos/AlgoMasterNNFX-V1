# AlgoMasterNNFX-V1
Complete and advanced No Nonsense Forex (NNFX) Algorithm Tester. Test your algorithm across all 28 forex 
pairs considering news, Euro FX Vix (EVZ) and currency exposure; 
or use it to help you create a whole algorithm from scratch with your favorite indicators.

Check the documentation (User Guide PDF) for more details on how to use this software.

# Installation and compilation

To compile this program, download all contents of this repository in a folder inside of the Experts folder in MT5 or MT4. 
Open the .mq5 or .mq4 file and compile it. The indicators included in the program as resources will also compile at that point.

# Possible risks and warnings

This software was discontinued for MT4 because of some limitations in that platform. In this repository it has been restored, 
but it's less reliable than MT5 and needs further testing in the future.

In both cases, the code will be subject to refactorings and bug fixes in the future.

This software currently is more reliable when used in Daily charts, and it's been made and tested mostly for that.

In its current state, it's not recommended to backtest symbols that aren't perfectly coordinated candle-by-candle (for example, 
weekend candles in crypto when backtesting forex too, which only trades during weekdays). If there is no option, it's more reliable to perform the backtest
in the symbol with more candles.

Some wrongly coded indicators in MT5 may give different signals when used in visual and non-visual backtests (but they can be fixed). 

The results in backtests don't include commissions, swaps and spreads (with the exception of real trades mode in MT5).

# Disclaimer

Any result obtained using this program should not be taken as financial advice.
The performance of an algorithm built using this system does not guarantee future success of that system in real trading. 
You should visually review the behaviour of the algorithm, check if there are potential errors (in the
algorithm, the indicators or the AlgoMaster NNFX program itself) and forward test.

This program is based on the author's subjective interpretation of the NNFX template and way of trading. 

The author of the program is not affiliated with/sponsored by VP (No Nonsense Forex), NNFX Discord and any other person/group related.
