//+------------------------------------------------------------------+
//|                                                NewsIndicator.mq4 |
//|                    Copyright 2020, Manuel Alejandro Cercós Pérez |
//|                         https://www.mql5.com/en/users/alexcercos |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Manuel Alejandro Cercós Pérez"
#property link      "https://www.mql5.com/en/users/alexcercos"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   0
#property indicator_label1 "News Indicator"
#property indicator_label2 "Impact"


#include "../CrossProjects/NewsImport.mqh"

#define LINE_PREFIX "News_VLine"
#define ARROW_PREFIX "News_Arrow"
#define FUTURE_PREFIX "News_FutArr"

#define LINE_NAME(index) LINE_PREFIX + "_"+(string)index
#define ARROW_NAME(index) ARROW_PREFIX + "_"+(string)index
#define FUT_ARROW_NAME(index) FUTURE_PREFIX + "_"+(string)index

#ifdef __MQL5__

   #define TRIM_STRING_LEFT(param) StringTrimLeft(param)
   #define TRIM_STRING_RIGHT(param) StringTrimRight(param)
   
#else

   #define TRIM_STRING_LEFT(param) param=StringTrimLeft(param)
   #define TRIM_STRING_RIGHT(param) param=StringTrimRight(param)

#endif

enum WhereAreNews
{
   NO_NEWS,
   NEWS_BASE,
   NEWS_QUOTE,
   NEWS_BOTH
};

//Inputs
input int indicatorDisplacement = 1; //Indicator Displacement
input NewsIndicatorMode indicatorMode = FILTER_IMPACT; // Indicator Mode
input bool show_news_lines = true; // Show Vertical Lines

//input group "Impact"
input bool showNoImpact = false; // Show news with no impact
input bool showLowImpact = true; // Show news with low impact
input bool showMediumImpact = true; // Show news with medium impact
input bool showHighImpact = true; // Show news with high impact

//input group "News Name"
input string newsEUR = "Monetary Policy Statement, Lagarde"; // EUR News
input string newsGBP = "MPC Official Bank Rate Votes, GDP";   // GBP News
input string newsAUD = "RBA Rate Statement, Unemployment Rate"; // AUD News
input string newsNZD = "Unemployment Rate, GDP, GDT, RBNZ Rate Statement"; // NZD News
input string newsUSD = "Non-Farm Employment, FOMC Statement, Fed Chair Powell, CPI"; // USD News
input string newsCAD = "BOC Rate Statement, Unemployment Rate, Retail Sales, CPI"; // CAD News
input string newsCHF = "SNB Monetary Policy Assessment"; // CHF News
input string newsJPY = "Monetary Policy Statement"; // JPY News

//input group "Indicator Display"
input int distanceFirst = 500; //Distance to first arrow
input int distanceBetween = 250; //Distance between arrows

color baseColor = clrDarkSlateBlue;
color quoteColor = clrSaddleBrown;
color bothColor = clrDimGray;

string currencyBase, currencyQuote;
string arrayFilterBase[], arrayFilterQuote[];

double ArrowBuffer[], impactBuffer[];

void ProcessArrayForCurrency(string currency, string &returnArray[])
{
   if (currency == "EUR")
      StringSplit(newsEUR, ',', returnArray);
   if (currency == "GBP")
      StringSplit(newsGBP, ',', returnArray);
   if (currency == "AUD")
      StringSplit(newsAUD, ',', returnArray);
   if (currency == "NZD")
      StringSplit(newsNZD, ',', returnArray);
   if (currency == "USD")
      StringSplit(newsUSD, ',', returnArray);
   if (currency == "CAD")
      StringSplit(newsCAD, ',', returnArray);
   if (currency == "CHF")
      StringSplit(newsCHF, ',', returnArray);
   if (currency == "JPY")
      StringSplit(newsJPY, ',', returnArray);
   
   TrimArray(returnArray);
}

void TrimArray(string & array[])
{
   for (int j=0; j<ArraySize(array); j++)
   {
      TRIM_STRING_LEFT(array[j]);
      TRIM_STRING_RIGHT(array[j]);
   }
}

int OnInitProcessCurrencies()
{
   #ifdef __MQL5__
   currencyBase = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE);
   currencyQuote = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT);
   #else
   
   if (StringLen(Symbol())>=6) //Slice (forex/metals)
   {
      currencyBase = StringSubstr(Symbol(), 0, 3);
      currencyQuote = StringSubstr(Symbol(), 3, 3);
   }
   
   #endif
   
   int id1 = CurrencyIndex(currencyBase);
   int id2 = CurrencyIndex(currencyQuote);
   
   if (id1 == -1 || id2 == -1 || id1 == id2)
   {
      Print("News not suitable for symbol " + Symbol());
      return INIT_FAILED;
   }
   
   ProcessArrayForCurrency(currencyBase, arrayFilterBase);
   ProcessArrayForCurrency(currencyQuote, arrayFilterQuote);
   
   lastRecordTime = 0;
   
   arrowIndex = 0;
   lineIndex = 0;
   isTester = MQLInfoInteger(MQL_TESTER);
   
   return(INIT_SUCCEEDED);
}

CNews* newsArray[];
MqlDateTime datetimeStruct;
datetime lastRecordTime;
int newsLastIndex = 0;

bool isTester;
int arrowIndex, lineIndex;


color GetColorLineNews(int whereNews)
{
   switch (whereNews)
   {
      case NEWS_BASE:
         return baseColor;
      case NEWS_QUOTE:
         return quoteColor;
      default:
         return bothColor;
   }
}

color GetColorByImpact(NewsImpactEnum impact)
{
   switch (impact)
   {
      case HIGH_IMPACT:
         return clrRed;
      case MEDIUM_IMPACT:
         return clrOrange;
      case LOW_IMPACT:
         return clrYellow;
      default:
         return clrGray;
   }
}

void CreateNewLine(color lineColor, datetime time)
{
	if (!show_news_lines) return;
	
   string timeName = TimeToString(time);
   string lineName = LINE_NAME(lineIndex++);
   
   if (isTester)
   {
      lineName = timeName;
   }

   ObjectCreate(ChartID(), lineName, OBJ_VLINE, 0, time, 0.0);
   ObjectSetInteger(ChartID(), lineName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(ChartID(), lineName, OBJPROP_STYLE, STYLE_DASHDOTDOT);
   ObjectSetInteger(ChartID(), lineName, OBJPROP_BACK, true);
   ObjectSetInteger(ChartID(), lineName, OBJPROP_SELECTABLE, false);
   ObjectSetString(ChartID(), lineName, OBJPROP_TOOLTIP, timeName);
}

void CreateNewsArray(CNews* &newsArr[], datetime timeN, double priceN)
{
   for (int k=ArraySize(newsArr)-1; k>=0; k--)
   {
      double priceEnd = priceN + Point() * (distanceFirst + distanceBetween* k);
	   string name;
	   string newsText = newsArr[k].NewsStringify();
	   if (isTester)
	   {
	      name = newsText;
	   }
	   else
	   {
	   	arrowIndex++;
	      name = ARROW_NAME(arrowIndex);
	   }
	   
	   
	   ObjectCreate(ChartID(), name, OBJ_ARROW, 0, timeN, priceEnd);
	   ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, 174);
	   //ObjectSetInteger(ChartID(), name, OBJPROP_BACK, true);
	   ObjectSetInteger(ChartID(), name, OBJPROP_SELECTABLE, false);
	   ObjectSetInteger(ChartID(), name, OBJPROP_ZORDER, 1);
	   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, GetColorByImpact(newsArr[k]._impact));
	   ObjectSetString(ChartID(), name, OBJPROP_TOOLTIP, newsText);
   }
}

void MoveArrows(datetime timeCurrent, double highCurrent)
{
   int lastArrowIndex = arrowIndex-1;
   
   datetime arrowTime = (datetime)ObjectGetInteger(ChartID(), ARROW_NAME(lastArrowIndex), OBJPROP_TIME);
   
   int id = 0;
   while (arrowTime >= timeCurrent)
   {
      ObjectSetDouble(ChartID(), ARROW_NAME(lastArrowIndex), OBJPROP_PRICE, highCurrent + id * Point() * distanceBetween);
      
      id++;
      lastArrowIndex--;
      arrowTime = (datetime)ObjectGetInteger(ChartID(), ARROW_NAME(lastArrowIndex), OBJPROP_TIME);
   }
}

void DeInitEvent()
{
   for (int j=ArraySize(newsArray)-1; j>=0;j--)
   {
      delete newsArray[j];
   }
   
   if (isTester) return;
   
   Comment("Removing News Indicator...");
   
   ObjectsDeleteAll(ChartID(), LINE_PREFIX);
   ObjectsDeleteAll(ChartID(), ARROW_PREFIX);
   ObjectsDeleteAll(ChartID(), FUTURE_PREFIX);
   
   Sleep(500);
   
   
   Comment("");
   
   ChartRedraw(0);
}

void CalculateEvent(const datetime &time[], const double &high[], double &arrowBufer[], int limit)
{
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(time, true);
   
   for (int i=limit; i>0 && !IsStopped(); i--)
   {
      TimeToStruct(time[i-1], datetimeStruct);
      TransformDayToWeekInit(datetimeStruct);
      datetime currentWeek = StructToTime(datetimeStruct);
      
      if (lastRecordTime < currentWeek)
      {
         ReadNewsFromFileAndCurrency(currencyBase, currencyQuote, currentWeek, newsArray);
         
         lastRecordTime = currentWeek;
         newsLastIndex = 0;
      }
      
      int drawLine = NO_NEWS;
      int impact = NON_ECONOMIC;
      
      CNews* currentNews[];
      
      int j;
      for (j=newsLastIndex; j<ArraySize(newsArray) && !IsStopped(); j++)
      {
         if (newsArray[j]._time >= GetEndOfCandle(time[i-1])) break;
         
         if (newsArray[j]._currency == "All" || newsArray[j]._currency == currencyBase) 
         {
            if ((indicatorMode == FILTER_NEWS && newsArray[j].CheckCoinciding(arrayFilterBase)) || 
                 (indicatorMode == FILTER_IMPACT && CheckImpact(newsArray[j].GetImpact())) )
            {
               drawLine = NEWS_BASE;
               
               impact = MathMax(impact, newsArray[j].GetImpact());
               
               AddNewToArray(currentNews, newsArray[j]);
            }
         }
         
         if (newsArray[j]._currency == "All" || newsArray[j]._currency == currencyQuote) 
         {
            if ((indicatorMode == FILTER_NEWS && newsArray[j].CheckCoinciding(arrayFilterQuote)) || 
                 (indicatorMode == FILTER_IMPACT && CheckImpact(newsArray[j].GetImpact())) )
            {
               if (drawLine == NEWS_BASE || drawLine == NEWS_BOTH) drawLine = NEWS_BOTH;
               else drawLine = NEWS_QUOTE;
               
               impact = MathMax(impact, newsArray[j].GetImpact());
               
               AddNewToArray(currentNews, newsArray[j]);
            }
         }
         
      }
      newsLastIndex = j;
      
      if (drawLine != NO_NEWS)
      {
         CreateNewLine(GetColorLineNews(drawLine), time[i-1]);
         
         //Crear noticias individuales
         //CreateNewsArray(currentNews, time[i-1], high[i-1]);
         for (int k=ArraySize(currentNews)-1; k>=0; k--)
		   {
		      double priceEnd = high[i-1] + Point() * (distanceFirst + distanceBetween* k);
			   string name;
			   string newsText = currentNews[k].NewsStringify();
			   if (isTester)
			   {
			      name = newsText;
			   }
			   else
			   {
			   	arrowIndex++;
			      name = ARROW_NAME(arrowIndex);
			   }
			   
			   
			   ObjectCreate(ChartID(), name, OBJ_ARROW, 0, time[i-1], priceEnd);
			   ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, 174);
			   //ObjectSetInteger(ChartID(), name, OBJPROP_BACK, true);
			   ObjectSetInteger(ChartID(), name, OBJPROP_SELECTABLE, false);
			   ObjectSetInteger(ChartID(), name, OBJPROP_ZORDER, 1);
			   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, GetColorByImpact(currentNews[k]._impact));
			   ObjectSetString(ChartID(), name, OBJPROP_TOOLTIP, newsText);
		   }
      }
      
      ArrowBuffer[i-1]=drawLine;
      impactBuffer[i-1]=impact;
      
      ArrayFree(currentNews);
   }
   
   if (limit>=1 && !IsStopped()) //Only on new candles
   {
   	ObjectsDeleteAll(ChartID(), FUTURE_PREFIX); //Restart future news
   	int future_index = 0;
   	
      datetime futureTime = time[0];
      for (int i=0; i<indicatorDisplacement; i++)
      {
         futureTime = GetEndOfCandle(futureTime);
         TimeToStruct(futureTime, datetimeStruct);
         TransformDayToWeekInit(datetimeStruct);
         datetime currentWeek = StructToTime(datetimeStruct);
         
         if (lastRecordTime < currentWeek)
         {
            ReadNewsFromFileAndCurrency(currencyBase, currencyQuote, currentWeek, newsArray);
            
            lastRecordTime = currentWeek;
            newsLastIndex = 0;
         }
         
         int drawLine = NO_NEWS;
         int impact = NON_ECONOMIC;
         
         CNews* currentNews[];
         
         int j;
         for (j=newsLastIndex; j<ArraySize(newsArray) && !IsStopped(); j++)
         {
            if (newsArray[j]._time >= GetEndOfCandle(futureTime)) break;
            
            if (newsArray[j]._currency == "All" || newsArray[j]._currency == currencyBase) 
            {
            	if ((indicatorMode == FILTER_NEWS && newsArray[j].CheckCoinciding(arrayFilterBase)) || 
                 (indicatorMode == FILTER_IMPACT && CheckImpact(newsArray[j].GetImpact())) )
               {
                  drawLine = NEWS_BASE;
                  
                  impact = MathMax(impact, newsArray[j].GetImpact());
                  
                  AddNewToArray(currentNews, newsArray[j]);
               }
               
            }
            
            if (newsArray[j]._currency == "All" || newsArray[j]._currency == currencyQuote) 
            {
               if ((indicatorMode == FILTER_NEWS && newsArray[j].CheckCoinciding(arrayFilterQuote)) || 
                 (indicatorMode == FILTER_IMPACT && CheckImpact(newsArray[j].GetImpact())) )
	            {
	               if (drawLine == NEWS_BASE || drawLine == NEWS_BOTH) drawLine = NEWS_BOTH;
	               else drawLine = NEWS_QUOTE;
	               
	               impact = MathMax(impact, newsArray[j].GetImpact());
	               
	               AddNewToArray(currentNews, newsArray[j]);
	            }
            }
            
         }
         newsLastIndex = j;
         
         if (drawLine != NO_NEWS)
         {
            CreateNewLine(GetColorLineNews(drawLine), futureTime);
            
            //Crear noticias individuales
            //CreateNewsArray(currentNews,futureTime, high[0]);
            
            for (int x=ArraySize(currentNews)-1; x>=0; x--)
            {
            	future_index++;
            	string name;
            	string newsText = currentNews[x].NewsStringify();
            	if (isTester)
				      name = newsText;
				   else
				   {
				   	arrowIndex++;
				      name = FUT_ARROW_NAME(future_index);
				   }
            	ObjectCreate(ChartID(), name, OBJ_ARROW, 0, futureTime, high[0] + Point()*(distanceFirst + distanceBetween*x));
				   ObjectSetInteger(ChartID(), name, OBJPROP_ARROWCODE, 174);
				   ObjectSetInteger(ChartID(), name, OBJPROP_SELECTABLE, false);
				   ObjectSetInteger(ChartID(), name, OBJPROP_ZORDER, 1);
				   //ObjectSetInteger(ChartID(), name, OBJPROP_BACK, true);
				   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, GetColorByImpact(currentNews[x]._impact));
				   ObjectSetString(ChartID(), name, OBJPROP_TOOLTIP, newsText);
            }
         }
         
         
         ArrayFree(currentNews);
      }
   }
   
	if (!IsStopped())
		MoveArrows(time[0], high[0] + distanceFirst * Point());
}

bool CheckImpact(NewsImpactEnum impact)
{
   switch (impact)
   {
      case NON_ECONOMIC:
         return showNoImpact;
      case LOW_IMPACT:
         return showLowImpact;
      case MEDIUM_IMPACT:
         return showMediumImpact;
      case HIGH_IMPACT:
         return showHighImpact;
   }
   return false;
}

int OnInit()
{
   if (MQLInfoInteger(MQL_LICENSE_TYPE) == LICENSE_DEMO)
   {
      return INIT_FAILED;
   }
   
   //Remove all first
   ObjectsDeleteAll(ChartID(), LINE_PREFIX);
   ObjectsDeleteAll(ChartID(), ARROW_PREFIX);
   
   IndicatorSetInteger(INDICATOR_DIGITS, 0);
   SetIndexBuffer(0, ArrowBuffer, INDICATOR_DATA);
   ArraySetAsSeries(ArrowBuffer, true);
   SetIndexBuffer(1, impactBuffer, INDICATOR_DATA);
   ArraySetAsSeries(impactBuffer, true);
   
   return OnInitProcessCurrencies();
}

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
   
   int limit = MathMin(rates_total, rates_total - prev_calculated);
   
   
   CalculateEvent(time, high, ArrowBuffer, limit);
   
   return(rates_total);
}

void OnDeinit(const int reason)
{
   DeInitEvent();
}