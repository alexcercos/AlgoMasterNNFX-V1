#include "Backtester.mqh"
#include "SummaryFunctions.mqh"
#include "ExposureController.mqh"
#include "ExtendedSummary.mqh"

//Debug handles
#define DEBUG_TRADE_FUNCTION false
#define DEBUG_TRADE_SIZES false

//Porcetaje decimal a exposure en entero (trade percent = /2)
#define PERCENT_TO_EXPOSURE(amount) amount * 200.0
#define EXPOSURE_TO_PERCENT(exposure) exposure / 200.0

#define EVZ_INDICATOR "::Indicators\\Personal\\EuroFXVix"
#define NEWS_INDICATOR "::Indicators\\Personal\\NewsIndicator"
#define INVISIBLE_ATR "::Indicators\\ATR"

class CompleteNNFXTester : public Backtester
{
   protected:
      bool useEvz;
      int evzHandle;
      double evzMinimum;
      double evzHalfRisk;
      bool scaleOut_halfRisk;
      
      double tradePercent;
      double tradeValueInitial;
      bool scaleOutInitial;
      double accountInitial;
      
      bool printAdvancedStats;
      bool writeJournal;
      
      bool saveEquityCurve;
      bool compoundInterest;
      
      double currentMaxPairExposure;
      
      
      bool useExposure;
      ExposureController* exposureControl;
      TradeSummary tradesToExecute[];
      
      
      bool useNews;
      NewsController* newsControl;
      
      
      double pairTops[], maxAbsDrawdown[];
      double maxGeneralTop, maxAbsGeneralDrawdown;
      
      
      //Statistical
      bool recordStatistics;
      double statsStep;
      int statsArray[];
      int maxIndex, minIndex;
      
      //Currency indexes (news/exposure)
      bool currenciesProcessed;
      CurrencyIndexObject* currencyIndexesInfo;
      
      //ROI
      datetime firstTradingDay;
      
      //Advanced TS
      bool use_advanced_ts;
      int adv_ts_buyBuffer, adv_ts_sellBuffer;
      int trailingHandles[];
      
      //Extended Summary
      bool use_extended_summary;
      CExtendedSummary extended_summary;
      
      #ifdef __MQL4__
      string trailingIndName;
      double trailingParameters[];
      #endif
      
      void UpdateEvzValue();
      
      virtual void AddProfits(double amount, double trade_elapsed);
      
      virtual void WaitMissedTrade();
      
      virtual void ExecuteBuy(string where, int signal_place);
      virtual void ExecuteSell(string where, int signal_place);
      
      void ExecuteTradesAfterExposureCheck();
      
      void RecalculateTradeValue();
      
      void SetStateBeforeExposure(int procedence);
      void ResetStateAfterExposure(int procedence, int symbol);
      void ChangeStateAtSymbol(TradeStates newState, int symbol);
      
      
      void ProcessCurrencies();
      
      virtual void UpdateTrailingStops();
      
      virtual void CheckForNewsExit();
      virtual void CloseEvent(datetime time, double profit, CloseTradeProcedence procedence, TradeCloseLevel level);
      
      void DetectPossibleGaps();

   public:
      CompleteNNFXTester(double trade_percent, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool result_in_pips=false, bool use_main_exit=true, double minimalTrade=0.5, double sl_atr=1.5, double tp_atr=1.0, double start_move_sl=2.0, bool advancedStats=false, bool useDistributions=false);
      ~CompleteNNFXTester();
      
      virtual double TesterResult(int optimization_mode, int write_to_file, string custom_str);
      virtual void BacktesterTick();
      
      void SetEVZHandle(int handle, double minimum, double halfRisk, bool scaleAtHalfRisk);
      
      void RecordEquityCurve() { if (!MQLInfoInteger(MQL_OPTIMIZATION)){ saveEquityCurve = true; ClearEquityFile(); } }
      void RecordTradeJournal() { if (!MQLInfoInteger(MQL_OPTIMIZATION)){ writeJournal = true; ClearJournalFile(); } }
      
      #ifdef __MQL5__
      void SetRealTradeMode();
      #endif
      
      void UseCompoundInterest() { compoundInterest = true; }
      void UseCurrencyExposure();
      void UseNewsFiltering(string news_EUR, string news_GBP, string news_AUD, string news_NZD, string news_USD, string news_CAD, string news_CHF, string news_JPY);
      
      void SetDistanceBaseline(double atrMult) {atrDistanceMultiplier = atrMult; }
      void SetBridgeTooFarCount(int btfCount) { bridgeTooFarCount = btfCount; }
      
      void SetAdvancedTrailingStops(int buy_buffer, int sell_buffer);
      void SetTrailingHandle(int handle, int symbolIndex);
      
      void UseExtendedSummary() { if (!MQLInfoInteger(MQL_OPTIMIZATION)) use_extended_summary = true; }
      
   #ifdef __MQL4__
      void SetTrailingIndicatorProperties(string indicator_name, double &parameters[]);
   #endif
};

CompleteNNFXTester::CompleteNNFXTester(double trade_percent,string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out,bool result_in_pips=false,bool use_main_exit=true,double minimalTrade=0.5,double sl_atr=1.5,double tp_atr=1.0,double start_move_sl=2.0, bool advancedStats=false, bool useDistributions=false)
   :Backtester(trade_percent*AccountInfoDouble(ACCOUNT_BALANCE), symbolsArray, pullback, one_candle, bridge_tf, scale_out, MQLInfoInteger(MQL_VISUAL_MODE), DEBUG_TRADE_FUNCTION, DEBUG_TRADE_SIZES, result_in_pips, use_main_exit)
{
   minimalTradePercent = minimalTrade;
   
   currenciesProcessed = false;
   
   tradePercent = trade_percent;
   accountInitial = AccountInfoDouble(ACCOUNT_BALANCE);
   tradeValueInitial = accountInitial * tradePercent;
   
   currentMaxPairExposure = PERCENT_TO_EXPOSURE(tradePercent); // En entero
   
   scaleOutInitial = scaleOut;
   useEvz = false;
   
   saveEquityCurve = false;
   compoundInterest = false;
   useExposure = false;
   
   firstTradingDay = TimeCurrent();
   
   use_extended_summary = false;
   
   recordStatistics = useDistributions;
   if (recordStatistics)
   {
      statsStep = tradeValueInitial==0.0 ? 1.0 : tradeValueInitial*2.0 / 10.0; //Dividir en 10 pasos
      minIndex = -10;
      maxIndex = 0;
      
      ArrayResize(statsArray, maxIndex - minIndex + 1);
      ArrayInitialize(statsArray, 0);
   }
   
   
   printAdvancedStats = advancedStats;
   
   ArrayResize(pairTops, totalSymbols);
   ArrayFill(pairTops, 0, totalSymbols, 0.0);
   ArrayResize(maxAbsDrawdown, totalSymbols);
   ArrayFill(maxAbsDrawdown, 0, totalSymbols, 0.0);
   maxGeneralTop = 0.0;
   maxAbsGeneralDrawdown = 0.0;
   
   use_advanced_ts = false;
   ArrayResize(trailingHandles, totalSymbols);

   for (int i=0; i < totalSymbols; i++)
   {
      buyArray[i].AdvancedSettings(sl_atr, tp_atr, start_move_sl, true);
      sellArray[i].AdvancedSettings(sl_atr, tp_atr, start_move_sl, true);
   }
}

void CompleteNNFXTester::SetTrailingHandle(int handle, int symbolIndex)
{
	trailingHandles[symbolIndex] = handle;
}

void CompleteNNFXTester::SetAdvancedTrailingStops(int buy_buffer, int sell_buffer)
{
	use_advanced_ts = true;
	
	adv_ts_buyBuffer = buy_buffer;
	adv_ts_sellBuffer = sell_buffer;
}

#ifdef __MQL4__
void CompleteNNFXTester::SetTrailingIndicatorProperties(string indicator_name,double &parameters[])
{
   trailingIndName = indicator_name;
   ArrayCopy(trailingParameters, parameters);
}
#endif

void CompleteNNFXTester::UseCurrencyExposure(void)
{
   useExposure = true;
   
   ProcessCurrencies();
   
   exposureControl = new ExposureController(currencyIndexesInfo);
}

#ifdef __MQL5__
void CompleteNNFXTester::SetRealTradeMode(void)
{
	for (int i=0; i < totalSymbols; i++)
   {
      buyArray[i].SetRealTrades();
      sellArray[i].SetRealTrades();
   }
}
#endif

void CompleteNNFXTester::UseNewsFiltering(string news_EUR, string news_GBP, string news_AUD, string news_NZD, string news_USD, string news_CAD, string news_CHF, string news_JPY)
{
   useNews = true;
   
   ProcessCurrencies();
   
   newsControl = new NewsController(currencyIndexesInfo);
   
   newsControl.ProcessNewsArrays(news_EUR, news_GBP, news_AUD, news_NZD, news_USD, news_CAD, news_CHF, news_JPY);
}

void CompleteNNFXTester::ProcessCurrencies(void)
{
   if (currenciesProcessed) return;
   
   currenciesProcessed = true;
   
   currencyIndexesInfo = new CurrencyIndexObject(symbolsToTrade);
}

CompleteNNFXTester::~CompleteNNFXTester()
{
   if (useExposure) delete exposureControl;
   if (useNews) delete newsControl;
   if (currenciesProcessed) delete currencyIndexesInfo;
}

double CompleteNNFXTester::TesterResult(int optimization_mode, int write_to_file, string custom_str)
{
	#ifdef __MQL5__
	if (optimization_mode == N_REAL_TRADES) return 0.0; //Don't do anything
	#endif 
	
   CloseTradesAtEnd();
   
   int numberOfLoses=0, numberOfWins=0;
   
   bool printStatistics = optimization_mode == N_DIST_SHAPE || optimization_mode == N_DIST_VALUE;
   
   for (int i = 0; i < totalSymbols; i++)
   {
      numberOfLoses += totalLosesArray[i];
      numberOfWins += totalWinsArray[i];
      
      if (!printStatistics)
         SymbolPrint(optimization_mode, symbolsToTrade[i], totalWinsArray[i], totalLosesArray[i], grossWinArray[i], grossLossArray[i], maxAbsDrawdown[i]);
   }
   
   //Statistics
   double statsShape=0.0, statsValue=0.0;
   if (recordStatistics)
   {
      CalculateStatistics(statsStep, maxIndex, minIndex, statsArray, statsShape, statsValue);
      
      if (printStatistics)
      {
         PrintStatsSummary(statsStep, maxIndex, minIndex, statsArray, statsShape, statsValue);
         if (write_to_file != NO_WRITE) WriteDistributionFile(statsStep, maxIndex, minIndex, statsArray);
      }
         
   }
   
   
   double g_winRate, g_profitFactor, g_expectedPayoff, g_ROI;
   
   CalculateGeneralStats(numberOfWins, numberOfLoses, grossWin, grossLoss, g_winRate, g_profitFactor, g_expectedPayoff);
   
   double years = ((TimeCurrent()-firstTradingDay)/(ONE_DAY * 365.0));
   
   CalculateReturnOnInvestment((grossWin+grossLoss)/accountInitial, years, compoundInterest, g_ROI);
   
   // Final Summary Prints
   FinalPrints(optimization_mode, numberOfWins, numberOfLoses, grossWin, grossLoss, g_winRate);
   
   if (use_extended_summary) extended_summary.PrintExtendedSummary();
   
   if (printAdvancedStats)
   {
      PrintAdvancedStats(g_profitFactor, maxAbsGeneralDrawdown, g_expectedPayoff, g_ROI);
   }
   
   if (write_to_file == SUMMARY)
   {
      WriteSummaryFile(optimization_mode, 
                           symbolsToTrade, 
                           totalWinsArray, 
                           totalLosesArray, 
                           grossWinArray, 
                           grossLossArray,
                           maxAbsDrawdown, 
                           totalSymbols,
                           years,
                           accountInitial,
                           compoundInterest);
      
      if (printAdvancedStats)
      {
         WriteMetricsInSummary(g_winRate, 
                              numberOfLoses+numberOfWins,
                              g_profitFactor, 
                              g_expectedPayoff, 
                              -maxAbsGeneralDrawdown,
                              g_ROI, 
                              grossWin+grossLoss, 
                              statsValue, 
                              statsShape);
      }
   }
   
   if (write_to_file == OPTIMIZE)
   {
      WriteOptimizeFile(optimization_mode, g_winRate, 
                           g_profitFactor, 
                           g_expectedPayoff, 
                           -maxAbsGeneralDrawdown,
                           g_ROI, 
                           grossWin+grossLoss, 
                           statsValue, 
                           statsShape,
                           numberOfLoses+numberOfWins);
   }
   
   DetectPossibleGaps();
   
   
   if (optimization_mode == N_WIN_RATE)
      return g_winRate;
      
   if (optimization_mode == N_TOTAL_PIPS || optimization_mode == N_TOTAL_PROFIT)
      return grossWin+grossLoss;
      
   if (optimization_mode == N_DRAWDOWN)
      return -maxAbsGeneralDrawdown;
      
   if (optimization_mode == N_PROFIT_FACTOR)
      return g_profitFactor;
   
   if (optimization_mode == N_EXP_PAYOFF)
      return g_expectedPayoff;
      
   if (optimization_mode == N_DIST_VALUE)
      return statsValue;
      
   if (optimization_mode == N_DIST_SHAPE)
      return statsShape;
      
   if (optimization_mode == N_EQUITY_COMP || optimization_mode == N_EQUITY_CURVE)
      return grossWin + grossLoss;
      
   if (optimization_mode == N_ROI)
      return g_ROI;
      
   if (optimization_mode == N_CUSTOM_OPTIMIZE)
   {
   	//Create Dictionary
   	CDictionary* var_dict = new CDictionary();
   	
   	var_dict.Set<double>("#WR", g_winRate);
   	var_dict.Set<double>("#DD", maxAbsGeneralDrawdown); //POSITIVE
   	var_dict.Set<double>("#PF", g_profitFactor);
   	var_dict.Set<double>("#EP", g_expectedPayoff);
   	var_dict.Set<double>("#SV", statsValue);
   	var_dict.Set<double>("#SS", statsShape);
   	var_dict.Set<double>("#ROI", g_ROI);
   	
   	var_dict.Set<double>("#NW", double(numberOfWins));
   	var_dict.Set<double>("#NL", double(numberOfLoses));
   	var_dict.Set<double>("#NT", double(numberOfWins+numberOfLoses)); //Number of trades
   	var_dict.Set<double>("#GW", grossWin);
   	var_dict.Set<double>("#GL", grossLoss);
   	var_dict.Set<double>("#FP", grossWin+grossLoss); //Final Profit
   
   	double result = EvaluateCustomOptimization(custom_str, var_dict);
   	
   	delete var_dict;
   	return result;
   }
      
   return 0.0;
}

void CompleteNNFXTester::BacktesterTick()
{
   //Interes compuesto
   if (compoundInterest) RecalculateTradeValue();

   //Evz, News y tal
   UpdateEvzValue();
   
   if (useExposure || useNews) ArrayFree(tradesToExecute);
   
   if (useNews) newsControl.GetNewsOfCandle(TimeCurrent());
   
   
   ///###############################
   GenericBacktester::BacktesterTick();
   
   
   if (useNews) newsControl.DiscardTradesWithNews(tradesToExecute);
   
   if (useExposure)
   {
      //Calcular exposure (puede haber cerrado trades, pero no abierto nuevos)
      
      exposureControl.ResetExposure();
      
      for (int i=0; i<totalSymbols; i++)
      {
         exposureControl.AddExposure(i, buyArray[i].GetExposure(), true);
         exposureControl.AddExposure(i, sellArray[i].GetExposure(), false);
      }
      
      exposureControl.ProcessTradesWithExposure(tradesToExecute, currentMaxPairExposure);
   }
   
   if (useNews || useExposure)
   {
      //Tomar trades (como los devuelva el exposure controller)
      ExecuteTradesAfterExposureCheck();
   }
   
   if (saveEquityCurve) WriteEquity(currentRates[DATA_RECENT].time, accountInitial + grossWin + grossLoss);
}

void CompleteNNFXTester::SetEVZHandle(int handle, double minimum, double halfRisk, bool scaleAtHalfRisk)
{
   useEvz = true;
   
   evzHandle = handle;
   evzMinimum = minimum;
   evzHalfRisk = halfRisk;
   scaleOut_halfRisk = scaleAtHalfRisk;
}

void CompleteNNFXTester::UpdateEvzValue(void)
{
   if (!useEvz) return;
   
   #ifdef __MQL5__ 
   
      //EVZ para MT5 solamente
      
      double values[];
      CopyBuffer(evzHandle, 0, DISPLACEMENT, 1, values);
      
      double currentEvz = values[0];
      
   #else
   
      double currentEvz = iCustom(_Symbol, PERIOD_CURRENT, EVZ_INDICATOR, 0, DISPLACEMENT);
      
   #endif
      
      if (currentEvz == 0 || currentEvz == EMPTY_VALUE)
      {
         tradeValue = tradeValueInitial;
         return;
      }
      
      if (currentEvz < evzMinimum)
      {
         tradeValue = 0.0;
         currentMaxPairExposure = 0.0;
      }
      else if (currentEvz < evzHalfRisk)
      {
         tradeValue = tradeValueInitial / 2.0;
         currentMaxPairExposure = PERCENT_TO_EXPOSURE(tradePercent)/2.0;
      }
         
      else //currentEvz >= evzHalfRisk
      {
         tradeValue = tradeValueInitial;
         currentMaxPairExposure = PERCENT_TO_EXPOSURE(tradePercent);
      }
         
         
      if (!scaleOut_halfRisk) //Sino, se mantiene como este al principio
      {
         if (currentEvz < evzHalfRisk)
            scaleOut = false;
         else
            scaleOut = scaleOutInitial;
      }
      
}

void CompleteNNFXTester::WaitMissedTrade(void)
{
   //Print("Miss");
   if (!useBaseline)
   {
      ChangeState(MAIN_SIGNAL);
      return;
   }
   
   int currentSignal, reverseSignal;
   
   string out_info = "";

   
   if (CheckMainConfirmationSignal(out_info, BUY_SIGNAL, false))         { currentSignal = BUY_SIGNAL; reverseSignal = SELL_SIGNAL; }
   else if (CheckMainConfirmationSignal(out_info, SELL_SIGNAL, false))   { currentSignal = SELL_SIGNAL; reverseSignal = BUY_SIGNAL; }
   else { return; }
   
   if (CheckExitIndicator(out_info, reverseSignal)) //Si son opuestos, uno da salida
   {
      ChangeState(CONTINUATION);
      return;
   }
   
   // Se da la vuelta, Continuation
   if (useMainForExit && !CheckBaseline(out_info, currentSignal))
   {
      ChangeState(CONTINUATION);
      return;
   }
}

void CompleteNNFXTester::ExecuteBuy(string where, int signal_place)
{
   if (tradeValue == 0.0) 
   {
      DebugFilteredTrade(BUY_SIGNAL, where, "EVZ", "");
      if (useBaseline)
         ChangeState(MISSED_TRADE);
      else
      	ChangeState(MAIN_SIGNAL);
      return;
   }
   
   if (!buyArray[activeSymbol].CheckIfOpen())
   {
      //Guardar trades en arrays para procesar al final, y comprobar exposure
   
      double price = currentRates[DATA_RECENT].close;
      datetime time = currentRates[DATA_RECENT].time;
      
      #ifdef __MQL5__
      double atr = atrCurrentValues[DATA_RECENT];
      #else
      double atr = GetIndicatorValue(ATR_IND, DISPLACEMENT);
      #endif
   
      if (useExposure  || useNews)
      {
         int tradeAmount = ArraySize(tradesToExecute);
         ArrayResize(tradesToExecute, tradeAmount+1);
         
         tradesToExecute[tradeAmount].open_price = price;
         tradesToExecute[tradeAmount].atr = atr;
         tradesToExecute[tradeAmount].open_time = time;
         tradesToExecute[tradeAmount].order_type = ORDER_TYPE_BUY;
         tradesToExecute[tradeAmount].symbol_index = activeSymbol;
         tradesToExecute[tradeAmount].result_exposure = useExposure ? 0.0 : currentMaxPairExposure;
         tradesToExecute[tradeAmount].trade_procedence = signal_place;
         
         SetStateBeforeExposure(signal_place);
      }
      else
      {
         buyArray[activeSymbol].OpenTrade(price, atr, ORDER_TYPE_BUY, time, tradeValue, scaleOut, currentMaxPairExposure);
         
         if (writeJournal) WriteInJournal(time, symbolsToTrade[activeSymbol], 0.0, "BUY OPEN");
         
         DebugCompleteTrade(ORDER_TYPE_BUY, where);
      }
      
      color arrowColor;
      string arrowString;
      GetTradeIconSets(signal_place, arrowColor, arrowString);
      CreateNewIcon(TRADE_SYMBOL, arrowString, arrowColor);
   }
   else
   {
      DebugFilteredTrade(ORDER_TYPE_BUY, where, "ALREADY OPEN", "");
   }
}

void CompleteNNFXTester::ExecuteSell(string where, int signal_place)
{
   if (tradeValue == 0.0) 
   {
      DebugFilteredTrade(SELL_SIGNAL, where, "EVZ", "");
      if (useBaseline)
         ChangeState(MISSED_TRADE);
      else
      	ChangeState(MAIN_SIGNAL);
      return;
   }
   
   if (!sellArray[activeSymbol].CheckIfOpen())
   {
      //Guardar trades en arrays para procesar al final, y comprobar exposure
   
      double price = currentRates[DATA_RECENT].close;
      datetime time = currentRates[DATA_RECENT].time;
      
      #ifdef __MQL5__
      double atr = atrCurrentValues[DATA_RECENT];
      #else
      double atr = GetIndicatorValue(ATR_IND, DISPLACEMENT);
      #endif
      
      if (useExposure || useNews)
      {
         int tradeAmount = ArraySize(tradesToExecute);
         ArrayResize(tradesToExecute, tradeAmount+1);
         
         tradesToExecute[tradeAmount].open_price = price;
         tradesToExecute[tradeAmount].atr = atr;
         tradesToExecute[tradeAmount].open_time = time;
         tradesToExecute[tradeAmount].order_type = ORDER_TYPE_SELL;
         tradesToExecute[tradeAmount].symbol_index = activeSymbol;
         tradesToExecute[tradeAmount].result_exposure = useExposure ? 0.0 : currentMaxPairExposure;
         tradesToExecute[tradeAmount].trade_procedence = signal_place;
         
         SetStateBeforeExposure(signal_place);
      }
      else
      {
         sellArray[activeSymbol].OpenTrade(price, atr, ORDER_TYPE_SELL, time, tradeValue, scaleOut, currentMaxPairExposure);
         
         if (writeJournal) WriteInJournal(time, symbolsToTrade[activeSymbol], 0.0, "SELL OPEN");
         
         DebugCompleteTrade(ORDER_TYPE_SELL, where);
      }
      
      color arrowColor;
      string arrowString;
      GetTradeIconSets(signal_place, arrowColor, arrowString);
      CreateNewIcon(TRADE_SYMBOL, arrowString, arrowColor);
   }
   else
   {
      DebugFilteredTrade(ORDER_TYPE_SELL, where, "ALREADY OPEN", "");
   }
}

void CompleteNNFXTester::AddProfits(double amount, double trade_elapsed)
{
   GenericBacktester::AddProfits(amount, trade_elapsed);
   
   if (amount == 0.0) return;
   
   //drawdown pair y general
   
   if (maxGeneralTop < (grossWin + grossLoss)) maxGeneralTop = grossWin + grossLoss;
   if (pairTops[activeSymbol] < (grossWinArray[activeSymbol] + grossLossArray[activeSymbol])) pairTops[activeSymbol] = grossWinArray[activeSymbol] + grossLossArray[activeSymbol];
   
   double currentDD, currentSymbolDD;
   
   if (compoundInterest)
   {
      currentDD = (maxGeneralTop - (grossWin + grossLoss)) / (accountInitial + grossWin + grossLoss)*100.0;
      currentSymbolDD = (pairTops[activeSymbol] - (grossWinArray[activeSymbol] + grossLossArray[activeSymbol])) / (accountInitial + grossWinArray[activeSymbol] + grossLossArray[activeSymbol])*100.0;
   }
   else
   {
      currentDD = (maxGeneralTop - (grossWin + grossLoss)) / accountInitial*100.0;
      currentSymbolDD = (pairTops[activeSymbol] - (grossWinArray[activeSymbol] + grossLossArray[activeSymbol])) / accountInitial*100.0;
   }
   
   
   if (maxAbsGeneralDrawdown < currentDD) maxAbsGeneralDrawdown = currentDD;
   if (maxAbsDrawdown[activeSymbol] < currentSymbolDD) maxAbsDrawdown[activeSymbol] = currentSymbolDD;
   
   if (recordStatistics)
   {
      int current = (int)MathRound(amount / statsStep);
      
      if (current > maxIndex)
      {
         ArrayResize(statsArray, current - minIndex + 1);
         ArrayFill(statsArray, maxIndex - minIndex, current - maxIndex+1, 0);
         maxIndex = current;
      }
      if (current < minIndex)
      {
         current = minIndex;
         Print("STAT INDEX OUT OF RANGE");
      }
      
      statsArray[current - minIndex] += 1;
   }
}

void CompleteNNFXTester::RecalculateTradeValue(void)
{
   //Solo para interes compuesto
   tradeValueInitial = tradePercent * (accountInitial + grossLoss + grossWin);
}

void CompleteNNFXTester::ExecuteTradesAfterExposureCheck()
{
   for (int i=0; i<ArraySize(tradesToExecute); i++)
   {
      int symbolId = tradesToExecute[i].symbol_index;
      double price = tradesToExecute[i].open_price;
      double atr = tradesToExecute[i].atr;
      datetime time = tradesToExecute[i].open_time;
      
      double exposure = tradesToExecute[i].result_exposure;
      
      double tradeFinalValue = tradeValueInitial * (EXPOSURE_TO_PERCENT(exposure) / tradePercent);
      
      
      if (tradesToExecute[i].order_type == ORDER_TYPE_BUY)
      {
         buyArray[symbolId].OpenTrade(price, atr, ORDER_TYPE_BUY, time, tradeFinalValue, scaleOut, exposure);
         
         if (writeJournal) WriteInJournal(time, symbolsToTrade[symbolId], 0.0, "BUY OPEN");
      }
      else //tradesToExecute[i].order_type == ORDER_TYPE_SELL
      {
         sellArray[symbolId].OpenTrade(price, atr, ORDER_TYPE_SELL, time, tradeFinalValue, scaleOut, exposure);
         
         if (writeJournal) WriteInJournal(time, symbolsToTrade[symbolId], 0.0, "SELL OPEN");
      }
      
      ResetStateAfterExposure(tradesToExecute[i].trade_procedence, symbolId);
   }
}

void CompleteNNFXTester::SetStateBeforeExposure(int procedence)
{
   if (!useBaseline)
   {
      ChangeState(MAIN_SIGNAL); //Por si es OCR
   }
   else if (procedence != TP_CONTINUATION)
   {
      ChangeState(MISSED_TRADE);
   }
}

void CompleteNNFXTester::ResetStateAfterExposure(int procedence, int symbol)
{
   if (!useBaseline) return; //Ya estarian los correctos
   
   ChangeStateAtSymbol(CONTINUATION, symbol);
}

void CompleteNNFXTester::ChangeStateAtSymbol(TradeStates newState, int symbol)
{
   tradeCurrentState[symbol] = newState;
}

void CompleteNNFXTester::UpdateTrailingStops(void)
{
	if (!buyArray[activeSymbol].HasTouchedTP() && !sellArray[activeSymbol].HasTouchedTP()) return;
	
	#ifdef __MQL5__
	int finalDisplace;
   if (correctIndicatorDisplace)
   {
      finalDisplace = 0; //Caso especifico -> Gap en la siguiente vela (no actual) y sin displaceCorrection, se ignora el desplazamiento
   }
   else
   {
      finalDisplace = displaceCorrection[activeSymbol] + DISPLACEMENT;
   }
   double trailingValue[];
   #endif
   
   if (buyArray[activeSymbol].HasTouchedTP())
   {
   	if (use_advanced_ts)
   	{
   	   #ifdef __MQL5__
   		CopyBuffer(trailingHandles[activeSymbol], adv_ts_buyBuffer, finalDisplace, 1, trailingValue);
   		double tValue = trailingValue[0];
   		#else
   		double tValue = GetICustom(trailingIndName, trailingParameters, adv_ts_buyBuffer, DISPLACEMENT);
   		#endif
   		
   		buyArray[activeSymbol].UpdateTrailingStopToValue(currentRates[DATA_RECENT].close, tValue, currentRates[DATA_RECENT].time);
   	}
   	else
   		buyArray[activeSymbol].UpdateTrailingStop(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time);
   }
   if (sellArray[activeSymbol].HasTouchedTP())
   {
   	if (use_advanced_ts)
   	{
   	   #ifdef __MQL5__
   		CopyBuffer(trailingHandles[activeSymbol], adv_ts_sellBuffer, finalDisplace, 1, trailingValue);
   		double tValue = trailingValue[0];
   		#else
   		double tValue = GetICustom(trailingIndName, trailingParameters, adv_ts_sellBuffer, DISPLACEMENT);
   		#endif
   		
   		sellArray[activeSymbol].UpdateTrailingStopToValue(currentRates[DATA_RECENT].close, tValue, currentRates[DATA_RECENT].time);
   	}
   	else
   		sellArray[activeSymbol].UpdateTrailingStop(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time);
   }
      
}

void CompleteNNFXTester::CheckForNewsExit() //En Generic Backtester
{
   if (!useNews) return;
   
   int longId, shortId;
   currencyIndexesInfo.GetLongShortIds(activeSymbol, ORDER_TYPE_BUY, longId, shortId); //No importa Order Type
   if (newsControl.CheckNewsOfPair(longId, shortId))
   {
      if (buyArray[activeSymbol].GetExposure()>0.0)
      {
         if (CloseTrade(ORDER_TYPE_BUY, CTP_NEWS))
            CreateNewIcon(174, "EXIT BY NEWS", NEWS_COLOR);
      }
      if (sellArray[activeSymbol].GetExposure()>0.0)
      {
         if (CloseTrade(ORDER_TYPE_SELL, CTP_NEWS))
            CreateNewIcon(174, "EXIT BY NEWS", NEWS_COLOR);
      }
   }
   
}

void CompleteNNFXTester::DetectPossibleGaps(void)
{
   int symbolCandles[];
   ArrayResize(symbolCandles, totalSymbols);

   int maxCandles = iBarShift(Symbol(), PERIOD_CURRENT, firstTradingDay);
   bool detected = false;
   
   for (int i=0; i<totalSymbols; i++)
   {
      symbolCandles[i] = iBarShift(symbolsToTrade[i], PERIOD_CURRENT, firstTradingDay);
      
      if (symbolCandles[i] != maxCandles)
      {
         detected = true;
         maxCandles = MathMax(symbolCandles[i], maxCandles);
      }
   }
   
   if (detected)
   {
      Print(BIG_SEPARATOR_LINE);
      Print(BIG_SEPARATOR_LINE);
      Print("Possible gaps in data history have been detected:");
      
      for (int i=0; i<totalSymbols; i++)
      {
         if (symbolCandles[i] < maxCandles)
         {
            int missing = maxCandles - symbolCandles[i];
            Print(" - ", symbolsToTrade[i], " : ", missing, " candles missing");
         }
      }
      
      Print("The results of the trading symbols displayed above can be inaccurate.");
      Print("IF THE BACKTEST WAS PERFORMED IN ONE OF THOSE SYMBOLS, ALL OF THE TEST RESULTS MAY BE ALTERED.");
      Print("(The symbol with the maximum amount of candles is the one used for reference to count missing candles)");
      Print(BIG_SEPARATOR_LINE);
   }
}

void CompleteNNFXTester::CloseEvent(datetime time, double profit, CloseTradeProcedence procedence, TradeCloseLevel level)
{
	if (use_extended_summary)
	{
		switch (level)
		{
			case TCL_MAX_SL:
				extended_summary.Add_MaxSL();
				break;
			case TCL_LOSS:
			{
				if (procedence == CTP_BASELINE) extended_summary.Add_Loss_Baseline();
				else if (procedence == CTP_C1) extended_summary.Add_Loss_C1();
				else if (procedence == CTP_EXIT) extended_summary.Add_Loss_Exit();
				else if (procedence == CTP_NEWS) extended_summary.Add_Loss_News();
				break;
			}
			case TCL_BE:
				extended_summary.Add_Breakeven();
				break;
			case TCL_PROFIT_BEFORE:
			{
				if (procedence == CTP_BASELINE) extended_summary.Add_BeforeTP_Baseline();
				else if (procedence == CTP_C1) extended_summary.Add_BeforeTP_C1();
				else if (procedence == CTP_EXIT) extended_summary.Add_BeforeTP_Exit();
				else if (procedence == CTP_NEWS) extended_summary.Add_BeforeTP_News();
				break;
			}
			case TCL_TRAILING_STOP:
				extended_summary.Add_TrailingStop();
				break;
			case TCL_PROFIT_AFTER:
			{
				if (procedence == CTP_BASELINE) extended_summary.Add_AfterTP_Baseline();
				else if (procedence == CTP_C1) extended_summary.Add_AfterTP_C1();
				else if (procedence == CTP_EXIT) extended_summary.Add_AfterTP_Exit();
				break;
			}
		}
	}

   if (writeJournal) WriteInJournal(time, symbolsToTrade[activeSymbol], profit, GetProcedenceString(procedence));
}