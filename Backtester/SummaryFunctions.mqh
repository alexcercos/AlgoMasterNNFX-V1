#include "Enumerators.mqh"

#include "..\Other\RPN.mqh"


#define SEPARATOR_LINE "================================"
#define BIG_SEPARATOR_LINE "################################################################################################"
#define SUMMARY_FILE "NNFXTESTER_SUMMARY.txt"
#define OPTIMIZE_FILE "NNFXTESTER_OPTIMIZATION_DATA.txt"
#define EQUITY_FILE "NNFXTESTER_EQUITY_CURVE.txt"
#define JOURNAL_FILE "NNFXTESTER_TRADE_JOURNAL.txt"
#define DISTRIBUTION_FILE "NNFXTESTER_DISTRIBUTION.txt"

void FinalPrints(int mode, int nWins, int nLoses, double grossW, double grossL, double winRate)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;
   
   Print(SEPARATOR_LINE);
   Print("Total Wins: ", IntegerToString(nWins));
   Print("Total Loses: ", IntegerToString(nLoses));
   Print("WIN RATE: ", DoubleToString(winRate, 2) + "%");
   if (mode == N_TOTAL_PIPS)
   {
      Print(SEPARATOR_LINE);
      Print("Pips Won: " + DoubleToString(grossW, 0));
      Print("Pips Lost: " + DoubleToString(grossL, 0));
      Print("NET PIPS: " + DoubleToString(grossW+grossL, 0));
   }
   else //if (mode == N_TOTAL_PROFIT) //Resto incluidos
   {
      Print(SEPARATOR_LINE);
      Print("Gross Profit: " + DoubleToString(grossW, 2));
      Print("Gross Loss: " + DoubleToString(grossL, 2));
      Print("NET PROFIT: " + DoubleToString(grossW+grossL, 2));
   }
   Print(SEPARATOR_LINE);
}

void SymbolPrint(int mode, string symbol, int nWins, int nLoses, double gWin, double gLoss, double drawdown)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;
   
   string toPrint = symbol + ":  Wins = " + IntegerToString(nWins);
   NormalizeString(toPrint, 21);
   
   toPrint = toPrint + "Loses = " + IntegerToString(nLoses);
   NormalizeString(toPrint, 37);
   
   if (mode == N_WIN_RATE)
   {
      double wr;
      CalculateWinRate(nLoses, nWins, wr);
      
      toPrint = toPrint + "Win Rate: " + DoubleToString(wr, 2) + "%";
   }
   else if (mode == N_TOTAL_PIPS)
   {
      toPrint = toPrint + "Pips Won = " + DoubleToString(gWin, 0);
      NormalizeString(toPrint, 58);
      
      toPrint = toPrint + "Pips Lost = " + DoubleToString(gLoss, 0);
   }
   else if (mode == N_TOTAL_PROFIT)
   {
      toPrint = toPrint + "Gross Win = " + DoubleToString(gWin, 2);
      NormalizeString(toPrint, 62);
      
      toPrint = toPrint + "Gross Loss = " + DoubleToString(gLoss, 2);
   }
   else if (mode == N_DRAWDOWN)
   {
      toPrint = toPrint + "Net Profit = " + DoubleToString(gWin+gLoss, 2);
      NormalizeString(toPrint, 65);
      
      toPrint = toPrint + "Max Drawdown = " + DoubleToString(drawdown, 2) + "%";
   }
   else if (mode == N_PROFIT_FACTOR)
   {
      double pf;
      CalculateProfitFactor(gWin, gLoss, pf);
      toPrint = toPrint + "Net Profit = " + DoubleToString(gWin+gLoss, 2);
      NormalizeString(toPrint, 65);
      
      toPrint = toPrint + "Profit Factor = " + DoubleToString(pf, 2);
   }
   else if (mode == N_EXP_PAYOFF)
   {
      double expP;
      CalculateExpectedPayoff(gWin+gLoss, nWins+nLoses, expP);
      toPrint = toPrint + "Net Profit = " + DoubleToString(gWin+gLoss, 2);
      NormalizeString(toPrint, 65);
      
      toPrint = toPrint + "Expected Payoff = " + DoubleToString(expP, 2);
   }
   else
   {
      toPrint = toPrint + "Gross Win = " + DoubleToString(gWin, 2);
      NormalizeString(toPrint, 62);
      
      toPrint = toPrint + "Gross Loss = " + DoubleToString(gLoss, 2);
   }
   
   Print(toPrint);
}

void PrintAdvancedStats(double profitFactor, double drawdownPercent, double expectedPayoff, double returnOnInvestment)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;
   
   Print("PROFIT FACTOR: ", DoubleToString(profitFactor, 2));
   Print("MAX DRAWDOWN: ", DoubleToString(drawdownPercent, 2) + "%");
   Print("ROI ANNUALIZED: ", DoubleToString(returnOnInvestment, 2) + "%");
   Print("EXPECTED PAYOFF: ", DoubleToString(expectedPayoff, 2));
   Print(SEPARATOR_LINE);
   Print(SEPARATOR_LINE);
}


void WriteSummaryFile(int optMode, string &symbolsNames[], int &totalWins[], int &totalLoses[], double &grossWins[], double &grossLoses[], double &drawdowns[], int total_symbols, double years, double initialAccount, bool compound)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;

   int filehandle = FileOpen(SUMMARY_FILE,FILE_WRITE|FILE_TXT|FILE_COMMON);
   
   if (filehandle<0)
   {
      Print("Failed to open the file " + SUMMARY_FILE + " by the absolute path.");
      Print("Error code ",GetLastError());
   }
	
	int i;
   if (filehandle != INVALID_HANDLE)
   {
      string toWrite = "";
      #ifdef NNFX_MAIN_TESTER
	      if (optMode == N_TOTAL_PROFIT)
	      {
	         for (int i = 0; i < total_symbols; i++)
	            toWrite = toWrite + symbolsNames[i]+ "+\t";
	         
	         for (int i = 0; i < total_symbols; i++)
	            toWrite = toWrite + symbolsNames[i]+ "-\t";
	      }
	      else 
      #endif
      if (optMode == N_EQUITY_COMP || optMode == N_EQUITY_CURVE || optMode == N_WIN_RATE || optMode == N_TOTAL_PIPS) //Only duplicate on Equity Curves and Win Rate
      {
      	
         for (i = 0; i < total_symbols; i++)
            toWrite = toWrite + symbolsNames[i]+ "+\t";
         
         for (i = 0; i < total_symbols; i++)
            toWrite = toWrite + symbolsNames[i]+ "-\t";
      }
      else
      {
         for (i = 0; i < total_symbols; i++)
            toWrite = toWrite + symbolsNames[i]+ "\t";
      }
      
      FileWrite(filehandle, toWrite);
      
      toWrite = "";
      
      #ifdef NNFX_MAIN_TESTER
	      if (optMode == N_TOTAL_PROFIT)
	      {
	         for (i = 0; i < total_symbols; i++)
	         {
	            toWrite = toWrite + DoubleToString(grossWins[i], 2)+ "\t";
	         }
	         for (i = 0; i < total_symbols; i++)
	         {
	            toWrite = toWrite + DoubleToString(grossLoses[i], 2)+ "\t";
	         }
	      }
	      else 
      #endif
      if (optMode == N_WIN_RATE)
      {
         for (i = 0; i < total_symbols; i++)
         {
            toWrite = toWrite + IntegerToString(totalWins[i])+ "\t";
         }
         for (i = 0; i < total_symbols; i++)
         {
            toWrite = toWrite + IntegerToString(totalLoses[i])+ "\t";
         }
      }
      else if (optMode == N_DRAWDOWN)
      {
         for (i = 0; i < total_symbols; i++)
         {
            toWrite = toWrite + DoubleToString(-drawdowns[i], 2)+ "\t";
         }
      }
      else if (optMode == N_ROI)
      {
         for (i = 0; i < total_symbols; i++)
         {
            double pairRoi;
            CalculateReturnOnInvestment((grossWins[i]+grossLoses[i])/initialAccount, years, compound, pairRoi);
            toWrite = toWrite + DoubleToString(pairRoi, 2)+ "\t";
         }
      }
      else if (optMode == N_PROFIT_FACTOR)
      {
         for (i = 0; i < total_symbols; i++)
         {
            double pairPF;
            CalculateProfitFactor(grossWins[i], grossLoses[i], pairPF);
            toWrite = toWrite + DoubleToString(pairPF, 2)+ "\t";
         }
      }
      else if (optMode == N_EXP_PAYOFF)
      {
         for (i = 0; i < total_symbols; i++)
         {
            double pairEP;
            CalculateExpectedPayoff((grossWins[i]+ grossLoses[i]), (totalWins[i]+totalLoses[i]), pairEP);
            toWrite = toWrite + DoubleToString(pairEP, 2)+ "\t";
         }
      }
      else if (optMode == N_DIST_SHAPE || optMode == N_DIST_VALUE || optMode == N_TOTAL_PROFIT)
      {
         for (i = 0; i < total_symbols; i++)
         {
            toWrite = toWrite + DoubleToString(grossWins[i]+grossLoses[i], 2)+ "\t";
         }
      }
      else //N_TOTAL_PIPS, N_EQUITY_CURVE, N_EQUITY_COMP
      {
         int digits = optMode==N_TOTAL_PIPS?0:2;
      
         for (i = 0; i < total_symbols; i++)
         {
            toWrite = toWrite + DoubleToString(grossWins[i], digits)+ "\t";
         }
         for (i = 0; i < total_symbols; i++)
         {
            toWrite = toWrite + DoubleToString(grossLoses[i], digits)+ "\t";
         }
      }
   
      FileWrite(filehandle, toWrite);
      
      FileFlush(filehandle);
      FileClose(filehandle);
      
      Print("Summary file \"" + SUMMARY_FILE +  "\" saved in directory " + TerminalInfoString(TERMINAL_COMMONDATA_PATH));
   }
}

void WriteMetricsInSummary(double winRate, int totalTrades, double profitFactor, double expectedPayoff, double drawdown, double roi, double finalProfit, double distValue, double distShape)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;
   
   int filehandle=FileOpen(SUMMARY_FILE,FILE_READ|FILE_WRITE|FILE_TXT|FILE_COMMON);
      
   if(filehandle<0)
   {
      Print("Failed to open the file " + SUMMARY_FILE + " by the absolute path.");
      Print("Error code ",GetLastError());
   }

   if(filehandle!=INVALID_HANDLE)
   {
      FileSeek(filehandle,0,SEEK_END);
      
      FileWrite(filehandle, "");
      FileWrite(filehandle, "WIN RATE\tTOTAL TRADES\tTOTAL PROFIT\tDRAWDOWN\tROI\tPROFIT FACTOR\tEXP.PAYOFF\tDIST.VALUE\tDIST.SHAPE");
      
      string content =  DoubleToString(winRate, 2) + "\t" + 
                        IntegerToString(totalTrades) + "\t" +
                        DoubleToString(finalProfit, 2) + "\t" + 
                        DoubleToString(drawdown, 2) + "\t" + 
                        DoubleToString(roi, 2) + "\t" + 
                        DoubleToString(profitFactor, 2) + "\t" + 
                        DoubleToString(expectedPayoff, 2) + "\t" + 
                        DoubleToString(distValue, 2) + "\t" + 
                        DoubleToString(distShape, 5);

                       
      FileWrite(filehandle, content);
      FileFlush(filehandle);
      FileClose(filehandle);
   }
}

void WriteOptimizeFile(int optMode, double winRate, double profitFactor, double expectedPayoff, double drawdown, double roi, double finalProfit, double distValue, double distShape, int totalTrades)
{
   if (!MQLInfoInteger(MQL_OPTIMIZATION)) return;

   int filehandle=FileOpen(OPTIMIZE_FILE,FILE_READ|FILE_WRITE|FILE_TXT);
      
   if(filehandle<0)
   {
      Print("Failed to open the file " + OPTIMIZE_FILE + " by the absolute path.");
      Print("Error code ",GetLastError());
   }

   if(filehandle!=INVALID_HANDLE)
   {
      FileSeek(filehandle,0,SEEK_END);
      
      //String fill para nivelar tabulaciones (usar espacios)
      
      double identifier = 0.0;
      int idDigits = 8;
      switch (optMode)
      {
         case N_WIN_RATE:
            identifier = winRate;
            break;
         
         case N_TOTAL_PIPS:
            idDigits = 0;
            identifier = finalProfit;
            break;
            
         case N_TOTAL_PROFIT:
            idDigits = 2;
            identifier = finalProfit;
            break;
         
         case N_DRAWDOWN:
            identifier = drawdown;
            break;
            
         case N_PROFIT_FACTOR:
            identifier = profitFactor;
            break;
            
         case N_EXP_PAYOFF:
            identifier = expectedPayoff;
            break;
            
         case N_DIST_VALUE:
            identifier = distValue;
            break;
            
         case N_DIST_SHAPE:
            identifier = distShape;
            break;
            
         case N_EQUITY_COMP:
         case N_EQUITY_CURVE:
            identifier = finalProfit;
            break;
            
         case N_ROI:
            identifier = roi;
            break;
      }
      
      
      //Procesar archivo con python
      string content =  DoubleToString(identifier, idDigits) + "\t" + 
                        DoubleToString(winRate, 2) + "\t" + 
                        IntegerToString(totalTrades) + "\t" +
                        DoubleToString(finalProfit, optMode==N_TOTAL_PIPS?0:2) + "\t" + 
                        DoubleToString(drawdown, 2) + "\t" + 
                        DoubleToString(roi, 2) + "\t" + 
                        DoubleToString(profitFactor, 2) + "\t" + 
                        DoubleToString(expectedPayoff, 2) + "\t" + 
                        DoubleToString(distValue, 2) + "\t" + 
                        DoubleToString(distShape, 5);

                       
      FileWrite(filehandle, content);
      FileFlush(filehandle);
      FileClose(filehandle);
      /*
      double data[]={ identifier, winRate, finalProfit, drawdown, roi, profitFactor, expectedPayoff, distValue, distShape };
      
      FrameAdd("testframe", 0, identifier, data);
      */
   }
}

void CalculateGeneralStats(int &nWins, int &nLoses, double &gWin, double &gLoss, double &Win_Rate, double &Profit_Factor, double &Expected_Payoff)
{
   CalculateWinRate(nLoses, nWins, Win_Rate);
   CalculateProfitFactor(gWin, gLoss, Profit_Factor);
   CalculateExpectedPayoff(gWin+gLoss, nWins+nLoses, Expected_Payoff);
}


void CalculateProfitFactor(double grossWin, double grossLoss, double &Profit_Factor)
{
   Profit_Factor = grossLoss==0.0?999.99:MathMin(999.99, grossWin / (-grossLoss));
}
void CalculateWinRate(int &totalLoses, int &totalWins, double &Win_Rate)
{
   Win_Rate = (totalLoses+totalWins)>0?100.0*totalWins/(totalLoses+totalWins):50.0;
}
void CalculateExpectedPayoff(double netProfit, int totalTrades, double &Expected_Payoff)
{
   Expected_Payoff = totalTrades>0 ? netProfit / totalTrades : 0.0;
}

void CalculateReturnOnInvestment(double percent_roi, double years, bool isCompound, double &Roi)
{
   if (isCompound)
   {
      Roi = MathPow(1.0 + percent_roi, 1.0 / years) - 1.0;
   }
   else
   {
      if (years != 0.0) Roi = percent_roi / years;
      else Roi = percent_roi;
   }
   
   Roi *= 100.0;
}


void CalculateStatistics(double statStep, int maxIndex, int minIndex, int &statsArray[], double &Stats_Shape, double &Stats_Value)
{
   Stats_Shape = 0.0;
   Stats_Value = 0.0;
   
   int totalTrades = 0;
   
   for (int d=0; d < maxIndex - minIndex + 1; d++)
   {
      int index = d + minIndex;
   
      double currentAmount = index * statStep;
      Stats_Value += (currentAmount * statsArray[d]);
      
      double currentScore = index <= 10 ? index/10.0 : MathLog10(10 + (index-10.0)*2);
      if (index <= 10)
      {
         Stats_Shape += (currentScore * (statsArray[d]+1));
         totalTrades += (statsArray[d]+1);
         
      }
      else
      {
         Stats_Shape += (currentScore * statsArray[d]);
         totalTrades += statsArray[d];
         
      }
      
   }
   
   Stats_Shape *= 100.0;
   
   if (totalTrades > 0)
      Stats_Shape /= totalTrades;
      
}

void PrintStatsSummary(double statStep, int maxIndex, int minIndex, int &statsArray[], double distShape, double distValue)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;
   
   Print(SEPARATOR_LINE);
   Print("          DISTRIBUTION          ");
   Print(SEPARATOR_LINE);
   
   for (int d=0; d < maxIndex - minIndex + 1; d++)
   {
      double currentAmount = (d+minIndex)*statStep;
      
      Print(DoubleToString(currentAmount, 0), " = ", IntegerToString(statsArray[d]));
   }
   
   Print(SEPARATOR_LINE);
   Print("Distribution Value (Absolute): ", DoubleToString(distValue, 2));
   Print("Distribution Shape Score: ", DoubleToString(distShape, 4));
   Print(SEPARATOR_LINE);
}

void NormalizeString(string &inputString, int totalSpaces)
{
   int length = StringLen(inputString);
   
   if (length > totalSpaces){ inputString = inputString + " "; return;}
   
   inputString = inputString + StringSpaces(totalSpaces - length);
}

string StringSpaces(int num)
{
   string x = "";
   
   for (int i=0; i<num; i++)
      x = x + " ";
      
   return x;
}

void WriteEquity(datetime time, double equity)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;
   
   int filehandle=FileOpen(EQUITY_FILE,FILE_READ|FILE_WRITE|FILE_TXT|FILE_COMMON);
   
   if(filehandle!=INVALID_HANDLE)
   {
      FileSeek(filehandle,0,SEEK_END); 
             
      FileWrite(filehandle, TimeToString(time) + "\t"+DoubleToString(equity, 2));
      FileFlush(filehandle);
      FileClose(filehandle);
   }
}

void WriteInJournal(datetime time, string symbol, double profit, string event)
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;
   
   int filehandle=FileOpen(JOURNAL_FILE,FILE_READ|FILE_WRITE|FILE_TXT|FILE_COMMON);
      
   if(filehandle<0)
   {
      Print("Failed to open the file " + JOURNAL_FILE + " by the absolute path.");
      Print("Error code ",GetLastError());
   }

   if(filehandle!=INVALID_HANDLE)
   {
      FileSeek(filehandle,0,SEEK_END);
      
      
      FileWrite(filehandle, TimeToString(time) + "\t" + symbol + "\t" + event + "\t" + DoubleToString(profit, 2));
      
      FileFlush(filehandle);
      FileClose(filehandle);
   }
}

void WriteDistributionFile(double statStep, int maxIndex, int minIndex, int &statsArray[])
{
   if (MQLInfoInteger(MQL_OPTIMIZATION)) return;

   int filehandle = FileOpen(DISTRIBUTION_FILE,FILE_WRITE|FILE_TXT|FILE_COMMON);
   
   if(filehandle<0)
   {
      Print("Failed to open the file " + DISTRIBUTION_FILE + " by the absolute path.");
      Print("Error code ",GetLastError());
   }

   if(filehandle!=INVALID_HANDLE)
   {
      string toWrite = "";
      int d;
      for (d=0; d < maxIndex - minIndex + 1; d++)
      {
         double currentAmount = (d+minIndex)*statStep;
         
         toWrite = toWrite + DoubleToString(currentAmount, 0) + "\t";
      }
      
      FileWrite(filehandle, toWrite);
      toWrite = "";
      
      for (d=0; d < maxIndex - minIndex + 1; d++)
      {
         toWrite = toWrite + IntegerToString(statsArray[d]) + "\t";
      }
      
      FileWrite(filehandle, toWrite);
      FileFlush(filehandle);
      FileClose(filehandle);
   }

   Print("Distribution file \"" + DISTRIBUTION_FILE +  "\" saved in directory " + TerminalInfoString(TERMINAL_COMMONDATA_PATH));
}

void ClearEquityFile()
{
   ClearFile(EQUITY_FILE);
}

void ClearJournalFile()
{
   ClearFile(JOURNAL_FILE);
}

void ClearFile(string file)
{
   int filehandle=FileOpen(file,FILE_WRITE|FILE_TXT|FILE_COMMON);
   
   if(filehandle!=INVALID_HANDLE)
   {
      FileClose(filehandle);
   }
}

double EvaluateCustomOptimization(string custom_func, CDictionary* variables)
{
	return CReversePolishNotation::EvaluateInfixString(custom_func, variables);
}