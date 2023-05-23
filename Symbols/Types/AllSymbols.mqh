
#include "../Base.mqh"

//+------------------------------------------------------------------+
//| All Symbols Processor                                            |
//+------------------------------------------------------------------+
class CSymbolProcessorAll : public CSymbolProcessorBase
{
	protected:
		virtual void PreProcessString(string &symbol_string, string &custom_string);
};

void CSymbolProcessorAll::PreProcessString(string &symbol_string, string &custom_string)
{
	SetStringToAllSymbols(symbol_string);
}
