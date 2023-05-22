//+------------------------------------------------------------------+
//|                                                IndicatorRead.mqh |
//|                                 Copyright 2020, Alejandro Cercós |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Alejandro Cercós"
#property link      "https://www.mql5.com"

#include "Enumerators.mqh" //Indicator Read

//+------------------------------------------------------------------+
//| Zero Line Cross                                                  |
//+------------------------------------------------------------------+

int ZeroLineCross(double actual, double last, double cross, bool invert)
{
   if (last <= cross && actual > cross)
   {
      if (!invert)   { return BUY_SIGNAL;  }
      else           { return SELL_SIGNAL; }
   }
   else if (last >= cross && actual < cross)
   {
      if (!invert)   { return SELL_SIGNAL; }
      else           { return BUY_SIGNAL;  }
   }
   else if (actual > cross)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else if (actual < cross)
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
   
   return NEUTRAL;
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 2 Lines Cross                                                    |
//+------------------------------------------------------------------+

int TwoLinesCrossover(double actLine, double lastLine, double actSignal, double lastSignal, bool invert)
{
   if (lastLine <= lastSignal && actLine > actSignal)
   {
      if (!invert)   { return BUY_SIGNAL;  }
      else           { return SELL_SIGNAL; }
   }
   else if (lastLine >= lastSignal && actLine < actSignal)
   {
      if (!invert)   { return SELL_SIGNAL; }
      else           { return BUY_SIGNAL;  }
   }
   
   else if (actLine > actSignal)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else if (actLine < actSignal)
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
   
   else if (lastLine > lastSignal)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else if (lastLine < lastSignal)
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
   
   else if (actLine > lastLine)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else if (actLine < lastLine)
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
   
   else if (actLine > 0)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else // actLine <=0
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Chart dot signals                                                |
//+------------------------------------------------------------------+

int ChartDotSignal (double buySignal, double sellSignal, bool invert)
{
   
   if (buySignal != 0 && buySignal!=EMPTY_VALUE)
   {
      if (!invert)   { return BUY_SIGNAL;  }
      else           { return SELL_SIGNAL; }
   }
   else if (sellSignal != 0 && sellSignal!=EMPTY_VALUE)
   {
      if (!invert)   { return SELL_SIGNAL; }
      else           { return BUY_SIGNAL;  }
   }
   
   return NEUTRAL;
}

int ChartDotColor(double signal, int currentColor, int buyColor, int sellColor, bool invert)
{
   if (signal != 0 && signal != EMPTY_VALUE)
   {
      if (currentColor == buyColor)
      {
         if (!invert)   { return BUY_SIGNAL;  }
         else           { return SELL_SIGNAL; }
      }
      else if (currentColor == sellColor)
      {
         if (!invert)   { return SELL_SIGNAL; }
         else           { return BUY_SIGNAL;  }
      }
   }
   
   return NEUTRAL;
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Buffer activation                                                |
//+------------------------------------------------------------------+

int BufferActivation(double buySignal, double sellSignal, double lastBuySignal, double lastSellSignal, bool invert)
{
   if (buySignal != 0 && buySignal != EMPTY_VALUE)
   {
      if (lastBuySignal != 0 && lastBuySignal != EMPTY_VALUE)
      {
         if (!invert)   { return BUY_CURRENT;  }
         else           { return SELL_CURRENT; }
      }
      else
      {
         if (!invert)   { return BUY_SIGNAL;  }
         else           { return SELL_SIGNAL; }
      }
   }
   else if (sellSignal != 0 && sellSignal != EMPTY_VALUE)
   {
      if (lastSellSignal !=0 && lastSellSignal != EMPTY_VALUE)
      {
         if (!invert)   { return SELL_CURRENT; }
         else           { return BUY_CURRENT;  }
      }
      else
      {
         if (!invert)   { return SELL_SIGNAL; }
         else           { return BUY_SIGNAL;  }
      }
   }
   
   return NEUTRAL;
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Zero Line Filtered                                               |
//+------------------------------------------------------------------+

int ZeroLineFilter(double actual, double last, double lineLevel, double lineFilter, bool invert, double atr=1, double lastAtr=1)
{
      
   if (last <= lineLevel + lastAtr * lineFilter  &&  actual > lineLevel + atr * lineFilter)
   {
      if (!invert)   { return BUY_SIGNAL;  }
      else           { return SELL_SIGNAL; }
   }
   else if (last >= lineLevel - lastAtr * lineFilter  &&  actual < lineLevel - atr * lineFilter)
   {
      if (!invert)   { return SELL_SIGNAL; }
      else           { return BUY_SIGNAL;  }
   }
   else if (actual > lineLevel + atr * lineFilter)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else if (actual < lineLevel - atr * lineFilter)
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
   else
   {
      return NEUTRAL;
   }
} 

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 2 Lines Cross Filtered                                           |
//+------------------------------------------------------------------+

int TwoLinesFiltered(double actLine, double lastLine, double actSignal, double lastSignal, double lineFilter, bool invert, double atr=1, double lastAtr=1)
{
   
   if (lastLine <= lastSignal + lastAtr * lineFilter  &&  actLine > actSignal + atr * lineFilter)
   {
      if (!invert)   { return BUY_SIGNAL;  }
      else           { return SELL_SIGNAL; }
   }
   else if (lastLine >= lastSignal - lastAtr * lineFilter  &&  actLine < actSignal - atr * lineFilter)
   {
      if (!invert)   { return SELL_SIGNAL; }
      else           { return BUY_SIGNAL;  }
   }
   else if (actLine > actSignal + atr * lineFilter)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else if (actLine < actSignal - atr * lineFilter)
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
   else
   {
      return NEUTRAL;
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Color Buffers                                                    |
//+------------------------------------------------------------------+

int ColorBuffer(int actColor, int lastColor, int buyColor, int sellColor, bool invert=false)
{
   if (actColor == buyColor)
   {
      if (lastColor == buyColor) 
      { 
         if (!invert)   { return BUY_CURRENT;  }
         else           { return SELL_CURRENT; }
      }
      else
      { 
         if (!invert)   { return BUY_SIGNAL;  }
         else           { return SELL_SIGNAL; }
      }
   }
   else if (actColor == sellColor)
   {
      if (lastColor == sellColor) 
      { 
         if (!invert)   { return SELL_CURRENT; }
         else           { return BUY_CURRENT;  }
      }
      else
      {
         if (!invert)   { return SELL_SIGNAL; }
         else           { return BUY_SIGNAL;  }
      }
   }
   else
   {
      return NEUTRAL;
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Color Buffers                                                    |
//+------------------------------------------------------------------+

int CrossInsideFilter(double actual, double last, double lineLevel, double lineFilter, bool invert, double atr=1, double lastAtr=1)
{
      
   if (last > lineLevel + lastAtr * lineFilter  &&  actual <= lineLevel + atr * lineFilter)
   {
      if (!invert)   { return SELL_SIGNAL; }
      else           { return BUY_SIGNAL;  }
   }
   else if (last < lineLevel - lastAtr * lineFilter  &&  actual >= lineLevel - atr * lineFilter)
   {
      if (!invert)   { return BUY_SIGNAL;  }
      else           { return SELL_SIGNAL; }
   }
   else if (actual > lineLevel + atr * lineFilter)
   {
      if (!invert)   { return BUY_CURRENT;  }
      else           { return SELL_CURRENT; }
   }
   else if (actual < lineLevel - atr * lineFilter)
   {
      if (!invert)   { return SELL_CURRENT; }
      else           { return BUY_CURRENT;  }
   }
   else
   {
      return NEUTRAL;
   }
}

int ColorOverLevel(double mainValue, double lastValue, double minimumLevel, bool isBuyColor, bool lastIsBuyColor, bool invert)
{
   if (mainValue < minimumLevel)
   {
      return NEUTRAL;
   }
   else if (lastValue<minimumLevel)
   {
   	if (!invert)
      	return isBuyColor?BUY_SIGNAL:SELL_SIGNAL;
      else
      	return isBuyColor?SELL_SIGNAL:BUY_SIGNAL;
   }
   else if (lastIsBuyColor != isBuyColor)
   {
   	if (!invert)
      	return isBuyColor?BUY_SIGNAL:SELL_SIGNAL;
      else
      	return isBuyColor?SELL_SIGNAL:BUY_SIGNAL;
   }
   else 
   {
		if (!invert)
      	return isBuyColor?BUY_CURRENT:SELL_CURRENT;
      else
      	return isBuyColor?SELL_CURRENT:BUY_CURRENT;
   }
}

int ColorOverSignal(double actLine, double lastLine, double actSignal, double lastSignal, bool isBuyColor, bool lastIsBuyColor, bool invert)
{
   if (actLine < actSignal)
   {
      return NEUTRAL;
   }
   else if (lastLine<lastSignal)
   {
   	if (!invert)
      	return isBuyColor?BUY_SIGNAL:SELL_SIGNAL;
      else
      	return isBuyColor?SELL_SIGNAL:BUY_SIGNAL;
   }
   else if (lastIsBuyColor != isBuyColor)
   {
   	if (!invert)
      	return isBuyColor?BUY_SIGNAL:SELL_SIGNAL;
      else
      	return isBuyColor?SELL_SIGNAL:BUY_SIGNAL;
   }
   else 
   {
		if (!invert)
      	return isBuyColor?BUY_CURRENT:SELL_CURRENT;
      else
      	return isBuyColor?SELL_CURRENT:BUY_CURRENT;
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Volume Indicators                                                |
//+------------------------------------------------------------------+

bool VolumeOverLevel(double volumeValue, double minimumLevel, double atr=1.0, int volumeSignal=NEUTRAL, int currentSignal=NEUTRAL)
{
   if (volumeValue * atr < minimumLevel)
   {
      return false;
   }
   else if (volumeSignal == NEUTRAL)
   {
      return true;
   }
   else if (volumeSignal == BUY_CURRENT || volumeSignal == BUY_SIGNAL)
   {
      return (currentSignal == BUY_CURRENT || currentSignal == BUY_SIGNAL);
   }
   else //if (volumeSignal == SELL_CURRENT || volumeSignal == SELL_SIGNAL)
   {
      return (currentSignal == SELL_CURRENT || currentSignal == SELL_SIGNAL);
   }
}

bool VolumeOverSignal(double volumeValue, double signalValue, int volumeSignal=NEUTRAL, int currentSignal=NEUTRAL)
{
   if (volumeValue < signalValue)
   {
      return false;
   }
   else if (volumeSignal == NEUTRAL)
   {
      return true;
   }
   else if (volumeSignal == BUY_CURRENT || volumeSignal == BUY_SIGNAL)
   {
      return (currentSignal == BUY_CURRENT || currentSignal == BUY_SIGNAL);
   }
   else //if (volumeSignal == SELL_CURRENT || volumeSignal == SELL_SIGNAL)
   {
      return (currentSignal == SELL_CURRENT || currentSignal == SELL_SIGNAL);
   }
}

bool VolumeBidirectional(double volumeValue, double levelValue, double signalValue, int currentSignal)
{
   if (volumeValue >= levelValue + signalValue)
   {
      return currentSignal != SELL_CURRENT && currentSignal != SELL_SIGNAL;
   }
   else if (volumeValue <= levelValue - signalValue)
   {
      return currentSignal != BUY_CURRENT && currentSignal != BUY_SIGNAL;
   }
   else
   {
      return false;
   }
}



//+------------------------------------------------------------------+
//|                 INDICATOR SIGNAL                                 |
//+------------------------------------------------------------------+
int Get_Indicator_Signal(IndicatorRead type, double actualMain, double lastMain, double actualSignal, 
							double lastSignal, double actualClose, double lastClose, double cross, 
							double w_filter, bool invert, int buy_color, int sell_color,
							bool isBuyColor=true, bool lastBuyColor=true)
{
   switch (type)
   {
      case ZERO_LINE_CROSS:
         return ZeroLineCross(actualMain, lastMain, cross, invert);
         
      case TWO_LINES_CROSS:
         return TwoLinesCrossover(actualMain, lastMain, actualSignal, lastSignal, invert);
         
      case CHART_DOT_SIGNAL:
         return ChartDotSignal(actualMain, actualSignal, invert);
         
      case BUFFER_ACTIVATION:
         return BufferActivation(actualMain, actualSignal, lastMain, lastSignal, invert);
         
      case ZERO_LINE_FILTER:
         return ZeroLineFilter(actualMain, lastMain, cross, w_filter, invert);
      
      #ifdef __MQL5__
      case COLOR_BUFFER:
         return ColorBuffer((int)actualMain, (int)lastMain, buy_color, sell_color, invert);
      #endif
         
      case CROSS_PRICE:
         return TwoLinesCrossover(actualClose, lastClose, actualMain, lastMain, invert);
      
      case CROSS_IN_FILTER:
         return CrossInsideFilter(actualMain, lastMain, cross, w_filter, invert);
         
      #ifdef __MQL5__
      case CHART_DOT_COLOR:
         return ChartDotColor(actualMain, (int)actualSignal, buy_color, sell_color, invert);
      #endif
      
      case OVER_SIGNAL_COLOR:
      	return ColorOverSignal(actualMain, lastMain, actualSignal, lastSignal, isBuyColor, lastBuyColor, invert);
      
     	case OVER_LEVEL_COLOR:
     		return ColorOverLevel(actualMain, lastMain, cross, isBuyColor, lastBuyColor, invert);
     	
   }
   
   return NEUTRAL;
}