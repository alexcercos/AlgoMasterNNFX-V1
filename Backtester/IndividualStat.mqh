#include "Backtester.mqh"

#define OPT_STEP 1000

class IndStatBacktester : public Backtester
{
protected:
   
   int statsArray[];
   
   int maxIndex, minIndex;

   virtual void AddProfits(double amount);
   
   double Sigmoid(double num, bool zeroLimit=false);
   virtual double RewardSystem(double amount, int times);
   

public: 
   IndStatBacktester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false);
   ~IndStatBacktester();
   
   virtual double TesterResult(int optimization_mode, int write_to_file);
};

void IndStatBacktester::IndStatBacktester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false)
         :Backtester(trade_value, symbolsArray, pullback, one_candle, bridge_tf, scale_out, draw_arrows, debug_trades, debug_virtual_trades, result_in_pips, use_main_exit)
{
   minIndex = -10;
   maxIndex = 0;
   
   ArrayResize(statsArray, maxIndex - minIndex + 1);
   ArrayInitialize(statsArray, 0);
}

void IndStatBacktester::~IndStatBacktester()
{

}


void IndStatBacktester::AddProfits(double amount)
{
   Backtester::AddProfits(amount);
   
   if (amount == 0.0) return;
   
   int current = (int)MathRound(amount / 1000.0);
   
   if (current > maxIndex)
   {
      ArrayResize(statsArray, current - minIndex + 1);
      ArrayFill(statsArray, maxIndex - minIndex, current - maxIndex+1, 0);
      maxIndex = current;
   }
   //Print(current, " ", minIndex, " ", maxIndex);
   statsArray[current - minIndex] += 1;
}

double IndStatBacktester::TesterResult(int optimization_mode,int write_to_file)
{
   double finalReward = 0.0;
   
   if (optimization_mode!=DISTRIBUTION_VALUE && optimization_mode!=EXPECTED_D_VALUE && optimization_mode!=DIST_V_PF)
   {
      finalReward = Backtester::TesterResult(optimization_mode, write_to_file);
   }
   else //DISTRIBUTION_VALUE  O  EXPECTED_D_VALUE
   {
      double id = Backtester::TesterResult(TOTAL_PROFIT, write_to_file);
      
      double expectedReturn = 0.0;
      
      double expectedPositive = 0.0;
      double expectedNegative = 0.0;
      
      int totalTrades = 0;
   
      for (int d=0; d < maxIndex - minIndex + 1; d++)
      {
         double currentAmount = (d+minIndex)*OPT_STEP;
         double rew = RewardSystem(currentAmount, statsArray[d]);
         finalReward+=rew;
         expectedReturn += (currentAmount * statsArray[d]);
         
         if (currentAmount>0)
            expectedPositive += (currentAmount * statsArray[d]);
         else
            expectedNegative += (currentAmount * statsArray[d]);
         
         totalTrades += statsArray[d];
         Print(DoubleToString(currentAmount, 0) + " " + IntegerToString(statsArray[d]) + " " + DoubleToString(rew, 2));
      }
      
      if (totalTrades > 0)
         expectedReturn /= totalTrades;
      
      Print("Valoration: " + DoubleToString(finalReward, 2));
      Print("Total Profit: " + DoubleToString(id, 2));
      Print("Expected Return: " + DoubleToString(expectedReturn, 2));
      
      if (optimization_mode == DIST_V_PF)
      {
         if (finalReward>0)
         {
            double PFreward = Sigmoid(expectedPositive/(MathMax(-expectedNegative, 100000.0)), true);
            
            finalReward = finalReward * PFreward;
         }
      }
      
      if (write_to_file == OPTIMIZE)
      {
         int filehandle=FileOpen("OPTDIST_DATA.txt",FILE_READ|FILE_WRITE|FILE_TXT);
         
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
            
            string content = DoubleToString(finalReward, 2) + "\t" + 
                              DoubleToString(id, 2) + "\t" + 
                              DoubleToString(expectedReturn, 2) + "\t" + 
                              IntegerToString(minIndex*OPT_STEP) + "\t" + 
                              IntegerToString(maxIndex*OPT_STEP);
                             
            FileWrite(filehandle, content);
            FileFlush(filehandle);
            FileClose(filehandle);
         }
      }
      else if (write_to_file == SUMMARY)
      {
         int filehandle=FileOpen("DIST_SUMMARY.txt",FILE_WRITE|FILE_TXT);
         
         if(filehandle<0)
         {
            Print("Failed to open the file by the absolute path ");
            Print("Error code ",GetLastError());
         }
      
         if(filehandle!=INVALID_HANDLE)
         {
            
            //String fill para nivelar tabulaciones (usar espacios)
            //Procesar archivo con python
            
            string content = "";
            
               for (int d=0; d < maxIndex - minIndex + 1; d++)
               {
                  
                  int amount = (d+minIndex)*OPT_STEP;
                  
                  content += IntegerToString(amount) + "\t";
                  
                  if (amount<0)
                  {
                     content += "0\t0\t" + IntegerToString(statsArray[d]) + "\n";
                  }
                  else if (amount>0)
                  {
                     content += IntegerToString(statsArray[d]) + "\t0\t0\n";
                  }
                  else
                  {
                     content += "0\t" + IntegerToString(statsArray[d]) + "\t0\n";
                  }
               }
                             
            FileWrite(filehandle, content);
            FileWrite(filehandle, DoubleToString(finalReward, 2) + "\t" + DoubleToString(expectedReturn, 2));
            FileFlush(filehandle);
            FileClose(filehandle);
         }
      }
      
      if (optimization_mode == EXPECTED_D_VALUE)
      {
         return expectedReturn;
      }
   }

   return finalReward;
}

double IndStatBacktester::Sigmoid(double num, bool zeroLimit=false) //0, 1
{
   double expP = MathExp(num);
   double expN = MathExp(-num);
   
   if (expN == 0) return 1;
   
   double res = (expP - expN)/(expP + expN);
   
   if (zeroLimit)
      return (res+1.0)/2.0;
   else
      return res;
}

double IndStatBacktester::RewardSystem(double amount, int times)
{
   double factor = 1.0 - Sigmoid(amount/100000.0)/4.0;
   
   //Print(factor);
   
   return factor * amount * times;
}