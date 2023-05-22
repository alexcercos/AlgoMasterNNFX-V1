#undef IS_NATIVE_IND
#define IS_NATIVE_IND(indicator) indicator[0] == '<' && indicator[StringLen(indicator)-1] == '>'

string StringToLow(string str)
{
   StringToLower(str);
   return str;
}

#include "..\Other\Dictionary.mqh"


#define GET_OPT_RES \
	if (!opt_var.Get<double>(parameter, res)) \
   	Print(" -ERROR: Unrecognised Optimization Variable: ", parameter);

double ParseStringToDouble(string parameter, CDictionary* opt_var=NULL)
{
	TRIM_STRING_LEFT(parameter);
   TRIM_STRING_RIGHT(parameter);
      
	if (opt_var!=NULL && parameter[0]=='#')
	{
		int last = parameter[StringLen(parameter)-1];
   	double res=0.0;
   	if (last < '0' || last > '9')
   	{
   		parameter = StringSubstr(parameter, 0, StringLen(parameter)-1);
   	}
   	
   	GET_OPT_RES
   	return res;
	}
	return StringToDouble(parameter);
}

#ifdef __MQL5__

   MqlParam ParseParameter(string parameter, CDictionary* opt_var=NULL)
   {
      TRIM_STRING_LEFT(parameter);
   	TRIM_STRING_RIGHT(parameter);
   
      MqlParam struct_param;
      
      if (opt_var!=NULL && parameter[0]=='#')
      {
      	int last = parameter[StringLen(parameter)-1];
      	double res=0.0;
      	if (last == 'b')
      	{
      		parameter = StringSubstr(parameter, 0, StringLen(parameter)-1);
      		
      		GET_OPT_RES
      		
      		struct_param.type = TYPE_BOOL;
      		struct_param.integer_value = bool(res);
      	}
      	else if (last == 'i')
      	{
      		parameter = StringSubstr(parameter, 0, StringLen(parameter)-1);
      		
      		GET_OPT_RES
      		
      		struct_param.type = TYPE_INT;
      		struct_param.integer_value = int(res);
      	}
      	else if (last == 'd')
      	{
      		parameter = StringSubstr(parameter, 0, StringLen(parameter)-1);
      		
      		GET_OPT_RES
      		
      		struct_param.type = TYPE_DOUBLE;
      		struct_param.double_value = res;
      	}
      	else //Will fail with other letters
      	{
      		GET_OPT_RES
      		
      		struct_param.type = TYPE_DOUBLE;
      		struct_param.double_value = res;
      	}
      }
      else if (parameter[0] == '\"' && parameter[StringLen(parameter)-1] == '\"')
      {
         parameter = StringSubstr(parameter, 1, StringLen(parameter)-2);
         //StringReplace(parameter, "\"", "");
         
         struct_param.type = TYPE_STRING;
         struct_param.string_value = parameter;
      }
      else if (StringFind(parameter, ".") != -1)
      {
         double num = StringToDouble(parameter);
         
         struct_param.type = TYPE_DOUBLE;
         struct_param.double_value = num;
      }
      else if (StringToLow(parameter) == "true")
      {
         struct_param.type = TYPE_BOOL;
         struct_param.integer_value = true;
      }
      else if (StringToLow(parameter) == "false")
      {
         struct_param.type = TYPE_BOOL;
         struct_param.integer_value = false;
      }
      else
      {
         long num = StringToInteger(parameter);
         
         struct_param.type = TYPE_LONG;
         struct_param.integer_value = num;
      }
      
      
      return struct_param;
   }
   
   
   int GetIndicatorWithParameters(string symbol, MqlParam &parameters[], bool isNative=false, string indicator_name=NULL, ENUM_TIMEFRAMES period=PERIOD_CURRENT)
   {
      int total = ArraySize(parameters);
      
      if (isNative)
      {
         return CreateNativeIndicator(symbol, parameters, indicator_name, period);
      }
      else
      {
         return IndicatorCreate(symbol, period, IND_CUSTOM, total, parameters);
      }
   }
   
   void ProcessParameters(string indicator_name, string param_string, MqlParam &processed[], CDictionary* opt_dict=NULL)
   {
      string params[];
      StringSplit(param_string, ',', params);
   
      int total = ArraySize(params);
      
      ArrayResize(processed, total+1);
      
      processed[0].type = TYPE_STRING;
      processed[0].string_value = indicator_name;
      
      if (IS_NATIVE_IND(indicator_name))
      {
         PreProcessNativeParameters(processed);
         
         
         for (int i=1; i<=total; i++) //Substitute from parameters
            SubstituteOptimizationParameter(params[i-1], i, processed, opt_dict);
         
      }
      else
      {
         for (int i=1; i<=total; i++)
         {
            processed[i] = ParseParameter(params[i-1], opt_dict);
         }
      }
   }
   
   void ProcessParameters(string indicator_name, MqlParam &processed[])
   {
      ArrayResize(processed, 1);
      
      processed[0].type = TYPE_STRING;
      processed[0].string_value = indicator_name;
   }
   
   void SubstituteOptimizationParameter(string newParameter, int index, MqlParam &paramArray[], CDictionary* opt_dict=NULL)
   {
      if (index <= 0) return;
      if (index >= ArraySize(paramArray)) return;
      
      double d_param = ParseStringToDouble(newParameter, opt_dict);
      
      if (paramArray[index].type == TYPE_INT)
      {
         paramArray[index].integer_value = (int)d_param;
      }
      else if (paramArray[index].type == TYPE_LONG)
      {
         paramArray[index].integer_value = (long)d_param;
      }
      else if (paramArray[index].type == TYPE_DOUBLE)
      {
         paramArray[index].double_value = d_param;
      }
      else if (paramArray[index].type == TYPE_BOOL)
      {
         paramArray[index].integer_value = (bool)d_param;
      }
   }
   
   void PreProcessNativeParameters(MqlParam &processed[])
   {
      string indName = processed[0].string_value;
      
      if (indName == "<AMA>")
      {
         ArrayResize(processed, 6);
         processed[1].type = TYPE_INT;    //ama_period
         processed[1].integer_value = 9;
         processed[2].type = TYPE_INT;    //fast_ma_period
         processed[2].integer_value = 2;
         processed[3].type = TYPE_INT;    //slow_ma_period
         processed[3].integer_value = 30;
         processed[4].type = TYPE_INT;    //ama_shift
         processed[4].integer_value = 0;
         processed[5].type = TYPE_INT;    //applied_price
         processed[5].integer_value = PRICE_CLOSE;
         
         return;
      }
      if (indName == "<ADX>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //adx_period
         processed[1].integer_value = 14;
         
         return;
      }
      if (indName == "<ADXW>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //adx_period
         processed[1].integer_value = 14;
         
         return;
      }
      if (indName == "<BB>")
      {
         ArrayResize(processed, 5);
         processed[1].type = TYPE_INT;    //bands_period
         processed[1].integer_value = 20;
         processed[2].type = TYPE_INT;    //bands_shift
         processed[2].integer_value = 0;
         processed[3].type = TYPE_DOUBLE;    //deviation
         processed[3].integer_value = 2.0;
         processed[4].type = TYPE_INT;    //applied_price
         processed[4].integer_value = PRICE_CLOSE;
         
         return;
      }
      if (indName == "<DEMA>")
      {
         ArrayResize(processed, 4);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //ma_shift
         processed[2].integer_value = 0;
         processed[3].type = TYPE_INT;    //applied_price
         processed[3].integer_value = PRICE_CLOSE;
         
         return;
      }
      if (indName == "<ENVELOPES>")
      {
         ArrayResize(processed, 6);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //ma_shift
         processed[2].integer_value = 0;
         processed[3].type = TYPE_INT;    //ma_method
         processed[3].integer_value = MODE_SMA;
         processed[4].type = TYPE_INT;    //applied_price
         processed[4].integer_value = PRICE_CLOSE;
         processed[5].type = TYPE_DOUBLE;    //deviation
         processed[5].double_value = 0.1;
         
         return;
      }
      if (indName == "<FRAMA>")
      {
         ArrayResize(processed, 4);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //ma_shift
         processed[2].integer_value = 0;
         processed[3].type = TYPE_INT;    //applied_price
         processed[3].integer_value = PRICE_CLOSE;
      
         return;
      }
      if (indName == "<ICHIMOKU>")
      {
         ArrayResize(processed, 4);
         processed[1].type = TYPE_INT;    //tenkan_sen
         processed[1].integer_value = 9;
         processed[2].type = TYPE_INT;    //kijun_sen
         processed[2].integer_value = 26;
         processed[3].type = TYPE_INT;    //senkou_span_b
         processed[3].integer_value = 52;
         
         return;
      }
      if (indName == "<MA>")
      {
         ArrayResize(processed, 5);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 10;
         processed[2].type = TYPE_INT;    //ma_shift
         processed[2].integer_value = 0;
         processed[3].type = TYPE_INT;    //ma_method
         processed[3].integer_value = MODE_SMA;
         processed[4].type = TYPE_INT;    //applied_price
         processed[4].integer_value = PRICE_CLOSE;
         
         return;
      }
      if (indName == "<SAR>")
      {
         ArrayResize(processed, 3);
         processed[1].type = TYPE_DOUBLE;    //step
         processed[1].double_value = 0.02;
         processed[2].type = TYPE_DOUBLE;    //maximum
         processed[2].double_value = 0.2;
      
         return;
      }
      if (indName == "<STDEV>")
      {
         ArrayResize(processed, 5);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 20;
         processed[2].type = TYPE_INT;    //ma_shift
         processed[2].integer_value = 0;
         processed[3].type = TYPE_INT;    //ma_method
         processed[3].integer_value = MODE_SMA;
         processed[4].type = TYPE_INT;    //applied_price
         processed[4].integer_value = PRICE_CLOSE;
      
         return;
      }
      if (indName == "<TEMA>")
      {
         ArrayResize(processed, 4);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //ma_shift
         processed[2].integer_value = 0;
         processed[3].type = TYPE_INT;    //applied_price
         processed[3].integer_value = PRICE_CLOSE;
      
         return;
      }
      if (indName == "<VIDYA>")
      {
         ArrayResize(processed, 5);
         processed[1].type = TYPE_INT;    //cmo_period
         processed[1].integer_value = 9;
         processed[2].type = TYPE_INT;    //ema_period
         processed[2].integer_value = 12;
         processed[3].type = TYPE_INT;    //ma_shift
         processed[3].integer_value = 0;
         processed[4].type = TYPE_INT;    //applied_price
         processed[4].integer_value = PRICE_CLOSE;
         
         return;
      }
      
      if (indName == "<ATR>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         
         return;
      }
      if (indName == "<BEARS>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 13;
         
         return;
      }
      if (indName == "<BULLS>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 13;
      
         return;
      }
      if (indName == "<CHAIKIN>")
      {
         ArrayResize(processed, 5);
         processed[1].type = TYPE_INT;    //fast_ma_period
         processed[1].integer_value = 3;
         processed[2].type = TYPE_INT;    //slow_ma_period
         processed[2].integer_value = 10;
         processed[3].type = TYPE_INT;    //ma_method
         processed[3].integer_value = MODE_EMA;
         processed[4].type = TYPE_INT;    //applied_voulme
         processed[4].integer_value = VOLUME_TICK;
      
         return;
      }
      if (indName == "<CCI>")
      {
         ArrayResize(processed, 3);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //applied_price
         processed[2].integer_value = PRICE_TYPICAL;
         
         return;
      }
      if (indName == "<DEMARKER>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         
         return;
      }
      if (indName == "<FORCE>")
      {
         ArrayResize(processed, 4);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 13;
         processed[2].type = TYPE_INT;    //ma_method
         processed[2].integer_value = MODE_SMA;
         processed[3].type = TYPE_INT;    //applied_volume
         processed[3].integer_value = VOLUME_TICK;
      
         return;
      }
      if (indName == "<MACD>")
      {
         ArrayResize(processed, 5);
         processed[1].type = TYPE_INT;    //fast_ema_period
         processed[1].integer_value = 12;
         processed[2].type = TYPE_INT;    //slow_ema_period
         processed[2].integer_value = 26;
         processed[3].type = TYPE_INT;    //signal_period
         processed[3].integer_value = 9;
         processed[4].type = TYPE_INT;    //applied_price
         processed[4].integer_value = PRICE_CLOSE;
         
         return;
      }
      if (indName == "<MOMENTUM>")
      {
         ArrayResize(processed, 3);
         processed[1].type = TYPE_INT;    //mom_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //applied_price
         processed[2].integer_value = PRICE_CLOSE;
      
         return;
      }
      if (indName == "<OSMA>")
      {
         ArrayResize(processed, 5);
         processed[1].type = TYPE_INT;    //fast_ema_period
         processed[1].integer_value = 12;
         processed[2].type = TYPE_INT;    //slow_ema_period
         processed[2].integer_value = 26;
         processed[3].type = TYPE_INT;    //signal_period
         processed[3].integer_value = 9;
         processed[4].type = TYPE_INT;    //applied_price
         processed[4].integer_value = PRICE_CLOSE;
      
         return;
      }
      if (indName == "<RSI>")
      {
         ArrayResize(processed, 3);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //applied_price
         processed[2].integer_value = PRICE_CLOSE;
      
         return;
      }
      if (indName == "<RVI>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 10;
      
         return;
      }
      if (indName == "<STOCHASTIC>")
      {
         ArrayResize(processed, 6);
         processed[1].type = TYPE_INT;    //Kperiod
         processed[1].integer_value = 5;
         processed[2].type = TYPE_INT;    //Dperiod
         processed[2].integer_value = 3;
         processed[3].type = TYPE_INT;    //slowing
         processed[3].integer_value = 3;
         processed[4].type = TYPE_INT;    //ma_method
         processed[4].integer_value = MODE_SMA;
         processed[5].type = TYPE_INT;    //price_field
         processed[5].integer_value = STO_LOWHIGH;
      
         return;
      }
      if (indName == "<TRIX>")
      {
         ArrayResize(processed, 3);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //applied_price
         processed[2].integer_value = PRICE_CLOSE;
      
         return;
      }
      if (indName == "<WPR>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //calc_period
         processed[1].integer_value = 14;
      
         return;
      }
      
      if (indName == "<AD>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //applied_volume
         processed[1].integer_value = VOLUME_TICK;
         
         return;
      }
      if (indName == "<MFI>")
      {
         ArrayResize(processed, 3);
         processed[1].type = TYPE_INT;    //ma_period
         processed[1].integer_value = 14;
         processed[2].type = TYPE_INT;    //applied_volume
         processed[2].integer_value = VOLUME_TICK;
         
         return;
      }
      if (indName == "<OBV>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //applied_volume
         processed[1].integer_value = VOLUME_TICK;
      
         return;
      }
      if (indName == "<VOLUMES>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //applied_volume
         processed[1].integer_value = VOLUME_TICK;
         
         return;
      }
      
      if (indName == "<AC>")
      {
         return;
      }
      if (indName == "<ALLIGATOR>")
      {
         ArrayResize(processed, 9);
         processed[1].type = TYPE_INT;    //jaw_period
         processed[1].integer_value = 13;
         processed[2].type = TYPE_INT;    //jaw_shift
         processed[2].integer_value = 8;
         processed[3].type = TYPE_INT;    //teeth_period
         processed[3].integer_value = 8;
         processed[4].type = TYPE_INT;    //teeth_shift
         processed[4].integer_value = 5;
         processed[5].type = TYPE_INT;    //lips_period
         processed[5].integer_value = 5;
         processed[6].type = TYPE_INT;    //lips_shift
         processed[6].integer_value = 3;
         processed[7].type = TYPE_INT;    //ma_method
         processed[7].integer_value = MODE_SMMA;
         processed[8].type = TYPE_INT;    //applied_price
         processed[8].integer_value = PRICE_MEDIAN;
         
         return;
      }
      if (indName == "<AO>")
      {
         return;
      }
      if (indName == "<FRACTALS>")
      {
         return;
      }
      if (indName == "<GATOR>")
      {
         ArrayResize(processed, 9);
         processed[1].type = TYPE_INT;    //jaw_period
         processed[1].integer_value = 13;
         processed[2].type = TYPE_INT;    //jaw_shift
         processed[2].integer_value = 8;
         processed[3].type = TYPE_INT;    //teeth_period
         processed[3].integer_value = 8;
         processed[4].type = TYPE_INT;    //teeth_shift
         processed[4].integer_value = 5;
         processed[5].type = TYPE_INT;    //lips__period
         processed[5].integer_value = 5;
         processed[6].type = TYPE_INT;    //lips_shift
         processed[6].integer_value = 3;
         processed[7].type = TYPE_INT;    //ma_method
         processed[7].integer_value = MODE_SMMA;
         processed[8].type = TYPE_INT;    //applied_price
         processed[8].integer_value = PRICE_MEDIAN;
         
         return;
      }
      if (indName == "<BWMFI>")
      {
         ArrayResize(processed, 2);
         processed[1].type = TYPE_INT;    //applied_volume
         processed[1].integer_value = VOLUME_TICK;
         
         return;
      }
   }
   
   int CreateNativeIndicator(string symbol, MqlParam &parameters[], string indName, ENUM_TIMEFRAMES period=PERIOD_CURRENT)
   {
      int total = ArraySize(parameters);
      
      if (indName == "<AMA>")
      {
         return IndicatorCreate(symbol, period, IND_AMA, total, parameters);
      }
      if (indName == "<ADX>")
      {
         return IndicatorCreate(symbol, period, IND_ADX, total, parameters);
      }
      if (indName == "<ADXW>")
      {
         return IndicatorCreate(symbol, period, IND_ADXW, total, parameters);
      }
      if (indName == "<BB>")
      {
         return IndicatorCreate(symbol, period, IND_BANDS, total, parameters);
      }
      if (indName == "<DEMA>")
      {
         return IndicatorCreate(symbol, period, IND_DEMA, total, parameters);
      }
      if (indName == "<ENVELOPES>")
      {
         return IndicatorCreate(symbol, period, IND_ENVELOPES, total, parameters);
      }
      if (indName == "<FRAMA>")
      {
         return IndicatorCreate(symbol, period, IND_FRAMA, total, parameters);
      }
      if (indName == "<ICHIMOKU>")
      {
         return IndicatorCreate(symbol, period, IND_ICHIMOKU, total, parameters);
      }
      if (indName == "<MA>")
      {
         return IndicatorCreate(symbol, period, IND_MA, total, parameters);
      }
      if (indName == "<SAR>")
      {
         return IndicatorCreate(symbol, period, IND_SAR, total, parameters);
      }
      if (indName == "<STDEV>")
      {
         return IndicatorCreate(symbol, period, IND_STDDEV, total, parameters);
      }
      if (indName == "<TEMA>")
      {
         return IndicatorCreate(symbol, period, IND_TEMA, total, parameters);
      }
      if (indName == "<VIDYA>")
      {
         return IndicatorCreate(symbol, period, IND_VIDYA, total, parameters);
      }
      
      if (indName == "<ATR>")
      {
         return IndicatorCreate(symbol, period, IND_ATR, total, parameters);
      }
      if (indName == "<BEARS>")
      {
         return IndicatorCreate(symbol, period, IND_BEARS, total, parameters);
      }
      if (indName == "<BULLS>")
      {
         return IndicatorCreate(symbol, period, IND_BULLS, total, parameters);
      }
      if (indName == "<CHAIKIN>")
      {
         return IndicatorCreate(symbol, period, IND_CHAIKIN, total, parameters);
      }
      if (indName == "<CCI>")
      {
         return IndicatorCreate(symbol, period, IND_CCI, total, parameters);
      }
      if (indName == "<DEMARKER>")
      {
         return IndicatorCreate(symbol, period, IND_DEMARKER, total, parameters);
      }
      if (indName == "<FORCE>")
      {
         return IndicatorCreate(symbol, period, IND_FORCE, total, parameters);
      }
      if (indName == "<MACD>")
      {
         return IndicatorCreate(symbol, period, IND_MACD, total, parameters);
      }
      if (indName == "<MOMENTUM>")
      {
         return IndicatorCreate(symbol, period, IND_MOMENTUM, total, parameters);
      }
      if (indName == "<OSMA>")
      {
         return IndicatorCreate(symbol, period, IND_OSMA, total, parameters);
      }
      if (indName == "<RSI>")
      {
         return IndicatorCreate(symbol, period, IND_RSI, total, parameters);
      }
      if (indName == "<RVI>")
      {
         return IndicatorCreate(symbol, period, IND_RVI, total, parameters);
      }
      if (indName == "<STOCHASTIC>")
      {
         return IndicatorCreate(symbol, period, IND_STOCHASTIC, total, parameters);
      }
      if (indName == "<TRIX>")
      {
         return IndicatorCreate(symbol, period, IND_TRIX, total, parameters);
      }
      if (indName == "<WPR>")
      {
         return IndicatorCreate(symbol, period, IND_WPR, total, parameters);
      }
      
      if (indName == "<AD>")
      {
         return IndicatorCreate(symbol, period, IND_AD, total, parameters);
      }
      if (indName == "<MFI>")
      {
         return IndicatorCreate(symbol, period, IND_MFI, total, parameters);
      }
      if (indName == "<OBV>")
      {
         return IndicatorCreate(symbol, period, IND_OBV, total, parameters);
      }
      if (indName == "<VOLUMES>")
      {
         return IndicatorCreate(symbol, period, IND_VOLUMES, total, parameters);
      }
      
      if (indName == "<AC>")
      {
         return IndicatorCreate(symbol, period, IND_AC);
      }
      if (indName == "<ALLIGATOR>")
      {
         return IndicatorCreate(symbol, period, IND_ALLIGATOR, total, parameters);
      }
      if (indName == "<AO>")
      {
         return IndicatorCreate(symbol, period, IND_AO);
      }
      if (indName == "<FRACTALS>")
      {
         return IndicatorCreate(symbol, period, IND_FRACTALS);
      }
      if (indName == "<GATOR>")
      {
         return IndicatorCreate(symbol, period, IND_GATOR, total, parameters);
      }
      if (indName == "<BWMFI>")
      {
         return IndicatorCreate(symbol, period, IND_BWMFI, total, parameters);
      }
      
      
      Print("UNKNOWN NATIVE INDICATOR: ", indName);
      return INVALID_HANDLE;
   }

#else
//+------------------------------------------------------------------+
//|             MQL4 FUNCTIONS                                       |
//+------------------------------------------------------------------+


   void ProcessParameters(string indicator_name, string param_string, double &processed[], CDictionary* opt_dict=NULL)
   {
      string paramStringsArr[];
      StringSplit(param_string, ',', paramStringsArr);
      
      int size = ArraySize(paramStringsArr);
      ArrayResize(processed, size);
      
      for (int i=0; i<size; i++)
      {
         processed[i] = ParseParameter(paramStringsArr[i], opt_dict);
      }
   }
   
   void ProcessParameters(string indicator_name, double &processed[])
   {
      ArrayResize(processed, 0);
   }
   
   double ParseParameter(string parameter, CDictionary* opt_var=NULL)
   {
      TRIM_STRING_LEFT(parameter);
      TRIM_STRING_RIGHT(parameter);
      
      if (opt_var!=NULL && parameter[0]=='#')
      {
      	int last = parameter[StringLen(parameter)-1];
      	double res=0.0;
      	if (last < '0' || last > '9')
      	{
      		parameter = StringSubstr(parameter, 0, StringLen(parameter)-1);
      	}
      	
   		GET_OPT_RES
   		return res;
      }
      else if (StringToLow(parameter) == "true")
      {
         return true;
      }
      else if (StringToLow(parameter) == "false")
      {
         return false;
      }
      else
      {
         return StringToDouble(parameter);
      }
   }
   
   void SubstituteOptimizationParameter(string newParameter, int index, double &paramArray[], CDictionary* opt_dict)
   {
      if (index <= 0) return;
      if (index > ArraySize(paramArray)) return;
      
      index--;
      
      paramArray[index] = ParseStringToDouble(newParameter, opt_dict);
   }
   
   #define SET_NATIVE(index, value) if (orgSize <= index) processed[index] = value
   
   void ProcessNativeParameters(string indName, double &processed[])
   {
      int orgSize = ArraySize(processed);
      
      if (indName == "<ADX>")
      {
         ArrayResize(processed, 2);
         SET_NATIVE(0, 14); //period 
         SET_NATIVE(1, PRICE_CLOSE); //applied_price
         
         return;
      }
      if (indName == "<BB>")
      {
         ArrayResize(processed, 4);
         SET_NATIVE(0, 20); //period
         SET_NATIVE(1, 2.0); //deviation
         SET_NATIVE(2, 0); //shift
         SET_NATIVE(3, PRICE_CLOSE); //applied_price
         
         return;
      }
      if (indName == "<ENVELOPES>")
      {
         ArrayResize(processed, 5);
         SET_NATIVE(0, 14); //ma_period
         SET_NATIVE(1, MODE_SMA); //ma_method
         SET_NATIVE(2, 0); //ma_shift
         SET_NATIVE(3, PRICE_CLOSE); //applied_price
         SET_NATIVE(4, 0.1); //deviation
         
         return;
      }
      if (indName == "<ICHIMOKU>")
      {
         ArrayResize(processed, 3);
         SET_NATIVE(0, 9); //tenkan_sen
         SET_NATIVE(1, 26); //kijun_sen
         SET_NATIVE(2, 52); //senkou_span_b
         
         return;
      }
      if (indName == "<MA>")
      {
         ArrayResize(processed, 4);
         SET_NATIVE(0, 14); //ma_period
         SET_NATIVE(1, 0); //ma_shift
         SET_NATIVE(2, MODE_SMA); //ma_method
         SET_NATIVE(3, PRICE_CLOSE); //applied_price
         
         return;
      }
      if (indName == "<SAR>")
      {
         ArrayResize(processed, 2);
         SET_NATIVE(0, 0.02); //step
         SET_NATIVE(1, 0.2); //maximum
      
         return;
      }
      if (indName == "<STDEV>")
      {
         ArrayResize(processed, 4);
         SET_NATIVE(0, 20); //ma_period
         SET_NATIVE(1, 0); //ma_shift
         SET_NATIVE(2, MODE_SMA); //ma_method
         SET_NATIVE(3, PRICE_CLOSE); //applied_price
      
         return;
      }
      
      if (indName == "<ATR>")
      {
         ArrayResize(processed, 1);
         SET_NATIVE(0, 14); //period
         
         return;
      }
      if (indName == "<BEARS>")
      {
         ArrayResize(processed, 2);
         SET_NATIVE(0, 13); //period
         SET_NATIVE(1, PRICE_CLOSE); //applied_price
         
         return;
      }
      if (indName == "<BULLS>")
      {
         ArrayResize(processed, 2);
         SET_NATIVE(0, 13); //period
         SET_NATIVE(1, PRICE_CLOSE); //applied_price
      
         return;
      }
      if (indName == "<CCI>")
      {
         ArrayResize(processed, 2);
         SET_NATIVE(0, 14); //period
         SET_NATIVE(1, PRICE_TYPICAL); //applied_price
         
         return;
      }
      if (indName == "<DEMARKER>")
      {
         ArrayResize(processed, 1);
         SET_NATIVE(0, 14); //period
         
         return;
      }
      if (indName == "<FORCE>")
      {
         ArrayResize(processed, 3);
         SET_NATIVE(0, 13); //period
         SET_NATIVE(1, MODE_SMA); //ma_method
         SET_NATIVE(2, PRICE_CLOSE); //applied_price
      
         return;
      }
      if (indName == "<MACD>")
      {
         ArrayResize(processed, 4);
         SET_NATIVE(0, 12); //fast_ema_period
         SET_NATIVE(1, 26); //slow_ema_period
         SET_NATIVE(2, 9); //signal_period
         SET_NATIVE(3, PRICE_CLOSE); //applied_price
         
         return;
      }
      if (indName == "<MOMENTUM>")
      {
         ArrayResize(processed, 2);
         SET_NATIVE(0, 14); //period
         SET_NATIVE(1, PRICE_CLOSE); //applied_price
      
         return;
      }
      if (indName == "<OSMA>")
      {
         ArrayResize(processed, 4);
         SET_NATIVE(0, 12); //fast_ema_period
         SET_NATIVE(1, 26); //slow_ema_period
         SET_NATIVE(2, 9); //signal_period
         SET_NATIVE(3, PRICE_CLOSE); //applied_price
      
         return;
      }
      if (indName == "<RSI>")
      {
         ArrayResize(processed, 2);
         SET_NATIVE(0, 14); //period
         SET_NATIVE(1, PRICE_CLOSE); //applied_price
      
         return;
      }
      if (indName == "<RVI>")
      {
         ArrayResize(processed, 1);
         SET_NATIVE(0, 10); //period
      
         return;
      }
      if (indName == "<STOCHASTIC>")
      {
         ArrayResize(processed, 5);
         SET_NATIVE(0, 5); //Kperiod
         SET_NATIVE(1, 3); //Dperiod
         SET_NATIVE(2, 3); //slowing
         SET_NATIVE(3, MODE_SMA); //ma_method
         SET_NATIVE(4, STO_LOWHIGH); //price_field
      
         return;
      }
      if (indName == "<WPR>")
      {
         ArrayResize(processed, 1);
         SET_NATIVE(0, 14); //period
      
         return;
      }
      
      if (indName == "<AD>")
      {
         ArrayResize(processed, 0);
         return;
      }
      if (indName == "<MFI>")
      {
         ArrayResize(processed, 1);
         SET_NATIVE(0, 14); //period
         
         return;
      }
      if (indName == "<OBV>")
      {
         ArrayResize(processed, 1);
         SET_NATIVE(0, PRICE_CLOSE); //applied_price
      
         return;
      }
      if (indName == "<VOLUMES>")
      {
         ArrayResize(processed, 0);
         return;
      }
      
      if (indName == "<AC>")
      {
         ArrayResize(processed, 0);
         return;
      }
      if (indName == "<ALLIGATOR>")
      {
         ArrayResize(processed, 8);
         SET_NATIVE(0, 13); //jaw_period
         SET_NATIVE(1, 8); //jaw_shift
         SET_NATIVE(2, 8); //teeth_period
         SET_NATIVE(3, 5); //teeth_shift
         SET_NATIVE(4, 5); //lips__period
         SET_NATIVE(5, 3); //lips_shift
         SET_NATIVE(6, MODE_SMMA); //ma_method
         SET_NATIVE(7, PRICE_MEDIAN); //applied_price
         
         return;
      }
      if (indName == "<AO>")
      {
         ArrayResize(processed, 0);
         return;
      }
      if (indName == "<FRACTALS>")
      {
         ArrayResize(processed, 0);
         return;
      }
      if (indName == "<GATOR>")
      {
         ArrayResize(processed, 8);
         SET_NATIVE(0, 13); //jaw_period
         SET_NATIVE(1, 8); //jaw_shift
         SET_NATIVE(2, 8); //teeth_period
         SET_NATIVE(3, 5); //teeth_shift
         SET_NATIVE(4, 5); //lips__period
         SET_NATIVE(5, 3); //lips_shift
         SET_NATIVE(6, MODE_SMMA); //ma_method
         SET_NATIVE(7, PRICE_MEDIAN); //applied_price
         
         return;
      }
      if (indName == "<BWMFI>")
      {
         ArrayResize(processed, 0);
         return;
      }
   }

#endif