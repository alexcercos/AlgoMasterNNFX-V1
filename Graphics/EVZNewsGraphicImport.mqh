
#include "../CrossProjects\YahooScraper.mqh"
#include "../CrossProjects\NewsImport.mqh"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>

#define FONT_SIZE			(10)
#define BUTTON_WIDTH		(100)
#define BUTTON_HEIGHT	(25)
#define CONTROLS_GAP		(10)

class CGraphicProgram : public CAppDialog
{
private:
   CLabel            m_label_start_date, m_label_end_date;
   CEdit             m_edit_start_date, m_edit_end_date;
   CButton           m_button_news, m_button_evz;
   
   YahooScraper      scraper;

public:
	CGraphicProgram();

   virtual bool      Create(const string name);
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

protected:
   //--- create dependent controls
   bool              CreateButton(CButton &button, string name, int x1, int y1, int x2, int y2, color clr_back=clrDarkCyan);
   bool              CreateEdit(CEdit &edit, string name, string editText, int x1, int y1, int x2, int y2);
   bool              CreateLabel(CLabel &label, string name, int x1, int y1, int x2, int y2);
   //--- handlers of the dependent controls events
   void              OnEditStart(void);
   void              OnEditEnd(void);
   
   void              OnClickNews(void);
   void              OnClickEVZ(void);
};

CGraphicProgram::CGraphicProgram() : scraper("^EVZ")
{
}

EVENT_MAP_BEGIN(CGraphicProgram)
ON_EVENT(ON_END_EDIT, m_edit_start_date, OnEditStart)
ON_EVENT(ON_END_EDIT, m_edit_end_date, OnEditEnd)
ON_EVENT(ON_CLICK, m_button_news, OnClickNews)
ON_EVENT(ON_CLICK, m_button_evz, OnClickEVZ)
EVENT_MAP_END(CAppDialog)

bool CGraphicProgram::Create(const string name)
{
	int x1 = 100;
	int y1 = 100;
   int x2 = 8 + x1 + CONTROLS_GAP * 3 + BUTTON_WIDTH * 2;
   int y2 = 30 + y1 + CONTROLS_GAP * 3 + BUTTON_HEIGHT * 5;
	
	if(!CAppDialog::Create(0, name, 1, x1, y1, x2, y2))
		return false;
	
   int bx1=CONTROLS_GAP;
   int by1=CONTROLS_GAP;
   int bx2=bx1+BUTTON_WIDTH;
   int by2=by1+BUTTON_HEIGHT;

#define NEXT_COLUMN \
   	bx1 += (BUTTON_WIDTH+CONTROLS_GAP); \
   	bx2 += (BUTTON_WIDTH+CONTROLS_GAP);

#define PREV_COLUMN \
   	bx1 -= (BUTTON_WIDTH+CONTROLS_GAP); \
   	bx2 -= (BUTTON_WIDTH+CONTROLS_GAP);

#define NEXT_ROW \
   	by1 += (BUTTON_HEIGHT+CONTROLS_GAP); \
   	by2 += (BUTTON_HEIGHT+CONTROLS_GAP);
   
   if(!CreateLabel(m_label_start_date, "News Start:", bx1, by1, bx2, by2))
      return(false);

   NEXT_COLUMN

   if(!CreateEdit(m_edit_start_date, "am_edit_st", "2007.12.31", bx1, by1, bx2, by2))
      return(false);

   PREV_COLUMN
   NEXT_ROW
  
  	if(!CreateLabel(m_label_end_date, "News End:", bx1, by1, bx2, by2))
      return(false);

   NEXT_COLUMN

   if(!CreateEdit(m_edit_end_date, "am_edit_end", TimeToString(TimeCurrent(), TIME_DATE), bx1, by1, bx2, by2))
      return(false);

   NEXT_ROW

   if(!CreateButton(m_button_news, "Download news", bx1, by1, bx2, by2, clrGray))
      return(false);
     
   NEXT_ROW
   if(!CreateButton(m_button_evz, "Download EVZ", bx1, by1, bx2, by2, clrSeaGreen))
      return(false);
   
#undef NEXT_COLUMN
#undef PREV_COLUMN
#undef NEXT_ROW
	
	return true;
}

bool CGraphicProgram::CreateButton(CButton &button, string name,int x1,int y1,int x2,int y2, color clr_back=clrDarkCyan)
{
//--- create
   if(!button.Create(m_chart_id, m_name+name, m_subwin, x1, y1, x2, y2))
      return(false);
   if(!button.Text(name))
      return(false);
   if (!button.FontSize(FONT_SIZE))
      return(false);
   button.ColorBorder(clrBlack);
   button.Color(clrWhite);
   button.ColorBackground(clr_back);

   if(!Add(button))
      return(false);
//--- succeed
   return(true);
}

bool CGraphicProgram::CreateEdit(CEdit &edit, string name, string editText, int x1, int y1, int x2, int y2)
{
//--- create
   if(!edit.Create(m_chart_id,m_name+name,m_subwin,x1,y1,x2,y2))
      return(false);

   if(!edit.ReadOnly(false))
      return(false);

   if(!edit.Text(editText))
      return(false);
   if (!edit.FontSize(FONT_SIZE))
      return(false);
   if(!edit.TextAlign(ALIGN_CENTER))
      return(false);
   if(!Add(edit))
      return(false);
//--- succeed
   return(true);
}

bool CGraphicProgram::CreateLabel(CLabel &label,string name,int x1,int y1,int x2,int y2)
{
//--- create
   if(!label.Create(m_chart_id,m_name+name,m_subwin,x1,y1,x2,y2))
      return(false);
   if(!label.Text(name))
      return(false);
   if (!label.FontSize(FONT_SIZE))
      return(false);
   if(!Add(label))
      return(false);
//--- succeed
   return(true);
}

void CGraphicProgram::OnClickEVZ(void)
{
	scraper.SaveFile(CUSTOM_FILE_NAME+".txt", TIME_LIMIT, MAX_TIME);
         
   Print("EVZ Data downloaded");
}

void CGraphicProgram::OnClickNews(void)
{
	//Add rewrite control
	bool rewrite_news_files = true;
	datetime start = StringToTime(m_edit_start_date.Text());
	datetime end = StringToTime(m_edit_end_date.Text());
	ImportNewsFromPeriod(start, end, rewrite_news_files);
   Print("News Data downloaded");
}

void CGraphicProgram::OnEditStart(void)
{
	datetime time = StringToTime(m_edit_start_date.Text());
	m_edit_start_date.Text(TimeToString(time, TIME_DATE));
}

void CGraphicProgram::OnEditEnd(void)
{
	datetime time = StringToTime(m_edit_end_date.Text());
	m_edit_end_date.Text(TimeToString(time, TIME_DATE));
}
