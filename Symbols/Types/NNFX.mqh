
#include "../Base.mqh"

//+------------------------------------------------------------------+
//| NNFX Backtesting Symbols Processor                               |
//+------------------------------------------------------------------+
class CSymbolProcessorNNFX : public CSymbolProcessorBase
{
	protected:
		virtual void PreProcessString(string &symbol_string, string &custom_string);
};

void CSymbolProcessorNNFX::PreProcessString(string &symbol_string, string &custom_string)
{
	symbol_string = "AUDCAD,AUDNZD,CHFJPY,EURGBP,EURUSD";
}
