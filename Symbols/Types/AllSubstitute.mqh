
#include "../Base.mqh"

//+------------------------------------------------------------------+
//| Substitute from all symbols Processor                            |
//+------------------------------------------------------------------+
class CSymbolProcessorSubstituteAll : public CSymbolProcessorBase
{
	private:
		void SwapSymbol(string &array[], string &original, string &replace);
	
	protected:
		virtual void PreProcessString(string &symbol_string, string &custom_string);
		virtual void PostProcessArray(string &array[], string &custom_string);
};

void CSymbolProcessorSubstituteAll::PreProcessString(string &symbol_string, string &custom_string)
{
	SetStringToAllSymbols(symbol_string);
}

void CSymbolProcessorSubstituteAll::PostProcessArray(string &array[], string &custom_string)
{
	string substitution_pairs[];
	StringSplit(custom_string, ',', substitution_pairs);
	
	for (int i=0; i<ArraySize(substitution_pairs); i++)
	{
		string swapPair[];
		StringSplit(substitution_pairs[i], '/', swapPair);
		if (ArraySize(swapPair) != 2) continue;
		
		SwapSymbol(array, swapPair[0], swapPair[1]);
	}
}

void CSymbolProcessorSubstituteAll::SwapSymbol(string &array[], string &original, string &replace)
{
	TrimString(original);
	TrimString(replace);
	
	int index = NArrayFunctions::BinarySearch<string>(array, original);
	
	if (array[index]!=original) return;
	
	if (replace=="")
	{
		int total = ArraySize(array);
		array[index] = array[total-1];
		
		ArrayResize(array, total-1);
	}
	else
		array[index] = replace;
		
	//Sort after each change
	NArrayFunctions::Sort<string>(array);
}
