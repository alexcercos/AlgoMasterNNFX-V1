
class CExtendedSummary
{
	private:
		enum CloseLevelsEnum
		{
			CL_MAX_SL,
			CL_LOSS_EX,
			CL_LOSS_C1,
			CL_LOSS_BL,
			CL_LOSS_NEWS,
			CL_BE_SL,
			CL_PROFIT_BEF_EX,
			CL_PROFIT_BEF_C1,
			CL_PROFIT_BEF_BL,
			CL_PROFIT_BEF_NEWS,
			CL_HIT_TRAILING,
			CL_PROFIT_AFTER_EX,
			CL_PROFIT_AFTER_C1,
			CL_PROFIT_AFTER_BL
		};
		
		int total_closes;
		int close_levels[14];
	
	public:
		CExtendedSummary();
		
		#define ADD_CL(func, en) void Add_##func() { close_levels[en]++; total_closes++; }
		
		ADD_CL(MaxSL, CL_MAX_SL)
		ADD_CL(Loss_Exit, CL_LOSS_EX)
		ADD_CL(Loss_C1, CL_LOSS_C1)
		ADD_CL(Loss_Baseline, CL_LOSS_BL)
		ADD_CL(Loss_News, CL_LOSS_NEWS)
		ADD_CL(Breakeven, CL_BE_SL)
		ADD_CL(BeforeTP_Exit, CL_PROFIT_BEF_EX)
		ADD_CL(BeforeTP_C1, CL_PROFIT_BEF_C1)
		ADD_CL(BeforeTP_Baseline, CL_PROFIT_BEF_BL)
		ADD_CL(BeforeTP_News, CL_PROFIT_BEF_NEWS)
		ADD_CL(TrailingStop, CL_HIT_TRAILING)
		ADD_CL(AfterTP_Exit, CL_PROFIT_AFTER_EX)
		ADD_CL(AfterTP_C1, CL_PROFIT_AFTER_C1)
		ADD_CL(AfterTP_Baseline, CL_PROFIT_AFTER_BL)
		
		void PrintExtendedSummary();
};

CExtendedSummary::CExtendedSummary()
{
	total_closes = 0;
	ArrayInitialize(close_levels, 0);
}

#define SEP_LINES_EXTSUM "-------------------------"
#define PRINT_CL(mes, en) Print(mes, IntegerToString(close_levels[en]));
#define PRINT_CL_IF(mes, en) if (close_levels[en]>0) PRINT_CL(mes, en)

void CExtendedSummary::PrintExtendedSummary(void)
{
	Print(SEP_LINES_EXTSUM);
	Print("EXTENDED SUMMARY (Total = ", total_closes, ")");
	PRINT_CL(" - Maximum SL Hit: ", CL_MAX_SL)
	PRINT_CL_IF("  - Close at Loss (Exit): ", CL_LOSS_EX)
	PRINT_CL_IF("  - Close at Loss (C1): ", CL_LOSS_C1)
	PRINT_CL_IF("  - Close at Loss (Baseline): ", CL_LOSS_BL)
	PRINT_CL_IF("  - Close at Loss (News): ", CL_LOSS_NEWS)
	PRINT_CL_IF(" - Hit Breakeven SL: ", CL_BE_SL)
	PRINT_CL_IF("  - Close in Profit before TP (Exit): ", CL_PROFIT_BEF_EX)
	PRINT_CL_IF("  - Close in Profit before TP (C1): ", CL_PROFIT_BEF_C1)
	PRINT_CL_IF("  - Close in Profit before TP (Baseline): ", CL_PROFIT_BEF_BL)
	PRINT_CL_IF("  - Close in Profit before TP (News): ", CL_PROFIT_BEF_NEWS)
	PRINT_CL_IF(" - Hit Trailing Stop: ", CL_HIT_TRAILING)
	PRINT_CL_IF("  - Close in Profit after TP (Exit): ", CL_PROFIT_AFTER_EX)
	PRINT_CL_IF("  - Close in Profit after TP (C1): ", CL_PROFIT_AFTER_C1)
	PRINT_CL_IF("  - Close in Profit after TP (Baseline): ", CL_PROFIT_AFTER_BL)
	Print(SEP_LINES_EXTSUM);
}