//+------------------------------------------------------------------+
//|                                                NewsIndicator.mq5 |
//|                    Copyright 2020, Manuel Alejandro Cercós Pérez |
//|                         https://www.mql5.com/en/users/alexcercos |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Manuel Alejandro Cercós Pérez"
#property link      "https://www.mql5.com/en/users/alexcercos"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1 "News Indicator"
#property indicator_type1   DRAW_NONE
#property indicator_label2 "Impact"
#property indicator_type2   DRAW_NONE

#define ONE_MINUTE 60
#define ONE_HOUR 3600
#define ONE_DAY 86400
#define ONE_WEEK 604800

#define TIME_TO_FILENAME(time) "News\\" + TimeToString(time, TIME_DATE) + ".txt"

#define START_OF_CANDLE(time) time - time%ONE_DAY


union LongDouble 
{ 
  long   long_value; 
  double double_value; 
};

enum NewsIndicatorMode
{
   FILTER_IMPACT, //Filter by Impact
   FILTER_NEWS    //Filter by News Name
};


string months[]={ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

void ImportNewsFromPeriod(datetime initTime, datetime lastTime, bool rewrite_files = false)
{
   if (MQLInfoInteger(MQL_TESTER)) return;
   MqlDateTime timeStruct;
   TimeToStruct(initTime, timeStruct);
   TransformDayToWeekInit(timeStruct);
   
   datetime currentTime = StructToTime(timeStruct);
   
   
   if (initTime >= lastTime)
   {
      ImportWeekNews(initTime, rewrite_files);
   }
   else
   {
      while(currentTime < lastTime && !IsStopped())
      {
         currentTime = ImportWeekNews(currentTime, rewrite_files);
         
         currentTime += ONE_WEEK;
      }
      
      currentTime -= ONE_WEEK;
   }
   
}

datetime ImportWeekNews(datetime fromTime, bool rewrite_files = false)
{
   if (MQLInfoInteger(MQL_TESTER)) return fromTime;
   //string cookie="fftimezone=Eet";
   string cookie="fftimezone=Europe/Riga";
   string headers;
   //string reqheaders="User-Agent: Mozilla/4.0\r\n";
   char post[],result[];
   int res;
   string domain = "http://www.forexfactory.com";
   
   MqlDateTime timeStruct;
   
   TimeToStruct(fromTime, timeStruct);
   
   string currentWeek = GetCurrentWeek(timeStruct, fromTime);
   string subdomain="/calendar?week="+currentWeek;
   string url = domain + subdomain;
   int timeout=5000;
   
   ResetLastError();
   
   string filename = TIME_TO_FILENAME(fromTime);
   
   if (FileIsExist(filename, FILE_COMMON) && !rewrite_files)
   {
      Print(filename, " found. Not reimported");
      
      return fromTime;
   }
   else
   {
      Print("Importing week " + TimeToString(fromTime, TIME_DATE));
   }
   
   res = WebRequest("GET", url, cookie, NULL, timeout, post, 0, result, headers);
   if(res==-1)
   {
      Print("Error in WebRequest. Error code  =",GetLastError());
      
      MessageBox("Add the address '"+domain+"' in the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
   }
   else
   {
      string resultStr = CharArrayToString(result,0,WHOLE_ARRAY,CP_UTF8);
      
         
      int i = StringFind(resultStr, "calendar__table", 0);
      
      i = StringFind(resultStr, "</thead>", i);
      
      int j = StringFind(resultStr, "<div class=\"foot\">", i);
               
      resultStr = StringSubstr(resultStr, i, j-i);
      
      
      i = StringFind(resultStr, "<tr class=\"calendar__row calendar_row calendar__row", 0);
      i = StringFind(resultStr, ">", i);
      
      j = StringFind(resultStr, "</tr>", i);
      
      string arrayStrings[];
      
      while (i!=-1)
      {
         string thisRow = StringSubstr(resultStr, i, j-i);
         
         
         string infoRow = GetInfoRow(timeStruct, thisRow);
         
         if (infoRow !="")
         {
            int aSize = ArraySize(arrayStrings);
            ArrayResize(arrayStrings, aSize+1, aSize+2);
            arrayStrings[aSize] = infoRow;
            
         }
         
         resultStr = StringSubstr(resultStr, j);
         
         i = StringFind(resultStr, "<tr class=\"calendar__row calendar_row", 0);
         i = StringFind(resultStr, ">", i);
         
         j = StringFind(resultStr, "</tr>", i);
      }
      
      
      int filehandle=FileOpen(filename,FILE_COMMON|FILE_WRITE|FILE_TXT);
      if(filehandle!=INVALID_HANDLE)
      {
         for (int e = 0; e<ArraySize(arrayStrings); e++)
         {
            FileWrite(filehandle, arrayStrings[e]);
         }
         
         //--- Close the file
         FileClose(filehandle);
         
      }
      
      else Print("Error in FileOpen. Error code=",GetLastError());
   }
   
   return fromTime;
}

string GetCurrentWeek(MqlDateTime &dateStruct, datetime &time)
{
   TransformDayToWeekInit(dateStruct);
   time = StructToTime(dateStruct);

   string result = months[dateStruct.mon-1] + (string)dateStruct.day + "." + (string)dateStruct.year;
   
   return result;
}

void TransformDayToWeekInit(MqlDateTime &dateStruct)
{
   int weekDay = dateStruct.day_of_week;

   dateStruct.hour = 0;
   dateStruct.min = 0;
   
   datetime time = StructToTime(dateStruct);
   
   time -= weekDay * ONE_DAY;
   
   TimeToStruct(time, dateStruct);
}

string GetInfoRow(MqlDateTime& currentTime, string &row)
{
   static string lastDate = "";
   static string lastTime = "00:00";
   
   string info = "";
   
   int thisMonth = currentTime.mon;
   int thisYear = currentTime.year;
   
   // DATE
   
   int init = StringFind(row, "<td class=\"calendar__cell calendar__date", 0);
   init = StringFind(row, ">", init+1);
   
   int end = StringFind(row, "</td>", init)-1;
   
   if (init != 0)
   {
      string rawDate;
   
      if (end-init-1 == 0) rawDate = "";
      else rawDate = StringSubstr(row, init+2, end-init-1);

      if (rawDate != "")
      {
         init = StringFind(rawDate, ">", 0)+1;
         end = StringFind(rawDate, "</", 0);
         
         rawDate = StringSubstr(rawDate, init, end-init);
         
         StringReplace(rawDate, "<span>", " ");
         
         string parsedDate[];
         StringSplit(rawDate, ' ', parsedDate);
         
         int currentMonth = FindMonth(parsedDate[1]);
         
         if (currentMonth == 1 && thisMonth==12) //Cambio de año
         {
            rawDate = (string)(thisYear+1) + "." + (string)currentMonth + "." + parsedDate[2];
         }
         else
         {
            rawDate = (string)thisYear + "." + (string)currentMonth + "." + parsedDate[2];
         }
         if (lastDate != rawDate) lastTime="00:00";
         lastDate = rawDate;
      }
      info = info + lastDate + " ";
   }
   
   
   // TIME
   
   init = StringFind(row, "<td class=\"calendar__cell calendar__time", 0);
   init = StringFind(row, ">", init+1);
   
   end = StringFind(row, "</td>", init)-1;
   
   int upNext = StringFind(row, "<a name=\"upnext\"", init);
   
   if (upNext != -1)
   {
      init = StringFind(row, "></span", init);
      init = StringFind(row, ">", init+1);
      end = StringFind(row, "<", init)-1;
   }
   
   if (init != 0)
   {
      string nDate = "";
      string processDate = StringSubstr(row, init+1, end-init);
      if (processDate == "Tentative" || processDate == "All Day") nDate = "";
      
      if (StringSubstr(processDate, 4) == "Data") return "";
      
      if (processDate != "")
      {
         string meridian = StringSubstr(processDate, StringLen(processDate)-2);
         
         processDate = StringSubstr(processDate, 0, StringLen(processDate)-2);
         
         string values[];
         StringSplit(processDate, ':', values);
         
         if (ArraySize(values)==2)
         {
            int hour = (int)values[0];
            if (hour == 12) hour = 0;
            
            int minutes = (int)values[1];
            
            hour += (meridian=="pm"?12:0);
            
            nDate = AutocompleteZeros(hour) + (string)hour + ":" + AutocompleteZeros(minutes) + (string)minutes;
         }
      }
      
      if (nDate != "") lastTime = nDate;
      
      info = info + lastTime;
   }
   
   datetime realTime = StringToTime(info);

   info = TimeToString(realTime) + "\t";
   
   // CURRENCY
   
   init = StringFind(row, "<td class=\"calendar__cell calendar__currency", 0);
   init = StringFind(row, ">", init+1);
   end = StringFind(row, "</td>", init)-1;
   
   if (init != 0)
   {
      string currency = "";
      if (end-init >1)
         currency = StringSubstr(row, init+2, end-init-2);
      
      if (currency == "" || currency == "CNY") return "";
         
      info = info + currency + "\t";

   }
   
   // IMPACT
   
   init = StringFind(row, "<td class=\"calendar__cell calendar__impact", 0);
   init = StringFind(row, "-", init+1);
   end = StringFind(row, ">", init+1);
   
   string impact = "";
   
   if (init != 0)
   {
      if (end-init >1)
         impact = StringSubstr(row, init+2, end-init-3);
   }
   
   
   // EVENT
   
   init = StringFind(row, "<span class=\"calendar__event-title", 0);
   init = StringFind(row, ">", init);
   end = StringFind(row, "<", init)-1;
   
   if (init != 0)
   {
      if (end-init >1)
         info = info + StringSubstr(row, init+1, end-init);
   }
   else
   {
      return "";
   }
   
   StringReplace(info, "&amp;", "&");
   
   //Add impact at end
   info = info + "\t" + impact;
   
   return info;
}

int FindMonth(string raw)
{
   for (int i=0; i<12; i++)
   {
      if (months[i]==raw) return i+1;
   }
   return -1;
}

string AutocompleteZeros(int num)
{
   if (num < 10) return "0";
   
   return "";
}


enum NewsImpactEnum
{
   NON_ECONOMIC,  // No Impact
   LOW_IMPACT,    // Low Impact
   MEDIUM_IMPACT, // Medium Impact
   HIGH_IMPACT    // High Impact
};

// NEWS CLASS

class CNews
{
public:

   string _currency;
   string _event;
   datetime _time;
   NewsImpactEnum _impact;
   
   CNews(string Currency, string Event, datetime TimeEvent, NewsImpactEnum Impact = NON_ECONOMIC);
   ~CNews();
   
   bool CheckCoinciding(string &influenceNews[]);
   bool CheckByImpact(NewsImpactEnum minimum_impact);
   datetime GetNewsTime() { return _time; }
   NewsImpactEnum GetImpact() { return _impact; }
   string NewsStringify();
};

CNews::CNews(string Currency, string Event, datetime TimeEvent, NewsImpactEnum Impact = NON_ECONOMIC)
{
   _currency = Currency;
   _event = Event;
   _time = TimeEvent;
   _impact = Impact;
}

CNews::~CNews(void){}


#define CHECK_EXACT_MATCH(newsStr) newsStr[0] == '\"' && newsStr[StringLen(newsStr)-1] == '\"'

bool CNews::CheckCoinciding(string &influenceNews[])
{
   for (int i=0; i<ArraySize(influenceNews); i++)
   {
      if (CHECK_EXACT_MATCH(influenceNews[i]))
      {
         string mod = StringSubstr(influenceNews[i], 1, StringLen(influenceNews[i])-2);
                
         if (mod == _event)
         {
            return true;
         }
         
      }
      else
      {
         if (StringFind(_event, influenceNews[i]) != -1)
         {
            return true;
         }
      }
      
   }
   return false;
}

bool CNews::CheckByImpact(NewsImpactEnum minimum_impact)
{
   return minimum_impact <= _impact;
}

string CNews::NewsStringify()
{
   return TimeToString(_time) + " " + _currency + ": " + _event + " (" + ImpactString(_impact) + ")";
}

string ImpactString(NewsImpactEnum impact)
{
   switch (impact)
   {
      case NON_ECONOMIC:
         return "N";
      case LOW_IMPACT:
         return "L";
      case MEDIUM_IMPACT:
         return "M";
      case HIGH_IMPACT:
         return "H";
   }
   return "x";
}

CNews* CreateNews(string completeLine)
{
   string sep[];
   StringSplit(completeLine, '\t', sep);
   
   if (ArraySize(sep)<3)
   {
      Print(completeLine + " -- not valid new");
      return NULL;
   }
   
   NewsImpactEnum impact = NON_ECONOMIC;
   if (ArraySize(sep)>=4)
   {
      if (sep[3]=="low") impact = LOW_IMPACT;
      else if (sep[3]=="medium") impact = MEDIUM_IMPACT;
      else if (sep[3]=="high") impact = HIGH_IMPACT;
   }
   
   return new CNews(sep[1], sep[2], StringToTime(sep[0]), impact);
}

void AddNewToArray(CNews* &array[], CNews* newToAdd)
{
   int aSize = ArraySize(array);
   ArrayResize(array, aSize+1, aSize+2);
   
   array[aSize] = newToAdd;
}


void ReadNewsFromFileAndCurrency(string currency1, string currency2, datetime newsDate, CNews* &resultArray[])
{
   /*
   MqlDateTime dateStruct;
   TimeToStruct(newsDate, dateStruct);
   
   TransformDayToWeekInit(dateStruct);
   newsDate = StructToTime(dateStruct);
   */
   
   string file_name = TIME_TO_FILENAME(newsDate);
   
   EmptyNewsArray(resultArray);
   
   if (!FileIsExist(file_name, FILE_COMMON))
      return;
   
    
   
   int filehandle=FileOpen(file_name,FILE_COMMON|FILE_READ|FILE_TXT);
   if(filehandle!=INVALID_HANDLE)
   {
      while(!FileIsEnding(filehandle))
      {
         CNews* addNew = CreateNews(FileReadString(filehandle));
         
         if (addNew!=NULL)
         {
            if (addNew._currency=="All" || addNew._currency == currency1 || addNew._currency == currency2) 
               AddNewToArray(resultArray, addNew);
            else
               delete addNew;
         }
            
      }
      
      FileClose(filehandle);
   }
   else
   {
      Print("File not found: " + file_name);
   }
}

void ReadNewsFromFile(datetime newsDate, CNews* &resultArray[])
{
   /*
   MqlDateTime dateStruct;
   TimeToStruct(newsDate, dateStruct);
   
   TransformDayToWeekInit(dateStruct);
   newsDate = StructToTime(dateStruct);
   */
   
   string file_name = TIME_TO_FILENAME(newsDate);
   
   EmptyNewsArray(resultArray);
   
   if (!FileIsExist(file_name, FILE_COMMON))
      return;
   
   int filehandle=FileOpen(file_name,FILE_COMMON|FILE_READ|FILE_TXT);
   if(filehandle!=INVALID_HANDLE)
   {
   
      while(!FileIsEnding(filehandle) && !IsStopped())
      {
         CNews* addNew = CreateNews(FileReadString(filehandle));
         
         if (addNew!=NULL)
            AddNewToArray(resultArray, addNew);
      }
      
      FileClose(filehandle);
   }
   else
   {
      Print("File not found: " + file_name);
   }
}

string symbols[] = {"EUR", "GBP", "AUD", "NZD", "USD", "CAD", "CHF", "JPY"};

int CurrencyIndex(string currency)
{
   for (int i=0; i<ArraySize(symbols);i++)
   {
      if (currency == symbols[i]) return i;
   }
   return -1;
}

string CurrencyString(int index)
{
   if (index<0 || index>7) return "";
   
   return symbols[index];
}

datetime GetEndOfCandle(datetime time)
{
   int divisor;
   
   switch (_Period)
   {
      case PERIOD_M1:
         divisor = ONE_MINUTE;
         break;
         
      case PERIOD_M5:
         divisor = ONE_MINUTE * 5;
         break;
         
      case PERIOD_M15:
         divisor = ONE_MINUTE * 15;
         break;
         
      case PERIOD_M30:
         divisor = ONE_MINUTE * 30;
         break;
         
      case PERIOD_H1:
         divisor = ONE_HOUR;
         break;
         
      case PERIOD_H4:
         divisor = ONE_HOUR * 4;
         break;
         
      case PERIOD_D1:
         divisor = ONE_DAY;
         break;
         
      case PERIOD_W1:
         divisor = ONE_WEEK;
         break;
      
      default:
         divisor = ONE_DAY;
   }
   
   return time - time%divisor + divisor;
}

void EmptyNewsArray(CNews* &array[])
{
   for (int j=ArraySize(array)-1; j>=0;j--)
   {
      delete array[j];
   }
   ArrayFree(array);
}

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
      Print("Not valid license");
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