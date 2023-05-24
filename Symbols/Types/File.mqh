
#include "../Base.mqh"

//+------------------------------------------------------------------+
//| Custom file (Common) Processor                                   |
//+------------------------------------------------------------------+
class CSymbolProcessorFile : public CSymbolProcessorBase
{
	protected:
		virtual void PostProcessArray(string &array[], string &custom_string);
};

void CSymbolProcessorFile::PostProcessArray(string &array[], string &custom_string)
{
	int file_handle = FileOpen(custom_string, FILE_TXT|FILE_COMMON|FILE_READ|FILE_ANSI|FILE_SHARE_READ);
      
   if (file_handle != INVALID_HANDLE)
   {
      FileReadArray(file_handle, array);
      FileClose(file_handle);
   }
   else
   {
   	Print("SYMBOL FILE \"" + custom_string + "\" NOT FOUND");
   	Print("Using current symbol instead");
   	
   	ArrayResize(array, 1);
   	array[0] = Symbol();
   }
   
   //Sort symbols in file
   ArrayFunctions_Sort<string>(array);
}
