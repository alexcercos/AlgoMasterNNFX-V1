
#include "../Other/ArrayFunctions.mqh"

class CSymbolProcessorBase
{
	private:
		void SplitSymbols(string symbol_string, string &result[]);
		int FilterInvalid(string &origin[], string &destiny[]);
		
	#ifdef __MQL4__
		bool SymbolExist(const string symbol_name, bool &is_custom);
	#endif
	
	protected:
		void TrimString(string &str);
	
		void SetStringToAllSymbols(string &str);
		
		virtual void PreProcessString(string &symbol_string, string &custom_string) 	{ symbol_string = custom_string; }
		virtual void PostProcessArray(string &array[], string &custom_string) { /*Nothing*/ }

	public:
		int ProcessSymbolString(string custom_string, string &result_array[]);
};

void CSymbolProcessorBase::SetStringToAllSymbols(string &str)
{
	str = "EURJPY,EURCHF,EURCAD,EURUSD,EURNZD,EURAUD,EURGBP,GBPJPY,GBPCHF,"+
			"GBPCAD,GBPUSD,GBPNZD,GBPAUD,AUDJPY,AUDCHF,AUDCAD,AUDUSD,AUDNZD,"+
			"NZDJPY,NZDCHF,NZDCAD,NZDUSD,USDJPY,USDCHF,USDCAD,CADJPY,CADCHF,CHFJPY";
}

void CSymbolProcessorBase::TrimString(string &str)
{
	StringTrimLeft(str);
	StringTrimRight(str);
}

void CSymbolProcessorBase::SplitSymbols(string symbol_string,string &result[])
{
	StringSplit(symbol_string, ',', result);
	
	for (int i=0; i<ArraySize(result); i++)
		TrimString(result[i]);
}

int CSymbolProcessorBase::FilterInvalid(string &origin[],string &destiny[])
{
	bool is_custom; //not used
	
	int total_symbols = 0;
	int total_potential = ArraySize(origin);
	
	ArrayResize(destiny, 0, total_potential);
	
	string last_symbol = NULL;
	for (int i=0; i<total_potential; i++)
	{
		if (last_symbol == origin[i])
		{
			Print("SYMBOL DUPLICATED: \"", origin[i], "\"");
			continue;
		}
		
		if (SymbolExist(origin[i], is_custom))
			ArrayFunctions_AddAtEnd<string>(destiny, total_symbols, origin[i], total_potential);
		else
			Print("SYMBOL NOT FOUND: \"", origin[i], 
					"\" (check if it is available with a different name)");
		
		last_symbol = origin[i];
	}
	
	return total_symbols;
}

int CSymbolProcessorBase::ProcessSymbolString(string custom_string,string &result_array[])
{
	string symbol_string;
	PreProcessString(symbol_string, custom_string);

	string potential_symbols[];
	SplitSymbols(symbol_string, potential_symbols);
	
	ArrayFunctions_Sort<string>(potential_symbols);

	PostProcessArray(potential_symbols, custom_string);
	
	return FilterInvalid(potential_symbols, result_array);
}

#ifdef __MQL4__

bool CSymbolProcessorBase::SymbolExist(const string symbol_name,bool &is_custom)
{
	//is_custom not used
	MqlRates array[];
	
   if (CopyRates(symbol_name, PERIOD_CURRENT, 0, 1, array)<0)
		return false;
	
	return true;
}

#endif
