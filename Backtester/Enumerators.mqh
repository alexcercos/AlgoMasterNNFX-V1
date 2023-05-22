//+------------------------------------------------------------------+
//|                                                  Enumerators.mqh |
//|                                 Copyright 2020, Alejandro Cercós |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Alejandro Cercós"
#property link      "https://www.mql5.com"

#ifdef __MQL5__
   enum IndicatorRead
   {
      ZERO_LINE_CROSS,  //Zero Line Cross
      TWO_LINES_CROSS,  //Two Lines Cross
      CHART_DOT_SIGNAL, //Chart Dot Signal
      BUFFER_ACTIVATION,//Buffer Activation
      ZERO_LINE_FILTER, //Zero Line Filter
      COLOR_BUFFER,     //Color Buffer
      CROSS_PRICE,      //Cross With Price
      CROSS_IN_FILTER,  //Cross Inside Filter
      CHART_DOT_COLOR,  //Chart Dot (Color)
      OVER_SIGNAL_COLOR,//Over Signal (Colored)
      OVER_LEVEL_COLOR  //Over Level (Colored)
   };
#else
   enum IndicatorRead
   {
      ZERO_LINE_CROSS,  //Zero Line Cross
      TWO_LINES_CROSS,  //Two Lines Cross
      CHART_DOT_SIGNAL, //Chart Dot Signal
      BUFFER_ACTIVATION,//Buffer Activation
      ZERO_LINE_FILTER, //Zero Line Filter
      CROSS_PRICE,      //Cross With Price
      CROSS_IN_FILTER,  //Cross Inside Filter
      OVER_SIGNAL_COLOR,//Over Signal (Colored)
      OVER_LEVEL_COLOR  //Over Level (Colored)
   };
#endif

enum IndicatorSignal
{
   BUY_SIGNAL,
   SELL_SIGNAL,
   NEUTRAL,
   BUY_CURRENT,
   SELL_CURRENT
};

enum VolumeRead
{
   OVER_LEVEL,  //Over Level
   OVER_SIGNAL, //Over Signal
   OVER_LEVEL_BUY_SELL, //Over Level Buy/Sell
   OVER_SIGNAL_BUY_SELL, //Over Signal Buy/Sell
   BIDIRECTIONAL_LEVEL  //Bidirectional Levels
};

// Double Out level

enum IndicatorType
{
   ATR_IND,
   MAIN_IND,
   SECOND_IND,
   VOLUME_IND,
   EXIT_IND,
   BASELINE_IND,
   CONTINUATION_IND
};

enum Optimization
{
   TOTAL_PROFIT,        //Total Profit
   BEST_MINIMUM,        //Best Minimum
   AVG_MIN_TOTAL,       //Average Minimum-Total
   PROFIT_FACTOR_MOD,   //Profit Factor Modified
   MIN_PROFITFACTOR,    //Minimum Profit Factor
   PF_SQ_PER_W,         //PF squared per W
   DISTRIBUTION_VALUE,  //Distribution Value
   EXPECTED_D_VALUE,    //Expected Dist. Value
   DIST_V_PF,           //Dist. Value per Profit Factor
   WIN_RATE,            //Win Rate
   WORST_WIN_RATE,      //Worst Win Rate
   CORR_WIN_RATE        //Corrected Win Rate
};

enum Pairs
{
   ALL_SYMBOLS,    //All 28 Forex Symbols
   BT_ONLY,        //NNFX's Backtest Symbols (5)
   CUSTOM,         //Custom
   ALL_AND_CUSTOM, //All 28 Symbols + Custom symbols
   ACTIVE_ONLY,    //Only active
   ALL_SUBSTITUTE, //Substitute From All (REMOVE/ADDED, ...)
   ALL_SUFFIX,		 //All 28 Symbols with Suffix
   SYMBOL_FILE		 //Symbol file (In Common Files folder)
};

enum WriteFilesMode
{
   OPTIMIZE,   //Optimize
   SUMMARY,    //Summary
   NO_WRITE    //No write
};

enum WriteProfitMode
{
   ONLY_WINRATE,           // Only Win Rate
   NORMALIZED_TO_ACCOUNT,  // Trade Profit
   TOTAL_PIPS              // Total Pips
};

enum TradeStates
{
   NO_TRADE,
   MAIN_SIGNAL,
   MAIN_CATCH_UP,
   PULLBACK,
   ONE_CANDLE,
   CONTINUATION,
   MISSED_TRADE
};

enum TradeProcedence
{
   TP_BASELINE_CROSS,
   TP_MAIN_SIGNAL,
   TP_MAIN_CATCH,
   TP_CONTINUATION,
   TP_ONE_CANDLE,
   TP_PULLBACK
};

enum OptimizationNNFXAlgo
{
   N_WIN_RATE,       //Win Rate
   N_TOTAL_PROFIT,   //Total Profit
   N_TOTAL_PIPS,     //Total Pips
   N_DRAWDOWN,       //Drawdown
   N_ROI,            //Return On Investment
   N_PROFIT_FACTOR,  //Profit Factor
   N_EXP_PAYOFF,     //Expected Payoff
   N_DIST_VALUE,     //Trade Distribution Value
   N_DIST_SHAPE,     //Trade Distribution Shape
   N_EQUITY_CURVE,   //Equity Curve (Saved in File)
   N_EQUITY_COMP,    //Compound Interest + Equity Curve
#ifdef __MQL5__
   N_REAL_TRADES,		//Real Trades
#endif 
	N_CUSTOM_OPTIMIZE //Custom Optimization
};

enum ContinuationIndicatorMode
{
   CONT_DONT_USE,    //false
   CONT_USE_MAIN,    //Use Main Indicator
   CONT_USE_EXIT,    //Use Exit Indicator
   CONT_CUSTOM       //Use Continuation Indicator
};

enum TradeCloseLevel
{
	TCL_MAX_SL,
	TCL_LOSS,
	TCL_BE,
	TCL_PROFIT_BEFORE,
	TCL_TRAILING_STOP,
	TCL_PROFIT_AFTER
};

enum CloseTradeProcedence
{
	CTP_STOPS,
	CTP_C1,
	CTP_EXIT,
	CTP_BASELINE,
	CTP_NEWS,
	CTP_END_SIM,
	CTP_DATA_GAP
};