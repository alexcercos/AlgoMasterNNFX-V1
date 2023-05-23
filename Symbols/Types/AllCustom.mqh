
#include "../Base.mqh"

//+------------------------------------------------------------------+
//| All + custom symbols Processor                                   |
//+------------------------------------------------------------------+
class CSymbolProcessorAllAndCustom : public CSymbolProcessorBase
{
	protected:
		virtual void PreProcessString(string &symbol_string, string &custom_string);
};

void CSymbolProcessorAllAndCustom::PreProcessString(string &symbol_string, string &custom_string)
{
	SetStringToAllSymbols(symbol_string);
	
	symbol_string += ","+ custom_string;
}
