
#include "../Base.mqh"

//+------------------------------------------------------------------+
//| Only Active Symbol Processor                                     |
//+------------------------------------------------------------------+
class CSymbolProcessorActive : public CSymbolProcessorBase
{
	protected:
		virtual void PreProcessString(string &symbol_string, string &custom_string);
};

void CSymbolProcessorActive::PreProcessString(string &symbol_string, string &custom_string)
{
	symbol_string = Symbol();
}
