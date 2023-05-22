#include "Backtester.mqh"

#define OPT_STEP 5000

class StatisticalBacktester : public Backtester
{
protected:

   datetime initTime;
   datetime endTime;
   
   int optimizationStep;
   
   datetime interval;
   int numberOfPeriods;
   int currentPeriod;
   
   double statsArrayWins[]; // Array 2 dimensiones, row * numCols + col
   double statsArrayLoss[];

   virtual void AddProfits(double amount);
   
   double Sigmoid(double num, bool zeroLimit=false);
   virtual double RewardSystem(double amount, int times);
   

public: 
   StatisticalBacktester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false);
   ~StatisticalBacktester();
   
   void SetStatisticParameters(datetime init, datetime end, int periods, int step=OPT_STEP);
   
   virtual void BacktesterTick();
   virtual double TesterResult(int optimization_mode, int write_to_file);
   
};

void StatisticalBacktester::StatisticalBacktester(double trade_value, string &symbolsArray[], bool pullback, bool one_candle, bool bridge_tf, bool scale_out, bool draw_arrows=true, bool debug_trades=false, bool debug_virtual_trades=false, bool result_in_pips=false, bool use_main_exit=false)
         :Backtester(trade_value, symbolsArray, pullback, one_candle, bridge_tf, scale_out, draw_arrows, debug_trades, debug_virtual_trades, result_in_pips, use_main_exit)
{
   
}

void StatisticalBacktester::~StatisticalBacktester()
{
   
}

void StatisticalBacktester::SetStatisticParameters(datetime init,datetime end,int periods, int step=OPT_STEP)
{
   initTime = init;
   endTime = end;
   numberOfPeriods = periods;
   currentPeriod = 0;
   interval = (endTime - initTime)/periods;
   optimizationStep = step;
   
   ArrayResize(statsArrayWins, totalSymbols * numberOfPeriods);
   ArrayInitialize(statsArrayWins, 0.0);
   
   ArrayResize(statsArrayLoss, totalSymbols * numberOfPeriods);
   ArrayInitialize(statsArrayLoss, 0.0);
}

void StatisticalBacktester::AddProfits(double amount)
{
   Backtester::AddProfits(amount);

   if (amount > 0)
   {
      statsArrayWins[activeSymbol * numberOfPeriods + currentPeriod] += amount;
   }
   else
   {
      statsArrayLoss[activeSymbol * numberOfPeriods + currentPeriod] += amount;
   }
}

void StatisticalBacktester::BacktesterTick()
{
   //cambiar periodo
   if (TimeCurrent()>=initTime + interval*currentPeriod) currentPeriod = MathMin(numberOfPeriods-1, currentPeriod+1);
   
   Backtester::BacktesterTick();
}

double StatisticalBacktester::TesterResult(int optimization_mode,int write_to_file)
{
   double finalReward = 0.0;
   
   if (optimization_mode!=DISTRIBUTION_VALUE && optimization_mode!=EXPECTED_D_VALUE && optimization_mode!=DIST_V_PF)
   {
      finalReward = Backtester::TesterResult(optimization_mode, write_to_file);
   }
   else
   {
      double id = Backtester::TesterResult(TOTAL_PROFIT, write_to_file);
      
      for (int i=0; i<numberOfPeriods*totalSymbols; i++) //Juntar arrays
      {
         statsArrayWins[i] += statsArrayLoss[i];
      }
      
      int minimum = (int)statsArrayWins[ArrayMinimum(statsArrayWins)];
      int maximum = (int)statsArrayWins[ArrayMaximum(statsArrayWins)];
      
      if (minimum < 0) minimum -=optimizationStep;
      if (maximum < 0) maximum -=optimizationStep;
      if (minimum > 0) minimum +=optimizationStep;
      if (maximum > 0) maximum +=optimizationStep;
      
      minimum /=optimizationStep;
      maximum /=optimizationStep;
      
      int size = maximum - minimum + 1;
      
      int distributionArray[];
      ArrayResize(distributionArray, size);
      ArrayInitialize(distributionArray, 0);
      
      for (int i=0; i<numberOfPeriods*totalSymbols; i++)
      {
         int current = (int)statsArrayWins[i];
         if (current < 0) current -=optimizationStep;
         if (current > 0) current +=optimizationStep;
         
         current/=optimizationStep;
         
         int index = current - minimum;
         
         distributionArray[index]++;
      }
      
      double expectedReturn = 0.0;
      
      double expectedPositive = 0.0;
      double expectedNegative = 0.0;
   
      for (int d=0; d<size; d++)
      {
         double rew = RewardSystem((d+minimum)*optimizationStep, distributionArray[d]);
         finalReward+=rew;
         expectedReturn += ((d+minimum)*optimizationStep) * distributionArray[d];
         
         if ((d+minimum)*optimizationStep>0)
            expectedPositive += ((d+minimum)*optimizationStep) * distributionArray[d];
         else
            expectedNegative += ((d+minimum)*optimizationStep) * distributionArray[d];
         
         Print(IntegerToString((d+minimum)*optimizationStep) + " " + IntegerToString(distributionArray[d]) + " " + DoubleToString(rew, 2));
      }
      
      expectedReturn /= (totalSymbols * numberOfPeriods);
      
      Print("Valoration: " + DoubleToString(finalReward, 2));
      Print("Total Profit: " + DoubleToString(id, 2));
      Print("Expected Return: " + DoubleToString(expectedReturn, 2));
      
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
                              IntegerToString(minimum*optimizationStep) + "\t" + 
                              IntegerToString(maximum*optimizationStep);
                             
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
            
               for (int d=0; d<size; d++)
               {
                  
                  int amount = (d+minimum)*optimizationStep;
                  
                  content += IntegerToString(amount) + "\t";
                  
                  if (amount<0)
                  {
                     content += "0\t0\t" + IntegerToString(distributionArray[d]) + "\n";
                  }
                  else if (amount>0)
                  {
                     content += IntegerToString(distributionArray[d]) + "\t0\t0\n";
                  }
                  else
                  {
                     content += "0\t" + IntegerToString(distributionArray[d]) + "\t0\n";
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
      else if (optimization_mode == DIST_V_PF)
      {
         if (finalReward>0)
         {
            double PFreward = 1.0;
            if (expectedNegative < 0) PFreward = Sigmoid(expectedPositive/MathMax(-expectedNegative, 10000.0), true);
            
            return finalReward * PFreward;
         }
      }
   }
   return finalReward;
}

double StatisticalBacktester::Sigmoid(double num, bool zeroLimit=false) //0, 1
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

double StatisticalBacktester::RewardSystem(double amount, int times)
{
   double factor = 1.0 - Sigmoid(amount/100000.0)/4.0;
   
   //Print(factor);
   
   return factor * amount * times;
}