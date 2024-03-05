//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#property script_show_inputs
CTrade   *Trade;
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;
COrderInfo     m_order;

input int      InpMagicNumber  = 2000001; //uniq
input string   InpTradeComment = __FILE__;  //optional cm

input int Inp = 48;
input double LoT = 0.01;


int         Handle_Indic;
double      Buffer_slow[2];
double      Buffer_fast[2];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Trade = new CTrade();
   Trade.SetExpertMagicNumber(InpMagicNumber);
   Handle_Indic = iCustom(Symbol(),Period(),"double-ssm",Inp);

   if(Handle_Indic==INVALID_HANDLE)
     {
      PrintFormat("Error %i",GetLastError());
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(Handle_Indic);
   delete   Trade;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!NewBar())
      return;

   int buys=0,sells=0;
   CalculateAllPositions(buys,sells);
   string text=("BUY: "+IntegerToString(buys)+", SELL: "+IntegerToString(sells));

   
   MqlRates PriceInformation[];
   ArraySetAsSeries(PriceInformation,true);
   int    Data=CopyRates(Symbol(), Period(),0,Bars(Symbol(),Period()),PriceInformation);
   double Ask =NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid =NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

   if (CopyBuffer(Handle_Indic,0,1,2,Buffer_slow) != 2) return;
   if (CopyBuffer(Handle_Indic,1,1,2,Buffer_fast) != 2) return;
   
   
   double current_slow = NormalizeDouble(Buffer_slow[1],5);
   double current_fast = NormalizeDouble(Buffer_fast[1],5);
   double prior_slow   = NormalizeDouble(Buffer_slow[0],5);
   double prior_fast   = NormalizeDouble(Buffer_fast[0],5);
   
   
   bool GoLong = ((current_fast<current_slow)&&(prior_fast>prior_slow));
   bool GoShort = ((current_fast>current_slow)&&(prior_fast<prior_slow));
   
   bool LongDone  = (buys>0 && current_fast>current_slow);
   bool ShortDone = (sells>0 && current_fast<current_slow);
   
   if((LongDone)||(ShortDone))
      {Trade.PositionClose(_Symbol,ULONG_MAX);}
   
   if(GoLong || ShortDone)
     {Trade.Buy(LoT,_Symbol,Ask,0,0);}
   
   if(GoShort || LongDone)
     {Trade.Sell(LoT,_Symbol,Bid,0,0);}
   
   
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar()
  {
   static datetime prevTime = 0;
   datetime currentTime = iTime(Symbol(),Period(),0);
   if(currentTime!=prevTime)
     {
      prevTime = currentTime;
      return (true);
     }
   return (false);
  }

void CalculateAllPositions(int &count_buys,int &count_sells)
  {
   count_buys=0;
   count_sells=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         //if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==InpMagic)
        {
         if(m_position.PositionType()==POSITION_TYPE_BUY)
            count_buys++;

         if(m_position.PositionType()==POSITION_TYPE_SELL)
            count_sells++;
        }
   return;
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+