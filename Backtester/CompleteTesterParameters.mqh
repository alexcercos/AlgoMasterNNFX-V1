
#ifdef __MQL5__
   input group "Pairs to Backtest"
#else 
   input string Pairs_to_Backtest = "==============="; //Pairs to Backtest
#endif
sinput Pairs pairsPreset = ALL_SYMBOLS; //Pairs Preset
input string symbolString = "AUDNZD,EURUSD,GBPJPY"; //Custom Symbols (separate by ",")


#ifdef __MQL5__
   input group "Main Confirmation (C1) Settings"
#else 
   input string Main_Confirmation_Settings = "==============="; //Main Confirmation (C1) Settings
#endif
input string indicatorName = "Folder\\Name"; //C1 Indicator NAME
input string indicatorParams = ""; //C1 Ind. PARAMETERS (60 MAX ; empty = Default)
input IndicatorRead indicatorMode = ZERO_LINE_CROSS; //C1 Indicator Read Mode
input bool useMainForExit = true; //Use C1 for Exits
input int mainBuffer = 0; //C1 Main Buffer (lead)
input int signalBuffer = 1; //C1 Second Buffer (signal, if used)
input double crossLevel = 0.0; //C1 Cross Level
input double widthFilter = 0.0; //C1 Half Filter
#ifdef __MQL5__
   input int colorBuy = 0; //C1 Buy Color Index
   input int colorSell = 1; //C1 Sell Color Index
#else
   input int colorSell = 1; // C1 Extra Main-Sell Buffer (for color modes)
#endif
input bool invertOperative = false; //C1 Invert Operative (Flip Buy-Sell)


#ifdef __MQL5__
   input group "Second Confirmation (C2) Settings"
#else 
   input string Second_Confirmation_Settings = "==============="; //Second Confirmation (C2) Settings
#endif
input bool use2Confirm = false; //USE C2 INDICATOR
input string indicatorName2nd = "Folder\\Name"; //C2 Indicator NAME
input string indicatorParams2nd = ""; //C2 Ind. PARAMETERS (60 MAX ; empty = Default)
input IndicatorRead indicatorMode2nd = ZERO_LINE_CROSS; //C2 Indicator Read Mode
input int mainBuffer2nd = 0; //C2 Main Buffer (lead)
input int signalBuffer2nd = 1; //C2 Second Buffer (signal, if used)
input double crossLevel2nd = 0.0; //C2 Cross Level 
input double widthFilter2nd = 0.0; //C2 Half Filter 
#ifdef __MQL5__
   input int colorBuy2nd = 0; //C2 Buy Color Index
   input int colorSell2nd = 1; //C2 Sell Color Index
#else
   input int colorSell2nd = 1; // C2 Extra Main-Sell Buffer (for color modes)
#endif
input bool invertOperative2nd = false; //C2 Invert Operative (Flip Buy-Sell)


#ifdef __MQL5__
   input group "Exit Indicator Settings"
#else 
   input string Exit_Indicator_Settings = "==============="; //Exit Indicator Settings
#endif
input bool useExitIndicator = false; //USE EXIT INDICATOR
input string indicatorNameExit = "Folder\\Name"; //EXIT Indicator NAME
input string indicatorParamsExit = ""; //EXIT Ind. PARAMETERS (60 MAX ; empty = Default)
input IndicatorRead indicatorModeExit = ZERO_LINE_CROSS; //EXIT Indicator Read Mode
input bool useExitAtSignal = false; //EXIT Check Only Signals (not current state)
input int mainBufferExit = 0; //EXIT Main Buffer (lead)
input int signalBufferExit = 1; //EXIT Second Buffer (signal, if used)
input double crossLevelExit = 0.0; //EXIT Cross Level 
input double widthFilterExit = 0.0; //EXIT Half Filter 
#ifdef __MQL5__
   input int colorBuyExit = 0; //EXIT Buy Color Index
   input int colorSellExit = 1; //EXIT Sell Color Index
#else
   input int colorSellExit = 1; // EXIT Extra Main-Sell Buffer (for color modes)
#endif
input bool invertOperativeExit = false; //EXIT Invert Operative (Flip Buy-Sell)


#ifdef __MQL5__
   input group "Volume Indicator Settings"
#else 
   input string Volume_Indicator_Settings = "==============="; //Volume Indicator Settings
#endif
input bool useVolumeIndicator = false; //USE VOLUME INDICATOR
input string indicatorNameVolume = "Folder\\Name";  //VOLUME Indicator NAME
input string indicatorParamsVolume = ""; //VOLUME Ind. PARAMETERS (60 MAX ; empty = Default)
input VolumeRead indicatorModeVolume = OVER_LEVEL; //VOLUME Indicator Read Mode
input int mainBufferVolume = 0; //VOLUME Main Buffer
input int signalBufferVolume = 1; //VOLUME Signal Buffer
input double minimumLevelVolume = 1.0; //VOLUME Volume Level
input double widthLevelVolume = 0.5; //VOLUME Width (for bidirecional volume: L+W, L-W)
//input int colorBufferVolume = 0; // VOLUME Color Index Buffer
input int volColorBuy = 0;       //VOLUME Buy Color Index
input int volColorSell = 1;      //VOLUME Sell Color Index


#ifdef __MQL5__
   input group "Baseline Settings"
#else 
   input string Baseline_Settings = "==============="; //Baseline Settings
#endif
input bool useBaseline = false; //USE BASELINE
input string indicatorNameBaseline = "Folder\\Name"; //BASELINE NAME
input string indicatorParamsBaseline = ""; //BASELINE PARAMETERS (60 MAX ; empty = Default)
input int baselineBuffer = 0; //BASELINE Buffer


#ifdef __MQL5__
   input group "Continuation Indicator Settings"
#else 
   input string Continuation_Indicator_Settings = "==============="; //Continuation Indicator Settings
#endif
input ContinuationIndicatorMode useContIndicator = CONT_DONT_USE; //USE CONTINUATION INDICATOR
input string indicatorNameCont = "Folder\\Name"; //CONTINUATION Indicator NAME
input string indicatorParamsCont = ""; //CONTINUATION Ind. PARAMETERS (60 MAX ; empty = Default)
input IndicatorRead indicatorModeCont = ZERO_LINE_CROSS; //CONTINUATION Indicator Read Mode
input int mainBufferCont = 0; //CONTINUATION Main Buffer (lead)
input int signalBufferCont = 1; //CONTINUATION Second Buffer (signal, if used)
input double crossLevelCont = 0.0; //CONTINUATION Cross Level 
input double widthFilterCont = 0.0; //CONTINUATION Half Filter 
#ifdef __MQL5__
input int colorBuyCont = 0; //CONTINUATION Buy Color Index
input int colorSellCont = 1; //CONTINUATION Sell Color Index
#else
   input int colorSellCont = 1; // CONTINUATION Extra Main-Sell Buffer (for color modes)
#endif
input bool invertOperativeCont = false; //CONTINUATION Invert Operative (Flip Buy-Sell)


#ifdef __MQL5__
   input group "Extra Settings"
#else 
   input string Extra_Settings = "==============="; //Extra Settings
#endif
input bool scaleOut = true;               //Scale Out (Half with Trailing Stop)
input bool applyCatchUp = true;				//Wait to Catch Up (C2 and Volume after Baseline Cross)
input bool applyPullbackRule = true;      //Apply Pullbacks
input bool applyOneCandleRule = true;     //Apply One-Candle Rule
input bool applyBridgeTooFar = false;     //Apply Bridge Too Far


#ifdef __MQL5__
   input group "EVZ Settings"
#else 
   input string EVZ_Settings = "==============="; //EVZ Settings
#endif
input bool useEvz = false;                //Use EVZ (Euro FX Vix)
input bool scaleOutHalfRisk = false;      //Scale Out When EVZ < Half Risk
input double halfRiskEvz = 7.0;           //EVZ Limit (Half Risk)
input double minimumEvz = 5.0;            //Minimum EVZ (No trade)


#ifdef __MQL5__
   input group "Other Filtering Settings"
#else 
   input string Other_Filtering_Settings = "==============="; //Other Filtering Settings
#endif
input bool useExposure = false;           //Use Exposure
input bool useNews = false;               //Use News
#ifdef __MQL5__
input bool showNewsIndicator = false;     //Show News Indicator (on active pair only)
#endif
input string newsEUR = "Monetary Policy Statement, Lagarde, Draghi"; // EUR News
input string newsGBP = "MPC Official Bank Rate Votes, GDP";   // GBP News
input string newsAUD = "RBA Rate Statement, Unemployment Rate"; // AUD News
input string newsNZD = "Unemployment Rate, GDP, GDT, RBNZ Rate Statement"; // NZD News
input string newsUSD = "\"Non-Farm Employment Change\", FOMC Statement, Fed Chair Powell, CPI"; // USD News
input string newsCAD = "BOC Rate Statement, Unemployment Rate, Retail Sales, \"CPI m/m\""; // CAD News
input string newsCHF = "SNB Monetary Policy Assessment"; // CHF News
input string newsJPY = "Monetary Policy Statement"; // JPY News
sinput int newsIconDistance = 4000; //News Indicator: Icon Distance
sinput int newsIconBetween = 3000; //News Indicator: Distance Between Icons


#ifdef __MQL5__
   input group "Summary Settings"
#else 
   input string Summary_Settings = "==============="; //Summary Settings
#endif
sinput bool writeToFile = true; 				//Create Summary / Optimization files
sinput OptimizationNNFXAlgo optimizationMode = N_TOTAL_PROFIT; //-----Optimization Mode-----
input string customOptimizationFormula = "#PF^2 * ( #GW/max(#NW,1) + #GL/max(#NL,1) )"; // Custom Optimization Formula
sinput bool writeTradeJournal = false; 	//Write Trade Journal
sinput bool showExtendedSummary = false; 	//Show Extended Summary
sinput bool displayIcons = true;				//Display Event Icons


#ifdef __MQL5__
   input group "Advanced Settings"
#else 
   input string Advanced_Settings = "==============="; //Advanced Settings
#endif
input double stopLossAtr = 1.5; //Stop Loss ATR
input double takeProfitAtr = 1.0; //Take Profit ATR
input double startMoveAtr = 2.0; //ATR to start moving Trailing Stop
input double baselineAtr = 1.0; //Distance to Baseline ATR (0=Ignore Distance to Baseline)
input int bridgeTooFarCount = 7; //Bridge Too Far Max Candles
input int atrPeriod = 14; //ATR Period
sinput int minimalPercent = 0; //Minimal % to Count Win/Loss
sinput double riskPercent = 2.0; //Risk (% of balance at risk in each trade)
sinput bool use_advanced_TS = false; //Use Advanced Trailing Stop (indicator)
input string indicatorNameTrailing = "Folder\\Name";  //Trailing Stop Indicator NAME
input string indicatorParamsTrailing = ""; // Trailing Stop Ind. PARAMETERS (60 MAX ; empty = Default)
sinput int TS_buy_buffer = 0; 	// Trailing Stop Buffer for BUY orders
sinput int TS_sell_buffer = 0; 	// Trailing Stop Buffer for SELL orders


#ifdef __MQL5__
   input group "Optimization Parameters"
#else 
   input string Optimization_Parameters = "==============="; //Optimization Parameters
#endif
input double opt_param_1 = 0.0;  // Optimization Parameter 1
input double opt_param_2 = 0.0;  // Optimization Parameter 2
input double opt_param_3 = 0.0;  // Optimization Parameter 3
input double opt_param_4 = 0.0;  // Optimization Parameter 4
input double opt_param_5 = 0.0;  // Optimization Parameter 5
input double opt_param_6 = 0.0;  // Optimization Parameter 6
input double opt_param_7 = 0.0;  // Optimization Parameter 7
input double opt_param_8 = 0.0;  // Optimization Parameter 8
input double opt_param_9 = 0.0;  // Optimization Parameter 9
input double opt_param_10 = 0.0;  // Optimization Parameter 10

input double opt_param_11 = 0.0;  // Optimization Parameter 11
input double opt_param_12 = 0.0;  // Optimization Parameter 12
input double opt_param_13 = 0.0;  // Optimization Parameter 13
input double opt_param_14 = 0.0;  // Optimization Parameter 14
input double opt_param_15 = 0.0;  // Optimization Parameter 15
input double opt_param_16 = 0.0;  // Optimization Parameter 16
input double opt_param_17 = 0.0;  // Optimization Parameter 17
input double opt_param_18 = 0.0;  // Optimization Parameter 18
input double opt_param_19 = 0.0;  // Optimization Parameter 19
input double opt_param_20 = 0.0;  // Optimization Parameter 20

input double opt_param_21 = 0.0;  // Optimization Parameter 21
input double opt_param_22 = 0.0;  // Optimization Parameter 22
input double opt_param_23 = 0.0;  // Optimization Parameter 23
input double opt_param_24 = 0.0;  // Optimization Parameter 24
input double opt_param_25 = 0.0;  // Optimization Parameter 25
input double opt_param_26 = 0.0;  // Optimization Parameter 26
input double opt_param_27 = 0.0;  // Optimization Parameter 27
input double opt_param_28 = 0.0;  // Optimization Parameter 28
input double opt_param_29 = 0.0;  // Optimization Parameter 29
input double opt_param_30 = 0.0;  // Optimization Parameter 30

input double opt_param_31 = 0.0;  // Optimization Parameter 31
input double opt_param_32 = 0.0;  // Optimization Parameter 32
input double opt_param_33 = 0.0;  // Optimization Parameter 33
input double opt_param_34 = 0.0;  // Optimization Parameter 34
input double opt_param_35 = 0.0;  // Optimization Parameter 35
input double opt_param_36 = 0.0;  // Optimization Parameter 36
input double opt_param_37 = 0.0;  // Optimization Parameter 37
input double opt_param_38 = 0.0;  // Optimization Parameter 38
input double opt_param_39 = 0.0;  // Optimization Parameter 39
input double opt_param_40 = 0.0;  // Optimization Parameter 40

input double opt_param_41 = 0.0;  // Optimization Parameter 41
input double opt_param_42 = 0.0;  // Optimization Parameter 42
input double opt_param_43 = 0.0;  // Optimization Parameter 43
input double opt_param_44 = 0.0;  // Optimization Parameter 44
input double opt_param_45 = 0.0;  // Optimization Parameter 45
input double opt_param_46 = 0.0;  // Optimization Parameter 46
input double opt_param_47 = 0.0;  // Optimization Parameter 47
input double opt_param_48 = 0.0;  // Optimization Parameter 48
input double opt_param_49 = 0.0;  // Optimization Parameter 49
input double opt_param_50 = 0.0;  // Optimization Parameter 50