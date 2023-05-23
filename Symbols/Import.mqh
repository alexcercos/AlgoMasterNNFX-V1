
#include "EnumPresets.mqh"

#include "Types/AllSymbols.mqh"
#include "Types/NNFX.mqh"
#include "Types/AllCustom.mqh"
#include "Types/OnlyActive.mqh"
#include "Types/AllSubstitute.mqh"
#include "Types/AllSufix.mqh"
#include "Types/File.mqh"

//+------------------------------------------------------------------+
//| Static factory class                                             |
//+------------------------------------------------------------------+
class CSymbolProcessorFactory
{
	public:
		static int ProcessSymbols(string symbol_string, string &result_array[], EPairPresets preset);
};

int CSymbolProcessorFactory::ProcessSymbols(string symbol_string,string &result_array[],
															EPairPresets preset)
{
	CSymbolProcessorBase* processor;
	
	switch (preset)
	{
		case PP_ALL_SYMBOLS:
			processor = new CSymbolProcessorAll();
			break;
		
		case PP_NNFX_BT_ONLY:
			processor = new CSymbolProcessorNNFX();
			break;
			
		case PP_ALL_AND_CUSTOM:
			processor = new CSymbolProcessorAllAndCustom();
			break;
			
		case PP_ACTIVE_ONLY:
			processor = new CSymbolProcessorActive();
			break;
			
		case PP_ALL_SUBSTITUTE:
			processor = new CSymbolProcessorSubstituteAll();
			break;
			
		case PP_ALL_SUFFIX:
			processor = new CSymbolProcessorAllSufix();
			break;
			
		case PP_SYMBOL_FILE:
			processor = new CSymbolProcessorFile();
			break;
		
		default: //PP_CUSTOM
			processor = new CSymbolProcessorBase();
			break;
	}
	
	int total = processor.ProcessSymbolString(symbol_string, result_array);
	
	delete processor;
	return total;
}