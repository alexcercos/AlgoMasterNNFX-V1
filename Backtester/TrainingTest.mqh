#include "Backtester.mqh"

#define MAX_DATETIME 32535244799

class TrainingTestBacktester : public Backtester
{
protected:
   datetime testDatetime;
   
   double grossTestWinArray[], grossTestLossArray[]; //Amount
   int totalTestWinsArray[], totalTestLosesArray[];  //Number
   
   
   virtual void AddProfits(double amount);
   
public: 
   TrainingTestBacktester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false, datetime testDate=MAX_DATETIME);
   ~TrainingTestBacktester();
   
   virtual double TesterResult(int optimization_mode, int write_to_file);
   
};

TrainingTestBacktester::TrainingTestBacktester(double trade_value,string &symbolsArray[],bool pullback,bool one_candle,bool bridge_tf,bool scale_out,bool draw_arrows=true,bool debug_trades=false,bool debug_virtual_trades=false,bool result_in_pips=false,bool use_main_exit=false,datetime testDate=MAX_DATETIME)
         :Backtester(trade_value, symbolsArray, pullback, one_candle, bridge_tf, scale_out, draw_arrows, debug_trades, debug_virtual_trades, result_in_pips, use_main_exit)
{
   testDatetime = testDate;
   
   ArrayResize(grossTestWinArray, totalSymbols);
   ArrayFill(grossTestWinArray, 0, totalSymbols, 0.0);
   
   ArrayResize(grossTestLossArray, totalSymbols);
   ArrayFill(grossTestLossArray, 0, totalSymbols, 0.0);
   
   ArrayResize(totalTestWinsArray, totalSymbols);
   ArrayFill(totalTestWinsArray, 0, totalSymbols, 0);
   
   ArrayResize(totalTestLosesArray, totalSymbols);
   ArrayFill(totalTestLosesArray, 0, totalSymbols, 0);
}

TrainingTestBacktester::~TrainingTestBacktester(void)
{
}

void TrainingTestBacktester::AddProfits(double amount)
{
   if (amount>0)
   {
      if (TimeCurrent()<testDatetime)
      {
         grossWinArray[activeSymbol] += amount;
         
         totalWinsArray[activeSymbol] += 1;
      }
      else //Test group
      {
         grossTestWinArray[activeSymbol] += amount;
         
         totalTestWinsArray[activeSymbol] += 1;
      }
   }
   else if (amount < 0)
   {
      if (TimeCurrent()<testDatetime)
      {
         grossLossArray[activeSymbol] += amount;
         
         totalLosesArray[activeSymbol] += 1;
      }
      else
      {
         grossTestLossArray[activeSymbol] += amount;
         
         totalTestLosesArray[activeSymbol] += 1;
      }
   }
}

double TrainingTestBacktester::TesterResult(int optimization_mode, int write_to_file)
{
   double pfLimit = 5.0;
   
   double bestMin = grossWinArray[0]+grossLossArray[0];
   
   double bestMinTest = grossTestWinArray[0]+grossTestLossArray[0];
   
   double grossW = 0.0, grossL = 0.0;
   double grossWTest = 0.0, grossLTest = 0.0;
   
   int numberOfTrades = 0;
   int numberOfTradesTest = 0;
         
   for (int i = 0; i < totalSymbols; i++)
   {
      grossW += grossWinArray[i];
      grossWTest += grossTestWinArray[i];
      
      grossL += grossLossArray[i];
      grossLTest += grossTestLossArray[i];
      
      numberOfTrades += totalLosesArray[i] + totalWinsArray[i];
      numberOfTradesTest += totalTestLosesArray[i] + totalTestWinsArray[i];
      
      bestMin = MathMin(grossWinArray[i]+grossLossArray[i], bestMin);
      bestMinTest = MathMin(grossTestWinArray[i]+grossTestLossArray[i], bestMinTest);
      
      Print (symbolsToTrade[i] + ": " + DoubleToString(grossWinArray[i], 2) + "  " + 
                                       DoubleToString(grossLossArray[i], 2) + 
                                       "     Wins = " + IntegerToString(totalWinsArray[i]) + 
                                       " , Lose = " + IntegerToString(totalLosesArray[i]) +
                                       " ; TEST: " + DoubleToString(grossTestWinArray[i], 2) + "  " + 
                                       DoubleToString(grossTestLossArray[i], 2) + 
                                       "     Wins = " + IntegerToString(totalTestWinsArray[i]) + 
                                       " , Lose = " + IntegerToString(totalTestLosesArray[i])
                                       );
   }
   
   
   double profitFactor, profitFactorTest;
   
   if (grossL == 0)
   {
      profitFactor = 1.0 + grossW / 10000.0;
   }
   else
   {
      profitFactor = grossW / (-grossL);
   }
   
   if (grossLTest == 0)
   {
      profitFactorTest = 1.0 + grossWTest / 10000.0;
   }
   else
   {
      profitFactorTest = grossWTest / (-grossLTest);
   }
      
   double finalValue = grossW + grossL;
   double finalValueTest = grossWTest + grossLTest;
   
   Print("Profit factor: " + DoubleToString(profitFactor, 2));
   Print("Balance: " + DoubleToString(finalValue, 2));
   Print("Minimum: " + DoubleToString(bestMin, 2));
   Print("Total trades: " + IntegerToString(numberOfTrades));
   Print("TEST Profit factor: " + DoubleToString(profitFactorTest, 2));
   Print("TEST Balance: " + DoubleToString(finalValueTest, 2));
   Print("TEST Minimum: " + DoubleToString(bestMinTest, 2));
   Print("TEST Total trades: " + IntegerToString(numberOfTradesTest));
   
   double returnValue = 0;
   
   switch(optimization_mode)
   {
      case TOTAL_PROFIT:
         returnValue = finalValue;
         break;
      
      case BEST_MINIMUM:
         returnValue = bestMin;
         break;
         
      case AVG_MIN_TOTAL:
      {
         double minimum = grossWinArray[0]+grossLossArray[0];
         double average = 0.0;
         for (int i = 0; i < totalSymbols; i++)
         {
            average += grossWinArray[i] + grossLossArray[i];
            
            minimum = MathMin(grossWinArray[i]+grossLossArray[i], minimum);
         }
         
         average = average/totalSymbols;
         

         if (finalValue == 0) return -100000;
         
         double pfSigmoid = 1.0 / (1.0 + MathExp(-profitFactor));
         
         returnValue = pfSigmoid * totalSymbols * (average + minimum) / 2.0;
         break;
      }
      case PROFIT_FACTOR_MOD:
         returnValue = AccountInfoDouble(ACCOUNT_BALANCE) * (grossW + AccountInfoDouble(ACCOUNT_BALANCE)) / (AccountInfoDouble(ACCOUNT_BALANCE)-grossL) - AccountInfoDouble(ACCOUNT_BALANCE);
         break;
      
      case MIN_PROFITFACTOR:
      {
         double minPF = profitFactor;
         for (int i = 0; i < totalSymbols; i++)
         {
            double gw = grossWinArray[i];
            double gl = -grossLossArray[i];
            
            if (gl > 0)
            {
               minPF = MathMin(minPF, gw/gl);
            }
            else
            {
               minPF = MathMin(minPF, 1.0 + gw / 10000.0);
            }
         }
         returnValue = MathMin(minPF, pfLimit);
         break;
      }
      case PF_SQ_PER_W:
         if (finalValue == 0) return -40000;
         returnValue = MathMin(pfLimit, profitFactor) * (1 + MathLog(1.0+profitFactor)) * finalValue;
         break;
   }
   
   if (write_to_file == OPTIMIZE)
   {
      int filehandle=FileOpen("OPT_DATA.txt",FILE_READ|FILE_WRITE|FILE_TXT);
      
      if(filehandle<0)
      {
         Print("Failed to open the file by the absolute path ");
         Print("Error code ",GetLastError());
      }
   
      if(filehandle!=INVALID_HANDLE)
      {
         FileSeek(filehandle,0,SEEK_END); 
         
         //String fill para nivelar tabulaciones (usar espacios)
         //Procesar archivo con python
         
         string content = DoubleToString(finalValue, 0) + "\t" + 
                          DoubleToString(bestMin, 0) + "\t" + 
                          DoubleToString(profitFactor, 2) + "\t" + 
                          DoubleToString(returnValue, 2) + "\t" + 
                          DoubleToString(finalValueTest, 0) + "\t" + 
                          DoubleToString(bestMinTest, 0) + "\t" + 
                          DoubleToString(profitFactorTest, 2);
                          
         FileWrite(filehandle, content);
         FileFlush(filehandle);
         FileClose(filehandle);
      }
   }
   else if (write_to_file == SUMMARY)
   {
      int filehandle=FileOpen("SUMMARY.txt",FILE_WRITE|FILE_TXT);
      
      if(filehandle<0)
      {
         Print("Failed to open the file by the absolute path ");
         Print("Error code ",GetLastError());
      }
   
      if(filehandle!=INVALID_HANDLE)
      {
         string toWrite = "";
         if (scaleOut)
         {
            for (int i = 0; i < totalSymbols; i++)
            {
               toWrite = toWrite + DoubleToString(grossWinArray[i]+grossLossArray[i], 0) + "\t";
            }
            
            for (int i = 0; i < totalSymbols; i++)
            {
               if (grossLossArray[i] == 0)
               {
                  if (grossWinArray[i] == 0)
                  {
                     toWrite = toWrite + DoubleToString(1.0, 2) + "\t";
                  }
                  else
                  {
                     toWrite = toWrite + DoubleToString(999.99, 2) + "\t";
                  }
               }
               else
               {
                  toWrite = toWrite + DoubleToString(grossWinArray[i]/(-grossLossArray[i]), 2) + "\t";
               }
            }
            
            
            for (int i = 0; i < totalSymbols; i++)
            {
               toWrite = toWrite + DoubleToString(grossTestWinArray[i]+grossTestLossArray[i], 0) + "\t";
            }
            
            for (int i = 0; i < totalSymbols; i++)
            {
               if (grossTestLossArray[i] == 0)
               {
                  if (grossTestWinArray[i] == 0)
                  {
                     toWrite = toWrite + DoubleToString(1.0, 2) + "\t";
                  }
                  else
                  {
                     toWrite = toWrite + DoubleToString(999.99, 2) + "\t";
                  }
               }
               else
               {
                  toWrite = toWrite + DoubleToString(grossTestWinArray[i]/(-grossTestLossArray[i]), 2) + "\t";
               }
            }
            
            
            FileWrite(filehandle, toWrite);
            
            FileWrite(filehandle, IntegerToString(numberOfTrades) + "\t" + DoubleToString(profitFactor, 2) + "\t" + IntegerToString(numberOfTradesTest) + "\t" + DoubleToString(profitFactorTest, 2));
         }
         else
         {
            for (int i = 0; i < totalSymbols; i++)
            {
               toWrite = toWrite + IntegerToString(totalWinsArray[i]) + "\t";
            }
            for (int i = 0; i < totalSymbols; i++)
            {
               toWrite = toWrite + IntegerToString(totalLosesArray[i]) + "\t";
            }
            
            FileWrite(filehandle, toWrite);
         }
         
         FileFlush(filehandle);
         FileClose(filehandle);
      }
   }
   
   return returnValue;
}