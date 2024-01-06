/*

Change Symbol ya incluye su propio codigo, este archivo no esta incluido alli

*/
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
         
         if (currentTime == 0) return;
         
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
      
      return 0;
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
         StringReplace(rawDate, "<span>", "");
         
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
   }
   info = lastDate + " ";
   
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
         currency = StringSubstr(row, init+1, end-init);
      
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
      if (sep[3]=="low" || sep[3] == "ff-impact-yel") impact = LOW_IMPACT;
      else if (sep[3]=="medium" || sep[3] == "ff-impact-ora") impact = MEDIUM_IMPACT;
      else if (sep[3]=="high" || sep[3] == "ff-impact-red") impact = HIGH_IMPACT;
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