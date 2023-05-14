//+------------------------------------------------------------------+
//|                                                     MyExpert.mq5 |
//|                                                Angelica Almuenda |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Angelica Almuenda"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalSAR.mqh>
#include <Expert\Signal\SignalAMA.mqh>
#include <Expert\Signal\SignalRSI.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingParabolicSAR.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedRisk.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                 ="MyExpert";  // Document name
ulong                    Expert_MagicNumber           =28266;       //
bool                     Expert_EveryTick             =false;       //
//--- inputs for main signal
input int                Signal_ThresholdOpen         =10;          // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose        =10;          // Signal threshold value to close [0...100]
input double             Signal_PriceLevel            =0.0;         // Price level to execute a deal
input double             Signal_StopLevel             =50.0;        // Stop Loss level (in points)
input double             Signal_TakeLevel             =50.0;        // Take Profit level (in points)
input int                Signal_Expiration            =4;           // Expiration of pending orders (in bars)
input double             Signal_SAR_Step              =0.02;        // Parabolic SAR(0.02,0.2) Speed increment
input double             Signal_SAR_Maximum           =0.2;         // Parabolic SAR(0.02,0.2) Maximum rate
input double             Signal_SAR_Weight            =1.0;         // Parabolic SAR(0.02,0.2) Weight [0...1.0]
input int                Signal_AMA_PeriodMA          =10;          // Adaptive Moving Average(10,...) Period of averaging
input int                Signal_AMA_PeriodFast        =2;           // Adaptive Moving Average(10,...) Period of fast EMA
input int                Signal_AMA_PeriodSlow        =30;          // Adaptive Moving Average(10,...) Period of slow EMA
input int                Signal_AMA_Shift             =0;           // Adaptive Moving Average(10,...) Time shift
input ENUM_APPLIED_PRICE Signal_AMA_Applied           =PRICE_CLOSE; // Adaptive Moving Average(10,...) Prices series
input double             Signal_AMA_Weight            =1.0;         // Adaptive Moving Average(10,...) Weight [0...1.0]
input int                Signal_RSI_PeriodRSI         =8;           // Relative Strength Index(8,...) Period of calculation
input ENUM_APPLIED_PRICE Signal_RSI_Applied           =PRICE_CLOSE; // Relative Strength Index(8,...) Prices series
input double             Signal_RSI_Weight            =1.0;         // Relative Strength Index(8,...) Weight [0...1.0]
//--- inputs for trailing
input double             Trailing_ParabolicSAR_Step   =0.02;        // Speed increment
input double             Trailing_ParabolicSAR_Maximum=0.2;         // Maximum rate
//--- inputs for money
input double             Money_FixRisk_Percent        =0.1;         // Risk percentage
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.StopLevel(Signal_StopLevel);
   signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter CSignalSAR
   CSignalSAR *filter0=new CSignalSAR;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.Step(Signal_SAR_Step);
   filter0.Maximum(Signal_SAR_Maximum);
   filter0.Weight(Signal_SAR_Weight);
//--- Creating filter CSignalAMA
   CSignalAMA *filter1=new CSignalAMA;
   if(filter1==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter1");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter1);
//--- Set filter parameters
   filter1.PeriodMA(Signal_AMA_PeriodMA);
   filter1.PeriodFast(Signal_AMA_PeriodFast);
   filter1.PeriodSlow(Signal_AMA_PeriodSlow);
   filter1.Shift(Signal_AMA_Shift);
   filter1.Applied(Signal_AMA_Applied);
   filter1.Weight(Signal_AMA_Weight);
//--- Creating filter CSignalRSI
   CSignalRSI *filter2=new CSignalRSI;
   if(filter2==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter2");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter2);
//--- Set filter parameters
   filter2.PeriodRSI(Signal_RSI_PeriodRSI);
   filter2.Applied(Signal_RSI_Applied);
   filter2.Weight(Signal_RSI_Weight);
//--- Creation of trailing object
   CTrailingPSAR *trailing=new CTrailingPSAR;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
   trailing.Step(Trailing_ParabolicSAR_Step);
   trailing.Maximum(Trailing_ParabolicSAR_Maximum);
//--- Creation of money object
   CMoneyFixedRisk *money=new CMoneyFixedRisk;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Percent(Money_FixRisk_Percent);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
