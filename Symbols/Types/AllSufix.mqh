
#include "../Base.mqh"

//+------------------------------------------------------------------+
//| All Symbols with Sufix Processor                                 |
//+------------------------------------------------------------------+
class CSymbolProcessorAllSufix : public CSymbolProcessorBase
{
	protected:
		virtual void PreProcessString(string &symbol_string, string &custom_string);
		virtual void PostProcessArray(string &array[], string &custom_string);
};

void CSymbolProcessorAllSufix::PreProcessString(string &symbol_string, string &custom_string)
{
	SetStringToAllSymbols(symbol_string);
}

void CSymbolProcessorAllSufix::PostProcessArray(string &array[], string &custom_string)
{
	TrimString(custom_string);
	
	for (int i=0; i<ArraySize(array); i++)
		array[i] += custom_string;
}
