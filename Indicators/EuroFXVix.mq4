//+------------------------------------------------------------------+
//|                                                    EuroFXVix.mq4 |
//|                    Copyright 2020, Manuel Alejandro Cercós Pérez |
//|                         https://www.mql5.com/en/users/alexcercos |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, Manuel Alejandro Cercós Pérez"
#property link      "https://www.mql5.com/en/users/alexcercos"
#property strict

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "EVZ Close"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#define TIME_LIMIT 1217635200
#define CUSTOM_FILE_NAME "EVZ_Data"
#define ROW_BYTE_SIZE 40

class DataScraper
{
private:
   datetime recentCandle;
   
   double ClosePrices[];
   datetime DatetimeArray[];
   
   int totalCandles;
   
   int lastRequestedIndex;
   
   int GetCandleIndex(datetime candleTime);
   
   public:
      int repeatCount;
   
      DataScraper();
      ~DataScraper();
      
      bool ReadDataFromFile();
      
      int GetTotalCandles() { return totalCandles; }
      datetime GetFirstDatetime() { if (totalCandles>0) return DatetimeArray[totalCandles-1]; else return TIME_LIMIT; }
      datetime GetOldestDatetime() { if (totalCandles>0) return DatetimeArray[0]; else return TIME_LIMIT; }
      void GetCandleData(datetime timeToSearch, double &closePrice);
      
};

DataScraper::DataScraper(void)
{
   totalCandles = 0;
   lastRequestedIndex = 0;
   repeatCount = 0;
   
   int file_handle=FileOpen(CUSTOM_FILE_NAME+".txt",FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);
   FileClose(file_handle);
   
   if (!ReadDataFromFile())
   {
      Alert("No Data was found. Load EVZ data from AlgoMasterNNFX terminal");
   }
}

bool DataScraper::ReadDataFromFile(void)
{
   ResetLastError();
   int file_handle=FileOpen(CUSTOM_FILE_NAME+".txt",FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI);
   
   if(file_handle!=INVALID_HANDLE)
   {
      
      string str = "";
      
      str = FileReadString(file_handle);
      
      totalCandles = (int)StringToInteger(str); //Primera linea = total candles
      
      ArrayResize(DatetimeArray, totalCandles);
      ArrayResize(ClosePrices, totalCandles);
      
      int index=0;
      
      for (int i=0; i < totalCandles; i++)
      {

         str = FileReadString(file_handle);
         
         string items[];
         StringSplit(str, ',', items);
         
         
         if (StringToDouble(items[1])==0.0)
         {
            
            DatetimeArray[index] = StringToTime(items[0]);
            
            if (index > 0)
               ClosePrices[index] = ClosePrices[index-1];
            else
               ClosePrices[index] = EMPTY_VALUE;
         }
         else
         {
            DatetimeArray[index] = StringToTime(items[0]);
            ClosePrices[index] = StringToDouble(items[4]);
         }
         
         index++;
      }
      FileClose(file_handle);
      if (totalCandles == 0) return false;
      return true;
   }
   else
   {
      Print("Invalid file handle: \""+CUSTOM_FILE_NAME+".txt\".");
   }
   
   FileClose(file_handle);
   
   return false;
}

DataScraper::~DataScraper(void)
{
}

void DataScraper::GetCandleData(datetime timeToSearch, double &closePrice)
{
   int candleIndex = GetCandleIndex(timeToSearch);
   
   if (candleIndex == -2)
   {
      closePrice = ClosePrices[totalCandles-1];
      return;
   }
   else if (candleIndex == -5)
   {
      closePrice = 0.0;
      return;
   }
   else if (candleIndex < 0)
   {
      closePrice = EMPTY_VALUE;
      return;
   }
   
   if (DatetimeArray[candleIndex]!=timeToSearch)
      closePrice = ClosePrices[candleIndex];
   else
      closePrice = ClosePrices[candleIndex];
}

int DataScraper::GetCandleIndex(datetime candleTime)
{
   
   if (totalCandles == 0) return -5;
   if (DatetimeArray[0] > candleTime)
   {
      return -1;
   }
   else if (DatetimeArray[totalCandles-1] < candleTime)
   {
      return -2;
   }
   else if (DatetimeArray[lastRequestedIndex] == candleTime)
   {
      return lastRequestedIndex;
   }
   else if (DatetimeArray[lastRequestedIndex] < candleTime)
   {
      while (DatetimeArray[lastRequestedIndex] < candleTime)
      {
         if (lastRequestedIndex<totalCandles-1)
         {
            lastRequestedIndex++;
         }
         else
         {
            return -3; //No hay datos
         }
         
      }
      if (DatetimeArray[lastRequestedIndex]==candleTime)
      {
         return lastRequestedIndex;
      }
      else
      {
         lastRequestedIndex--;
         return lastRequestedIndex;
      }

   }
   else
   {
      while (DatetimeArray[lastRequestedIndex] > candleTime)
      {
         if (lastRequestedIndex>0)
         {
            lastRequestedIndex--;
         }
         else
         {
            return -4;
         }
      }
      return lastRequestedIndex;
   }
}


//--- Indicator buffer
double         EVZClose[];


DataScraper* dataScraperObj;

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME,"EVZ");
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   
   
   SetIndexBuffer(0,EVZClose,INDICATOR_DATA);


   ArraySetAsSeries(EVZClose, true);
   
   
   dataScraperObj = new DataScraper();
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete dataScraperObj;
}

datetime lastTime;
#define ONE_DAY 86400
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int limit = MathMin(rates_total-prev_calculated, iBarShift(NULL,PERIOD_CURRENT,dataScraperObj.GetOldestDatetime())+1);
   
   if (prev_calculated==0)
   {
   	limit-=1;
   	ArrayInitialize(EVZClose, EMPTY_VALUE);
   }

   ArraySetAsSeries(time, true);
   
   
   int possibleRepeatCount = 0;
   
   for(int i=limit; i>=0 && !IsStopped(); i--)
   {
      datetime currentTime = time[i];
      double closeP;
		
		if (Period()<PERIOD_D1)
		{
			dataScraperObj.GetCandleData(currentTime-ONE_DAY, closeP);
			
	      EVZClose[i] = closeP;
		}
      else if (Period()==PERIOD_D1)
      {
      	dataScraperObj.GetCandleData(currentTime, closeP);
      	
	      EVZClose[i] = closeP;
      }
      else
      {
      	
	      EVZClose[i] = 0.0;
	      
	      datetime limit_time=0;
	      if (i==0)
	      {
	      	if (Period()==PERIOD_MN1)
	      	{
	      		MqlDateTime tstr; TimeToStruct(currentTime, tstr);
	      		
	      		tstr.day = 1;
	      		if (tstr.mon==12)
	      		{
	      			tstr.year++;
	      			tstr.mon=1;
	      		}
	      		else
	      			tstr.mon++;
	      			
	      		
	      		limit_time = StructToTime(tstr);
	      	}
	      	else limit_time = currentTime + PeriodSeconds();
	      }
	      else
	      	limit_time = time[i-1];
      	do
      	{
      		dataScraperObj.GetCandleData(currentTime, closeP);
      		
      		if (closeP==0.0) break; //No data
      		
		      
      		EVZClose[i] = closeP;
      		
      		currentTime+=ONE_DAY;
      	} while (currentTime<limit_time);
      	
      }
      
      
      if (i<rates_total-1 && (EVZClose[i] != EVZClose[i+1])) possibleRepeatCount=0;
   }

   dataScraperObj.repeatCount = possibleRepeatCount;
   
   return(rates_total  - possibleRepeatCount);
}
//+------------------------------------------------------------------+
