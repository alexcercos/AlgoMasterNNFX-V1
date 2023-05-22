#include "EVZDefines.mqh"

class YahooScraper
{
   string symbol_read, symbol_write;
   
public:
   YahooScraper(string symbolToRead, string symbolToWrite="");
   
#ifdef __MQL5__
   bool CreateSymbol();
   void SymbolCustomSettings();
   
   bool GetWebData(int initTime, int endTime);
#endif
   
   void GetWebPage(int initTime, int endTime, string &resultStr);
   
   void SaveFile(string filename, int initTime, int endTime);
   
   void UpdateFile(string filename, int endTime);
   
   string ProcessRow(string row);
   string nZeros(int num);
};

YahooScraper::YahooScraper(string symbolToRead,string symbolToWrite="")
{
   symbol_read = symbolToRead;
   symbol_write = symbolToWrite;
}


#ifdef __MQL5__
bool YahooScraper::CreateSymbol(void)
{
   return CustomSymbolCreate(symbol_write);
}

void YahooScraper::SymbolCustomSettings(void)
{
   //Print("Symbol " + symbol_write + " created");
   CustomSymbolSetString(symbol_write, SYMBOL_DESCRIPTION, "Spain 35 Index");
   CustomSymbolSetInteger(symbol_write, SYMBOL_DIGITS, 2);
   CustomSymbolSetString(symbol_write, SYMBOL_CURRENCY_BASE, "EUR");
   CustomSymbolSetString(symbol_write, SYMBOL_CURRENCY_PROFIT, "EUR");
   CustomSymbolSetString(symbol_write, SYMBOL_CURRENCY_MARGIN, "EUR");
   CustomSymbolSetInteger(symbol_write, SYMBOL_TICKS_BOOKDEPTH, 10);
   CustomSymbolSetDouble(symbol_write, SYMBOL_TRADE_CONTRACT_SIZE, 1.0);
   CustomSymbolSetInteger(symbol_write, SYMBOL_TRADE_CALC_MODE, SYMBOL_CALC_MODE_CFD);
   CustomSymbolSetInteger(symbol_write, SYMBOL_TRADE_STOPS_LEVEL, 0);
   CustomSymbolSetDouble(symbol_write, SYMBOL_TRADE_TICK_SIZE, 0.01);
   CustomSymbolSetDouble(symbol_write, SYMBOL_TRADE_TICK_VALUE, 0.01);
   CustomSymbolSetInteger(symbol_write, SYMBOL_TRADE_EXEMODE, SYMBOL_TRADE_EXECUTION_MARKET);
   CustomSymbolSetInteger(symbol_write, SYMBOL_FILLING_MODE, SYMBOL_FILLING_IOC);
   CustomSymbolSetDouble(symbol_write, SYMBOL_VOLUME_STEP, 0.1);
   CustomSymbolSetDouble(symbol_write, SYMBOL_VOLUME_MIN, 0.1);
   CustomSymbolSetDouble(symbol_write, SYMBOL_VOLUME_MAX, 250);
   CustomSymbolSetDouble(symbol_write, SYMBOL_MARGIN_HEDGED, 0.0);
}

bool YahooScraper::GetWebData(int initTime, int endTime)
{
   string tmpStr;
   GetWebPage(initTime, endTime, tmpStr);
   
   if (tmpStr == "") return false;
   
   string queryRows[];
   StringSplit(tmpStr, '\n', queryRows);
   
   int size = ArraySize(queryRows);
   
   MqlRates ratesArray[];
   ArrayResize(ratesArray, size-1);
   
   double openPrice=0, highPrice=0, lowPrice=0, closePrice=0;
   long volume=50000000;
      
   for (int i = 1; i<size; i++)
   {
   
      //Print(queryRows[i]);
      
      string items[];
      
      StringSplit(queryRows[i], ',', items);
      
      datetime date = StringToTime(items[0]);
      if (items[1]=="null")
      {
         //Print("Null candle on " + TimeToString(date));
         ratesArray[i-1].time = date;
         ratesArray[i-1].open = closePrice;
         ratesArray[i-1].high = closePrice;
         ratesArray[i-1].low = closePrice;
         ratesArray[i-1].close = closePrice;
         ratesArray[i-1].real_volume = 0;
         ratesArray[i-1].tick_volume = volume;
         ratesArray[i-1].spread = 1;
      }
      else
      {
         openPrice = StringToDouble(items[1]);
         highPrice = StringToDouble(items[2]);
         lowPrice = StringToDouble(items[3]);
         closePrice = StringToDouble(items[4]);
         volume = StringToInteger(items[6]);
         
         
         ratesArray[i-1].time = date;
         ratesArray[i-1].open = openPrice;
         ratesArray[i-1].high = highPrice;
         ratesArray[i-1].low = lowPrice;
         ratesArray[i-1].close = closePrice;
         ratesArray[i-1].real_volume = 0;
         ratesArray[i-1].tick_volume = volume;
         ratesArray[i-1].spread = 1;
      }
   }
   
   CustomRatesUpdate(symbol_write, ratesArray);

   
   return true;
}
#endif

void YahooScraper::GetWebPage(int initTime,int endTime,string &resultStr)
{
   resultStr = "";
   
   string cookie=NULL,headers;
   char   post[],result[];
   string domain = "https://query1.finance.yahoo.com";
   string url= domain + "/v7/finance/download/" + symbol_read + "?period1=" + IntegerToString(initTime) + "&period2=" + IntegerToString(endTime) + "&interval=1d&events=history";
   
   //Print(url);
   
   ResetLastError();
   
   int res=WebRequest("GET",url,cookie,NULL,500,post,0,result,headers);
   if(res==-1)
   {
      Print("WebRequest Error. Error code  =",GetLastError());
      
      MessageBox("It is necessary to add the address '"+domain+"' to the list of allowed URLs in the 'Advisors' tab","Error",MB_ICONINFORMATION);

   }
   else if(res==200)
   {
      resultStr = CharArrayToString(result,0,WHOLE_ARRAY,CP_UTF8);
   }
   else
   {
      PrintFormat("Load page error '%s', code %d",url,res);

   }
}

string YahooScraper::ProcessRow(string row)
{
   string items[];
   StringSplit(row, ',', items);
   

   string date = items[0];
   
   StringReplace(date, "-", ".");
   
   string openS, highS, lowS, closeS;
   
   if (items[1]=="null")
   {
      openS = DoubleToString(0.0, 2);
      openS = nZeros(6-StringLen(openS)) + openS;
      
      highS = DoubleToString(0.0, 2);
      highS = nZeros(6-StringLen(highS)) + highS;
      
      lowS = DoubleToString(0.0, 2);
      lowS = nZeros(6-StringLen(lowS)) + lowS;
      
      closeS = DoubleToString(0.0, 2);
      closeS = nZeros(6-StringLen(closeS)) + closeS;
   }
   else
   {
      openS = DoubleToString(StringToDouble(items[1]), 2);
      openS = nZeros(6-StringLen(openS)) + openS;
      
      highS = DoubleToString(StringToDouble(items[2]), 2);
      highS = nZeros(6-StringLen(highS)) + highS;
      
      lowS = DoubleToString(StringToDouble(items[3]), 2);
      lowS = nZeros(6-StringLen(lowS)) + lowS;
      
      closeS = DoubleToString(StringToDouble(items[4]), 2);
      closeS = nZeros(6-StringLen(closeS)) + closeS;

   }
   
   return date + "," + openS + "," + lowS + "," + highS + ","+closeS;
}

void YahooScraper::SaveFile(string filename, int initTime, int endTime)
{
   string tmpStr;
   GetWebPage(initTime, endTime, tmpStr);
   
   if (tmpStr == "") return;
   
   string queryRows[];
   StringSplit(tmpStr, '\n', queryRows);
   
   int requestSize = ArraySize(queryRows);
   
   int filehandle=FileOpen(filename,FILE_COMMON|FILE_SHARE_WRITE|FILE_SHARE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);

   
   if(filehandle!=INVALID_HANDLE)
   {
      FileWrite(filehandle, IntegerToString(requestSize-1));
      for (int i = 1; i<requestSize; i++)
      {
         string toWrite = ProcessRow(queryRows[i]);

         FileWrite(filehandle, toWrite);
      }
   }
   FileFlush(filehandle);
   FileClose(filehandle);
   
}

string YahooScraper::nZeros(int num)
{
   string zeros = "";
   
   for(int z=0; z<num; z++)
   {
      zeros = zeros + "0";
   }
   return zeros;
}

void YahooScraper::UpdateFile(string filename,int endTime)
{
   //Abrir archivo anterior, initTime es el datetime de la ultima fila
   if (!FileIsExist(filename, FILE_COMMON))
   {
   	SaveFile(filename, TIME_LIMIT, MAX_TIME);
   	return;
   }
   
   int filehandle=FileOpen(filename,FILE_COMMON|FILE_SHARE_WRITE|FILE_SHARE_READ|FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);

   
   if(filehandle!=INVALID_HANDLE)
   {
      FileSeek(filehandle, -ROW_BYTE_SIZE, SEEK_END);
      
      
      int str_size=FileReadInteger(filehandle,INT_VALUE);
      string str = FileReadString(filehandle,str_size);
      
      string items[];
      StringSplit(str, ',', items);
      
      int initTime = (int)StringToTime(items[0]);
      
      string tmpStr;
      
      //Pagina web
      GetWebPage(initTime, endTime, tmpStr);
      
      string queryRows[];
      StringSplit(tmpStr, '\n', queryRows);
      
      int requestSize = ArraySize(queryRows);
      
      if (requestSize>=2 && queryRows[requestSize-1]==queryRows[requestSize-2]) //Prevent repeated values from weekends
      {
      	requestSize--;
      }
      
      //Reescribir inicio
      FileSeek(filehandle, 0, SEEK_SET);
      
      str_size=FileReadInteger(filehandle,INT_VALUE);
      str = FileReadString(filehandle,str_size);
      
      int lastRows = (int)StringToInteger(str);
      
      FileSeek(filehandle, 0, SEEK_SET);
      
      //FileWrite(filehandle, IntegerToString(lastRows + requestSize - 2));
      FileWriteString(filehandle, IntegerToString(lastRows + requestSize - 2)+" ");
      
      //Reescribir filas
      FileSeek(filehandle, -ROW_BYTE_SIZE, SEEK_END);
      for (int i = 1; i<requestSize; i++)
      {
         string toWrite = ProcessRow(queryRows[i]);
         
         //Print(toWrite);

         FileWrite(filehandle, toWrite);
      }
   }
   FileFlush(filehandle);
   FileClose(filehandle);
}