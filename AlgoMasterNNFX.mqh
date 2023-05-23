#define PROGRAM_NAME "NNFX_Am"

#include "Backtester/CompleteNNFXTester.mqh"
//#include "Backtester/ExternalFunctions.mqh"
#include "Program/Parameters.mqh"

#include "Symbols/Import.mqh"


#include "Graphics/EVZNewsGraphicImport.mqh"
#include "Backtester/CustomIndicators.mqh"

#ifdef __MQL5__

#resource "Indicators\\EuroFXVix.ex5"
#resource "Indicators\\NewsIndicator.ex5"
#resource "Indicators\\ATR.ex5"

#else

#resource "Indicators\\EuroFXVix.ex4"
#resource "Indicators\\NewsIndicator.ex4"
#resource "Indicators\\ATR.ex4"

#endif

//CGraphicProgram program; //TODO


CompleteNNFXTester *backtester;

string symbolsToTrade[];
int totalSymbols;

bool detectTicks = false;
bool isTester;

int InitEvent()
{
   isTester = MQLInfoInteger(MQL_TESTER);
   if (!isTester)
   {
      //program.OnInitEvent(); //TODO
      /*
      if (!program.CreateGUI())
      {
         return INIT_FAILED;
      }*/
      
      return INIT_SUCCEEDED;
   }
   else //isTester
   {
      if (!CheckExpertParameters()) return INIT_PARAMETERS_INCORRECT;
      
      //double tradeValue = (riskPercent /2.0) * AccountInfoDouble(ACCOUNT_BALANCE)/100.0;
      
      totalSymbols = CSymbolProcessorFactory::ProcessSymbols(
								symbolString,
								symbolsToTrade, 
								pairsPreset);
      
      bool useStats = (optimizationMode != N_EQUITY_COMP); //(optimizationMode == N_DIST_VALUE || optimizationMode == N_DIST_SHAPE);
      
      backtester = new CompleteNNFXTester(riskPercent/200.0, symbolsToTrade, applyPullbackRule, applyOneCandleRule, applyBridgeTooFar, scaleOut, optimizationMode==N_TOTAL_PIPS, useMainForExit, minimalPercent/100.0, stopLossAtr, takeProfitAtr, startMoveAtr, true, useStats);
      
      backtester.SetDistanceBaseline(baselineAtr);
      backtester.SetBridgeTooFarCount(bridgeTooFarCount);
      backtester.SetMainCatchUp(applyCatchUp);
      
      backtester.SetIndicator(MAIN_IND, mainBuffer, signalBuffer, crossLevel, invertOperative, widthFilter, indicatorMode);
      #ifdef __MQL5__
         backtester.SetIndicatorColors(MAIN_IND, colorBuy, colorSell);
      #else
         backtester.SetIndicatorColors(MAIN_IND, colorSell, colorSell);
      #endif
      
      if (use2Confirm)
      {
         backtester.SetIndicator(SECOND_IND, mainBuffer2nd, signalBuffer2nd, crossLevel2nd, invertOperative2nd, widthFilter2nd, indicatorMode2nd);
         #ifdef __MQL5__
            backtester.SetIndicatorColors(SECOND_IND, colorBuy2nd, colorSell2nd);
         #else
            backtester.SetIndicatorColors(SECOND_IND, colorSell2nd, colorSell2nd);
         #endif
      }
      
      if (useExitIndicator) 
      {
         backtester.SetIndicator(EXIT_IND, mainBufferExit, signalBufferExit, crossLevelExit, invertOperativeExit, widthFilterExit, indicatorModeExit);
         backtester.SetExitOnlyAtSignal(useExitAtSignal);
         #ifdef __MQL5__
            backtester.SetIndicatorColors(EXIT_IND, colorBuyExit, colorSellExit);
         #else
            backtester.SetIndicatorColors(EXIT_IND, colorSellExit, colorSellExit);
         #endif
      }
      
      
      if (useContIndicator == CONT_CUSTOM)
      {
         backtester.SetIndicator(CONTINUATION_IND, mainBufferCont, signalBufferCont, crossLevelCont, invertOperativeCont, widthFilterCont, indicatorModeCont);
         #ifdef __MQL5__
            backtester.SetIndicatorColors(CONTINUATION_IND, colorBuyCont, colorSellCont);
         #else
            backtester.SetIndicatorColors(CONTINUATION_IND, colorSellCont, colorSellCont);
         #endif
      }
      else //Hacer despues de configurar exit y main
      {
         backtester.SetContinuationIndicator(useContIndicator);
      }
      
      if (useVolumeIndicator)
      {
         backtester.SetIndicator(VOLUME_IND, mainBufferVolume, signalBufferVolume, minimumLevelVolume);
         
         if (indicatorModeVolume == OVER_LEVEL_BUY_SELL ||indicatorModeVolume == OVER_SIGNAL_BUY_SELL)
         {
            backtester.SetVolumeSettings(indicatorModeVolume, false, 0, volColorBuy, volColorSell);
         }
         else
         {
            backtester.SetVolumeSettings(indicatorModeVolume, false);
         }
         
         if (indicatorModeVolume == BIDIRECTIONAL_LEVEL)
         {
            backtester.SetVolumeBidirectionalWidth(widthLevelVolume);
         }
      }
      
      if (useBaseline) backtester.SetIndicator(BASELINE_IND, baselineBuffer);
      
      
      backtester.DrawIcons(displayIcons);
      
      if (optimizationMode == N_EQUITY_CURVE) backtester.RecordEquityCurve();
      
      if (optimizationMode == N_EQUITY_COMP)
      {
         backtester.RecordEquityCurve();
         backtester.UseCompoundInterest();
      }
      
      GetIndicatorHandles();
      
      if (use_advanced_TS)
      {
      	GetTrailingStopHandles();
      	backtester.SetAdvancedTrailingStops(TS_buy_buffer, TS_sell_buffer);
      }
      
      if (useEvz) GetEVZHandle();
      if (useExposure) backtester.UseCurrencyExposure();
      
      if (useNews)
      {
         backtester.UseNewsFiltering(newsEUR, newsGBP, newsAUD, newsNZD, newsUSD, newsCAD, newsCHF, newsJPY);
      }
      #ifdef __MQL5__
      if (showNewsIndicator && MQLInfoInteger(MQL_VISUAL_MODE))
      {
         int newsHandle = iCustom(Symbol(), PERIOD_CURRENT, NEWS_INDICATOR, 0, 1, true, false, false, false, false, newsEUR, newsGBP, newsAUD, newsNZD, newsUSD, newsCAD, newsCHF, newsJPY, newsIconDistance, newsIconBetween);
         ChartIndicatorAdd(0, 0, newsHandle);
      }
      
      if (optimizationMode == N_REAL_TRADES)
      {
      	backtester.SetRealTradeMode();
      }
      else
      {
      #endif
      
      	if (writeTradeJournal) backtester.RecordTradeJournal();
      	if (showExtendedSummary) backtester.UseExtendedSummary();
      
      #ifdef __MQL5__
      } //Close else (Real trade mode) in MQL5 only
      #endif
      
      return INIT_SUCCEEDED;
   }
}


double TesterEvent()
{
   if (!isTester) return -1.0;
   
   
   Print(BIG_SEPARATOR_LINE);
   
   WriteFilesMode fileMode = NO_WRITE;
   if (writeToFile)
   {
      fileMode = MQLInfoInteger(MQL_OPTIMIZATION)? OPTIMIZE : SUMMARY;
   }

   double finalvalue = backtester.TesterResult(optimizationMode, fileMode, customOptimizationFormula);
   
   Print(BIG_SEPARATOR_LINE);
   if (detectTicks)
   { 
      Print(BIG_SEPARATOR_LINE);
      
      Print("WARNING: ");
      Print("We have detected that this optimization was performed using multiple ticks per candle.");
      Print("This backtester is more efficient when using the Modelling method \"OPEN PRICES ONLY\"");
      
      Print(BIG_SEPARATOR_LINE);
      Print(BIG_SEPARATOR_LINE);
   }
   
   return finalvalue;
}


void TickEvent()
{
   if (isTester)
   {
      datetime arr[];
      CopyTime(_Symbol, PERIOD_CURRENT, 0, 1, arr);
      
      
      if (lastCandle != arr[0])
      {
         lastCandle = arr[0];
         
         backtester.BacktesterTick();
         
         //#ifdef __MQL4__ //Show news in MT4
         //if (showNewsIndicator && MQLInfoInteger(MQL_VISUAL_MODE))
         //{
         //   double getNews = iCustom(_Symbol, PERIOD_CURRENT, NEWS_INDICATOR, 0, 1, false, false, false, false, newsEUR, newsGBP, newsAUD, newsNZD, newsUSD, newsCAD, newsCHF, newsJPY, newsIconDistance, newsIconBetween, 0, DISPLACEMENT);
         //}
         //#endif
      }
      else
      {
         #ifdef __MQL4__
         static int gapCount = 0;
         
         if (gapCount>0) detectTicks = true; //Last candle repeats
         gapCount++;
         #else
         
         detectTicks = true;
         
         #endif
      }
   }
}


void ChartEvent_Event(const int id,const long& lparam,const double& dparam,const string& sparam)
{
   //program.ChartEvent(id, lparam, dparam, sparam); //TODO
}

datetime lastCandle = 0;

void DeInitEvent(int reason)
{
   if (!isTester)
   {
      //program.OnDeinitEvent(reason); //TODO
      return;
   }
   
   delete backtester;
}


void TimerEvent()
{
   //if (!isTester) //TODO
   //   program.OnTimerEvent();
   
}

#define SUBSTITUTE_PARAM(type, id) SubstituteOptimizationParameter(type##_param##id, type##_index##id, type##Params);

void GetIndicatorHandles()
{
   //Process parameters
   #ifdef __MQL5__
      MqlParam mainParams[];
      MqlParam secondParams[];
      MqlParam exitParams[];
      MqlParam volumeParams[];
      MqlParam baselineParams[];
      MqlParam contParams[];
   #else
      double mainParams[];
      double secondParams[];
      double exitParams[];
      double volumeParams[];
      double baselineParams[];
      double contParams[];
   #endif
   

	CDictionary* opt_dict = new CDictionary();
	CreateOptimizationDict(opt_dict);

   ProcessParameters(indicatorName, indicatorParams, mainParams, opt_dict);
   if (use2Confirm) ProcessParameters(indicatorName2nd, indicatorParams2nd, secondParams, opt_dict);
   if (useExitIndicator) ProcessParameters(indicatorNameExit, indicatorParamsExit, exitParams, opt_dict);
   if (useVolumeIndicator) ProcessParameters(indicatorNameVolume, indicatorParamsVolume, volumeParams, opt_dict);
   if (useBaseline)        ProcessParameters(indicatorNameBaseline, indicatorParamsBaseline, baselineParams, opt_dict);
   if (useContIndicator == CONT_CUSTOM)   ProcessParameters(indicatorNameCont, indicatorParamsCont, contParams, opt_dict);
   
   delete opt_dict;

   
   
   // Check Native indicators
   
   #ifdef __MQL5__
   
   string mainName, secondName, exitName, volumeName, baselineName, contName;
   bool mainNative=false, secondNative=false, exitNative=false, volumeNative=false, baselineNative=false, contNative=false;
   if (IS_NATIVE_IND(mainParams[0].string_value))
   {
      mainName = mainParams[0].string_value;
      mainNative = true;
      ArrayRemove(mainParams, 0, 1);
   }
   
   if (use2Confirm)
   {
      if (IS_NATIVE_IND(secondParams[0].string_value))
      {
         secondName = secondParams[0].string_value;
         secondNative = true;
         ArrayRemove(secondParams, 0, 1);
      }
   }
   if (useExitIndicator)
   {
      if (IS_NATIVE_IND(exitParams[0].string_value))
      {
         exitName = exitParams[0].string_value;
         exitNative = true;
         ArrayRemove(exitParams, 0, 1);
      }
   }
   if (useVolumeIndicator)
   {
      if (IS_NATIVE_IND(volumeParams[0].string_value))
      {
         volumeName = volumeParams[0].string_value;
         volumeNative = true;
         ArrayRemove(volumeParams, 0, 1);
      }
   }
   if (useBaseline)
   {
      if (IS_NATIVE_IND(baselineParams[0].string_value))
      {
         baselineName = baselineParams[0].string_value;
         baselineNative = true;
         ArrayRemove(baselineParams, 0, 1);
      }
   }
   if (useContIndicator == CONT_CUSTOM)
   {
      if (IS_NATIVE_IND(contParams[0].string_value))
      {
         contName = contParams[0].string_value;
         contNative = true;
         ArrayRemove(contParams, 0, 1);
      }
   }
   
   //Get Handles

   for (int i=0; i < totalSymbols; i++)
   {
      //int atrHandle = iATR(symbolsToTrade[i], PERIOD_CURRENT, 14);
      int atrHandle = iCustom(symbolsToTrade[i], PERIOD_CURRENT, INVISIBLE_ATR, atrPeriod);
      
      backtester.SetHandle(atrHandle, ATR_IND, i);
      
      int mainHandle = GetIndicatorWithParameters(symbolsToTrade[i], mainParams, mainNative, mainName);
      backtester.SetHandle(mainHandle, MAIN_IND, i);
      
      
      if (use2Confirm)
      {
         int secondHandle = GetIndicatorWithParameters(symbolsToTrade[i], secondParams, secondNative, secondName);
         backtester.SetHandle(secondHandle, SECOND_IND, i);
      }
      if (useExitIndicator)
      {
         int exitHandle = GetIndicatorWithParameters(symbolsToTrade[i], exitParams, exitNative, exitName);
         backtester.SetHandle(exitHandle, EXIT_IND, i);
      }
      if (useVolumeIndicator)
      {
         int volumeHandle = GetIndicatorWithParameters(symbolsToTrade[i], volumeParams, volumeNative, volumeName);
         backtester.SetHandle(volumeHandle, VOLUME_IND, i);
      }
      if (useBaseline)
      {

         int baselineHandle = GetIndicatorWithParameters(symbolsToTrade[i], baselineParams, baselineNative, baselineName);
         backtester.SetHandle(baselineHandle, BASELINE_IND, i);
      }
      if (useContIndicator == CONT_CUSTOM)
      {
         int continuationHandle = GetIndicatorWithParameters(symbolsToTrade[i], contParams, contNative, contName);
         backtester.SetHandle(continuationHandle, CONTINUATION_IND, i);
      }
      
   }
   
   #else
   
   if (IS_NATIVE_IND(indicatorName))
      ProcessNativeParameters(indicatorName, mainParams);
   
   double atrParams[1];
   atrParams[0] = atrPeriod;
   backtester.SetIndicatorProperties(ATR_IND, INVISIBLE_ATR, atrParams);
   
   backtester.SetIndicatorProperties(MAIN_IND, indicatorName, mainParams);
   
   
   if (use2Confirm)
   {
      if (IS_NATIVE_IND(indicatorName2nd))
         ProcessNativeParameters(indicatorName2nd, secondParams);
         
      backtester.SetIndicatorProperties(SECOND_IND, indicatorName2nd, secondParams);
   }
   if (useExitIndicator)
   {
      if (IS_NATIVE_IND(indicatorNameExit))
         ProcessNativeParameters(indicatorNameExit, exitParams);
         
      backtester.SetIndicatorProperties(EXIT_IND, indicatorNameExit, exitParams);
   }
   if (useVolumeIndicator)
   {
      if (IS_NATIVE_IND(indicatorNameVolume))
         ProcessNativeParameters(indicatorNameVolume, volumeParams);
         
      backtester.SetIndicatorProperties(VOLUME_IND, indicatorNameVolume, volumeParams);
   }
   if (useBaseline)
   {
      if (IS_NATIVE_IND(indicatorNameBaseline))
         ProcessNativeParameters(indicatorNameBaseline, baselineParams);
         
      backtester.SetIndicatorProperties(BASELINE_IND, indicatorNameBaseline, baselineParams);
   }
   if (useContIndicator)
   {
      if (IS_NATIVE_IND(indicatorNameCont))
         ProcessNativeParameters(indicatorNameCont, contParams);
         
      backtester.SetIndicatorProperties(CONTINUATION_IND, indicatorNameCont, contParams);
   }
   
   #endif
}

void GetTrailingStopHandles()
{
   //Process parameters
   #ifdef __MQL5__
      MqlParam trailingParams[];
   #else
      double trailingParams[];
   #endif
   
   ProcessParameters(indicatorNameTrailing, indicatorParamsTrailing, trailingParams);
   
   // Check Native indicators
   
   #ifdef __MQL5__
   
   string trailName;
   bool trailNative=false;
   if (IS_NATIVE_IND(trailingParams[0].string_value))
   {
      trailName = trailingParams[0].string_value;
      trailNative = true;
      ArrayRemove(trailingParams, 0, 1);
   }
   
   //Get Handles

   for (int i=0; i < totalSymbols; i++)
   {
      int trailHandle = GetIndicatorWithParameters(symbolsToTrade[i], trailingParams, trailNative, trailName);
      backtester.SetTrailingHandle(trailHandle, i);
   }
   
   #else
   
   if (IS_NATIVE_IND(indicatorNameTrailing))
      ProcessNativeParameters(indicatorNameTrailing, trailingParams);
   
   backtester.SetTrailingIndicatorProperties(indicatorNameTrailing, trailingParams);
   
   #endif
}

void GetEVZHandle()
{
   #ifdef __MQL5__
   MqlParam evzParams[];
   ProcessParameters(EVZ_INDICATOR, evzParams);

   int evzHandle = GetIndicatorWithParameters(Symbol(), evzParams);
   
   #else
   
   int evzHandle = 0; // Not used in MT4
   
   #endif
   
   backtester.SetEVZHandle(evzHandle, minimumEvz, halfRiskEvz, scaleOutHalfRisk);
}

bool CheckExpertParameters()
{
   if (stopLossAtr<=0.0 || takeProfitAtr<=0.0)
   {
      Print("Stop Loss and Take Profit ATR need to be greater than 0.0");
      return false;
   }
   
   if (minimumEvz > halfRiskEvz)
   {
      Print("Minimum EVZ cannot be greater than Half Risk EVZ");
      return false;
   }

   return true;
}

#define SET_OPT_DICT(n) dict.Set<double>("#" +IntegerToString(n), opt_param_##n); //if (opt_param_##n!=0.0) { }

void CreateOptimizationDict(CDictionary* dict)
{
	SET_OPT_DICT(1)  SET_OPT_DICT(2)  SET_OPT_DICT(3)  SET_OPT_DICT(4)  SET_OPT_DICT(5)
	SET_OPT_DICT(6)  SET_OPT_DICT(7)  SET_OPT_DICT(8)  SET_OPT_DICT(9)  SET_OPT_DICT(10)
	SET_OPT_DICT(11) SET_OPT_DICT(12) SET_OPT_DICT(13) SET_OPT_DICT(14) SET_OPT_DICT(15)
	SET_OPT_DICT(16) SET_OPT_DICT(17) SET_OPT_DICT(18) SET_OPT_DICT(19) SET_OPT_DICT(20)
	SET_OPT_DICT(21) SET_OPT_DICT(22) SET_OPT_DICT(23) SET_OPT_DICT(24) SET_OPT_DICT(25)
	SET_OPT_DICT(26) SET_OPT_DICT(27) SET_OPT_DICT(28) SET_OPT_DICT(29) SET_OPT_DICT(30)
	SET_OPT_DICT(31) SET_OPT_DICT(32) SET_OPT_DICT(33) SET_OPT_DICT(34) SET_OPT_DICT(35)
	SET_OPT_DICT(36) SET_OPT_DICT(37) SET_OPT_DICT(38) SET_OPT_DICT(39) SET_OPT_DICT(40)
	SET_OPT_DICT(41) SET_OPT_DICT(42) SET_OPT_DICT(43) SET_OPT_DICT(44) SET_OPT_DICT(45)
	SET_OPT_DICT(46) SET_OPT_DICT(47) SET_OPT_DICT(48) SET_OPT_DICT(49) SET_OPT_DICT(50)
}