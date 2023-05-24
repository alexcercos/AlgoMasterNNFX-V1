//+------------------------------------------------------------------+
//|                                            GenericBacktester.mqh |
//|                                 Copyright 2020, Alejandro Cercós |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Alejandro Cercós"
#property link      "https://www.mql5.com"

#include "VirtualTrades.mqh" //Virtual Trades
#include "IndicatorReader.mqh" //Indicator Read

#define DISPLACEMENT 1

#define DATA_RECENT 1
#define DATA_PAST 0

#define ICON_DISTANCE 1000

#define MAIN_IND_COLOR clrYellowGreen
#define SECOND_IND_COLOR clrOrange
#define VOLUME_IND_COLOR clrDarkOliveGreen
#define EXIT_IND_COLOR clrSkyBlue
#define BASELINE_COLOR clrAqua
#define CONTINUATION_COLOR clrSeaGreen
#define BRIDGE_TF_COLOR clrSienna
#define DISTANCE_COLOR clrWhiteSmoke
#define NEWS_COLOR clrRed

#define EXIT_SYMBOL 174
#define UNKNOWN_SYMBOL 117
#define TRADE_SYMBOL 254
#define NO_TRADE_SYMBOL 253


class GenericBacktester
{
   protected:
      //GAP correction
      bool displaceCalculated;
      int displaceCorrection[];
      datetime lastRateTime;
      bool currentIsGap;
      bool correctIndicatorDisplace;
      
      //Variables internas
      double tradeValue;      // Risk per trade
      bool scaleOut;
      bool debugTrades;
      bool resultInPips;
      MqlRates currentRates[2];
      
      double crossLevel,      crossLevel2nd,      crossLevelExit,    minimumLevelVolume,  crossLevelCont;
      double widthFilter,     widthFilter2nd,     widthFilterExit,   widthBidirectVolume, widthFilterCont;
      bool   invertOperative, invertOperative2nd, invertOperativeExit, invertOperativeCont;
      
      int    mainBuffer,      mainBuffer2nd,      mainBufferExit,    mainBufferVolume, baselineBuffer, mainBufferCont;
      int    signalBuffer,    signalBuffer2nd,    signalBufferExit, signalBufferVolume, signalBufferCont;
      
      bool   useMultipleBuffers, multipleBuffersVolume;
      bool  readMultipleFromList;
      int lastMainBuffer, lastBufferVolume;
      int buffersMain[], buffersSignal[];
      int lastSignalBuffer;
      
      int mainBuyColor, mainSellColor;
      int secondBuyColor, secondSellColor;
      int exitBuyColor, exitSellColor;
      int contBuyColor, contSellColor;
      
      int volumeBuyColor, volumeSellColor;
      
      IndicatorRead indicatorMode, indicatorMode2nd, indicatorModeExit, indicatorModeCont;
      VolumeRead indicatorModeVolume;
      bool use2Confirm, useExitIndicator, useVolumeIndicator, useBaseline;
      ContinuationIndicatorMode useContIndicator;
      bool useMainForExit;
      bool exitAtSignalOnly;
      
      bool atrRelativeVolume;
      
      bool applyPullbackRule, applyOneCandleRule, applyBridgeTooFar;
      bool useMainCatchUp;
      
      //Results (each pair)
      double grossWinArray[], grossLossArray[]; //Amount
      int totalWinsArray[], totalLosesArray[];  //Number
      
      double grossWin, grossLoss;
      
      //Options
      
      //bool doOCROperation[], doPBOperation[], waitReset[];
      TradeStates tradeCurrentState[];
      
      //Symbols
      string symbolsToTrade[];
      int totalSymbols;
      int activeSymbol;
      
      //Virtual Trades
      VirtualTrade *buyArray[];
      VirtualTrade *sellArray[];
      
      //Handles
      int atrHandles[], mainHandles[], secondHandles[], exitHandles[], volumeHandles[], baselineHandles[], continuationHandles[];
      
      //Indicator Values
      double atrCurrentValues[2], mainCurrentValues[2], mainSignalCurrentValues[2], secondCurrentValues[2], secondSignalCurrentValues[2], exitCurrentValues[2], exitSignalCurrentValues[2];
      double volumeCurrentValues[2], volumeSignalCurrentValues[2], baselineCurrentValues[2], continuationCurrentValues[2], continuationSignalCurrentValues[2];
      
      
      //Extras (no disponibles en backtester normal)
      double atrDistanceMultiplier;
      double minimalTradePercent;
      bool drawIconsInTesting;
      int bridgeTooFarCount;
      
      virtual void AddProfits(double amount, double trade_elapsed);
      /*
      virtual double GetValueFromBuffersVolume(int initBuffer, int endBuffer, int shift)  { return 0.0; }
      virtual double GetValueFromBuffers(int initBuffer, int endBuffer, int shift)        { return 0.0; }
      virtual double GetValueFromBuffersVolume(int &listBuffers[], int shift)             { return 0.0; }
      virtual double GetValueFromBuffers(int &listBuffers[], int shift)                   { return 0.0; }
      */
      int GetIndicatorSignal(string &out_info, int indicatorType, int shift = 0);
      int GetIndicatorMainBuffer(int indicatorType);
      double GetCrossLevel(int indicatorType);
      double GetCrossFilter(int indicatorType);
      int GetIndicatorMode(int indicatorType);
      bool GetIndicatorInvert(int indicatorType);
      int GetIndicatorBuyColor(int indicatorType);
      int GetIndicatorSellColor(int indicatorType);
      virtual double GetIndicatorValue(int indicatorType, int shift, bool main = true) { return 0.0; }
      virtual double GetIndicatorValue(int indicatorType, int shift, int buffer) { return -1.0; }
      virtual int GetVolumeIndColorSignal(int shift) { return NEUTRAL; }
      virtual void UpdateIndicatorValues(){}
      void UpdateCurrentRates(bool isEnd = false);
      
      void CopyActiveRates(int displace);
      
      virtual void ExecuteBuy(string where, int signal_place);
      virtual void ExecuteSell(string where, int signal_place);
      virtual bool CloseTrade(int tradeType, CloseTradeProcedence where);
      void CloseTradesAtEnd();
      
      void CloseTradesByGapCorrection();
      
      void CheckActiveTrades();
      bool CheckOpenOrders(int op_type);
      virtual void UpdateTrailingStops();
      
      
      bool CompareSignals(int expected, int received, bool onlyMain = false);
      
      bool CheckMainConfirmationSignal(string &out_info, int expectedSignal, bool onlyMainSignal = false);
      bool CheckSecondConfirmation(string &out_info, int expectedSignal);
      bool CheckExitIndicator(string &out_info, int reverseSignal);
      bool CheckVolumeIndicator(string &out_info, int currentSignal);
      bool CheckBaseline(string &out_info, int expectedSignal, bool onlyMainSignal = false);
      bool CheckContinuationSignal(string &out_info, int expectedSignal);
      bool CheckDistanceToBaseline(string &out_info);
      
      bool CheckPullback(string &out_info, int expectedSignal);
      bool CheckBridgeTooFar(string &out_info, int expectedSignal);
      bool CheckForExit();
      void CheckForExitByMain();
      void CheckForBaselineExit();
      
      virtual void CheckForNewsExit(); //No se usa aqui
      
      
      void DebugFilteredTrade(int operationType, string where, string cause, string info);
      void DebugCompleteTrade(int operationType, string where);
      void DebugClosedTrade(int operationType, string cause);
      
      
      bool BaselineCrossOperation();
      void DoMainTrade();
      void MainCatchUp();
      void DoContinuationTrade();
      void OneCandleRuleOperation();
      void PullbackOperation();
      
      void WaitNoTrade();
      virtual void WaitMissedTrade();
      
      void ChangeState(TradeStates newState);
      TradeStates GetCurrentState();
      
      
      void CreateNewIcon(int character, string name, color iconColor);
      void GetTradeIconSets(int procedence, color &arrowColor, string &arrowString);
      
      void GetDisplaceCorrection();
      
      virtual void CloseEvent(datetime time, double profit, CloseTradeProcedence procedence, TradeCloseLevel level) {}
      string GetProcedenceString(CloseTradeProcedence procedence);
      TradeCloseLevel GetTradeCloseLevel(VirtualTrade* trade, int type);
      TradeCloseLevel GetStopsLevel(VirtualTrade* trade, int type);
   
   public:
      GenericBacktester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, 
      						bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, 
      						bool result_in_pips=false, bool use_main_exit=false);
      ~GenericBacktester();
      void SetHandle(int handle, IndicatorType indicator, int symbolIndex);
      
      void SetIndicator(IndicatorType indicator, int main_buffer, int signal_buffer=1, double cross_level=0.0, bool invert=false, double filter=0.0, IndicatorRead mode=ZERO_LINE_CROSS);
      void SetContinuationIndicator(ContinuationIndicatorMode mode);
      
      void SetMultipleBufferMain(int last_main, int last_signal);
      void SetMultipleBufferMain(int &listBuffers[], int &listSignal[]);
      void SetIndicatorColors(IndicatorType indicator, int buyColor, int sellColor);
      void SetVolumeSettings(VolumeRead volume_read, bool use_multiple, int last_buffer=0, int buyColorIndex=0, int sellColorIndex=0);
      void SetVolumeBidirectionalWidth(double width) { widthBidirectVolume = width; }
      
      void SetExitOnlyAtSignal(bool setTo) { exitAtSignalOnly = setTo; }
      void SetMainCatchUp(bool setTo) { useMainCatchUp = setTo; }
      
      virtual void BacktesterTick();
      virtual double TesterResult(int optimization_mode, int write_to_file);
      
      void DrawIcons(bool set) { if (MQLInfoInteger(MQL_TESTER) && MQLInfoInteger(MQL_VISUAL_MODE)) drawIconsInTesting = set; }
};



// Constructor

void GenericBacktester::GenericBacktester(double trade_value, string &symbolsArray[], 
														bool pullback, bool one_candle, bool bridge_tf, bool scale_out, 
														bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, 
														bool result_in_pips=false, bool use_main_exit=false)
{
   activeSymbol = 0;
   tradeValue = trade_value;
   scaleOut = scale_out;
   debugTrades = debug_trades;
   
   applyPullbackRule = pullback;
   applyOneCandleRule = one_candle;
   applyBridgeTooFar = bridge_tf;
   useMainForExit = use_main_exit;
   exitAtSignalOnly = false;
   useMainCatchUp = true;
   
   useContIndicator = CONT_DONT_USE;
   
   resultInPips = result_in_pips;
   
   atrDistanceMultiplier = 1.0;
   minimalTradePercent = 0.5;
   drawIconsInTesting = false;
   bridgeTooFarCount = 7;
   
   ArrayCopy(symbolsToTrade, symbolsArray);
   
   totalSymbols = ArraySize(symbolsToTrade);
   
   ArrayResize(buyArray, totalSymbols);
   ArrayResize(sellArray, totalSymbols);
   
   for (int i=0; i < totalSymbols; i++)
   {
      SymbolSelect(symbolsToTrade[i], true);
      
      buyArray[i]  = new VirtualTrade(symbolsToTrade[i], debug_virtual_trades, draw_arrows, result_in_pips);
      sellArray[i] = new VirtualTrade(symbolsToTrade[i], debug_virtual_trades, draw_arrows, result_in_pips);
   }
   
   ArrayResize(grossWinArray, totalSymbols);
   ArrayFill(grossWinArray, 0, totalSymbols, 0.0);
   
   ArrayResize(grossLossArray, totalSymbols);
   ArrayFill(grossLossArray, 0, totalSymbols, 0.0);
   
   ArrayResize(totalLosesArray, totalSymbols);
   ArrayFill(totalLosesArray, 0, totalSymbols, 0);
   
   ArrayResize(totalWinsArray, totalSymbols);
   ArrayFill(totalWinsArray, 0, totalSymbols, 0);
   
   grossWin = 0.0;
   grossLoss = 0.0;
   
   ArrayResize(tradeCurrentState, totalSymbols);
   if (useBaseline)
      ArrayFill(tradeCurrentState, 0, totalSymbols, NO_TRADE);
   else
      ArrayFill(tradeCurrentState, 0, totalSymbols, MAIN_SIGNAL);

   
   ArrayResize(atrHandles, totalSymbols);
   ArrayResize(mainHandles, totalSymbols);
   ArrayResize(secondHandles, totalSymbols);
   ArrayResize(exitHandles, totalSymbols);
   ArrayResize(volumeHandles, totalSymbols);
   ArrayResize(baselineHandles, totalSymbols);
   ArrayResize(continuationHandles, totalSymbols);
   
   displaceCalculated = false;
   ArrayResize(displaceCorrection, totalSymbols);
   currentIsGap = false;
}

void GenericBacktester::~GenericBacktester()
{
   for (int i=0; i<totalSymbols; i++)
   {
      delete buyArray[i];
      delete sellArray[i];
   }
}

void GenericBacktester::SetHandle(int handle, IndicatorType indicator, int symbolIndex)
{
   switch (indicator)
   {
      case ATR_IND:
         atrHandles[symbolIndex] = handle;
         break;
      case MAIN_IND:
         mainHandles[symbolIndex] = handle;
         break;
      case SECOND_IND:
         secondHandles[symbolIndex] = handle;
         break;
      case VOLUME_IND:
         volumeHandles[symbolIndex] = handle;
         break;
      case EXIT_IND:
         exitHandles[symbolIndex] = handle;
         break;
      case BASELINE_IND:
         baselineHandles[symbolIndex] = handle;
         break;
      case CONTINUATION_IND:
         continuationHandles[symbolIndex] = handle;
         break;
   }
}

void GenericBacktester::SetIndicator(IndicatorType indicator, int main_buffer, int signal_buffer=1, double cross_level=0.0, 
													bool invert=false, double filter=0.0, IndicatorRead mode=ZERO_LINE_CROSS)
{
   switch (indicator)
   {
      case MAIN_IND:
         mainBuffer = main_buffer;
         
         signalBuffer = signal_buffer;
         crossLevel = cross_level;
         invertOperative = invert;
         widthFilter = filter;
         indicatorMode = mode;
         break;
         
      case SECOND_IND:
         use2Confirm = true;
         mainBuffer2nd = main_buffer;
         
         signalBuffer2nd = signal_buffer;
         crossLevel2nd = cross_level;
         invertOperative2nd = invert;
         widthFilter2nd = filter;
         indicatorMode2nd = mode;
         break;
         
      case EXIT_IND:
         useExitIndicator = true;
         mainBufferExit = main_buffer;
         
         signalBufferExit = signal_buffer;
         crossLevelExit = cross_level;
         invertOperativeExit = invert;
         widthFilterExit = filter;
         indicatorModeExit = mode;
         break;
         
      case VOLUME_IND:
         useVolumeIndicator = true;
         mainBufferVolume = main_buffer;
         
         signalBufferVolume = signal_buffer;
         minimumLevelVolume = cross_level;
         break;
         
      case BASELINE_IND:
         useBaseline = true;
         baselineBuffer = main_buffer;
         break;
      case CONTINUATION_IND:
         useContIndicator = CONT_CUSTOM;
         mainBufferCont = main_buffer;
         
         signalBufferCont = signal_buffer;
         crossLevelCont = cross_level;
         invertOperativeCont = invert;
         widthFilterCont = filter;
         indicatorModeCont = mode;
         break;
   }
}

void GenericBacktester::SetContinuationIndicator(ContinuationIndicatorMode mode)
{
   //Si es CONT_CUSTOM, usar la otra funcion
   if (mode == CONT_USE_MAIN)
   {
      useContIndicator = CONT_USE_MAIN;
      mainBufferCont = mainBuffer;
      
      signalBufferCont = signalBuffer;
      crossLevelCont = crossLevel;
      invertOperativeCont = invertOperative;
      widthFilterCont = widthFilter;
      indicatorModeCont = indicatorMode;
      
      contBuyColor = mainBuyColor;
      contSellColor = mainSellColor;
   }
   else if (mode == CONT_USE_EXIT)
   {
      useContIndicator = CONT_USE_EXIT;
      mainBufferCont = mainBufferExit;
      
      signalBufferCont = signalBufferExit;
      crossLevelCont = crossLevelExit;
      invertOperativeCont = invertOperativeExit;
      widthFilterCont = widthFilterExit;
      indicatorModeCont = indicatorModeExit;
      
      contBuyColor = exitBuyColor;
      contSellColor = exitSellColor;
   }
}

void GenericBacktester::SetMultipleBufferMain(int last_main, int last_signal)
{
   useMultipleBuffers = true;
   readMultipleFromList = false;
   lastMainBuffer = last_main;
   lastSignalBuffer = last_signal;
}

void GenericBacktester::SetMultipleBufferMain(int &listBuffers[], int &listSignal[])
{
   useMultipleBuffers = true;
   readMultipleFromList = true;
   ArrayCopy(buffersMain, listBuffers);
   ArrayCopy(buffersSignal, listSignal);
}

void GenericBacktester::SetIndicatorColors(IndicatorType indicator, int buyColor, int sellColor)
{
   switch (indicator)
   {
      case MAIN_IND:
         mainBuyColor = buyColor;
         mainSellColor = sellColor;
         break;
         
      case SECOND_IND:
         secondBuyColor = buyColor;
         secondSellColor = sellColor;
         break;
         
      case EXIT_IND:
         exitBuyColor = buyColor;
         exitSellColor = sellColor;
         break;
         
      case CONTINUATION_IND:
         contBuyColor = buyColor;
         contSellColor = sellColor;
         break;
   }
   
}

void GenericBacktester::SetVolumeSettings(VolumeRead volume_read, bool use_multiple, int last_buffer=0, 
														int buyColorIndex=0, int sellColorIndex=0)
{
   multipleBuffersVolume = use_multiple;
   lastBufferVolume = last_buffer;
   indicatorModeVolume = volume_read;
   
   volumeBuyColor = buyColorIndex;
   volumeSellColor = sellColorIndex;
}

void GenericBacktester::BacktesterTick()
{
   GetDisplaceCorrection();

   for (int i = 0; i < totalSymbols; i++)
   {
      activeSymbol = i;
      
      UpdateCurrentRates();
      
      
      if (currentIsGap)
      {
         CloseTradesByGapCorrection();
         continue;
      }
      
      UpdateIndicatorValues();
      
      
      CheckActiveTrades();
      
      //Update stops
      UpdateTrailingStops();
      
      //Check Exit for active trades 
      //si hay un trade activo ya esta en su estado correcto (CONT - bl / MAIN SIGNAL - no bl)
      
      bool hasClosed = CheckForExit();
      CheckForBaselineExit();
      
      if (useMainForExit)
         CheckForExitByMain();
      
      CheckForNewsExit();
      
      
      if (BaselineCrossOperation()) //Si cruza la baseline, no se tienen en cuenta otros estados
      {
         continue;
      }
      
      switch (GetCurrentState())
      {
         case NO_TRADE:
            WaitNoTrade();
            break;
            
         case MAIN_SIGNAL:
            DoMainTrade();
            break;
            
         case MAIN_CATCH_UP:
            MainCatchUp();
            break;
            
         case PULLBACK:
            PullbackOperation();
            break;
            
         case ONE_CANDLE:
            OneCandleRuleOperation();
            break;
            
         case CONTINUATION:
            if (!hasClosed)
               DoContinuationTrade();
            break;
            
         case MISSED_TRADE:
            WaitMissedTrade();
            break;
      }
   
   }
}

void GenericBacktester::GetDisplaceCorrection()
{
   if (displaceCalculated) return;
   
   displaceCalculated = true;
   
   #ifdef __MQL5__
   
   long refTime = SymbolInfoInteger(Symbol(), SYMBOL_TIME);
   
   for (int i=0; i<totalSymbols; i++)
   {
      if (SymbolInfoInteger(symbolsToTrade[i], SYMBOL_TIME) < refTime)
      {
         displaceCorrection[i] = -1;
      }
      else
      {
         displaceCorrection[i] = 0;
      }
   }
   
   #else
   for (int i=1; i<totalSymbols; i++)
   {
      displaceCorrection[i] = 0;
   }
   #endif
}

double GenericBacktester::TesterResult(int optimization_mode, int write_to_file)
{
   int i;
   CloseTradesAtEnd();

   double pfLimit = 5.0;
   
   double bestMin = grossWinArray[0]+grossLossArray[0];
   
   
   
   int numberOfWins = 0, numberOfLosses = 0;
   
   double worseWinRate = 100.0;
   
   
   for (i = 0; i < totalSymbols; i++)
   {
      numberOfLosses += totalLosesArray[i];
      numberOfWins += totalWinsArray[i];
      
      if (totalLosesArray[i]+totalWinsArray[i]>0)
         worseWinRate = MathMin(worseWinRate, 100.0*(double)totalWinsArray[i]/(totalLosesArray[i]+totalWinsArray[i]));
      else
         worseWinRate = MathMin(worseWinRate, 40.0);
      
      bestMin = MathMin(grossWinArray[i]+grossLossArray[i], bestMin);
      
      Print (symbolsToTrade[i] + ": " + DoubleToString(grossWinArray[i], 2) + "  " + 
                                       DoubleToString(grossLossArray[i], 2) + 
                                       "     Wins = " + IntegerToString(totalWinsArray[i]) + 
                                       " , Lose = " + IntegerToString(totalLosesArray[i]));
   }
   
   int numberOfTrades = numberOfWins + numberOfLosses;
   
   double profitFactor;
   
   if (grossLoss == 0)
   {
      profitFactor = 1.0 + grossWin / 10000.0;
   }
   else
   {
      profitFactor = grossWin / (-grossLoss);
   }
      
   double finalValue = grossWin + grossLoss;
   
   double winRate, correctedWinRate;
   
   if (numberOfTrades>0)
      winRate = 100.0 * numberOfWins / (numberOfTrades);
   else
      winRate = 0.0;
   
   if (numberOfTrades>0)
      correctedWinRate = 100.0 * (numberOfWins+totalSymbols)/(numberOfTrades+totalSymbols*2);
   else
      correctedWinRate = 0.0;
   
   Print("Profit factor: " + DoubleToString(profitFactor, 2));
   Print("Balance: " + DoubleToString(finalValue, 2));
   Print("Minimum: " + DoubleToString(bestMin, 2));
   Print("Total trades: " + IntegerToString(numberOfTrades));
   Print("Win Rate: " + DoubleToString(winRate, 2));
   Print("Worse Win Rate: " + DoubleToString(worseWinRate, 2));
   
   double returnValue = 0;
   
   switch(optimization_mode)
   {
      case TOTAL_PROFIT:
         returnValue = finalValue;
         break;
      
      case BEST_MINIMUM:
         returnValue = bestMin;
         break;
         
      case AVG_MIN_TOTAL:
      {
         double minimum = grossWinArray[0]+grossLossArray[0];
         double average = 0.0;
         for (i = 0; i < totalSymbols; i++)
         {
            average += grossWinArray[i] + grossLossArray[i];
            
            minimum = MathMin(grossWinArray[i]+grossLossArray[i], minimum);
         }
         
         average = average/totalSymbols;
         

         if (finalValue == 0) return -100000;
         
         double pfSigmoid = 1.0 / (1.0 + MathExp(-profitFactor));
         
         returnValue = pfSigmoid * totalSymbols * (average + minimum) / 2.0;
         break;
      }
      case PROFIT_FACTOR_MOD:
         returnValue = AccountInfoDouble(ACCOUNT_BALANCE) * (grossWin + AccountInfoDouble(ACCOUNT_BALANCE)) / 
         					(AccountInfoDouble(ACCOUNT_BALANCE)-grossLoss) - AccountInfoDouble(ACCOUNT_BALANCE);
         break;
      
      case MIN_PROFITFACTOR:
      {
         double minPF = profitFactor;
         for (i = 0; i < totalSymbols; i++)
         {
            double gw = grossWinArray[i];
            double gl = -grossLossArray[i];
            
            if (gl > 0)
            {
               minPF = MathMin(minPF, gw/gl);
            }
            else
            {
               minPF = MathMin(minPF, 1.0 + gw / 10000.0);
            }
         }
         returnValue = MathMin(minPF, pfLimit);
         break;
      }
      case PF_SQ_PER_W:
         if (finalValue == 0) return -50000;
         returnValue = MathMin(pfLimit, profitFactor) * (1 + MathLog(1.0+profitFactor)) * finalValue;
         break;
         
      case WIN_RATE:
         returnValue = winRate;
         break;
         
      case WORST_WIN_RATE:
         returnValue = worseWinRate;
         break;
         
      case CORR_WIN_RATE:
         returnValue = correctedWinRate;
         break;
   }
   
   int filehandle;
   if (write_to_file == OPTIMIZE)
   {
      filehandle=FileOpen("OPT_DATA.txt",FILE_READ|FILE_WRITE|FILE_TXT);
      
      if(filehandle<0)
      {
         Print("Failed to open the file by the absolute path ");
         Print("Error code ",GetLastError());
      }
   
      if(filehandle!=INVALID_HANDLE)
      {
         FileSeek(filehandle,0,SEEK_END); 
         
         //String fill para nivelar tabulaciones (usar espacios)
         //Procesar archivo con python
         string content;
         if (optimization_mode == WIN_RATE || optimization_mode == WORST_WIN_RATE || optimization_mode == CORR_WIN_RATE)
         {
            content = DoubleToString(winRate, 2) + "\t" + 
                      DoubleToString(worseWinRate, 2) + "\t" +
                      DoubleToString(correctedWinRate, 2) + "\t" +
                      IntegerToString(numberOfTrades);
         }
         else
         {
            content = DoubleToString(finalValue, 0) + "\t" + 
                      DoubleToString(bestMin, 0) + "\t" + 
                      DoubleToString(profitFactor, 2) + "\t" + 
                      DoubleToString(returnValue, 2);
         }

                          
         FileWrite(filehandle, content);
         FileFlush(filehandle);
         FileClose(filehandle);
      }
   }
   else if (write_to_file == SUMMARY)
   {
      filehandle=FileOpen("SUMMARY.txt",FILE_WRITE|FILE_TXT);
      
      if(filehandle<0)
      {
         Print("Failed to open the file by the absolute path ");
         Print("Error code ",GetLastError());
      }
   
      if(filehandle!=INVALID_HANDLE)
      {
         string toWrite = "";
         
         string symb;
         
         if (scaleOut)
         {
            for (i = 0; i < totalSymbols; i++)
            {
               symb = symbolsToTrade[i];
               toWrite = toWrite + symb+ "\t";
            }
            for (i = 0; i < totalSymbols; i++)
            {
               symb = symbolsToTrade[i];
               toWrite = toWrite + symb+ "\t";
            }
            toWrite = toWrite + "\n";
            
            for (i = 0; i < totalSymbols; i++)
            {
               toWrite = toWrite + DoubleToString(grossWinArray[i]+grossLossArray[i], 0) + "\t";
            }
            
            for (i = 0; i < totalSymbols; i++)
            {
               if (grossLossArray[i] == 0)
               {
                  if (grossWinArray[i] == 0)
                  {
                     toWrite = toWrite + DoubleToString(1.0, 2) + "\t";
                  }
                  else
                  {
                     toWrite = toWrite + DoubleToString(999.99, 2) + "\t";
                  }
               }
               else
               {
                  toWrite = toWrite + DoubleToString(grossWinArray[i]/(-grossLossArray[i]), 2) + "\t";
               }
            }
            
            
            FileWrite(filehandle, toWrite);
            
            FileWrite(filehandle, IntegerToString(numberOfTrades) + "\t" + DoubleToString(profitFactor, 2));
         }
         else
         {
            for (i = 0; i < totalSymbols; i++)
            {
               symb = symbolsToTrade[i];
               toWrite = toWrite + symb + "+" + "\t";
            }
            for (i = 0; i < totalSymbols; i++)
            {
               symb = symbolsToTrade[i];
               toWrite = toWrite + symb + "-" + "\t";
            }
            toWrite = toWrite + "\n";
            
            for (i = 0; i < totalSymbols; i++)
            {
               toWrite = toWrite + IntegerToString(totalWinsArray[i]) + "\t";
            }
            for (i = 0; i < totalSymbols; i++)
            {
               toWrite = toWrite + IntegerToString(totalLosesArray[i]) + "\t";
            }
            
            FileWrite(filehandle, toWrite);
         }
         
         FileFlush(filehandle);
         FileClose(filehandle);
      }
   }
   
   return returnValue;
}


void GenericBacktester::AddProfits(double amount, double trade_elapsed)
{
   if (amount>0)
   {
      grossWinArray[activeSymbol] += amount;
      grossWin += amount;
      
      if (trade_elapsed > minimalTradePercent)
         totalWinsArray[activeSymbol] += 1;
   }
   else if (amount < 0)
   {
      grossLossArray[activeSymbol] += amount;
      grossLoss += amount;
      
      if (trade_elapsed > minimalTradePercent)
         totalLosesArray[activeSymbol] += 1;
   }
}

//+------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------
//+------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------
//+------------------------------------------------------------------+
//|            GET INDICATOR VALUES (GENERAL)                        |
//+------------------------------------------------------------------+

int GenericBacktester::GetIndicatorSignal(string &out_info, int indicatorType, int shift = 0)
{
   double actual = GetIndicatorValue(indicatorType, DISPLACEMENT + shift);
   double last = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift);
   
   double actSignal, lastSignal;
   
   bool isBuyColor, lastBuyColor;
   
   #ifdef __MQL4__
   double sellAc, sellLs;
   #endif
   
   switch(GetIndicatorMode(indicatorType))
   {
      case ZERO_LINE_CROSS:
         out_info = "act: " + DoubleToString(actual, 5) + " last: " + DoubleToString(last, 5);
         return ZeroLineCross(actual, last, GetCrossLevel(indicatorType), GetIndicatorInvert(indicatorType));
         
      case TWO_LINES_CROSS:
         actSignal = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, false);
         lastSignal = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift, false);
         
         out_info = "act: " + DoubleToString(actual, 5) + " last: " + DoubleToString(last, 5) + " ; actSignal: "  
         							+ DoubleToString(actSignal, 5) + " lastSignal: " + DoubleToString(lastSignal, 5);
         
         return TwoLinesCrossover(actual, last, actSignal, lastSignal, GetIndicatorInvert(indicatorType));
         
      case CHART_DOT_SIGNAL:
         actSignal = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, false);
         out_info = "act: " + DoubleToString(actual, 5) + " ; actSignal: "  + DoubleToString(actSignal, 5);
         return ChartDotSignal(actual, actSignal, GetIndicatorInvert(indicatorType));
         
      case BUFFER_ACTIVATION:
         actSignal = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, false);
         lastSignal = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift, false);
         out_info = "act: " + DoubleToString(actual, 5) + DoubleToString(actSignal, 5);
         return BufferActivation(actual, actSignal, last, lastSignal, GetIndicatorInvert(indicatorType));
         
      case ZERO_LINE_FILTER:
         out_info = "act: " + DoubleToString(actual, 5) + " last: " + DoubleToString(last, 5);
         return ZeroLineFilter(actual, last, GetCrossLevel(indicatorType), GetCrossFilter(indicatorType), GetIndicatorInvert(indicatorType));
      
      #ifdef __MQL5__
      case COLOR_BUFFER:
         out_info = "act: " + DoubleToString(actual, 0) + " last: " + DoubleToString(last, 0); 
         return ColorBuffer((int)actual, (int)last, GetIndicatorBuyColor(indicatorType), GetIndicatorSellColor(indicatorType));
      #endif
      
      case CROSS_PRICE:
         out_info = "act: " + DoubleToString(actual, 5) + " last: " + DoubleToString(last, 5) + " ; actClose: "  
         					+ DoubleToString(currentRates[DATA_RECENT].close, 5) + " lastClose: " + DoubleToString(currentRates[DATA_PAST].close, 5);
         return TwoLinesCrossover(currentRates[DATA_RECENT].close, currentRates[DATA_PAST].close, actual, last, GetIndicatorInvert(indicatorType));
         
      case CROSS_IN_FILTER:
         return CrossInsideFilter(actual, last, GetCrossLevel(indicatorType), GetCrossFilter(indicatorType), GetIndicatorInvert(indicatorType));
      
      #ifdef __MQL5__
      case CHART_DOT_COLOR:
         actSignal = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, false);
         return ChartDotColor(actual, (int)actSignal, GetIndicatorBuyColor(indicatorType), GetIndicatorSellColor(indicatorType), GetIndicatorInvert(indicatorType));
      #endif
      
      case OVER_SIGNAL_COLOR:
      {
      	actSignal = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, false);
      	lastSignal = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift, false);
      	
      	#ifdef __MQL5__
         	isBuyColor = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, int(GetIndicatorMainBuffer(indicatorType)+1)) == GetIndicatorBuyColor(indicatorType);
         	lastBuyColor = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift, int(GetIndicatorMainBuffer(indicatorType)+1)) == GetIndicatorBuyColor(indicatorType);
      	#else
      	   sellAc = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, colorSell);
      	   actual = actual==EMPTY_VALUE?0.0 : actual;
      	   sellAc = sellAc==EMPTY_VALUE?0.0 : sellAc;
      	   
      	   sellLs = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift, colorSell);
      	   last = last==EMPTY_VALUE?0.0 : last;
      	   sellLs = sellLs==EMPTY_VALUE?0.0 : sellLs;
      	   
      	   isBuyColor = actual>sellAc;
      	   lastBuyColor = last>sellLs;
      	   
      	   actual = MathMax(actual, sellAc);
      	   last = MathMax(last, sellLs);
      	#endif
      	
         return ColorOverSignal(actual, last, actSignal, lastSignal, isBuyColor, lastBuyColor, GetIndicatorInvert(indicatorType));
      }
      case OVER_LEVEL_COLOR:
      {
      	#ifdef __MQL5__
         	isBuyColor = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, int(GetIndicatorMainBuffer(indicatorType)+1)) == GetIndicatorBuyColor(indicatorType);
         	lastBuyColor = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift, int(GetIndicatorMainBuffer(indicatorType)+1)) == GetIndicatorBuyColor(indicatorType);
      	#else
      	   sellAc = GetIndicatorValue(indicatorType, DISPLACEMENT + shift, colorSell);
      	   actual = actual==EMPTY_VALUE?0.0 : actual;
      	   sellAc = sellAc==EMPTY_VALUE?0.0 : sellAc;
      	   
      	   sellLs = GetIndicatorValue(indicatorType, DISPLACEMENT+1 + shift, colorSell);
      	   last = last==EMPTY_VALUE?0.0 : last;
      	   sellLs = sellLs==EMPTY_VALUE?0.0 : sellLs;
      	   
      	   isBuyColor = actual>sellAc;
      	   lastBuyColor = last>sellLs;
      	   
      	   actual = MathMax(actual, sellAc);
      	   last = MathMax(last, sellLs);
      	#endif
         
         return ColorOverLevel(actual, last, GetCrossLevel(indicatorType), isBuyColor, lastBuyColor, GetIndicatorInvert(indicatorType));
      }
   }
   
   return NEUTRAL;
}

int GenericBacktester::GetIndicatorMainBuffer(int indicatorType) //For color level/signal modes
{
   switch (indicatorType)
   {
      case MAIN_IND:
         return mainBuffer;
         
      case SECOND_IND:
         return mainBuffer2nd;
         
      case EXIT_IND:
         return mainBufferExit;

      case CONTINUATION_IND:
         return mainBufferCont;
   }
   
   return 0;
}

double GenericBacktester::GetCrossLevel(int indicatorType)
{
   switch (indicatorType)
   {
      case MAIN_IND:
         return crossLevel;
         
      case SECOND_IND:
         return crossLevel2nd;
         
      case VOLUME_IND:
         return minimumLevelVolume;
         
      case EXIT_IND:
         return crossLevelExit;

      case CONTINUATION_IND:
         return crossLevelCont;
   }
   
   return 0.0;
}

double GenericBacktester::GetCrossFilter(int indicatorType)
{
   switch (indicatorType)
   {
      case MAIN_IND:
         return widthFilter;
         
      case SECOND_IND:
         return widthFilter2nd;
         
      case EXIT_IND:
         return widthFilterExit;

      case CONTINUATION_IND:
         return widthFilterCont;
   }
   
   return 0.0;
}


int GenericBacktester::GetIndicatorMode(int indicatorType)
{
   switch (indicatorType)
   {
      case MAIN_IND:
         return indicatorMode;
         
      case SECOND_IND:
         return indicatorMode2nd;
         
      case EXIT_IND:
         return indicatorModeExit;

      case CONTINUATION_IND:
         return indicatorModeCont;
         
      case BASELINE_IND:
         return TWO_LINES_CROSS;
   }
   
   return 0;
}


bool GenericBacktester::GetIndicatorInvert(int indicatorType)
{
   switch (indicatorType)
   {
      case MAIN_IND:
         return invertOperative;
         
      case SECOND_IND:
         return invertOperative2nd;
         
      case EXIT_IND:
         return invertOperativeExit;

      case CONTINUATION_IND:
         return invertOperativeCont;
   }
   
   return false;
}

int GenericBacktester::GetIndicatorBuyColor(int indicatorType)
{
   switch (indicatorType)
   {
      case MAIN_IND:
         return mainBuyColor;
         
      case SECOND_IND:
         return secondBuyColor;
         
      case EXIT_IND:
         return exitBuyColor;

      case CONTINUATION_IND:
         return contBuyColor;
      
      case VOLUME_IND:
         return volumeBuyColor;
   }
   
   return 0;
}


int GenericBacktester::GetIndicatorSellColor(int indicatorType)
{
   switch (indicatorType)
   {
      case MAIN_IND:
         return mainSellColor;
         
      case SECOND_IND:
         return secondSellColor;
         
      case EXIT_IND:
         return exitSellColor;

      case CONTINUATION_IND:
         return contSellColor;
      
      case VOLUME_IND:
         return volumeSellColor;
   }
   
   return 0;
}

void GenericBacktester::CopyActiveRates(int displace)
{
   if(CopyRates(symbolsToTrade[activeSymbol], PERIOD_CURRENT, displace, 2, currentRates)!=2)
   {
      Print("CopyRates of ",symbolsToTrade[activeSymbol]," failed, no history");
   }
}

void GenericBacktester::UpdateCurrentRates(bool isEnd = false)
{
   int finalDisplace;
   currentIsGap = false;
   correctIndicatorDisplace = false;
   
   if (isEnd) finalDisplace = DISPLACEMENT;
   else finalDisplace = displaceCorrection[activeSymbol] + DISPLACEMENT;

   CopyActiveRates(finalDisplace);

   // GAP AVOIDANCE
   if (lastRateTime > currentRates[DATA_RECENT].time)
   {
      currentIsGap = true;
      
      if (finalDisplace == DISPLACEMENT)
      {
         //Reintentar con 0 desplazamiento
         CopyActiveRates(0);
         
         if (lastRateTime == currentRates[DATA_RECENT].time)
         {
            currentIsGap = false;
            correctIndicatorDisplace = true;
         }
         else if (lastRateTime < currentRates[DATA_RECENT].time)
         {
            //Recopiar los anteriores
            CopyActiveRates(finalDisplace);
         }
      }
      
   }
   else if (lastRateTime < currentRates[DATA_RECENT].time)
   {
      lastRateTime = currentRates[DATA_RECENT].time;
   }
   
}

//+------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------
//+------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------
//+------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------
//| Sell and buy                                                     |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void GenericBacktester::ExecuteBuy(string where, int signal_place)
{
   if (!buyArray[activeSymbol].CheckIfOpen())
   {
      double price = currentRates[DATA_RECENT].close;

      buyArray[activeSymbol].OpenTrade(price, GetIndicatorValue(ATR_IND, DISPLACEMENT), ORDER_TYPE_BUY, 
      												currentRates[DATA_RECENT].time, tradeValue, scaleOut);
      
      color arrowColor;
      string arrowString;
      GetTradeIconSets(signal_place, arrowColor, arrowString);
      CreateNewIcon(TRADE_SYMBOL, arrowString, arrowColor);
      
      DebugCompleteTrade(ORDER_TYPE_BUY, where);
   }
   else
   {
      DebugFilteredTrade(ORDER_TYPE_BUY, where, "ALREADY OPEN", "");
   }
}


void GenericBacktester::ExecuteSell(string where, int signal_place)
{
   if (!sellArray[activeSymbol].CheckIfOpen())
   {
      double price = currentRates[DATA_RECENT].close;
      
      sellArray[activeSymbol].OpenTrade(price, GetIndicatorValue(ATR_IND, DISPLACEMENT), ORDER_TYPE_SELL, 
      														currentRates[DATA_RECENT].time, tradeValue, scaleOut);
      
      color arrowColor;
      string arrowString;
      GetTradeIconSets(signal_place, arrowColor, arrowString);
      CreateNewIcon(TRADE_SYMBOL, arrowString, arrowColor);
      
      DebugCompleteTrade(ORDER_TYPE_SELL, where);
   }
   else
   {
      DebugFilteredTrade(ORDER_TYPE_SELL, where, "ALREADY OPEN", "");
   }
}

bool GenericBacktester::CloseTrade(int tradeType, CloseTradeProcedence where)
{
   double tradeElp=0.0;
   double profit;
   TradeCloseLevel level;
   if (tradeType == ORDER_TYPE_BUY)
   {
      if (buyArray[activeSymbol].CheckIfOpen())
      {
      	level = GetTradeCloseLevel(buyArray[activeSymbol], ORDER_TYPE_BUY);
      
         profit = buyArray[activeSymbol].CloseTrade(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time, tradeElp);
         AddProfits(profit, tradeElp);
         
         CloseEvent(currentRates[DATA_RECENT].time, profit, where, level);
         
         DebugClosedTrade(ORDER_TYPE_BUY, GetProcedenceString(where));
         return true;
      }
   }
   else
   {
      if (sellArray[activeSymbol].CheckIfOpen())
      {
      	level = GetTradeCloseLevel(sellArray[activeSymbol], ORDER_TYPE_SELL);
      	
         profit = sellArray[activeSymbol].CloseTrade(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time, tradeElp);
         AddProfits(profit, tradeElp);
         
         CloseEvent(currentRates[DATA_RECENT].time, profit, where, level);
         
         DebugClosedTrade(ORDER_TYPE_SELL, GetProcedenceString(where));
         return true;
      }
   }
   return false;
}

void GenericBacktester::CloseTradesAtEnd(void)
{
   for (int symb = 0; symb < totalSymbols; symb++)
   {
      activeSymbol = symb;
      UpdateCurrentRates(true);
      
      CloseTrade(ORDER_TYPE_BUY, CTP_END_SIM);
      CloseTrade(ORDER_TYPE_SELL, CTP_END_SIM);
   }

}

void GenericBacktester::CloseTradesByGapCorrection(void)
{
   //Cerrar trades pero no guardar el beneficio

   double tradeElp;
   if (buyArray[activeSymbol].CheckIfOpen())
   {
      buyArray[activeSymbol].CloseTrade(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time, tradeElp);
      
      CloseEvent(currentRates[DATA_RECENT].time, 0.0, CTP_DATA_GAP, TCL_MAX_SL);
      
      DebugClosedTrade(ORDER_TYPE_BUY, "GAP CORRECTION");
   }

   if (sellArray[activeSymbol].CheckIfOpen())
   {
      sellArray[activeSymbol].CloseTrade(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time, tradeElp);
      
      CloseEvent(currentRates[DATA_RECENT].time, 0.0, CTP_DATA_GAP, TCL_MAX_SL);
      
      DebugClosedTrade(ORDER_TYPE_SELL, "GAP CORRECTION");
   }
}

//--------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------

void GenericBacktester::CheckActiveTrades()
{
   double tradeElp=0.0;
   double profit;
	TradeCloseLevel level;
	
   if (buyArray[activeSymbol].CheckIfOpen())
   {
   	level = GetStopsLevel(buyArray[activeSymbol], ORDER_TYPE_BUY);
   	
      profit = buyArray[activeSymbol].CheckStops(currentRates[DATA_RECENT].high, currentRates[DATA_RECENT].low, currentRates[DATA_RECENT].time, tradeElp);
      AddProfits(profit, tradeElp);
      
      if (profit != 0.0) CloseEvent(currentRates[DATA_RECENT].time, profit, CTP_STOPS, level);
   }
   if (sellArray[activeSymbol].CheckIfOpen())
   {
   	level = GetStopsLevel(sellArray[activeSymbol], ORDER_TYPE_SELL);
   
      profit = sellArray[activeSymbol].CheckStops(currentRates[DATA_RECENT].high, currentRates[DATA_RECENT].low, currentRates[DATA_RECENT].time, tradeElp);
      AddProfits(profit, tradeElp);
      
      if (profit != 0.0) CloseEvent(currentRates[DATA_RECENT].time, profit, CTP_STOPS, level);
   }
}

bool GenericBacktester::CheckOpenOrders(int op_type)
{
   if (op_type == ORDER_TYPE_BUY)
   {
      return buyArray[activeSymbol].CheckIfOpen();
   }
   else
   {
      return sellArray[activeSymbol].CheckIfOpen();
   }
}

void GenericBacktester::UpdateTrailingStops()
{
   if (buyArray[activeSymbol].HasTouchedTP())
      buyArray[activeSymbol].UpdateTrailingStop(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time);
   if (sellArray[activeSymbol].HasTouchedTP())
      sellArray[activeSymbol].UpdateTrailingStop(currentRates[DATA_RECENT].close, currentRates[DATA_RECENT].time);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------

bool GenericBacktester::CompareSignals(int expected, int received, bool onlyMain = false)
{
   if (!onlyMain && expected == BUY_SIGNAL)
   {
      return received==BUY_CURRENT || received==BUY_SIGNAL;
   }
   else if (!onlyMain && expected==SELL_SIGNAL)
   {
      return received==SELL_CURRENT || received==SELL_SIGNAL;
   }
   else
   {
      return received==expected;
   }
}


bool GenericBacktester::CheckMainConfirmationSignal(string &out_info, int expectedSignal, bool onlyMainSignal = false)
{
   int signal = GetIndicatorSignal(out_info, MAIN_IND);

   return CompareSignals(expectedSignal, signal, onlyMainSignal);
}


bool GenericBacktester::CheckSecondConfirmation(string &out_info, int expectedSignal)
{
   if (!use2Confirm) return true;
   
   int signal = GetIndicatorSignal(out_info, SECOND_IND);
   
   return CompareSignals(expectedSignal, signal);
}


bool GenericBacktester::CheckExitIndicator(string &out_info, int reverseSignal)
{
   if (!useExitIndicator) return false;
   
   int signal = GetIndicatorSignal(out_info, EXIT_IND);
   
   return CompareSignals(reverseSignal, signal, exitAtSignalOnly);
}


bool GenericBacktester::CheckVolumeIndicator(string &out_info, int currentSignal)
{
   if (!useVolumeIndicator) return true;
   
   double volValue = GetIndicatorValue(VOLUME_IND, DISPLACEMENT);
   
   double volSignal;
   int volumeColor;
   
   switch(indicatorModeVolume)
   {
      case OVER_LEVEL:
      {
         if (atrRelativeVolume)
         {
            double atr = atrCurrentValues[DATA_RECENT];
            
            out_info = "vol: " + DoubleToString(volValue, 5) + " atr: " + DoubleToString(atr, 5);
            return VolumeOverLevel(volValue, minimumLevelVolume, atr);
         }
         
         out_info = "vol: " + DoubleToString(volValue, 5);
         return VolumeOverLevel(volValue, minimumLevelVolume);
         
      }
      case OVER_SIGNAL:
      {
         volSignal = GetIndicatorValue(VOLUME_IND, DISPLACEMENT, false);
         
         out_info = "vol: " + DoubleToString(volValue, 5) + " vol signal: " + DoubleToString(volSignal, 5);
         return VolumeOverSignal(volValue, volSignal);
      }
      case OVER_LEVEL_BUY_SELL:
      {
         volumeColor = GetVolumeIndColorSignal(0);
         
         out_info = "vol: " + DoubleToString(volValue, 5) + " vol color: " + EnumToString((IndicatorSignal)volumeColor);
         return VolumeOverLevel(volValue, minimumLevelVolume, 1.0, volumeColor, currentSignal);
      }
      case OVER_SIGNAL_BUY_SELL:
      {
         volSignal = GetIndicatorValue(VOLUME_IND, DISPLACEMENT, false);
         volumeColor = GetVolumeIndColorSignal(0);
         
         out_info = "vol: " + DoubleToString(volValue, 5)  + " vol signal: " + DoubleToString(volSignal, 5) 
         					+ " vol color: " + EnumToString((IndicatorSignal)volumeColor);
         return VolumeOverSignal(volValue, volSignal, volumeColor, currentSignal);
      }
      case BIDIRECTIONAL_LEVEL:
      {
         return VolumeBidirectional(volValue, minimumLevelVolume, widthBidirectVolume, currentSignal);
      }
   }
   
   return false;
}


bool GenericBacktester::CheckBaseline(string &out_info, int expectedSignal, bool onlyMainSignal = false)
{
   if (!useBaseline) return true;
   
   int signal = GetIndicatorSignal(out_info, BASELINE_IND);
   
   return CompareSignals(expectedSignal, signal, onlyMainSignal);
}


bool GenericBacktester::CheckContinuationSignal(string &out_info, int expectedSignal)
{
   if (useContIndicator == CONT_DONT_USE) return false;
   
   int signal = GetIndicatorSignal(out_info, CONTINUATION_IND);
   
   return CompareSignals(expectedSignal, signal, true);
}


bool GenericBacktester::CheckDistanceToBaseline(string &out_info)
{
   if (!useBaseline) return true;
   
   if (atrDistanceMultiplier <= 0.0) return true;
   
   double line = GetIndicatorValue(BASELINE_IND, DISPLACEMENT, false);
   double lastClose = GetIndicatorValue(BASELINE_IND, DISPLACEMENT, true);
   
      
   double atr = atrCurrentValues[DATA_RECENT];
   
   out_info = "(Line: " + DoubleToString(line, 5) + " Atr: " + DoubleToString(atr, 5) + " Close: " + DoubleToString(lastClose, 5) + ")";
   
   if (MathAbs(line - lastClose)>atr * atrDistanceMultiplier)
   {
      return false;
   }
   
   return true;
}

bool GenericBacktester::CheckPullback(string &out_info, int expectedSignal)
{
   if (expectedSignal == BUY_SIGNAL)
   {
      if (currentRates[DATA_RECENT].close > currentRates[DATA_PAST].close) return false;
      else                     return true;
   }
   else if (expectedSignal == SELL_SIGNAL)
   {
      if (currentRates[DATA_RECENT].close < currentRates[DATA_PAST].close) return false;
      else                     return true;
   }
   
   return false;
}


bool GenericBacktester::CheckBridgeTooFar(string &out_info, int expectedSignal)
{
   if (!applyBridgeTooFar) return true;
   
   for (int i = 1; i < bridgeTooFarCount; i++)
   {
      if (!CompareSignals(expectedSignal, GetIndicatorSignal(out_info, MAIN_IND, i), false))
      {
         out_info = IntegerToString(i);
         return true;
      }
   }
   out_info = ">" + IntegerToString(bridgeTooFarCount);
   return false;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------


bool GenericBacktester::CheckForExit()
{
   if (!useExitIndicator) return false;
   
   string out_info="";
   
   if (CheckExitIndicator(out_info, ORDER_TYPE_SELL))
   {
   
      if (CloseTrade(ORDER_TYPE_BUY, CTP_EXIT))
      {
         CreateNewIcon(EXIT_SYMBOL, "EXIT", EXIT_IND_COLOR);
         return true;
      }
   }
   
   if (CheckExitIndicator(out_info, ORDER_TYPE_BUY))
   {
   
      if (CloseTrade(ORDER_TYPE_SELL, CTP_EXIT))
      {
         CreateNewIcon(EXIT_SYMBOL, "EXIT", EXIT_IND_COLOR);
         return true;
      }
   }
   
   return false;
}

void GenericBacktester::CheckForNewsExit()
{

}

void GenericBacktester::CheckForExitByMain()
{
   string out_info="";
   
   if (CheckMainConfirmationSignal(out_info, ORDER_TYPE_SELL, false)) //No importa si es solo main (pero asi puede valer para buffer activation)
   {
      if (CloseTrade(ORDER_TYPE_BUY, CTP_C1))
         CreateNewIcon(174, "EXIT BY C1", MAIN_IND_COLOR);
   }
   
   if (CheckMainConfirmationSignal(out_info, ORDER_TYPE_BUY, false))
   {
      if (CloseTrade(ORDER_TYPE_SELL, CTP_C1))
         CreateNewIcon(174, "EXIT BY C1", MAIN_IND_COLOR);
   }
}


void GenericBacktester::CheckForBaselineExit()
{
   if (!useBaseline) return;
   
   string out_info="";
   
   if (CheckBaseline(out_info, ORDER_TYPE_SELL, true))
   {
      CloseTrade(BUY_SIGNAL, CTP_BASELINE);
   }
   
   if (CheckBaseline(out_info, ORDER_TYPE_BUY, true))
   {
      CloseTrade(SELL_SIGNAL, CTP_BASELINE);
   }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------

void GenericBacktester::DebugFilteredTrade(int operationType, string where, string cause, string info)
{
   if (!debugTrades) return;
   
   string operationSt = GetSignalTypeString(operationType);
   
   Print("Filtered " + operationSt + " in " + where + " by " + cause + " -- " + info);
}


void GenericBacktester::DebugCompleteTrade(int operationType, string where)
{
   if (!debugTrades) return;
   
   string operationSt = GetSignalTypeString(operationType);
   
   Print("Opened " + operationSt + " in " + where);
}


void GenericBacktester::DebugClosedTrade(int operationType, string cause)
{
   if (!debugTrades) return;
   
   string operationSt = GetSignalTypeString(operationType);
   
   Print("Closed " + operationSt + " by " + cause);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------

bool GenericBacktester::BaselineCrossOperation() //Devuelve si ha cruzado
{
   if (!useBaseline) return false;
   
   int crossSignal;
   
   string out_info = "";
   
   if (CheckBaseline(out_info, BUY_SIGNAL, true))         { crossSignal = BUY_SIGNAL;  }
   else if (CheckBaseline(out_info, SELL_SIGNAL, true))   { crossSignal = SELL_SIGNAL; }
   else { return false; }
   
   if (!CheckMainConfirmationSignal(out_info, crossSignal, false))
   {
      ChangeState(MAIN_SIGNAL);
      DebugFilteredTrade(crossSignal, "BASELINE CROSS", "MAIN", out_info);
      
      CreateNewIcon(UNKNOWN_SYMBOL, "BASELINE CROSS: NO C1", MAIN_IND_COLOR);
      return true;
   }
   
   if (!CheckBridgeTooFar(out_info, crossSignal))
   {
      ChangeState(NO_TRADE);
      DebugFilteredTrade(crossSignal, "BASELINE CROSS", "BRIDGE FAR", out_info);
      
      CreateNewIcon(NO_TRADE_SYMBOL, "BASELINE CROSS: BRIDGE TOO FAR", BRIDGE_TF_COLOR);
      return true;
   }
   
   if (!CheckSecondConfirmation(out_info, crossSignal))
   {
   	if (useMainCatchUp)
      	ChangeState(MAIN_CATCH_UP);
      else
      	ChangeState(NO_TRADE);
      	
      DebugFilteredTrade(crossSignal, "BASELINE CROSS", "SECOND", out_info); 
      
      CreateNewIcon(UNKNOWN_SYMBOL, "BASELINE CROSS: NO C2", SECOND_IND_COLOR);
      return true;
   }
   
   if (!CheckVolumeIndicator(out_info, crossSignal))
   {
   	if (useMainCatchUp)
      	ChangeState(MAIN_CATCH_UP);
      else
      	ChangeState(NO_TRADE);
      	
      DebugFilteredTrade(crossSignal, "BASELINE CROSS", "VOLUME", out_info);
      
      CreateNewIcon(UNKNOWN_SYMBOL, "BASELINE CROSS: NO VOLUME", VOLUME_IND_COLOR);
      return true;
   }
   
   if (!CheckDistanceToBaseline(out_info)) 
   {
      if (applyPullbackRule)
         ChangeState(PULLBACK);
      else
         ChangeState(NO_TRADE);
      
      DebugFilteredTrade(crossSignal, "BASELINE CROSS", "DISTANCE > ATR", out_info);
      
      CreateNewIcon(UNKNOWN_SYMBOL, "BASELINE CROSS: DISTANCE>ATR", DISTANCE_COLOR);
      return true; 
   }
   
   if (crossSignal == BUY_SIGNAL)   { ExecuteBuy("BASELINE CROSS", TP_BASELINE_CROSS);  }
   else                             { ExecuteSell("BASELINE CROSS", TP_BASELINE_CROSS); }
   
   //CreateNewIcon(TRADE_SYMBOL, "BASELINE CROSS SIGNAL", BASELINE_COLOR);
   ChangeState(CONTINUATION);
   return true;
}


void GenericBacktester::DoMainTrade()
{
   int currentSignal;
   
   string out_info = "";
   
   if (CheckMainConfirmationSignal(out_info, BUY_SIGNAL, true))         { currentSignal = BUY_SIGNAL;  } //Puede que haya que cambiarlo por false si se usa baseline
   else if (CheckMainConfirmationSignal(out_info, SELL_SIGNAL, true))   { currentSignal = SELL_SIGNAL; }
   else { return; }
   
   
   if (!CheckBaseline(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "MAIN", "BASELINE SIDE", out_info);
      return;
   }
   

   
   if (!CheckDistanceToBaseline(out_info))
   {
      if (applyOneCandleRule)
         ChangeState(ONE_CANDLE);
      else
         ChangeState(NO_TRADE);
      
      DebugFilteredTrade(currentSignal, "MAIN", "DISTANCE > ATR", out_info);
      
      CreateNewIcon(UNKNOWN_SYMBOL, "C1 SIGNAL: DISTANCE>ATR", DISTANCE_COLOR);
      return; 
   }
   
   
   if (!CheckSecondConfirmation(out_info, currentSignal))
   {
      if (applyOneCandleRule)
         ChangeState(ONE_CANDLE);
      else if (useBaseline)
         ChangeState(NO_TRADE);
      
      DebugFilteredTrade(currentSignal, "MAIN", "SECOND", out_info);
      
      CreateNewIcon(UNKNOWN_SYMBOL, "C1 SIGNAL: NO C2", SECOND_IND_COLOR);
      return;
   }

   if (!CheckVolumeIndicator(out_info, currentSignal))
   {
      if (applyOneCandleRule)
         ChangeState(ONE_CANDLE);
      else if (useBaseline)
         ChangeState(NO_TRADE);
      
      DebugFilteredTrade(currentSignal, "MAIN", "VOLUME", out_info);
      
      CreateNewIcon(UNKNOWN_SYMBOL, "C1 SIGNAL: NO VOLUME", VOLUME_IND_COLOR);
      return;
   }
   
   
   if (currentSignal == BUY_SIGNAL) { ExecuteBuy("MAIN", TP_MAIN_SIGNAL);  }
   else                             { ExecuteSell("MAIN", TP_MAIN_SIGNAL); }
   
   //CreateNewIcon(TRADE_SYMBOL, "C1 SIGNAL", MAIN_IND_COLOR);
   
   if (useBaseline)
      ChangeState(CONTINUATION);
   
}

void GenericBacktester::MainCatchUp()
{
   int currentSignal;
   
   string out_info = "";
      
   if (CheckMainConfirmationSignal(out_info, BUY_SIGNAL, false))         { currentSignal = BUY_SIGNAL;  }
   else if (CheckMainConfirmationSignal(out_info, SELL_SIGNAL, false))   { currentSignal = SELL_SIGNAL; }
   else { return; }
   

   
   if (!CheckBaseline(out_info, currentSignal))
   {
      ChangeState(MAIN_SIGNAL); //Ha cambiado de lado, se espera a main para cumplir OCR
      DebugFilteredTrade(currentSignal, "MAIN CATCH", "BASELINE SIDE", out_info);
      return;
   }
   
   if (!CheckSecondConfirmation(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "MAIN CATCH", "SECOND", out_info);
      return;
   }

   if (!CheckVolumeIndicator(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "MAIN CATCH", "VOLUME", out_info);
      return;
   }
   
   if (!CheckDistanceToBaseline(out_info))
   {
      ChangeState(NO_TRADE);
      DebugFilteredTrade(currentSignal, "MAIN CATCH", "DISTANCE > ATR", out_info);
      
      CreateNewIcon(NO_TRADE_SYMBOL, "VOLUME-C2 CATCH UP: DISTANCE>ATR", DISTANCE_COLOR);
      return; 
   }
   
   if (currentSignal == BUY_SIGNAL) { ExecuteBuy("MAIN CATCH", TP_MAIN_CATCH);  }
   else                             { ExecuteSell("MAIN CATCH", TP_MAIN_CATCH); }
   
   //CreateNewIcon(TRADE_SYMBOL, "VOLUME-C2 CATCH UP", SECOND_IND_COLOR);
   
   ChangeState(CONTINUATION);
}


void GenericBacktester::DoContinuationTrade()
{
   if (!useBaseline) return;
   
   if (useContIndicator == CONT_DONT_USE)
   {
      ChangeState(NO_TRADE);
      return;
   }

   int currentSignal;
   
   string out_info = "";
   

   if (CheckContinuationSignal(out_info, BUY_SIGNAL))         { currentSignal = BUY_SIGNAL;  }
   else if (CheckContinuationSignal(out_info, SELL_SIGNAL))   { currentSignal = SELL_SIGNAL; }
   else { return; }

   
   
   
   if (!CheckBaseline(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "CONTINUATION", "BASELINE SIDE", out_info);
      return;
   }
   
   if (useContIndicator != CONT_USE_MAIN) //No comprobar otra vez
   {
      if (!CheckMainConfirmationSignal(out_info, currentSignal, false))
      {
         DebugFilteredTrade(currentSignal, "CONTINUATION", "MAIN", out_info);
         CreateNewIcon(UNKNOWN_SYMBOL, "CONTINUATION: NO C1", MAIN_IND_COLOR);
         return;
      }
   }
   
   if (!CheckSecondConfirmation(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "CONTINUATION", "SECOND", out_info);
      CreateNewIcon(UNKNOWN_SYMBOL, "CONTINUATION: NO C2", SECOND_IND_COLOR);
      return;
   }
   
   
   if (currentSignal == BUY_SIGNAL) { ExecuteBuy("CONTINUATION", TP_CONTINUATION);  }
   else                             { ExecuteSell("CONTINUATION", TP_CONTINUATION); }
   
   //CreateNewIcon(TRADE_SYMBOL, "CONTINUATION TRADE", CONTINUATION_COLOR);
   
}


void GenericBacktester::OneCandleRuleOperation()
{
   int currentSignal;
   
   if (useBaseline) ChangeState(NO_TRADE);
   else ChangeState(MAIN_SIGNAL);
   
   if (!applyOneCandleRule) return;
   
   string out_info = "";
   
   if (CheckMainConfirmationSignal(out_info, BUY_SIGNAL, false))         { currentSignal = BUY_SIGNAL;  }
   else if (CheckMainConfirmationSignal(out_info, SELL_SIGNAL, false))   { currentSignal = SELL_SIGNAL; }
   else { return; }
   
   if (!CheckPullback(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "ONE CANDLE", "NO PULLBACK", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "OCR: NO PULLBACK", DISTANCE_COLOR);
      return;
   }
   
   if (!CheckBaseline(out_info, currentSignal))
   {
      ChangeState(MAIN_SIGNAL);
      DebugFilteredTrade(currentSignal, "ONE CANDLE", "BASELINE SIDE", out_info);
      CreateNewIcon(UNKNOWN_SYMBOL, "OCR: NO C1 SIGNAL", MAIN_IND_COLOR);
      return;
   }
   
   if (!CheckDistanceToBaseline(out_info))
   {
      DebugFilteredTrade(currentSignal, "ONE CANDLE", "DISTANCE > ATR", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "OCR: DISTANCE>ATR", DISTANCE_COLOR);
      return;
   }
   
   if (!CheckSecondConfirmation(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "ONE CANDLE", "SECOND", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "OCR: NO C2", SECOND_IND_COLOR);
      return;
   }

   if (!CheckVolumeIndicator(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "ONE CANDLE", "VOLUME", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "OCR: NO VOLUME", VOLUME_IND_COLOR);
      return;
   }
   
   
   if (currentSignal == BUY_SIGNAL) { ExecuteBuy("ONE CANDLE", TP_ONE_CANDLE);  }
   else                             { ExecuteSell("ONE CANDLE", TP_ONE_CANDLE); }
   
   //CreateNewIcon(TRADE_SYMBOL, "ONE CANDLE RULE TRADE", MAIN_IND_COLOR);
   
   if (useBaseline)
      ChangeState(CONTINUATION);
     
}


void GenericBacktester::PullbackOperation()
{
   int currentSignal;
   
   ChangeState(NO_TRADE);
   
   if (!applyPullbackRule) return;
   
   string out_info = "";
   
   if (CheckMainConfirmationSignal(out_info, BUY_SIGNAL, false))         { currentSignal = BUY_SIGNAL;  }
   else if (CheckMainConfirmationSignal(out_info, SELL_SIGNAL, false))   { currentSignal = SELL_SIGNAL; }
   else { return; }
   
   
   if (!CheckPullback(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "PULLBACK", "NO PULLBACK", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "PULLBACK: NO PULLBACK", DISTANCE_COLOR);
      return;
   }
   
   if (!CheckBaseline(out_info, currentSignal))
   {
      ChangeState(MAIN_SIGNAL);
      DebugFilteredTrade(currentSignal, "PULLBACK", "BASELINE SIDE", out_info);
      CreateNewIcon(UNKNOWN_SYMBOL, "PULLBACK: NO C1 SIGNAL", MAIN_IND_COLOR);
      return;
   }
   
   
   if (!CheckDistanceToBaseline(out_info))
   {
      DebugFilteredTrade(currentSignal, "PULLBACK", "DISTANCE > ATR", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "PULLBACK: DISTANCE>ATR", DISTANCE_COLOR);
      return;
   }
   
   if (!CheckSecondConfirmation(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "PULLBACK", "SECOND", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "PULLBACK: NO C2", SECOND_IND_COLOR);
      return;
   }

   if (!CheckVolumeIndicator(out_info, currentSignal))
   {
      DebugFilteredTrade(currentSignal, "PULLBACK", "VOLUME", out_info);
      CreateNewIcon(NO_TRADE_SYMBOL, "OCR: NO VOLUME", VOLUME_IND_COLOR);
      return;
   }
   
   
   if (currentSignal == BUY_SIGNAL) { ExecuteBuy("PULLBACK", TP_PULLBACK);  }
   else                             { ExecuteSell("PULLBACK", TP_PULLBACK); }
   
   //CreateNewIcon(TRADE_SYMBOL, "PULLBACK TRADE", MAIN_IND_COLOR);

   ChangeState(CONTINUATION);
}


void GenericBacktester::WaitNoTrade()
{
   int currentSignal;
   
   string out_info = "";

   
   if (CheckMainConfirmationSignal(out_info, BUY_SIGNAL, false))         { currentSignal = BUY_SIGNAL;  }
   else if (CheckMainConfirmationSignal(out_info, SELL_SIGNAL, false))   { currentSignal = SELL_SIGNAL; }
   else { return; }
   
   // Se da la vuelta, esperar Main Signal desde ahora
   if (!CheckBaseline(out_info, currentSignal))
   {
      ChangeState(MAIN_SIGNAL);
      CreateNewIcon(UNKNOWN_SYMBOL, "C1 FLIP, WAIT FOR SIGNAL", MAIN_IND_COLOR);
      return;
   }
}

void GenericBacktester::WaitMissedTrade()
{
   if (useBaseline)
      ChangeState(CONTINUATION);
   else
      ChangeState(MAIN_SIGNAL);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------

void GenericBacktester::ChangeState(TradeStates newState)
{
   tradeCurrentState[activeSymbol] = newState;
}

TradeStates GenericBacktester::GetCurrentState()
{
   return tradeCurrentState[activeSymbol];
}

void GenericBacktester::CreateNewIcon(int character, string name, color iconColor)
{
   if (!drawIconsInTesting) return;
   if (symbolsToTrade[activeSymbol] != Symbol()) return;
   
   string compName = name + " (" +TimeToString(currentRates[DATA_RECENT].time, TIME_DATE) + ")";
   
   ObjectCreate(0, compName, OBJ_ARROW, 0, iTime(Symbol(), PERIOD_CURRENT, DISPLACEMENT), iLow(Symbol(), PERIOD_CURRENT, DISPLACEMENT) - Point()*ICON_DISTANCE);
   ObjectSetInteger(0, compName, OBJPROP_COLOR, iconColor);
   ObjectSetInteger(0, compName, OBJPROP_ARROWCODE, character);
   ObjectSetInteger(0, compName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, compName, OBJPROP_HIDDEN, true);
}

void GenericBacktester::GetTradeIconSets(int procedence, color &arrowColor, string &arrowString)
{
   switch (procedence)
   {
      case TP_BASELINE_CROSS:
         arrowString = "BASELINE CROSS SIGNAL";
         arrowColor = BASELINE_COLOR;
         break;
         
      case TP_MAIN_SIGNAL:
         arrowString = "C1 SIGNAL";
         arrowColor = MAIN_IND_COLOR;
         break;
         
      case TP_MAIN_CATCH:
         arrowString = "VOLUME-C2 CATCH UP";
         arrowColor = SECOND_IND_COLOR;
         break;
         
      case TP_CONTINUATION:
         arrowString = "CONTINUATION TRADE";
         arrowColor = CONTINUATION_COLOR;
         break;
         
      case TP_ONE_CANDLE:
         arrowString = "ONE CANDLE RULE TRADE";
         arrowColor = MAIN_IND_COLOR;
         break;
      
      case TP_PULLBACK:
         arrowString = "PULLBACK TRADE";
         arrowColor = MAIN_IND_COLOR;
         break;
   }
}

string GenericBacktester::GetProcedenceString(CloseTradeProcedence procedence)
{
	switch (procedence)
	{
		case CTP_STOPS:
			return "Stop Loss";
		case CTP_BASELINE:
			return "Baseline";
		case CTP_C1:
			return "Main Indicator";
		case CTP_EXIT:
			return "Exit Indicator";
		case CTP_NEWS:
			return "News Exit";
		case CTP_END_SIM:
			return "End Of Simulation";
		case CTP_DATA_GAP:
			return "Data Gap Correction";
	}
	return "Other";
}

TradeCloseLevel GenericBacktester::GetTradeCloseLevel(VirtualTrade *trade, int type)
{
	// Only for partial loses / forced closes

	double open = trade.GetOpenPrice();
	double stop = trade.GetStopLoss();
	bool touchedTP = trade.HasTouchedTP();
	
	if (type == ORDER_TYPE_BUY)
	{
		if (stop < open) return TCL_LOSS;
		else if (touchedTP) return TCL_PROFIT_AFTER;
		
		return TCL_PROFIT_BEFORE;
	}
	else //ORDER_TYPE_SELL
	{
		if (stop > open) return TCL_LOSS;
		else if (touchedTP) return TCL_PROFIT_AFTER;
		
		return TCL_PROFIT_BEFORE;
	}
}

TradeCloseLevel GenericBacktester::GetStopsLevel(VirtualTrade *trade,int type)
{
	double open = trade.GetOpenPrice();
	double stop = trade.GetStopLoss();
	
	if (type == ORDER_TYPE_BUY)
	{
		if (stop < open) return TCL_MAX_SL;
		else if (stop == open) return TCL_BE;
		
		return TCL_TRAILING_STOP;
	}
	else //ORDER_TYPE_SELL
	{
		if (stop > open) return TCL_MAX_SL;
		else if (stop == open) return TCL_BE;
		
		return TCL_TRAILING_STOP;
	}
}