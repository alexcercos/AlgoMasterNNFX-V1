#include "GenericBacktester.mqh" //Virtual Trades

#ifdef __MQL5__

class Backtester : public GenericBacktester
{
   protected:
   /*
      virtual double GetValueFromBuffersVolume(int initBuffer, int endBuffer, int shift);
      virtual double GetValueFromBuffers(int initBuffer, int endBuffer, int shift);
      virtual double GetValueFromBuffersVolume(int &listBuffers[], int shift);
      virtual double GetValueFromBuffers(int &listBuffers[], int shift);
      */
      virtual double GetIndicatorValue(int indicatorType, int shift, bool main = true);
      virtual double GetIndicatorValue(int indicatorType, int shift, int buffer);
      virtual int GetVolumeIndColorSignal(int shift);
      virtual void UpdateIndicatorValues();
      
   public:
      Backtester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false);
      ~Backtester();
};



// Constructor

void Backtester::Backtester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false)
   :GenericBacktester(trade_value, symbolsArray, pullback, one_candle, bridge_tf, scale_out, draw_arrows, debug_trades, debug_virtual_trades, result_in_pips, use_main_exit)
{

}

void Backtester::~Backtester()
{
}

double Backtester::GetIndicatorValue(int indicatorType, int shift, bool main = true)
{
   switch (indicatorType)
   {
      case ATR_IND:
         return atrCurrentValues[DISPLACEMENT+1-shift];
      case MAIN_IND:
         if (main)
         {
            if (shift<=DISPLACEMENT+1)
               return mainCurrentValues[DISPLACEMENT+1-shift];
            else
            {
            	int finalDisplace;
            	if (correctIndicatorDisplace)
				      finalDisplace = 0; //Caso especifico -> Gap en la siguiente vela (no actual) y sin displaceCorrection, se ignora el desplazamiento
				   else
				      finalDisplace = displaceCorrection[activeSymbol] + DISPLACEMENT;
				   
               double val[1];
               CopyBuffer(mainHandles[activeSymbol], mainBuffer, finalDisplace+shift, 1, val);
               return val[0];
            }
         }
         else
         {
            if (shift<=DISPLACEMENT+1)
               return mainSignalCurrentValues[DISPLACEMENT+1-shift];
            else
            {
               double val[1];
               CopyBuffer(mainHandles[activeSymbol], signalBuffer, shift, 1, val);
               return val[0];
            }
         }
         
      case SECOND_IND:
         if (main)
         {
            return secondCurrentValues[DISPLACEMENT+1-shift];
         }
         else
         {
            return secondSignalCurrentValues[DISPLACEMENT+1-shift];
         }
         
      case EXIT_IND:
         if (main)
         {
            return exitCurrentValues[DISPLACEMENT+1-shift];
         }
         else
         {
            return exitSignalCurrentValues[DISPLACEMENT+1-shift];
         }
         
      case VOLUME_IND:
         if (main)
         {
            return volumeCurrentValues[DISPLACEMENT+1-shift];
         }
         else
         {
            return volumeSignalCurrentValues[DISPLACEMENT+1-shift];
         }

      case CONTINUATION_IND:
         if (main)
         {
            return continuationCurrentValues[DISPLACEMENT+1-shift];
         }
         else
         {
            return continuationSignalCurrentValues[DISPLACEMENT+1-shift];
         }
         
      case BASELINE_IND:
         if (main)
         {
            return currentRates[DISPLACEMENT+1-shift].close;
         }
         else
         {
            return baselineCurrentValues[DISPLACEMENT+1-shift];
         }
   }
   
   return 0;
}

double Backtester::GetIndicatorValue(int indicatorType, int shift, int buffer)
{
	int finalDisplace;
   
   if (correctIndicatorDisplace)
   {
      finalDisplace = 0; //Caso especifico -> Gap en la siguiente vela (no actual) y sin displaceCorrection, se ignora el desplazamiento
   }
   else
   {
      finalDisplace = displaceCorrection[activeSymbol];
   }
   
   double val[1];
   
	switch (indicatorType)
   {
      case ATR_IND:
         CopyBuffer(atrHandles[activeSymbol], buffer, finalDisplace+shift, 1, val);
         return val[0];
         
      case MAIN_IND:
         CopyBuffer(mainHandles[activeSymbol], buffer, finalDisplace+shift, 1, val);
         return val[0];
         
      case SECOND_IND:
         CopyBuffer(secondHandles[activeSymbol], buffer, finalDisplace+shift, 1, val);
         return val[0];
         
      case EXIT_IND:
         CopyBuffer(exitHandles[activeSymbol], buffer, finalDisplace+shift, 1, val);
         return val[0];
         
      case VOLUME_IND:
         CopyBuffer(volumeHandles[activeSymbol], buffer, finalDisplace+shift, 1, val);
         return val[0];

      case CONTINUATION_IND:
         CopyBuffer(continuationHandles[activeSymbol], buffer, finalDisplace+shift, 1, val);
         return val[0];
         
      case BASELINE_IND:
         CopyBuffer(baselineHandles[activeSymbol], buffer, finalDisplace+shift, 1, val);
         return val[0];
   }
   
   return 0.0;
}

void Backtester::UpdateIndicatorValues()
{
   int finalDisplace;
   
   if (correctIndicatorDisplace)
   {
      finalDisplace = 0; //Caso especifico -> Gap en la siguiente vela (no actual) y sin displaceCorrection, se ignora el desplazamiento
   }
   else
   {
      finalDisplace = displaceCorrection[activeSymbol] + DISPLACEMENT;
   }
   

   CopyBuffer(atrHandles[activeSymbol], 0, finalDisplace, 2, atrCurrentValues);
   
   CopyBuffer(mainHandles[activeSymbol], mainBuffer, finalDisplace, 2, mainCurrentValues);
   CopyBuffer(mainHandles[activeSymbol], signalBuffer, finalDisplace, 2, mainSignalCurrentValues);

   
   if (use2Confirm)
   {
      CopyBuffer(secondHandles[activeSymbol], mainBuffer2nd, finalDisplace, 2, secondCurrentValues);
      CopyBuffer(secondHandles[activeSymbol], signalBuffer2nd, finalDisplace, 2, secondSignalCurrentValues);
   }
   
   if (useExitIndicator)
   {
      CopyBuffer(exitHandles[activeSymbol], mainBufferExit, finalDisplace, 2, exitCurrentValues);
      CopyBuffer(exitHandles[activeSymbol], signalBufferExit, finalDisplace, 2, exitSignalCurrentValues);
   }
   
   if (useVolumeIndicator)
   {
      CopyBuffer(volumeHandles[activeSymbol], mainBufferVolume, finalDisplace, 2, volumeCurrentValues);
      
      CopyBuffer(volumeHandles[activeSymbol], signalBufferVolume, finalDisplace, 2, volumeSignalCurrentValues);
   }

   if (useContIndicator == CONT_CUSTOM)
   {
      CopyBuffer(continuationHandles[activeSymbol], mainBufferCont, finalDisplace, 2, continuationCurrentValues);
      CopyBuffer(continuationHandles[activeSymbol], signalBufferCont, finalDisplace, 2, continuationSignalCurrentValues);
   }
   else if (useContIndicator == CONT_USE_MAIN)
   {
      ArrayCopy(continuationCurrentValues, mainCurrentValues);
      ArrayCopy(continuationSignalCurrentValues, mainSignalCurrentValues);
   }
   else if (useContIndicator == CONT_USE_EXIT)
   {
      ArrayCopy(continuationCurrentValues, exitCurrentValues);
      ArrayCopy(continuationSignalCurrentValues, exitSignalCurrentValues);
   }
   
   if (useBaseline)
   {
      CopyBuffer(baselineHandles[activeSymbol], baselineBuffer, finalDisplace, 2, baselineCurrentValues);
   }
}

int Backtester::GetVolumeIndColorSignal(int shift)
{
   double volColor[];
   CopyBuffer(volumeHandles[activeSymbol], mainBufferVolume+1, displaceCorrection[activeSymbol] + DISPLACEMENT+shift, 1, volColor);
   
   int volumeSignal = NEUTRAL;
   
   if (volColor[0] == volumeBuyColor) volumeSignal = BUY_SIGNAL;
   else if (volColor[0] == volumeSellColor) volumeSignal = SELL_SIGNAL;
   
   return volumeSignal;
}

#else //MQL4

class Backtester : public GenericBacktester
{
   protected:
      string atrIndName, mainIndName, secondIndName, volumeIndName, exitIndName, baselineIndName, contIndName;
      double atrParameters[];
      double mainParameters[];
      double secondParameters[];
      double volumeParameters[];
      double exitParameters[];
      double baselineParameters[];
      double continuationParameters[];
      
      virtual double GetIndicatorValue(int indicatorType, int shift, bool main = true);
      virtual double GetIndicatorValue(int indicatorType, int shift, int buffer);
      virtual int GetVolumeIndColorSignal(int shift);
      virtual void UpdateIndicatorValues();
      
      double GetCustomIndicatorValue(IndicatorType indicator, int buffer, int shift);
      double GetICustom(const string name, double &parameters[], int buffer, int shift);
      double GetNativeIndicator(string name, double &parameters[], int buffer, int shift);
      
   public:
      Backtester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false);
      ~Backtester();
      
      void SetIndicatorProperties(IndicatorType indicator, string indicator_name, double &parameters[]);
};

// Constructor

void Backtester::Backtester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false)
   :GenericBacktester(trade_value, symbolsArray, pullback, one_candle, bridge_tf, scale_out, draw_arrows, debug_trades, debug_virtual_trades, result_in_pips, use_main_exit)
{

}

void Backtester::~Backtester()
{
}

void Backtester::SetIndicatorProperties(IndicatorType indicator,string indicator_name,double &parameters[])
{
   switch (indicator)
   {
      case ATR_IND:
         atrIndName = indicator_name;
         ArrayCopy(atrParameters, parameters);
         break;
      case MAIN_IND:
         mainIndName = indicator_name;
         ArrayCopy(mainParameters, parameters);
         break;
      case SECOND_IND:
         secondIndName = indicator_name;
         ArrayCopy(secondParameters, parameters);
         break;
      case VOLUME_IND:
         volumeIndName = indicator_name;
         ArrayCopy(volumeParameters, parameters);
         break;
      case EXIT_IND:
         exitIndName = indicator_name;
         ArrayCopy(exitParameters, parameters);
         break;
      case BASELINE_IND:
         baselineIndName = indicator_name;
         ArrayCopy(baselineParameters, parameters);
         break;
      case CONTINUATION_IND:
         contIndName = indicator_name;
         ArrayCopy(continuationParameters, parameters);
         break;
   }
}

/*

   PUEDE QUE NO HAGA FALTA EL UPDATE, Y BASTE CON iCustoms DESDE GetIndicatorValue
   (Depende de como actualice los indicadores el tester)
   
*/

double Backtester::GetIndicatorValue(int indicatorType, int shift, bool main = true)
{
   int finalDisplace;

   if (correctIndicatorDisplace)
   {
      finalDisplace = -DISPLACEMENT; //Caso especifico -> Gap en la siguiente vela (no actual) y sin displaceCorrection, se ignora el desplazamiento
   }
   else
   {
      finalDisplace = displaceCorrection[activeSymbol];
   }

   switch (indicatorType)
   {
      case ATR_IND:
         return GetCustomIndicatorValue(ATR_IND, 0, finalDisplace + shift);
      case MAIN_IND:
         if (main)
         {
            return GetCustomIndicatorValue(MAIN_IND, mainBuffer, finalDisplace + shift);
         }
         else
         {
            return GetCustomIndicatorValue(MAIN_IND, signalBuffer, finalDisplace + shift);
         }
         
      case SECOND_IND:
         if (main)
         {
            return GetCustomIndicatorValue(SECOND_IND, mainBuffer2nd, finalDisplace + shift);
         }
         else
         {
            return GetCustomIndicatorValue(SECOND_IND, signalBuffer2nd, finalDisplace + shift);
         }
         
      case EXIT_IND:
         if (main)
         {
            return GetCustomIndicatorValue(EXIT_IND, mainBufferExit, finalDisplace + shift);
         }
         else
         {
            return GetCustomIndicatorValue(EXIT_IND, signalBufferExit, finalDisplace + shift);
         }
         
      case VOLUME_IND:
         if (main)
         {
            if (indicatorModeVolume == OVER_LEVEL_BUY_SELL || indicatorModeVolume == OVER_SIGNAL_BUY_SELL) //COLOR MODES
            {
               double volBuy = GetCustomIndicatorValue(VOLUME_IND, volumeBuyColor, finalDisplace + shift);
               double volSell = GetCustomIndicatorValue(VOLUME_IND, volumeSellColor, finalDisplace + shift);
               
               if (volBuy!=EMPTY_VALUE && volSell!=EMPTY_VALUE) return MathMax(volBuy, volSell);
               else return MathMin(volBuy, volSell);
               
            }
            else
               return GetCustomIndicatorValue(VOLUME_IND, mainBufferVolume, finalDisplace + shift);
         }
         else
         {
            return GetCustomIndicatorValue(VOLUME_IND, signalBufferVolume, finalDisplace + shift);
         }

      case CONTINUATION_IND:
         if (main)
         {
            return GetCustomIndicatorValue(CONTINUATION_IND, mainBufferCont, finalDisplace + shift);
         }
         else
         {
            return GetCustomIndicatorValue(CONTINUATION_IND, signalBufferCont, finalDisplace + shift);
         }
         
      case BASELINE_IND:
         if (main)
         {
            return iClose(symbolsToTrade[activeSymbol], PERIOD_CURRENT, finalDisplace + shift);
         }
         else
         {
            return GetCustomIndicatorValue(BASELINE_IND, baselineBuffer, finalDisplace + shift);
         }
   }
   
   return 0;
}

double Backtester::GetIndicatorValue(int indicatorType, int shift, int buffer)
{
   int finalDisplace;

   if (correctIndicatorDisplace)
   {
      finalDisplace = -DISPLACEMENT; //Caso especifico -> Gap en la siguiente vela (no actual) y sin displaceCorrection, se ignora el desplazamiento
   }
   else
   {
      finalDisplace = displaceCorrection[activeSymbol];
   }

   return GetCustomIndicatorValue((IndicatorType)indicatorType, buffer, finalDisplace + shift);
   
}

void Backtester::UpdateIndicatorValues()
{
   int finalDisplace;
   
   if (correctIndicatorDisplace)
   {
      finalDisplace = 0; //Caso especifico -> Gap en la siguiente vela (no actual) y sin displaceCorrection, se ignora el desplazamiento
   }
   else
   {
      finalDisplace = displaceCorrection[activeSymbol] + DISPLACEMENT;
   }
   
   atrCurrentValues[DATA_PAST] = GetCustomIndicatorValue(ATR_IND, 0, finalDisplace + 1);
   atrCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(ATR_IND, 0, finalDisplace);
   
   mainCurrentValues[DATA_PAST] = GetCustomIndicatorValue(MAIN_IND, mainBuffer, finalDisplace+1);
   mainCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(MAIN_IND, mainBuffer, finalDisplace);
   mainSignalCurrentValues[DATA_PAST] = GetCustomIndicatorValue(MAIN_IND, signalBuffer, finalDisplace+1);
   mainSignalCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(MAIN_IND, signalBuffer, finalDisplace);
   
   if (use2Confirm)
   {
      secondCurrentValues[DATA_PAST] = GetCustomIndicatorValue(SECOND_IND, mainBuffer2nd, finalDisplace+1);
      secondCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(SECOND_IND, mainBuffer2nd, finalDisplace);
      secondSignalCurrentValues[DATA_PAST] = GetCustomIndicatorValue(SECOND_IND, signalBuffer2nd, finalDisplace+1);
      secondSignalCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(SECOND_IND, signalBuffer2nd, finalDisplace);
   }
   
   if (useExitIndicator)
   {
      exitCurrentValues[DATA_PAST] = GetCustomIndicatorValue(EXIT_IND, mainBufferExit, finalDisplace+1);
      exitCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(EXIT_IND, mainBufferExit, finalDisplace);
      exitSignalCurrentValues[DATA_PAST] = GetCustomIndicatorValue(EXIT_IND, signalBufferExit, finalDisplace+1);
      exitSignalCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(EXIT_IND, signalBufferExit, finalDisplace);
   }
   
   if (useVolumeIndicator)
   {
      if (indicatorModeVolume == OVER_LEVEL_BUY_SELL || indicatorModeVolume == OVER_SIGNAL_BUY_SELL) //COLOR MODES
      {
         double volBuy = GetCustomIndicatorValue(VOLUME_IND, volumeBuyColor, finalDisplace+1);
         double volSell = GetCustomIndicatorValue(VOLUME_IND, volumeSellColor, finalDisplace+1);
         
         if (volBuy!=EMPTY_VALUE && volSell!=EMPTY_VALUE) volumeCurrentValues[DATA_PAST] = MathMax(volBuy, volSell);
         else volumeCurrentValues[DATA_PAST] = MathMin(volBuy, volSell);
         
         volBuy = GetCustomIndicatorValue(VOLUME_IND, volumeBuyColor, finalDisplace);
         volSell = GetCustomIndicatorValue(VOLUME_IND, volumeSellColor, finalDisplace);
         
         if (volBuy!=EMPTY_VALUE && volSell!=EMPTY_VALUE) volumeCurrentValues[DATA_RECENT] = MathMax(volBuy, volSell);
         else volumeCurrentValues[DATA_RECENT] = MathMin(volBuy, volSell);
         
      }
      else
      {
         volumeCurrentValues[DATA_PAST] = GetCustomIndicatorValue(VOLUME_IND, mainBufferVolume, finalDisplace+1);
         volumeCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(VOLUME_IND, mainBufferVolume, finalDisplace);
      }
      
      volumeSignalCurrentValues[DATA_PAST] = GetCustomIndicatorValue(VOLUME_IND, signalBufferVolume, finalDisplace+1);
      volumeSignalCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(VOLUME_IND, signalBufferVolume, finalDisplace);
   }

   if (useContIndicator==CONT_CUSTOM)
   {
      continuationCurrentValues[DATA_PAST] = GetCustomIndicatorValue(CONTINUATION_IND, mainBufferCont, finalDisplace+1);
      continuationCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(CONTINUATION_IND, mainBufferCont, finalDisplace);
      continuationSignalCurrentValues[DATA_PAST] = GetCustomIndicatorValue(CONTINUATION_IND, signalBufferCont, finalDisplace+1);
      continuationSignalCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(CONTINUATION_IND, signalBufferCont, finalDisplace);
   }
   
   if (useBaseline)
   {
      baselineCurrentValues[DATA_PAST] = GetCustomIndicatorValue(BASELINE_IND, baselineBuffer, finalDisplace+1);
      baselineCurrentValues[DATA_RECENT] = GetCustomIndicatorValue(BASELINE_IND, baselineBuffer, finalDisplace);
   }
}

int Backtester::GetVolumeIndColorSignal(int shift)
{
   double volBuy = GetCustomIndicatorValue(VOLUME_IND, volumeBuyColor, displaceCorrection[activeSymbol] + DISPLACEMENT+shift);
   double volSell = GetCustomIndicatorValue(VOLUME_IND, volumeSellColor, displaceCorrection[activeSymbol] + DISPLACEMENT+shift);
   
   
   int volumeSignal = NEUTRAL;
   
   if (volBuy!=0 && volBuy!=EMPTY_VALUE) volumeSignal = BUY_SIGNAL;
   else if (volSell!=0 && volSell!=EMPTY_VALUE) volumeSignal = SELL_SIGNAL;
   
   return volumeSignal;
}

//Soporte para inds nativos

double Backtester::GetCustomIndicatorValue(IndicatorType indicator,int buffer,int shift)
{
   switch (indicator)
   {
      case ATR_IND:
         return GetICustom(atrIndName, atrParameters, 0, shift);
         
      case MAIN_IND:
         return GetICustom(mainIndName, mainParameters, buffer, shift);
         
      case SECOND_IND:
         return GetICustom(secondIndName, secondParameters, buffer, shift);
         
      case VOLUME_IND:
         return GetICustom(volumeIndName, volumeParameters, buffer, shift);
         
      case EXIT_IND:
         return GetICustom(exitIndName, exitParameters, buffer, shift);

      case BASELINE_IND:
         return GetICustom(baselineIndName, baselineParameters, buffer, shift);

      case CONTINUATION_IND:
         if (useContIndicator==CONT_CUSTOM)
            return GetICustom(contIndName, continuationParameters, buffer, shift);
         else if (useContIndicator==CONT_USE_EXIT)
            return GetICustom(exitIndName, exitParameters, buffer, shift);
         else
            return GetICustom(mainIndName, mainParameters, buffer, shift);

   }
   
   return 0;
}

double Backtester::GetNativeIndicator(string name, double &parameters[], int buffer, int shift)
{
   if (name == "<ADX>")
   {
      return iADX(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_APPLIED_PRICE)parameters[1], buffer, shift);
   }
   if (name == "<BB>")
   {
      return iBands(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], parameters[1], (int)parameters[2], (ENUM_APPLIED_PRICE)parameters[3], buffer, shift);
   }
   if (name == "<ENVELOPES>")
   {
      return iEnvelopes(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_MA_METHOD)parameters[1], (int)parameters[2], (ENUM_APPLIED_PRICE)parameters[3], parameters[4], buffer, shift);
   }
   if (name == "<ICHIMOKU>")
   {
      return iIchimoku(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (int)parameters[2], buffer, shift);
   }
   if (name == "<MA>")
   {
      return iMA(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (ENUM_MA_METHOD)parameters[2], (ENUM_APPLIED_PRICE)parameters[3], shift);
   }
   if (name == "<SAR>")
   {
      return iSAR(symbolsToTrade[activeSymbol], PERIOD_CURRENT, parameters[0], parameters[1], shift);
   }
   if (name == "<STDEV>")
   {
      return iStdDev(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (ENUM_MA_METHOD)parameters[2], (ENUM_APPLIED_PRICE)parameters[3], shift);
   }
   
   if (name == "<ATR>")
   {
      return iATR(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], shift);
   }
   if (name == "<BEARS>")
   {
      return iBearsPower(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_APPLIED_PRICE)parameters[1], shift);
   }
   if (name == "<BULLS>")
   {
      return iBullsPower(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_APPLIED_PRICE)parameters[1], shift);
   }
   if (name == "<CCI>")
   {
      return iCCI(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_APPLIED_PRICE)parameters[1], shift);
   }
   if (name == "<DEMARKER>")
   {
      return iDeMarker(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], shift);
   }
   if (name == "<FORCE>")
   {
      return iForce(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_MA_METHOD)parameters[1], (ENUM_APPLIED_PRICE)parameters[2], shift);
   }
   if (name == "<MACD>")
   {
      return iMACD(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (int)parameters[2], (ENUM_APPLIED_PRICE)parameters[3], buffer, shift);
   }
   if (name == "<MOMENTUM>")
   {
      return iMomentum(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_APPLIED_PRICE)parameters[1], shift);
   }
   if (name == "<OSMA>")
   {
      return iOsMA(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (int)parameters[2], (ENUM_APPLIED_PRICE)parameters[3], shift);
   }
   if (name == "<RSI>")
   {
      return iRSI(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (ENUM_APPLIED_PRICE)parameters[1], shift);
   }
   if (name == "<RVI>")
   {
      return iRVI(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], buffer, shift);
   }
   if (name == "<STOCHASTIC>")
   {
      return iStochastic(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (int)parameters[2], (ENUM_MA_METHOD)parameters[3], (ENUM_STO_PRICE)parameters[4], buffer, shift);
   }
   if (name == "<WPR>")
   {
      return iWPR(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], shift);
   }
   
   if (name == "<AD>")
   {
      return iAD(symbolsToTrade[activeSymbol], PERIOD_CURRENT, shift);
   }
   if (name == "<MFI>")
   {
      return iMFI(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], shift);
   }
   if (name == "<OBV>")
   {
      return iOBV(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (ENUM_APPLIED_PRICE)parameters[0], shift);
   }
   if (name == "<VOLUMES>")
   {
      return (double)iVolume(symbolsToTrade[activeSymbol], PERIOD_CURRENT, shift);
   }
   
   if (name == "<AC>")
   {
      return iAC(symbolsToTrade[activeSymbol], PERIOD_CURRENT, shift);
   }
   if (name == "<ALLIGATOR>")
   {
      return iAlligator(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (int)parameters[2], (int)parameters[3], (int)parameters[4], (int)parameters[5], (ENUM_MA_METHOD)parameters[6], (ENUM_APPLIED_PRICE)parameters[7], buffer, shift);
   }
   if (name == "<AO>")
   {
      return iAO(symbolsToTrade[activeSymbol], PERIOD_CURRENT, shift);
   }
   if (name == "<FRACTALS>")
   {
      return iFractals(symbolsToTrade[activeSymbol], PERIOD_CURRENT, buffer, shift);
   }
   if (name == "<GATOR>")
   {
      return iGator(symbolsToTrade[activeSymbol], PERIOD_CURRENT, (int)parameters[0], (int)parameters[1], (int)parameters[2], (int)parameters[3], (int)parameters[4], (int)parameters[5], (ENUM_MA_METHOD)parameters[6], (ENUM_APPLIED_PRICE)parameters[7], buffer, shift);
   }
   if (name == "<BWMFI>")
   {
      return iBWMFI(symbolsToTrade[activeSymbol], PERIOD_CURRENT, shift);
   }
   return 0.0;
}


#undef IS_NATIVE_IND
#define IS_NATIVE_IND(indicator) indicator[0] == '<' && indicator[StringLen(indicator)-1] == '>'

#define CUSTOM_CALL iCustom(symbolsToTrade[activeSymbol], PERIOD_CURRENT, name 
#define END_CALL buffer, shift)
#define P(id) parameters[id]
#define PR1(row) P(row)
#define PR2(row) PR1(row), P(row+1)
#define PR3(row) PR2(row), P(row+2)
#define PR4(row) PR3(row), P(row+3)
#define PR5(row) PR4(row), P(row+4)
#define PR6(row) PR5(row), P(row+5)
#define PR7(row) PR6(row), P(row+6)
#define PR8(row) PR7(row), P(row+7)
#define PR9(row) PR8(row), P(row+8)
#define PRC(row) PR9(row), P(row+9)

double Backtester::GetICustom(const string name, double &parameters[], int buffer, int shift)
{
   int size = ArraySize(parameters);
   
   if (IS_NATIVE_IND(name))
   {
      return GetNativeIndicator(name, parameters, buffer, shift);
   }
   
   switch (size)
   {
      case 0:
         return CUSTOM_CALL, END_CALL;
         
      case 1:
         return CUSTOM_CALL, PR1(0), END_CALL;
         
      case 2:
         return CUSTOM_CALL, PR2(0), END_CALL;
         
      case 3:
         return CUSTOM_CALL, PR3(0), END_CALL;
         
      case 4:
         return CUSTOM_CALL, PR4(0), END_CALL;
         
      case 5:
         return CUSTOM_CALL, PR5(0), END_CALL;
         
      case 6:
         return CUSTOM_CALL, PR6(0), END_CALL;
         
      case 7:
         return CUSTOM_CALL, PR7(0), END_CALL;
         
      case 8:
         return CUSTOM_CALL, PR8(0), END_CALL;
         
      case 9:
         return CUSTOM_CALL, PR9(0), END_CALL;
         
      case 10:
         return CUSTOM_CALL, PRC(0), END_CALL;
         
         //--
      case 11:
         return CUSTOM_CALL, PRC(0), PR1(1), END_CALL;
         
      case 12:
         return CUSTOM_CALL, PRC(0), PR2(1), END_CALL;
         
      case 13:
         return CUSTOM_CALL, PRC(0), PR3(1), END_CALL;
         
      case 14:
         return CUSTOM_CALL, PRC(0), PR4(1), END_CALL;
         
      case 15:
         return CUSTOM_CALL, PRC(0), PR5(1), END_CALL;
         
      case 16:
         return CUSTOM_CALL, PRC(0), PR6(1), END_CALL;
         
      case 17:
         return CUSTOM_CALL, PRC(0), PR7(1), END_CALL;
         
      case 18:
         return CUSTOM_CALL, PRC(0), PR8(1), END_CALL;
         
      case 19:
         return CUSTOM_CALL, PRC(0), PR9(1), END_CALL;
         
      case 20:
         return CUSTOM_CALL, PRC(0), PRC(1), END_CALL;
         
         //--
      case 21:
         return CUSTOM_CALL, PRC(0), PRC(1), PR1(2), END_CALL;
         
      case 22:
         return CUSTOM_CALL, PRC(0), PRC(1), PR2(2), END_CALL;
         
      case 23:
         return CUSTOM_CALL, PRC(0), PRC(1), PR3(2), END_CALL;
         
      case 24:
         return CUSTOM_CALL, PRC(0), PRC(1), PR4(2), END_CALL;
         
      case 25:
         return CUSTOM_CALL, PRC(0), PRC(1), PR5(2), END_CALL;
         
      case 26:
         return CUSTOM_CALL, PRC(0), PRC(1), PR6(2), END_CALL;
         
      case 27:
         return CUSTOM_CALL, PRC(0), PRC(1), PR7(2), END_CALL;
         
      case 28:
         return CUSTOM_CALL, PRC(0), PRC(1), PR8(2), END_CALL;
         
      case 29:
         return CUSTOM_CALL, PRC(0), PRC(1), PR9(2), END_CALL;
         
      case 30:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), END_CALL;
         
         //--
      case 31:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR1(3), END_CALL;
         
      case 32:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR2(3), END_CALL;
         
      case 33:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR3(3), END_CALL;
         
      case 34:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR4(3), END_CALL;
         
      case 35:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR5(3), END_CALL;
         
      case 36:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR6(3), END_CALL;
         
      case 37:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR7(3), END_CALL;
         
      case 38:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR8(3), END_CALL;
         
      case 39:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PR9(3), END_CALL;
         
      case 40:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), END_CALL;
         
         //--
      case 41:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR1(4), END_CALL;
         
      case 42:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR2(4), END_CALL;
         
      case 43:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR3(4), END_CALL;
         
      case 44:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR4(4), END_CALL;
         
      case 45:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR5(4), END_CALL;
         
      case 46:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR6(4), END_CALL;
         
      case 47:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR7(4), END_CALL;
         
      case 48:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR8(4), END_CALL;
         
      case 49:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PR9(4), END_CALL;
         
      case 50:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), END_CALL;
         
         //--
      case 51:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR1(5), END_CALL;
         
      case 52:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR2(5), END_CALL;
         
      case 53:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR3(5), END_CALL;
         
      case 54:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR4(5), END_CALL;
         
      case 55:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR5(5), END_CALL;
         
      case 56:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR6(5), END_CALL;
         
      case 57:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR7(5), END_CALL;
         
      case 58:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR8(5), END_CALL;
         
      case 59:
         return CUSTOM_CALL, PRC(0), PRC(1), PRC(2), PRC(3), PRC(4), PR9(5), END_CALL;
         
      default:
         return 0;
   }
}

#endif 