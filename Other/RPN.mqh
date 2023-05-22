
#include "Dictionary.mqh"


class CReversePolishNotation
{
	protected:
	
		enum RevPol_TokenType
		{
			RP_TOKEN_NUMBER,
			RP_TOKEN_VARIABLE,
			RP_TOKEN_FUNCTION,
			RP_TOKEN_OPERATOR,
			RP_TOKEN_PARENTESIS
		};
		
		enum RevPol_FunctionType
		{
			RP_FUNC_MIN,
			RP_FUNC_MAX,
			RP_FUNC_SQRT,
			RP_FUNC_ABS,
			RP_FUNC_LOGN,
			RP_FUNC_LOG10,
			RP_FUNC_ROUND,
			RP_FUNC_UNARY_SUB
		};
		
		enum RevPol_OperatorType
		{
			RP_OPER_ADD,
			RP_OPER_SUB,
			RP_OPER_MUL,
			RP_OPER_DIV,
			RP_OPER_EXP
		};
		
		enum RevPol_ParentesisType
		{
			RP_PAR_LEFT,
			RP_PAR_RIGHT
		};
		
		struct RPNToken
		{
			RevPol_TokenType type;
			int second_type;
			
			int precedence;
			bool left_asociative;
			
			int function_arguments;
			
			double number;
			
			string variable;
		};
		
		static void ConvertStringToTokens(const string input_string, RPNToken &token_array[]);
		static double Evaluate_RPN(RPNToken &to_execute[], CDictionary* dict=NULL);
		static void Infix_to_ReversePolish(RPNToken &input_array[], RPNToken &output_array[]);
		
		static void PreProcessString(string &inp_str);
		
	private:
		
		static string GetTokenArrayString(const RPNToken &array[]);
		static bool IsNumber(const string s);
		static bool IsVariable(const string s);
		static double GetCustomVariable(string variable, CDictionary* dict=NULL);
		
		static string TokenToString(const RPNToken &token);

	public:
	
		static double EvaluateInfixString(string to_evaluate, CDictionary* variables=NULL);
		static double EvaluatePostfixString(string to_evaluate, CDictionary* variables=NULL);
		
		static CDictionary* GetDefaultDictionary();
};


#define CASE_OPERATOR(opStr, tkn_type, sub_type, prec, l, is_n) \
	else if (tokens[i]==opStr) \
		{ \
			token_array[n-1].type = tkn_type; \
			token_array[n-1].precedence = prec; \
			token_array[n-1].second_type = sub_type; \
			token_array[n-1].left_asociative = l; \
			last_is_number = is_n; \
		}
		
#define CASE_FUNCTION(opStr, sub_type, args) \
	else if (tokens[i]==opStr) \
		{ \
			token_array[n-1].type = RP_TOKEN_FUNCTION; \
			token_array[n-1].function_arguments = args; \
			token_array[n-1].second_type = sub_type; \
			last_is_number = false; \
		}

void CReversePolishNotation::ConvertStringToTokens(const string input_string, RPNToken &token_array[])
{
	string tokens[];
	StringSplit(input_string, ' ', tokens);
	
	int total = ArraySize(tokens);
	ArrayResize(token_array, 0, total);
	int n=0;
	
	bool last_is_number = false;
	
	for (int i=0; i<total; i++)
	{
		if (tokens[i]=="") continue;
		
		n++;
		ArrayResize(token_array, n);
		ZeroMemory(token_array[n-1]);
		
		//Print("\"", tokens[i], "\"");
		
		if (IsNumber(tokens[i]))
		{
			token_array[n-1].type = RP_TOKEN_NUMBER;
			token_array[n-1].number = StringToDouble(tokens[i]);
			last_is_number = true;
		}
		else if (IsVariable(tokens[i]))
		{
			token_array[n-1].type = RP_TOKEN_VARIABLE;
			token_array[n-1].variable = tokens[i];
			//token_array[n-1].number = GetCustomVariable(tokens[i], dict);
			last_is_number = true;
		}
		else if (tokens[i]=="-" && !last_is_number)
		{
			token_array[n-1].type = RP_TOKEN_FUNCTION;
			token_array[n-1].function_arguments = 1;
			token_array[n-1].second_type = RP_FUNC_UNARY_SUB;
			last_is_number = false;
		}
		CASE_OPERATOR("+", RP_TOKEN_OPERATOR, RP_OPER_ADD, 2, true, false)
		CASE_OPERATOR("-", RP_TOKEN_OPERATOR, RP_OPER_SUB, 2, true, false)
		CASE_OPERATOR("*", RP_TOKEN_OPERATOR, RP_OPER_MUL, 3, true, false)
		CASE_OPERATOR("/", RP_TOKEN_OPERATOR, RP_OPER_DIV, 3, true, false)
		CASE_OPERATOR("^", RP_TOKEN_OPERATOR, RP_OPER_EXP, 4, false, false)
		CASE_OPERATOR("(", RP_TOKEN_PARENTESIS, RP_PAR_LEFT, 5, false, false)
		CASE_OPERATOR(")", RP_TOKEN_PARENTESIS, RP_PAR_RIGHT, 5, false, true)
		CASE_FUNCTION("min", RP_FUNC_MIN, 2)
		CASE_FUNCTION("max", RP_FUNC_MAX, 2)
		CASE_FUNCTION("sqrt", RP_FUNC_SQRT, 1)
		CASE_FUNCTION("abs", RP_FUNC_ABS, 1)
		CASE_FUNCTION("logn", RP_FUNC_LOGN, 1)
		CASE_FUNCTION("log10", RP_FUNC_LOG10, 1)
		CASE_FUNCTION("round", RP_FUNC_ROUND, 1)
		else
		{
			#ifndef NO_DEBUG_PRINT
			Print("Unknown Token \"", tokens[i], "\"");
			#endif
		}
	}
}

#define PUSH_FROM_INPUT \
	s++; \
	ArrayResize(stack, s); \
	stack[s-1] = input_array[i];
	
#define POP_TO_OUTPUT \
	output_array[o] = stack[s-1]; \
	s--; \
	ArrayResize(stack, s); \
	o++;

#ifndef NO_DEBUG_PRINT
#define MISMATCH_ERROR \
	Print("MISMATCHED PARENTHESIS IN FORMULA"); \
	ArrayResize(output_array, 0); \
	return;
#else 
#define MISMATCH_ERROR \
	ArrayResize(output_array, 0); \
	return;
#endif

//Shunting yard algo (elements must have spaces between)
void CReversePolishNotation::Infix_to_ReversePolish(RPNToken &input_array[], RPNToken &output_array[])
{
	RPNToken stack[];
	int s = 0;
	
	int total = ArraySize(input_array);
	int i = 0;
	
	ArrayResize(output_array, total);
	int o = 0;
	
	while (i<total)
	{
		switch (input_array[i].type)
		{
			case RP_TOKEN_VARIABLE:
			case RP_TOKEN_NUMBER:
			{
				//Print("Add token to output: ", TokenToString(input_array[i]));
				output_array[o] = input_array[i];
				o++;
				break;
			}
			case RP_TOKEN_FUNCTION:
			{
				//Print("Push function token to stack: ", TokenToString(input_array[i]));
				PUSH_FROM_INPUT
				break;
			}
			case RP_TOKEN_OPERATOR:
			{
				while (s>0	//Not empty 
					// Not left parentesis
					&& (stack[s-1].type!=RP_TOKEN_PARENTESIS || stack[s-1].second_type!=RP_PAR_LEFT)
					//
					&& (stack[s-1].type==RP_TOKEN_FUNCTION
						|| stack[s-1].precedence > input_array[i].precedence 
						|| (stack[s-1].precedence == input_array[i].precedence && 
							input_array[i].left_asociative)
						)
					)
				{
					//Print("Pop stack to output: ", TokenToString(stack[s-1]));
					POP_TO_OUTPUT
				}
				//Print("Push token to stack: ", TokenToString(input_array[i]));
				PUSH_FROM_INPUT
				break;
			}
			case RP_TOKEN_PARENTESIS:
			{
				if (input_array[i].second_type==RP_PAR_LEFT)
				{
					//Print("Push token to stack: ", TokenToString(input_array[i]));
					PUSH_FROM_INPUT
				}
				else
				{
					while (s>0)
					{
						if (stack[s-1].type==RP_TOKEN_PARENTESIS &&
							stack[s-1].second_type==RP_PAR_LEFT)
							break;
						else
						{
							//Print("Pop stack to output: ", TokenToString(stack[s-1]));
							POP_TO_OUTPUT
						}
					}
					if (s==0) // Stack empty without left parenthesis
					{
						MISMATCH_ERROR
					}
					
					//Print("Pop stack: ", TokenToString(stack[s-1]));
					s--;
					ArrayResize(stack, s);
					
					if (s>0 && stack[s-1].type==RP_TOKEN_FUNCTION)
					{
						//Print("Pop stack to output: ", TokenToString(stack[s-1]));
						POP_TO_OUTPUT
					}
				}
				
				break;
			}
		}
		
		i++;
	}
	
	while (s>0)
	{
		if (stack[s-1].type==RP_TOKEN_PARENTESIS &&
			stack[s-1].second_type==RP_PAR_LEFT)
		{
			MISMATCH_ERROR
		}
		//Print("Pop stack to output: ", TokenToString(stack[s-1]));
		POP_TO_OUTPUT
	}
	ArrayResize(output_array, o);
}

string CReversePolishNotation::GetTokenArrayString(const RPNToken &array[])
{
	int size = ArraySize(array);
	if (size==0) 
		return "";
	string output = TokenToString(array[0]);
	
	for (int i=1; i<size;i++)
	{
		output = output + " " + TokenToString(array[i]);
	}
	return output;
}

bool CReversePolishNotation::IsNumber(string s)
{
	for(int iPos = StringLen(s) - 1; iPos >= 0; iPos--)
	{
		int c = StringGetCharacter(s, iPos);
		if( (c < '0' || c > '9') && c != '.') return false;
	}
	return true;
}

bool CReversePolishNotation::IsVariable(const string s)
{
	if (StringLen(s)<=0) return false;
	
	return s[0]=='#';
}

#define POP_OPERAND(var) \
	double var = stack[s-1].number; \
	s--; \
	ArrayResize(stack, s);

double CReversePolishNotation::Evaluate_RPN(RPNToken &to_execute[], CDictionary* dict=NULL)
{
	int total = ArraySize(to_execute);
	
	RPNToken stack[];
	int s=0;
	
	for (int i=0; i<total; i++)
	{
		switch (to_execute[i].type)
		{
			case RP_TOKEN_NUMBER:
			{
				// Push to stack
				s++;
				ArrayResize(stack, s);
				stack[s-1] = to_execute[i];
				break;
			}
			case RP_TOKEN_VARIABLE:
			{
				to_execute[i].number = GetCustomVariable(to_execute[i].variable, dict);
				
				// Push to stack
				s++;
				ArrayResize(stack, s);
				stack[s-1] = to_execute[i];
				break;
			}
			case RP_TOKEN_OPERATOR:
			{
				if (s<1)
				{
					#ifndef NO_DEBUG_PRINT
					Print("ERROR: unexpected operator");
					#endif
					return 0.0;
				}
				
				POP_OPERAND(o2)
				
				if (s==0) // Introducir elemento extra (0)
				{
					s++;
					ArrayResize(stack, s);
					stack[0].type = RP_TOKEN_NUMBER;
					stack[0].number = 0.0;
				}
				
				// Evaluate operation
				switch (to_execute[i].second_type)
				{
					case RP_OPER_ADD:
						stack[s-1].number += o2;
						break;
					case RP_OPER_SUB:
						stack[s-1].number -= o2;
						break;
					case RP_OPER_MUL:
						stack[s-1].number *= o2;
						break;
					case RP_OPER_DIV:
						if (!(o2 < 0.0 || o2>0.0))
						{
							#ifndef NO_DEBUG_PRINT
							Print("ERROR: Division by 0");
							#endif
							return 0.0;
						}
						stack[s-1].number /= o2;
						break;
					case RP_OPER_EXP:
						stack[s-1].number = MathPow(stack[s-1].number, o2);
						break;
				}
				//Result is in stack
				break;
			}
			case RP_TOKEN_FUNCTION:
			{
				if (s<to_execute[i].function_arguments)
				{
					#ifndef NO_DEBUG_PRINT
					Print("ERROR: not enough arguments for \"", TokenToString(to_execute[i]),"\"");
					#endif
					return 0.0;
				}
				switch (to_execute[i].second_type)
				{
					case RP_FUNC_MAX:
					{
						POP_OPERAND(o2)
						stack[s-1].number = MathMax(stack[s-1].number, o2);
						break;
					}
					case RP_FUNC_MIN:
					{
						POP_OPERAND(o2)
						stack[s-1].number = MathMin(stack[s-1].number, o2);
						break;
					}
					case RP_FUNC_SQRT:
					{
						stack[s-1].number = MathSqrt(stack[s-1].number);
						break;
					}
					case RP_FUNC_ABS:
					{
						stack[s-1].number = MathAbs(stack[s-1].number);
						break;
					}
					case RP_FUNC_LOGN:
					{
						stack[s-1].number = MathLog(stack[s-1].number);
						break;
					}
					case RP_FUNC_LOG10:
					{
						stack[s-1].number = MathLog10(stack[s-1].number);
						break;
					}
					case RP_FUNC_ROUND:
					{
						stack[s-1].number = MathRound(stack[s-1].number);
						break;
					}
					case RP_FUNC_UNARY_SUB:
					{
						stack[s-1].number = -stack[s-1].number;
						break;
					}
				}
				
				break;
			}
			
			// No hay parentesis al evaluar
		}
	}
	
	if (s>1)
	{
		#ifndef NO_DEBUG_PRINT
		Print(GetTokenArrayString(to_execute));
		Print("ERROR: Unexpected number (operator may be missing or function has excess arguments)");
		#endif
	}
	if (s>0)
		return stack[s-1].number;
	
	return 0.0;
}

string CReversePolishNotation::TokenToString(const RPNToken &token)
{
	switch (token.type)
	{
		case RP_TOKEN_NUMBER:
			return DoubleToString(token.number, (MathMod(token.number, 1.0)>0.0)?8:0);
		
		case RP_TOKEN_VARIABLE:
			return "~"+token.variable+"~";
		
		case RP_TOKEN_OPERATOR:
		{
			switch (token.second_type)
			{
				case RP_OPER_ADD:
					return "+";
				case RP_OPER_SUB:
					return "-";
				case RP_OPER_MUL:
					return "*";
				case RP_OPER_DIV:
					return "/";
				case RP_OPER_EXP:
					return "^";
			}
			return "";
		}
		case RP_TOKEN_FUNCTION:
		{
			switch (token.second_type)
			{
				case RP_FUNC_MAX:
					return "max";
				case RP_FUNC_MIN:
					return "min";
				case RP_FUNC_SQRT:
					return "sqrt";
				case RP_FUNC_ABS:
					return "abs";
				case RP_FUNC_LOGN:
					return "logn";
				case RP_FUNC_LOG10:
					return "log10";
				case RP_FUNC_ROUND:
					return "round";
				case RP_FUNC_UNARY_SUB:
					return "u-";
			}
			return "";
		}
		case RP_TOKEN_PARENTESIS:
		{
			if (token.second_type==RP_PAR_LEFT)
				return "(";
			else
				return ")";
		}
	}

	return "";
}

double CReversePolishNotation::EvaluateInfixString(string to_evaluate, CDictionary* variables=NULL)
{
	PreProcessString(to_evaluate);

	RPNToken array[], output[];
	ConvertStringToTokens(to_evaluate, array);
	Infix_to_ReversePolish(array, output);
	
	return Evaluate_RPN(output, variables);
}

double CReversePolishNotation::EvaluatePostfixString(string to_evaluate, CDictionary* variables=NULL)
{
	PreProcessString(to_evaluate);

	RPNToken array[];
	ConvertStringToTokens(to_evaluate, array);
	return Evaluate_RPN(array, variables);
}

void CReversePolishNotation::PreProcessString(string &inp_str)
{
	StringReplace(inp_str, "+", " + ");
	StringReplace(inp_str, "-", " - ");
	StringReplace(inp_str, "*", " * ");
	StringReplace(inp_str, "/", " / ");
	StringReplace(inp_str, "^", " ^ ");
	StringReplace(inp_str, "(", " ( ");
	StringReplace(inp_str, ")", " ) ");
	StringReplace(inp_str, ",", " ");
	StringReplace(inp_str, "#", " #");
}

double CReversePolishNotation::GetCustomVariable(string variable, CDictionary* dict=NULL)
{
	if (CheckPointer(dict)==POINTER_INVALID)
	{
		#ifndef NO_DEBUG_PRINT
		Print("Invalid Variable Dictionary");
		#endif
		return 0.0;
	}
	
	double result;
	if (dict.Get<double>(variable, result))
		return result;
	#ifndef NO_DEBUG_PRINT
	Print("Unknown variable: ", variable);
	#endif
	return 0.0;
}

CDictionary* CReversePolishNotation::GetDefaultDictionary(void)
{
	CDictionary* dict = new CDictionary();
	
	dict.Set<double>("#PI", 3.14159265359);
	
	return dict;
}