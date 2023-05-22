

double CalculateRiskPercentLots(double stopLoss, double percent, string symbol)
{
	if (stopLoss<=0.0) return 0.0;
   
   double riskTotal = AccountInfoDouble(ACCOUNT_BALANCE) * percent / 100.0;
   
   //double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   //stopLoss  /= point;
   
   double pointValue = riskTotal / stopLoss;
   
   
   string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
   string currencySecondary = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   
   double askPrice = GetCurrencyExchange(accountCurrency, currencySecondary);
   
   if (askPrice == 0) return 0.0;
   
   
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   
   return MathMax(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN), 
   			MathMin(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX),
   				MathFloor(pointValue / (askPrice * contractSize  * lotStep)) * lotStep));
}

double GetCurrencyExchange(string from, string to)
{
   string symbol = from + to;
   
   if (from==to) return 1.0;
   
   
   double exchange;
   if (SymbolInfoDouble(symbol, SYMBOL_ASK, exchange))
   {
      return 1 / exchange;
   }
   
   else //Reverse symbol is correct?
   {
      symbol = to + from;
      
      if (SymbolInfoDouble(symbol, SYMBOL_ASK, exchange))
      {
         return exchange;
      }
      
      else
      {
         Print("Symbol error: ", from + to, " / ", symbol, " not found. Make sure one of them is visible in MARKET WATCH.");
         return 0.0;
      }
   }
}