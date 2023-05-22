//+------------------------------------------------------------------+
//|         FUNCTIONS FOR BOTH TESTERS                               |
//+------------------------------------------------------------------+

void ProcessSymbolArray(bool license_is_demo, string custom_string, int pair_preset, string &symbols_to_trade[], int &total_symbols)
{
   string newSymbolString;
   
   if (license_is_demo)
   {
      newSymbolString = "EURUSD,GBPCHF,USDCHF";
   }
   else if (pair_preset == ALL_SYMBOLS  || pair_preset == ALL_SUBSTITUTE || pair_preset == ALL_SUFFIX)
   {
      newSymbolString = "EURJPY,EURCHF,EURCAD,EURUSD,EURNZD,EURAUD,EURGBP,GBPJPY,GBPCHF,GBPCAD,GBPUSD,GBPNZD,GBPAUD,AUDJPY,AUDCHF,AUDCAD,AUDUSD,AUDNZD,NZDJPY,NZDCHF,NZDCAD,NZDUSD,USDJPY,USDCHF,USDCAD,CADJPY,CADCHF,CHFJPY";
   }
   else if (pair_preset == BT_ONLY)
   {
      newSymbolString = "AUDCAD,AUDNZD,CHFJPY,EURGBP,EURUSD";
   }
   else if (pair_preset == ACTIVE_ONLY)
   {
      newSymbolString = Symbol();
   }
   else if (pair_preset == ALL_AND_CUSTOM)
   {
      newSymbolString = "EURJPY,EURCHF,EURCAD,EURUSD,EURNZD,EURAUD,EURGBP,GBPJPY,GBPCHF,GBPCAD,GBPUSD,GBPNZD,GBPAUD,AUDJPY,AUDCHF,AUDCAD,AUDUSD,AUDNZD,NZDJPY,NZDCHF,NZDCAD,NZDUSD,USDJPY,USDCHF,USDCAD,CADJPY,CADCHF,CHFJPY";
      if (custom_string != "")
         newSymbolString = newSymbolString + ","+custom_string;
   }
   else if (pair_preset == SYMBOL_FILE)
   {
   	int file_handle = FileOpen(custom_string, FILE_TXT|FILE_COMMON|FILE_READ|FILE_ANSI|FILE_SHARE_READ);
      
      if (file_handle != INVALID_HANDLE)
      {
         FileReadArray(file_handle, symbols_to_trade);
         FileClose(file_handle);
      }
      else
      {
      	Print("SYMBOL FILE \"" + custom_string + "\" NOT FOUND");
      }
   }
   else //ACTIVE_ONLY
   {
      newSymbolString = custom_string;
   }
   
   if (license_is_demo || pair_preset!=SYMBOL_FILE)
   {
	   StringReplace(newSymbolString, " ", "");
	   StringSplit(newSymbolString, ',', symbols_to_trade);
   }
   
   total_symbols = ArraySize(symbols_to_trade);
   int i;
   
   for (i=0; i<total_symbols; i++)
   {
      TRIM_STRING_LEFT(symbols_to_trade[i]);
      TRIM_STRING_RIGHT(symbols_to_trade[i]);
   }
   
   
   
   if (pair_preset == ALL_SUBSTITUTE && !license_is_demo)
   {
      string substitutions = custom_string;
      StringReplace(substitutions, " ", "");
      
      string subsPairs[];
      StringSplit(substitutions, ',', subsPairs);
      
      for (i=0; i<ArraySize(subsPairs); i++)
      {
         string swapPair[];
         StringSplit(subsPairs[i], '/', swapPair);
         
         if (ArraySize(swapPair) != 2) continue;
         
         for (int k=0; k<total_symbols; k++)
         {
            if (symbols_to_trade[k] == swapPair[0])
            {
            	if (swapPair[1]=="")
            	{
            		for (int d=k; d<total_symbols-1; d++)
            		{
            			symbolsToTrade[d] = symbolsToTrade[d+1];
            		}
            		total_symbols--;
	               ArrayResize(symbolsToTrade, total_symbols); //Delete last
            	}
            	else
               	symbols_to_trade[k] = swapPair[1];
               
               break;
            }
         }
      }
   }
   if (pair_preset == ALL_SUFFIX && !license_is_demo)
   {
   	string sufix = custom_string;
   	TRIM_STRING_LEFT(sufix);
   	TRIM_STRING_RIGHT(sufix);
   	
   	for (int k=0; k<total_symbols; k++)
      {
         symbolsToTrade[k] = symbolsToTrade[k] + sufix;
      }
   }
   
   string symbolsError[];
   int starting = total_symbols;
   
   for (int k=total_symbols-1; k>=0; k--)
   {
   	
   	#ifdef __MQL5__
   	SymbolSelect(symbols_to_trade[k], true);
   	bool isCustom;
   	if (!SymbolExist(symbolsToTrade[k], isCustom))
   	#else
   	MqlRates array[];
   	if (CopyRates(symbolsToTrade[k], PERIOD_CURRENT, 0, 1, array)<0)
   	#endif
   	{
   		int err=ArraySize(symbolsError);
   		ArrayResize(symbolsError, err+1, starting);
   		symbolsError[err]=symbols_to_trade[k];
   		
   		symbols_to_trade[k] = symbols_to_trade[total_symbols-1];
   		total_symbols--;
	      ArrayResize(symbolsToTrade, total_symbols); //Delete last
   	}
   }
   
   for (int e=0; e<ArraySize(symbolsError); e++)
   {
   	Print("SYMBOL NOT FOUND: \"", symbolsError[e], "\" (check if it is available with a different name)");
   }
}