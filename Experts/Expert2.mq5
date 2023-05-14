//+------------------------------------------------------------------+
//|                                                      Expert2.mq5 |
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
#include <Expert\Signal\SignalMA.mqh>
#include <Expert\Signal\SignalAC.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingParabolicSAR.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                 ="Expert2";   // Document name
ulong                    Expert_MagicNumber           =25877;       //
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
input int                Signal_MA_PeriodMA           =12;          // Moving Average(12,0,...) Period of averaging
input int                Signal_MA_Shift              =0;           // Moving Average(12,0,...) Time shift
input ENUM_MA_METHOD     Signal_MA_Method             =MODE_SMA;    // Moving Average(12,0,...) Method of averaging
input ENUM_APPLIED_PRICE Signal_MA_Applied            =PRICE_CLOSE; // Moving Average(12,0,...) Prices series
input double             Signal_MA_Weight             =1.0;         // Moving Average(12,0,...) Weight [0...1.0]
input double             Signal_AC_Weight             =1.0;         // Accelerator Oscillator Weight [0...1.0]
//--- inputs for trailing
input double             Trailing_ParabolicSAR_Step   =0.02;        // Speed increment
input double             Trailing_ParabolicSAR_Maximum=0.2;         // Maximum rate
//--- inputs for money
input double             Money_FixLot_Percent         =10.0;        // Percent
input double             Money_FixLot_Lots            =0.1;         // Fixed volume
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
//--- Creating filter CSignalMA
   CSignalMA *filter1=new CSignalMA;
   if(filter1==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter1");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter1);
//--- Set filter parameters
   filter1.PeriodMA(Signal_MA_PeriodMA);
   filter1.Shift(Signal_MA_Shift);
   filter1.Method(Signal_MA_Method);
   filter1.Applied(Signal_MA_Applied);
   filter1.Weight(Signal_MA_Weight);
//--- Creating filter CSignalAC
   CSignalAC *filter2=new CSignalAC;
   if(filter2==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter2");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter2);
//--- Set filter parameters
   filter2.Weight(Signal_AC_Weight);
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
   CMoneyFixedLot *money=new CMoneyFixedLot;
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
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
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