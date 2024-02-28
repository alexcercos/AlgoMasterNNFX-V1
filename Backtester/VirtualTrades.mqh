//+------------------------------------------------------------------+
//|                                                VirtualTrades.mqh |
//|                                 Copyright 2020, Alejandro Cercós |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Alejandro Cercós"
#property link      "https://www.mql5.com"

#ifdef __MQL5__
#include "../EAUtils\RiskCalc.mqh"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade m_trade;
CPositionInfo m_position_info;

#endif 

class VirtualTrade
{
   private:
      double openPrice;
      double stopLoss;
      double takeProfit;
      
      double openAtr;
      
      int tradeType;
      bool touchedFirstTP;
      bool startedMovingSL;
      bool isOpen;
      
      datetime openTime;
      
      double tradeValue;
      bool scaleOut;
      
      #ifdef __MQL5__
      bool perform_real_trades;
      
      ulong reference_ticket_tp;
      ulong reference_ticket_scale;
      #endif
      
      //Generic
      string _symbol;
      bool _debugVirtualTrades;
      bool _drawArrows;
      int _sy_digits;
      double _exposure;
      
      bool _profit_in_pips;
      
      double slAtr, tpAtr, startMoveAtr;
      bool drawSquares;
      
      string currentSquareSL, currentSquareTP;
      double lastTrailStop;
      void CreateNewSquare(datetime timeCurrent, double priceOpen, double priceSL, double priceTP);
      void UpdateCurrentSquare(datetime timeCurrent);
      void DrawTrailingStop(datetime currentTime, double currentStop);
      void CreateArrow(string name, datetime time, double price, color arrowColor, bool isOpenArrow=false);
      void CreateTrendline(string name, datetime time1, double price1, datetime time2, double price2, color lineColor);
   
   public:
   
      VirtualTrade(string symbol, bool debug_virtual_trades, bool draw_arrows, bool profitPips=false);
      
      void AdvancedSettings(double sl_atr=1.5, double tp_atr=1.0, double start_move_sl=2.0, bool squares=false);
      
      void OpenTrade(double open_price, double atr, int order_type, datetime open_time, double trade_value, bool scale_out, double exposure = 2.0);
      double CloseTrade(double closePrice, datetime closeTime, double &tradeElapsed);
      
      //void OpenTradePercent(double open_price, datetime open_time, double trade_value);
      //double CloseTradePercent(double closePrice, datetime closeTime);
      
      void UpdateTrailingStop(double closePrice, datetime currentTime);
      void UpdateTrailingStopToValue(double closePrice, double newTSValue, datetime currentTime);
      double CheckStops(double priceHigh, double priceLow, datetime currentTime, double &tradeElapsed);
      
      bool CheckIfOpen() { return isOpen; }
      
      double GetExposure() { return _exposure; }
      bool HasTouchedTP() { return isOpen && touchedFirstTP; }
      
      double GetOpenPrice() { return openPrice; }
      double GetStopLoss() { return stopLoss; }
      
   #ifdef __MQL5__
	   void SetRealTrades() { perform_real_trades = true; }
	#endif
};

// Open New Trade

void VirtualTrade::VirtualTrade(string symbol, bool debug_virtual_trades, bool draw_arrows, bool profitPips=false)
{
   touchedFirstTP = false;
   startedMovingSL = false;
   _symbol = symbol;
   _debugVirtualTrades = debug_virtual_trades;
   _drawArrows = draw_arrows;
   scaleOut = false;
   _profit_in_pips = profitPips;
   _exposure = 0.0;
   
   _sy_digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
   
   slAtr = 1.5;
   tpAtr = 1.0;
   startMoveAtr = 2.0;
   drawSquares = false;
   
   #ifdef __MQL5__
   perform_real_trades=false;
   
   reference_ticket_scale = 0;
   reference_ticket_tp = 0;
   #endif
   
   currentSquareSL = NULL;
   currentSquareTP = NULL;
}

void VirtualTrade::AdvancedSettings(double sl_atr=1.5,double tp_atr=1.0,double start_move_sl=2.0, bool squares=false)
{
   slAtr = sl_atr;
   tpAtr = tp_atr;
   startMoveAtr = start_move_sl;
   drawSquares = squares;
}

void VirtualTrade::CreateArrow(string name,datetime time,double price,color arrowColor, bool isOpenArrow=false)
{
   ObjectCreate(0, name, isOpenArrow?OBJ_ARROW_BUY:OBJ_ARROW_SELL, 0, time, price); //draw an up arrow
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_COLOR, arrowColor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void VirtualTrade::CreateTrendline(string name,datetime time1,double price1,datetime time2,double price2,color lineColor)
{
   ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void VirtualTrade::CreateNewSquare(datetime timeCurrent,double priceOpen,double priceSL,double priceTP)
{
   currentSquareSL = "SquareSL" + IntegerToString(timeCurrent);
   currentSquareTP = "SquareTP" + IntegerToString(timeCurrent);
   
   ObjectCreate(0, currentSquareSL, OBJ_RECTANGLE, 0, timeCurrent, priceOpen, timeCurrent + PeriodSeconds(), priceSL);
   ObjectSetInteger(0, currentSquareSL, OBJPROP_FILL, true);
   ObjectSetInteger(0, currentSquareSL, OBJPROP_COLOR, clrDarkRed);
   ObjectSetInteger(0, currentSquareSL, OBJPROP_BACK, true);
   ObjectSetInteger(0, currentSquareSL, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, currentSquareSL, OBJPROP_HIDDEN, true);
   
   ObjectCreate(0, currentSquareTP, OBJ_RECTANGLE, 0, timeCurrent, priceOpen, timeCurrent + PeriodSeconds(), priceTP);
   ObjectSetInteger(0, currentSquareTP, OBJPROP_FILL, true);
   ObjectSetInteger(0, currentSquareTP, OBJPROP_COLOR, clrGreen);
   ObjectSetInteger(0, currentSquareTP, OBJPROP_BACK, true);
   ObjectSetInteger(0, currentSquareTP, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, currentSquareTP, OBJPROP_HIDDEN, true);
}

void VirtualTrade::UpdateCurrentSquare(datetime timeCurrent)
{
   ObjectSetInteger(0, currentSquareSL, OBJPROP_TIME, 1, timeCurrent);
   ObjectSetInteger(0, currentSquareTP, OBJPROP_TIME, 1, timeCurrent);
}

void VirtualTrade::DrawTrailingStop(datetime currentTime,double currentStop)
{
	#ifdef __MQL5__
	if (perform_real_trades) return;
	#endif

   string name = "LineTrailing" + IntegerToString(currentTime);
   ObjectCreate(0, name, OBJ_TREND, 0, currentTime - PeriodSeconds(), lastTrailStop, currentTime, currentStop);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   
   lastTrailStop = currentStop;
}

void VirtualTrade::OpenTrade(double open_price, double atr, int order_type, datetime open_time, double trade_value, bool scale_out, double exposure = 2.0)
{
   if (atr==0.0) return;
   
   isOpen = true;
   
   openPrice = open_price;
   openAtr = atr;
   tradeType = order_type;
   openTime = open_time;
   tradeValue = trade_value;
   lastTrailStop = openPrice;
   scaleOut = scale_out;
   
   _exposure = exposure;
   
   #ifdef __MQL5__
   
	   #define SELECT_OPEN_TRADE m_position_info.SelectByIndex(PositionsTotal()-1);
	   
	   if (perform_real_trades)
	   {
	   	double lots = CalculateRiskPercentLots(atr*slAtr, exposure/2.0, _symbol);
	   	
	   	if (tradeType == ORDER_TYPE_BUY)
		   {
		   	double ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
		   	openPrice = ask;
		   	
		   	stopLoss = ask - atr * slAtr;
      		takeProfit = ask + atr * tpAtr;
		   
		      m_trade.Buy(lots, _symbol, 0.0, stopLoss, takeProfit);
		      SELECT_OPEN_TRADE
		      reference_ticket_tp = m_position_info.Ticket();
		      
		      m_trade.Buy(lots, _symbol, 0.0, stopLoss, 0.0);
		      SELECT_OPEN_TRADE
		      reference_ticket_scale = m_position_info.Ticket();
		   }
		   else //ORDER_TYPE_SELL
		   {
		   	double bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
		   	openPrice = bid;
		   	
		   	stopLoss = bid + atr * slAtr;
      		takeProfit = bid - atr * tpAtr;
		   
		   	m_trade.Sell(lots, _symbol, 0.0, stopLoss, takeProfit);
		      SELECT_OPEN_TRADE
		      reference_ticket_tp = m_position_info.Ticket();
		      
		      m_trade.Sell(lots, _symbol, 0.0, stopLoss, 0.0);
		      SELECT_OPEN_TRADE
		      reference_ticket_scale = m_position_info.Ticket();
		   }
	   	
	   	return;
	   }
   #endif
   
   if (tradeType == ORDER_TYPE_BUY)
   {
      stopLoss = openPrice - atr * slAtr;
      takeProfit = openPrice + atr * tpAtr;
   }
   else //ORDER_TYPE_SELL
   {
      stopLoss = openPrice + atr * slAtr;
      takeProfit = openPrice - atr * tpAtr;
   }
   
   if (_debugVirtualTrades)
   {
      Print(_symbol + ": " +
         "Open VIRTUAL " + GetSignalTypeString(tradeType) + 
         " at " + DoubleToString(openPrice, _sy_digits) + 
         " sl: " + DoubleToString(stopLoss, _sy_digits) + 
         " tp: " + DoubleToString(takeProfit, _sy_digits));
   }
   
   if (_drawArrows && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE))
   {
      if (drawSquares) CreateNewSquare(openTime, openPrice, stopLoss, takeProfit);
      
      color arrowColor;
      if (tradeType == ORDER_TYPE_BUY)
      {
         arrowColor = clrAqua;
      }
      else
      {
         arrowColor = clrOrange;
      }
      
      CreateArrow("ArrowOpen" + IntegerToString((long)openTime), openTime, openPrice, arrowColor, true);
      
   }
}


// Close Trade (Manual or touched Stop/TP)
// Returns profit of trade

double VirtualTrade::CloseTrade(double closePrice, datetime closeTime, double &tradeElapsed)
{
	double finalProfit = 0.0;

   #ifdef __MQL5__
	   if (perform_real_trades)
	   {
	   	if (m_position_info.SelectByTicket(reference_ticket_tp))
	   		m_trade.PositionClose(reference_ticket_tp);
	   		
	   	if (m_position_info.SelectByTicket(reference_ticket_scale))
	   		m_trade.PositionClose(reference_ticket_scale);
	   }
	else // To block changing stop loss
	{
   #endif
   
   if (tradeType == ORDER_TYPE_BUY)
   {
      if (_profit_in_pips)
      {
         finalProfit += (closePrice - openPrice);
      }
      else
      {
         finalProfit += tradeValue * (closePrice - openPrice) / (openAtr * slAtr);
      }
   }
   else //ORDER_TYPE_SELL
   {
      if (_profit_in_pips)
      {
         finalProfit += (openPrice - closePrice);
      }
      else
      {
         finalProfit += tradeValue * (openPrice - closePrice) / (openAtr * slAtr);
      }
   }
   
   if (touchedFirstTP)
   {
      tradeElapsed = MathAbs((takeProfit + closePrice)/2.0 - openPrice) / (openAtr * slAtr);
      if (_profit_in_pips)
      {
         finalProfit += MathAbs(openPrice - takeProfit);
      }
      else
      {
         finalProfit +=  tradeValue * MathAbs(openPrice - takeProfit) / (openAtr * slAtr);
      }
   }
   else
   {
      tradeElapsed = MathAbs(closePrice - openPrice) / (openAtr * slAtr);
      finalProfit = finalProfit * 2.0;
   }
   
   if (_profit_in_pips)
   {
      finalProfit /= (SymbolInfoDouble(_symbol, SYMBOL_POINT)*2.0);
   }
   
   if (_drawArrows && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE))
   {
      color arrowColor, lineColor;
      if (tradeType == ORDER_TYPE_BUY)
      {
         arrowColor = clrBlue;
         lineColor = clrDodgerBlue;
      }
      else
      {
         arrowColor = clrPurple;
         lineColor = clrYellow;
      }
      
      if (drawSquares && !touchedFirstTP) UpdateCurrentSquare(closeTime);
      
      CreateArrow("ArrowClose" + IntegerToString((long)openTime), closeTime, closePrice, arrowColor);
      CreateTrendline("LineClose" + IntegerToString((long)openTime), openTime, openPrice, closeTime, closePrice, lineColor);
      
   }
   
   if (_debugVirtualTrades)
   {
      Print(_symbol + ": " +
         "Close VIRTUAL " + GetSignalTypeString(tradeType) + 
         " at " + DoubleToString(openPrice, _sy_digits) + 
         " sl: " + DoubleToString(stopLoss, _sy_digits) + 
         " tp: " + DoubleToString(takeProfit, _sy_digits) +
         " at price: " + DoubleToString(closePrice, _sy_digits) + 
         " profit: " + DoubleToString(finalProfit, _profit_in_pips?0:2));
   }
   
   #ifdef __MQL5__
   } //end of real trade
   #endif
   
   // Reset
   
   isOpen = false;
   touchedFirstTP = false;
   startedMovingSL = false;
   openPrice = 0.0;
   takeProfit = 0.0;
   stopLoss = 0.0;
   openAtr = 0.0;
   _exposure = 0.0;
   
   if (_profit_in_pips) return NormalizeDouble(finalProfit, 0);
   else return NormalizeDouble(finalProfit, 2);
}


// Update Trailing Stops

void VirtualTrade::UpdateTrailingStop(double closePrice, datetime currentTime)
{
   if (!isOpen) return;
   
   
   if (touchedFirstTP)
   {
   	#ifdef __MQL5__
      if (perform_real_trades)
      {
      	closePrice = tradeType==ORDER_TYPE_BUY?SymbolInfoDouble(_symbol, SYMBOL_BID):SymbolInfoDouble(_symbol, SYMBOL_ASK);
      }
      #endif
   
      double startMove = openAtr * startMoveAtr;
      double distanceToOpen = MathAbs(closePrice - openPrice);
      
      if (distanceToOpen > startMove) startedMovingSL = true;
      
      if (startedMovingSL)
      {
         double currentDistance = MathAbs(closePrice - stopLoss);
         
         if (currentDistance > openAtr * slAtr)
         {
            if (tradeType == ORDER_TYPE_BUY)
            {
               stopLoss = closePrice - openAtr * slAtr;
            }
            else //ORDER_TYPE_SELL
            {
               stopLoss = closePrice + openAtr * slAtr;
            }
            
            #ifdef __MQL5__
            if (perform_real_trades)
            {
            	double point = SymbolInfoDouble(_symbol, SYMBOL_POINT);
            	double pos_stopLoss = m_position_info.StopLoss();
            	if ( (tradeType==ORDER_TYPE_BUY && pos_stopLoss + point < stopLoss) ||
            			(tradeType==ORDER_TYPE_SELL && pos_stopLoss - point > stopLoss))
            		m_trade.PositionModify(reference_ticket_scale, stopLoss, 0.0);
            	return;
            }
            #endif
            
            if (_debugVirtualTrades)
            {
               Print(_symbol + ": " +
                  "Modify VIRTUAL " + GetSignalTypeString(tradeType) + 
                  " at " + DoubleToString(openPrice, _sy_digits) + 
                  " price " + DoubleToString(closePrice, _sy_digits) + 
                  " sl: " + DoubleToString(stopLoss, _sy_digits));
            }
         }
      }
      
      if (_symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE) && _drawArrows && drawSquares) DrawTrailingStop(currentTime, stopLoss);
   }
}

void VirtualTrade::UpdateTrailingStopToValue(double closePrice, double newTSValue, datetime currentTime)
{
   if (!isOpen) return;
   
   if (touchedFirstTP)
   {
      double startMove = openAtr * startMoveAtr;
      double distanceToOpen = MathAbs(closePrice - openPrice);
      
      if (distanceToOpen > startMove) startedMovingSL = true;
      
      if (newTSValue!=EMPTY_VALUE && newTSValue>0.0 && startedMovingSL)
      {
      	bool changedSL = false;
      	
         if (tradeType == ORDER_TYPE_BUY)
         {
         	if (newTSValue > stopLoss && newTSValue < closePrice)
         	{
         		stopLoss = newTSValue;
         		changedSL = true;
         	}
         }
         else //ORDER_TYPE_SELL
         {
         	if (newTSValue < stopLoss && newTSValue > closePrice)
         	{
         		stopLoss = newTSValue;
         		changedSL = true;
         	}
         }
         
         #ifdef __MQL5__
         if (perform_real_trades && changedSL)
         {
         	double point = SymbolInfoDouble(_symbol, SYMBOL_POINT);
         	double pos_stopLoss = m_position_info.StopLoss();
         	if ( (tradeType==ORDER_TYPE_BUY && pos_stopLoss + point < stopLoss) ||
         			(tradeType==ORDER_TYPE_SELL && pos_stopLoss - point > stopLoss))
         		m_trade.PositionModify(reference_ticket_scale, stopLoss, 0.0);
         	return;
         }
         #endif
      
         if (changedSL && _debugVirtualTrades)
         {
            Print(_symbol + ": " +
               "Modify VIRTUAL " + GetSignalTypeString(tradeType) + 
               " at " + DoubleToString(openPrice, _sy_digits) + 
               " price " + DoubleToString(closePrice, _sy_digits) + 
               " sl: " + DoubleToString(stopLoss, _sy_digits));
         }
         
      }
      
      if (_symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE) && _drawArrows && drawSquares) DrawTrailingStop(currentTime, stopLoss);
   }
}

// Check If price touched stop or TP

double VirtualTrade::CheckStops(double priceHigh, double priceLow, datetime currentTime, double &tradeElapsed)
{
   if (!isOpen) return 0.0;
   
   #ifdef __MQL5__
   if (perform_real_trades)
   {
   	if (!m_position_info.SelectByTicket(reference_ticket_tp))
   	{
   		if (!m_position_info.SelectByTicket(reference_ticket_scale))
   		{
   			//Stop loss
   			CloseTrade(stopLoss, currentTime, tradeElapsed);
   		}
   		else
   		{
   			touchedFirstTP = true;
         	_exposure = 0.0; // Breakeven
         	stopLoss = openPrice;
         	
         	if (!touchedFirstTP)
         		m_trade.PositionModify(reference_ticket_scale, stopLoss, 0.0);
         	
   		}
   		
   	}
   	
   	return 0.0;
   }
   #endif

   if (tradeType == ORDER_TYPE_BUY)
   {
      // Check stop first
      if (priceLow <= stopLoss)
      {
         if (touchedFirstTP && _drawArrows && drawSquares && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE)) DrawTrailingStop(currentTime, stopLoss);
         return CloseTrade(stopLoss, currentTime, tradeElapsed);
      }
      else if (!touchedFirstTP)
      {
         if (priceHigh >= takeProfit) //breakeven
         {
            if (!scaleOut)
            {
               return CloseTrade(takeProfit, currentTime, tradeElapsed);
            }
            touchedFirstTP = true;
            _exposure = 0.0; // Breakeven
            
            if (_drawArrows && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE))
            {
               if (drawSquares) UpdateCurrentSquare(currentTime);
               
               CreateArrow("ArrowTP" + IntegerToString((long)openTime), currentTime, takeProfit, clrBlue);
               CreateTrendline("LineTP" + IntegerToString((long)openTime), openTime, openPrice, currentTime, takeProfit, clrDodgerBlue);
            }
            
            stopLoss = openPrice;
         }
         else if (_drawArrows && drawSquares && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE)) UpdateCurrentSquare(currentTime);
      }
   }
   else //ORDER_TYPE_SELL
   {
      // Check stop first
      if (priceHigh >= stopLoss)
      {
         if (touchedFirstTP && _drawArrows && drawSquares && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE)) DrawTrailingStop(currentTime, stopLoss);
         return CloseTrade(stopLoss, currentTime, tradeElapsed);
      }
      else if (!touchedFirstTP)
      {
         if (priceLow <= takeProfit) //breakeven
         {
            if (!scaleOut)
            {
               return CloseTrade(takeProfit, currentTime, tradeElapsed);
            }
            touchedFirstTP = true;
            _exposure = 0.0; // Breakeven
            
            if (_drawArrows && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE))
            {
               if (drawSquares) UpdateCurrentSquare(currentTime);
            
               CreateArrow("ArrowTP" + IntegerToString((long)openTime), currentTime, takeProfit, clrPurple);
               CreateTrendline("LineTP" + IntegerToString((long)openTime), openTime, openPrice, currentTime, takeProfit, clrYellow);
            }
            
            stopLoss = openPrice;
         }
         else if (_drawArrows && drawSquares && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE)) UpdateCurrentSquare(currentTime);
      }
   }
   return 0.0;
}

string GetSignalTypeString(int type)
{
   if (type == ORDER_TYPE_BUY) return "BUY";
   else if (type == ORDER_TYPE_SELL) return "SELL";
   else return "NEUTRAL";
}


//void VirtualTrade::OpenTradePercent(double open_price, datetime open_time, double trade_value) //para ibex
//{
//   isOpen = true;
//   
//   openPrice = open_price;
//   tradeType = ORDER_TYPE_BUY;
//   openTime = open_time;
//   tradeValue = trade_value;
//   takeProfit = openPrice*2;
//   stopLoss = 0.0;
//   openAtr = 0.0;
//   
//   
//   if (_debugVirtualTrades)
//   {
//      Print(_symbol + ": " +
//         "Open VIRTUAL " + GetSignalTypeString(tradeType) + 
//         " at " + DoubleToString(openPrice, _sy_digits));
//   }
//   
//   if (_drawArrows && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE))
//   {
//      color arrowColor;
//      if (tradeType == ORDER_TYPE_BUY)
//      {
//         arrowColor = clrAqua;
//      }
//      else
//      {
//         arrowColor = clrOrange;
//      }
//      
//      CreateArrow("ArrowOpenP" + IntegerToString((long)openTime), openTime, openPrice, arrowColor, true);
//   }
//}
//
//double VirtualTrade::CloseTradePercent(double closePrice,datetime closeTime)
//{
//double finalProfit = 0.0;
//   
//   if (tradeType == ORDER_TYPE_BUY)
//   {
//      finalProfit = (closePrice - openPrice) / openPrice * tradeValue;
//   }
//   
//   if (_drawArrows && _symbol == Symbol() && MQLInfoInteger(MQL_VISUAL_MODE))
//   {
//      color arrowColor, lineColor;
//      if (tradeType == ORDER_TYPE_BUY)
//      {
//         arrowColor = clrBlue;
//         lineColor = clrDodgerBlue;
//      }
//      else
//      {
//         arrowColor = clrPurple;
//         lineColor = clrYellow;
//      }
//      
//      CreateArrow("ArrowCloseP" + IntegerToString((long)openTime), closeTime, closePrice, arrowColor);
//      CreateTrendline("LineCloseP" + IntegerToString((long)openTime), openTime, openPrice, closeTime, closePrice, lineColor);
//      
//   }
//   
//   if (_debugVirtualTrades)
//   {
//      Print(_symbol + ": " +
//         "Close VIRTUAL " + GetSignalTypeString(tradeType) + 
//         " at " + DoubleToString(openPrice, _sy_digits) + 
//         " at price: " + DoubleToString(closePrice, _sy_digits) + 
//         " profit: " + DoubleToString(finalProfit, 5));
//   }
//   
//   // Reset
//   
//   isOpen = false;
//   touchedFirstTP = false;
//   startedMovingSL = false;
//   openPrice = 0.0;
//   takeProfit = 0.0;
//   stopLoss = 0.0;
//   openAtr = 0.0;
//   
//   return NormalizeDouble(finalProfit, 5);
//
//}