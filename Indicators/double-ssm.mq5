//+------------------------------------------------------------------+
//|                                                   double-ssm.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "saebix"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_label1  "Fast SSM"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_width1  1

#property indicator_label2  "Slow SSM"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_width2  1

input int             inpPeriod     = 48;            // Period*Multiplier
input ENUM_APPLIED_PRICE fastprice  = PRICE_CLOSE;  // Fast Price
input ENUM_APPLIED_PRICE slowprice  = PRICE_OPEN;  // Slow Price
//--- indicator buffers
//
double fastssm[];
double slowssm[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0,fastssm,INDICATOR_DATA);
   SetIndexBuffer(1,slowssm,INDICATOR_DATA);
   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]){
   int start = prev_calculated<=0 ? 0 : prev_calculated-3;
   for(int i=0; i<rates_total && !IsStopped(); i++)
    {
      fastssm[i]  = iSuperSmoother(close[i],inpPeriod,i);
    }
   for(int i=0; i<rates_total && !IsStopped(); i++)
    {
      slowssm[i]  = iSuperSmoother(open[i],inpPeriod,i);
    }
   return(rates_total);
  }
//+------------------------------------------------------------------+
#define _ssmInstances 1
#define _ssmInstancesSize 2
#define _ssmRingSize 20
double workSsm[_ssmRingSize][_ssmInstances*_ssmInstancesSize];
#define _price 0
#define _ssm   1
double workSsmCoeffs[][4];
#define _period 0
#define _c1     1
#define _c2     2
#define _c3     3
double iSuperSmoother(double price, double period, int i, int instance=0)
{
int _indC = (i)%_ssmRingSize;
int _inst = instance*_ssmInstancesSize;

   if(i>1 && period>1)
   {
      if(ArrayRange(workSsmCoeffs,0)<(instance+1)) { ArrayResize(workSsmCoeffs,instance+1); workSsmCoeffs[instance][_period]=-99; }
      if(workSsmCoeffs[instance][_period]!=period)
      {
         double a1 = MathExp(-1.414*M_PI/period);
         double b1 = 2.0*a1*MathCos(1.414*M_PI/period);
            workSsmCoeffs[instance][_c2]     = b1;
            workSsmCoeffs[instance][_c3]     = -a1*a1;
            workSsmCoeffs[instance][_c1]     = 1.0 - workSsmCoeffs[instance][_c2] - workSsmCoeffs[instance][_c3];
            workSsmCoeffs[instance][_period] = period;
      }
      int _indO = (i-2)%_ssmRingSize;
      int _indP = (i-1)%_ssmRingSize;
         workSsm[_indC][_inst+_price] = price;
         workSsm[_indC][_inst+_ssm]   = workSsmCoeffs[instance][_c1]*(price+workSsm[_indP][_inst+_price])/2.0 +
                                          workSsmCoeffs[instance][_c2]*       workSsm[_indP][_inst+_ssm]                                +
                                          workSsmCoeffs[instance][_c3]*       workSsm[_indO][_inst+_ssm];
   }                                      
   else for(int k=0; k<_ssmInstancesSize; k++) workSsm[_indC][_inst+k]= price;
return(workSsm[_indC][_inst+_ssm]);

#undef _period
#undef _c1
#undef _c2
#undef _c3
#undef _ssm
#undef _price
}