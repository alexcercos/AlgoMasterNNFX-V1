//+------------------------------------------------------------------+
//|                                               AlgoMasterNNFX.mq4 |
//|                    Copyright 2020, Manuel Alejandro Cercós Pérez |
//|                         https://www.mql5.com/en/users/alexcercos |
//+------------------------------------------------------------------+

#property copyright "Copyright 2021, Manuel Alejandro Cercós Pérez"
#property link      "https://www.mql5.com/en/users/alexcercos"
#property icon      "\\Images\\ProgramIcons\\algomasterLogo.ico"
#property description "Complete multipair algorithm tester for the No Nonsense Forex method (NNFX).\nIncludes 6 customizable indicators, money management rules (EVZ, news and exposure), many types of summary and optimization modes..."
#property version   "1.07"
#property strict

#include "AlgoMasterNNFX.mqh"


int OnInit()
{
   return InitEvent();
}

double OnTester()
{
   return TesterEvent();
}

void OnDeinit(const int reason) 
{
   DeInitEvent(reason);
}

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
{
   ChartEvent_Event(id, lparam, dparam, sparam);
}

void OnTick() 
{
   TickEvent();
}

void OnTimer()
{
   TimerEvent();
}