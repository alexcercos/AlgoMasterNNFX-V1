#include "..\Other\CMinHeap.mqh"

#define DEBUG_EXPOSURE false

template<typename T>
void DeleteAndSwapWithLast(T &array[],int index,int totalAmount)
{
   array[index] = array[totalAmount-1];
   
   ArrayResize(array, totalAmount-1);
}

class CurrencyIndexObject
{
   public:
      int longCurrencyIndexes[];
      int shortCurrencyIndexes[];
      
      int totalCurrencies;
      string currencies[];
      
      int GetCurrencyIndex(string currency);
      void GetLongShortIds(int symbolId, int orderType, int &longId, int &shortId);
   
      CurrencyIndexObject(string &symbolsArray[]);
      ~CurrencyIndexObject();
};



CurrencyIndexObject::CurrencyIndexObject(string &symbolsArray[])
{
   totalCurrencies = 0;
   
   int amountSymbols = ArraySize(symbolsArray);
   
   ArrayResize(longCurrencyIndexes, amountSymbols);
   ArrayResize(shortCurrencyIndexes, amountSymbols);
   
   for (int i=0; i<amountSymbols; i++)
   {
      #ifdef __MQL5__
      string currencyL = SymbolInfoString(symbolsArray[i], SYMBOL_CURRENCY_BASE);
      string currencyS = SymbolInfoString(symbolsArray[i], SYMBOL_CURRENCY_PROFIT);
      #else
      string currencyL = "";
      string currencyS = "";
      
      
      if (StringLen(symbolsArray[i])>=6) //Slice (forex/metals)
      {
         currencyL = StringSubstr(symbolsArray[i], 0, 3);
         currencyS = StringSubstr(symbolsArray[i], 3, 3);
      }
      
      #endif
   
      if (currencyL == currencyS) //No contar si son iguales (indices, acciones)
      {
         longCurrencyIndexes[i] = -1;
         shortCurrencyIndexes[i] = -1;
      }
      else
      {
         longCurrencyIndexes[i] = GetCurrencyIndex(currencyL);
         shortCurrencyIndexes[i] = GetCurrencyIndex(currencyS);
      }
   }
}

CurrencyIndexObject::~CurrencyIndexObject(void)
{
}

int CurrencyIndexObject::GetCurrencyIndex(string currency)
{
   for (int i = 0; i<totalCurrencies; i++)
   {
      if (currencies[i] == currency) return i; //FIND
   }
   
   ArrayResize(currencies, totalCurrencies+1);
   
   currencies[totalCurrencies] = currency; //ADD
   totalCurrencies++;
   
   return totalCurrencies - 1;
}

void CurrencyIndexObject::GetLongShortIds(int symbolId, int orderType, int &longId, int &shortId)
{
   if (orderType == ORDER_TYPE_BUY)
   {
      longId = longCurrencyIndexes[symbolId];
      shortId = shortCurrencyIndexes[symbolId];
   }
   else //tradesArray[i].order_type == ORDER_TYPE_SELL
   {
      longId = shortCurrencyIndexes[symbolId];
      shortId = longCurrencyIndexes[symbolId];
   }
}

struct TradeSummary
{
   int symbol_index;
   double open_price;
   double atr;
   int order_type;
   datetime open_time;
   
   double result_exposure;
   int trade_procedence;
};

struct CurrencyExposureInfo
{
   int currencyIndex;
   bool isLong;
   double maxExposure;
   int amountOfTrades;
   
   int Compare(const CurrencyExposureInfo &l, const CurrencyExposureInfo &r) const;
   
   bool operator>(const CurrencyExposureInfo &r) const { return Compare(this, r)==-1; }
   bool operator<(const CurrencyExposureInfo &r) const { return Compare(this, r)== 1; }
   bool operator==(const CurrencyExposureInfo &r) const { return Compare(this, r)== 0; }
};

int CurrencyExposureInfo::Compare(const CurrencyExposureInfo &l, const CurrencyExposureInfo &r) const
{
   if (l.amountOfTrades == 0 && r.amountOfTrades == 0) return 0;
   
   if (l.amountOfTrades == 0) return -1;
   
   if (r.amountOfTrades == 0) return 1;
   
   if (l.maxExposure / l.amountOfTrades > r.maxExposure / r.amountOfTrades)
      return -1;
      
   if (l.maxExposure / l.amountOfTrades < r.maxExposure / r.amountOfTrades)
      return 1;
   
   return 0;
}

class ExposureController
{
   private:
      CurrencyIndexObject* currencyIndexInfo;


      double currencyLongExposure[]; //Size = num currencies (8)
      double currencyShortExposure[];
      
      void DiscardOverexposedTrades(TradeSummary &tradesArray[], double currentMaxExposure);
      
      
      void GetSymbolInfoArray(TradeSummary &tradesArray[], CurrencyExposureInfo &currencyArray[], double currentMaxExp);
      void AddTradeToSymbol(CurrencyExposureInfo &currencyArray[], int longCurrency, int shortCurrency, double currentMaxExp);
      
      void FilterDefinitiveTrades(TradeSummary &tradesArray[], CurrencyExposureInfo &currencyArray[]);
      void ProcessCurrencyInfo(CurrencyExposureInfo &currentExpInfo, TradeSummary &originalArray[], TradeSummary &destinyArray[], CurrencyExposureInfo &currencyArray[]);

   public:
      ExposureController(CurrencyIndexObject* indexInfo);
      ~ExposureController();
      
      void ResetExposure();
      void AddExposure(int symbolIndex, double exposure, bool isLong);
      
      void ProcessTradesWithExposure(TradeSummary &tradesArray[], double currentMaxExposure);
      
};

ExposureController::ExposureController(CurrencyIndexObject* indexInfo)
{
   currencyIndexInfo = indexInfo;
   
   //Actualizado totalCurrencies en el bucle (GetCurrencyIndex)
   ArrayResize(currencyLongExposure, currencyIndexInfo.totalCurrencies);
   ArrayResize(currencyShortExposure, currencyIndexInfo.totalCurrencies);
}

ExposureController::~ExposureController(void)
{
}

void ExposureController::ResetExposure(void)
{
   ArrayFill(currencyLongExposure, 0, ArraySize(currencyLongExposure), 0.0);
   ArrayFill(currencyShortExposure, 0, ArraySize(currencyShortExposure), 0.0);
}

void ExposureController::AddExposure(int symbolIndex,double exposure,bool isLong)
{
   int longId = currencyIndexInfo.longCurrencyIndexes[symbolIndex];
   int shortId = currencyIndexInfo.shortCurrencyIndexes[symbolIndex];
   
   if (longId == -1 || shortId == -1) return;
   
   if (isLong)
   {
      currencyLongExposure[longId] += exposure;
      currencyShortExposure[shortId] += exposure;
   }
   else
   {
      currencyLongExposure[shortId] += exposure;
      currencyShortExposure[longId] += exposure;
   }
}

void ExposureController::ProcessTradesWithExposure(TradeSummary &tradesArray[], double currentMaxExposure)
{
   #ifdef __MQL5__
   if (DEBUG_EXPOSURE)
   {
      Print("########################### INIT: ");
      ArrayPrint(tradesArray);
      ArrayPrint(currencyIndexInfo.currencies);
      ArrayPrint(currencyLongExposure);
      ArrayPrint(currencyShortExposure);
   }
   #endif

   DiscardOverexposedTrades(tradesArray, currentMaxExposure);
   
   if (ArraySize(tradesArray) == 0) return;
   
   CurrencyExposureInfo symbolExpArray[];
   GetSymbolInfoArray(tradesArray, symbolExpArray, currentMaxExposure);
   
   
   FilterDefinitiveTrades(tradesArray, symbolExpArray);
   
   #ifdef __MQL5__
   if (DEBUG_EXPOSURE)
   {
      Print("############################ END: ");
      ArrayPrint(tradesArray);
   }
   #endif
   
   //Array resultado -> tradesArray
}

void ExposureController::DiscardOverexposedTrades(TradeSummary &tradesArray[], double currentMaxExposure)
{
   int index = 0;
   int total = ArraySize(tradesArray);
   
   while (index < total)
   {
      int longId, shortId;
      
      currencyIndexInfo.GetLongShortIds(tradesArray[index].symbol_index, tradesArray[index].order_type, longId, shortId);
      
      if (longId == -1 || shortId == -1)
      {  
         tradesArray[index].result_exposure = currentMaxExposure;
         index++;
         continue;
      }
      
      if (currencyLongExposure[longId] >= currentMaxExposure || currencyShortExposure[shortId] >= currentMaxExposure)
      {
         DeleteAndSwapWithLast(tradesArray, index, total);
         total--;
      }
      else
      {
         index++;
      }
      
   }
}

void ExposureController::GetSymbolInfoArray(TradeSummary &tradesArray[],CurrencyExposureInfo &currencyArray[], double currentMaxExp)
{
   for (int i=0; i<ArraySize(tradesArray); i++)
   {
      int longId, shortId;
      
      currencyIndexInfo.GetLongShortIds(tradesArray[i].symbol_index, tradesArray[i].order_type, longId, shortId);
      
      AddTradeToSymbol(currencyArray, longId, shortId, currentMaxExp);
   }
}

void ExposureController::AddTradeToSymbol(CurrencyExposureInfo &currencyArray[], int longCurrency, int shortCurrency, double currentMaxExp)
{
   //Buscar en array si estan (por separado)
   
   if (longCurrency == -1 || shortCurrency == -1) return;
   
   int total = ArraySize(currencyArray);
   
   bool longFound = false;
   bool shortFound = false;
   
   int i;
   for (i=0; i<total; i++) //Buscar long
   {
      if (currencyArray[i].currencyIndex == longCurrency && currencyArray[i].isLong)
      {
         currencyArray[i].amountOfTrades +=1;
         longFound = true;
         break;
      }
   }
   for (i=0; i<total; i++) //Buscar long
   {
      if (currencyArray[i].currencyIndex == shortCurrency && !currencyArray[i].isLong)
      {
         currencyArray[i].amountOfTrades +=1;
         shortFound = true;
         break;
      }
   }
   
   //Crear nuevo si no se encuentra
   if (!longFound)
   {
      ArrayResize(currencyArray, total+1);
      
      currencyArray[total].currencyIndex = longCurrency;
      currencyArray[total].isLong = true;
      currencyArray[total].amountOfTrades = 1;
      currencyArray[total].maxExposure = currentMaxExp - currencyLongExposure[longCurrency];
      
      total++;
   }
   
   if (!shortFound)
   {
      ArrayResize(currencyArray, total+1);
      
      currencyArray[total].currencyIndex = shortCurrency;
      currencyArray[total].isLong = false;
      currencyArray[total].amountOfTrades = 1;
      currencyArray[total].maxExposure = currentMaxExp - currencyShortExposure[shortCurrency];
   }
}

void ExposureController::FilterDefinitiveTrades(TradeSummary &tradesArray[], CurrencyExposureInfo &currencyArray[])
{
   //Filtrar trade array (recursivo?) - crear nuevo array y luego hacer ArrayCopy a tradesArray
   TradeSummary filteredTrades[];
   
   MinHeapify(currencyArray);
   
   while (ArraySize(currencyArray) > 0)
   {
      CurrencyExposureInfo minimum = Peek(currencyArray);
      RemoveTop(currencyArray);
      
      //Pasar filtro
      ProcessCurrencyInfo(minimum, tradesArray, filteredTrades, currencyArray);
      
   }
   
   ArrayCopy(tradesArray, filteredTrades);
}

void ExposureController::ProcessCurrencyInfo(CurrencyExposureInfo &currentExpInfo, TradeSummary &originalArray[], TradeSummary &destinyArray[], CurrencyExposureInfo &currencyArray[])
{
   int currIndex = currentExpInfo.currencyIndex;
   bool isLong = currentExpInfo.isLong;
   
   
   int maxAmount = currentExpInfo.amountOfTrades;
   int currentAmount = 0;
   
   //Extraer trades de originalArray a destinyArray
   int indexOrg = 0;
   int sizeOrg = ArraySize(originalArray);
   
   int sizeDest = ArraySize(destinyArray);
   
   while (indexOrg < sizeOrg) //Peligroso? No deberia excederse en teoria
   {
      int longId, shortId;
      currencyIndexInfo.GetLongShortIds(originalArray[indexOrg].symbol_index, originalArray[indexOrg].order_type, longId, shortId);
      
      if ((currentExpInfo.isLong && longId == currentExpInfo.currencyIndex)
         ||
         (!currentExpInfo.isLong && shortId == currentExpInfo.currencyIndex))
      {
         ArrayResize(destinyArray, sizeDest+1);
         destinyArray[sizeDest] = originalArray[indexOrg];
         destinyArray[sizeDest].result_exposure = currentExpInfo.maxExposure / currentExpInfo.amountOfTrades;
         
         DeleteAndSwapWithLast(originalArray, indexOrg, sizeOrg);
         
         sizeOrg--;
         sizeDest++;
      }
      else
      {
         indexOrg++;
      }
      
      //Procesar currencyArray a partir de destinyArray
      int cIndex = ArraySize(currencyArray)-1;
      
      while (cIndex >= 0) //Opuesto para empezar en el ultimo nodo (los demas pueden solo hundirse)
      {
         if ((currencyArray[cIndex].isLong && longId == currencyArray[cIndex].currencyIndex)
            ||
            (!currencyArray[cIndex].isLong && shortId == currencyArray[cIndex].currencyIndex))
         {
            
            if (currencyArray[cIndex].amountOfTrades <= 1)
            {
               RemoveAtIndex(currencyArray, cIndex);
            }
            else
            {
               currencyArray[cIndex].amountOfTrades -=1;
               Sink(currencyArray, ArraySize(currencyArray), cIndex);
            }
            
            break;
         }
         else
         {
            cIndex--;
         }
      }
      
   }
   
}


#ifdef __MQL5__

   #define TRIM_STRING_LEFT(param) StringTrimLeft(param)
   #define TRIM_STRING_RIGHT(param) StringTrimRight(param)
   
#else

   #define TRIM_STRING_LEFT(param) param=StringTrimLeft(param)
   #define TRIM_STRING_RIGHT(param) param=StringTrimRight(param)

#endif

#include "..\CrossProjects\NewsImport.mqh"


class NewsController
{
   private:
      CurrencyIndexObject* currencyIndexInfo;
      
      //News Strings
      string newsArrayEUR[];
      string newsArrayGBP[];
      string newsArrayAUD[];
      string newsArrayNZD[];
      string newsArrayUSD[];
      string newsArrayCAD[];
      string newsArrayCHF[];
      string newsArrayJPY[];
      
      
      bool currencyHasNews[];
      
      CNews* newsArray[];
      
      datetime lastRecordTime;
      int newsLastIndex;
      
      void TrimArray(string &array[]);
      
      
      void UpdateNewsInfluence(CNews* &newToCheck, int currencyIndex);
      
   public:
      NewsController(CurrencyIndexObject* indexInfo);
      ~NewsController();
      
      void ProcessNewsArrays(string news_EUR, string news_GBP, string news_AUD, string news_NZD, string news_USD, string news_CAD, string news_CHF, string news_JPY);
      
      void GetNewsOfCandle(datetime nextCandle);
      
      void DiscardTradesWithNews(TradeSummary &tradesArray[]);
      
      bool CheckNewsOfPair(int currencyIndexBase, int currencyIndexQuote);
};

NewsController::NewsController(CurrencyIndexObject* indexInfo)
{
   currencyIndexInfo = indexInfo;
   
   ArrayResize(currencyHasNews, currencyIndexInfo.totalCurrencies);
   
   newsLastIndex = 0;
}


NewsController::~NewsController(void)
{
   for (int i=0; i<ArraySize(newsArray); i++)
   {
      delete newsArray[i];
   }
}


void NewsController::ProcessNewsArrays(string news_EUR,string news_GBP,string news_AUD,string news_NZD,string news_USD,string news_CAD,string news_CHF,string news_JPY)
{
   StringSplit(news_EUR, ',', newsArrayEUR);
   TrimArray(newsArrayEUR);
   
   StringSplit(news_GBP, ',', newsArrayGBP);
   TrimArray(newsArrayGBP);
   
   StringSplit(news_AUD, ',', newsArrayAUD);
   TrimArray(newsArrayAUD);
   
   StringSplit(news_NZD, ',', newsArrayNZD);
   TrimArray(newsArrayNZD);
   
   StringSplit(news_USD, ',', newsArrayUSD);
   TrimArray(newsArrayUSD);
   
   StringSplit(news_CAD, ',', newsArrayCAD);
   TrimArray(newsArrayCAD);
   
   StringSplit(news_CHF, ',', newsArrayCHF);
   TrimArray(newsArrayCHF);
   
   StringSplit(news_JPY, ',', newsArrayJPY);
   TrimArray(newsArrayJPY);
}

void NewsController::TrimArray(string & array[])
{
   for (int j=0; j<ArraySize(array); j++)
   {
      TRIM_STRING_LEFT(array[j]);
      TRIM_STRING_RIGHT(array[j]);
   }
}


void NewsController::GetNewsOfCandle(datetime nextCandle)
{
   MqlDateTime datetimeStruct;
   TimeToStruct(nextCandle, datetimeStruct);
   TransformDayToWeekInit(datetimeStruct);
   datetime currentWeek = StructToTime(datetimeStruct);
   
   if (lastRecordTime != currentWeek)
   {
      ReadNewsFromFile(currentWeek, newsArray);
      
      lastRecordTime = currentWeek;
      newsLastIndex = 0;
   }
   
   //Procesar bool array
   ArrayFill(currencyHasNews, 0, currencyIndexInfo.totalCurrencies, false);
   
   int j;
   for (j=newsLastIndex; j<ArraySize(newsArray); j++)
   {
      if (newsArray[j]._time >= GetEndOfCandle(nextCandle)) break;
      
      for (int i=0; i<currencyIndexInfo.totalCurrencies; i++)
      {
         if (currencyHasNews[i]) continue;
         
         if (newsArray[j]._currency == "All" || newsArray[j]._currency == currencyIndexInfo.currencies[i])
         {
            UpdateNewsInfluence(newsArray[j], i);
         }
      }
   }
   newsLastIndex = j;
}

void NewsController::DiscardTradesWithNews(TradeSummary &tradesArray[])
{
   int index = 0;
   int total = ArraySize(tradesArray);
   
   while (index < total)
   {
      int longId, shortId;
      
      currencyIndexInfo.GetLongShortIds(tradesArray[index].symbol_index, tradesArray[index].order_type, longId, shortId);
      
      if (longId == -1 || shortId == -1)
      {  
         index++;
         continue;
      }
      
      if (currencyHasNews[longId] || currencyHasNews[shortId])
      {
         DeleteAndSwapWithLast(tradesArray, index, total);
         total--;
      }
      else
      {
         index++;
      }
      
   }
}

bool NewsController::CheckNewsOfPair(int currencyIndexBase, int currencyIndexQuote)
{
   bool currency1has = false;
   if (currencyIndexBase>=0) currency1has = currencyHasNews[currencyIndexBase];
   bool currency2has = false;
   if (currencyIndexQuote>=0) currency2has = currencyHasNews[currencyIndexQuote];
   
   return currency1has || currency2has;
}


void NewsController::UpdateNewsInfluence(CNews *&newToCheck, int currencyIndex)
{
   string currency = currencyIndexInfo.currencies[currencyIndex]; //News puede ser All
   
   if (currency == "EUR")
   {
      if (newToCheck.CheckCoinciding(newsArrayEUR)) currencyHasNews[currencyIndex] = true;
   }
   else if (currency == "GBP")
   {
      if (newToCheck.CheckCoinciding(newsArrayGBP)) currencyHasNews[currencyIndex] = true;
   }
   else if (currency == "AUD")
   {
      if (newToCheck.CheckCoinciding(newsArrayAUD)) currencyHasNews[currencyIndex] = true;
   }
   else if (currency == "NZD")
   {
      if (newToCheck.CheckCoinciding(newsArrayNZD)) currencyHasNews[currencyIndex] = true;
   }
   else if (currency == "USD")
   {
      if (newToCheck.CheckCoinciding(newsArrayUSD)) currencyHasNews[currencyIndex] = true;
   }
   else if (currency == "CAD")
   {
      if (newToCheck.CheckCoinciding(newsArrayCAD)) currencyHasNews[currencyIndex] = true;
   }
   else if (currency == "CHF")
   {
      if (newToCheck.CheckCoinciding(newsArrayCHF)) currencyHasNews[currencyIndex] = true;
   }
   else if (currency == "JPY")
   {
      if (newToCheck.CheckCoinciding(newsArrayJPY)) currencyHasNews[currencyIndex] = true;
   }
}