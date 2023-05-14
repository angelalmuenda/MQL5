//+------------------------------------------------------------------+
//|                                                    AutoTrail.mq5 |
//|                                                Angelica Almuenda |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Angelica Almuenda"
#property link "https://www.mql5.com"
#property version "1.00"
//+------------------------------------------------------------------+
//| includes                                                         |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
//--- inputs for expert
int STOP_LOSS_POINTS = 500;
int TAKE_PROFIT_POINTS = 1000;
double sureProfitPercent = 0.05; // every multiples change SL
double startTrail = 0.50;
double percentPriceSL = 0.30;
string currentSymbol = "";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //---
  currentSymbol = Symbol();
  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //---
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  //---
  int totalNumberOrders = PositionsTotal();
  //printf("#totalNumberOrders %d", totalNumberOrders);
  for (int i = 0; i < totalNumberOrders; i++)
  {
    ulong ticket = PositionGetTicket(i);
    if (PositionSelectByTicket(ticket))
    {
      if (currentSymbol != PositionGetString(POSITION_SYMBOL)) continue;
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_tp = PositionGetDouble(POSITION_TP);
      double dividend = 100000;
      if (currentSymbol == "USDJPY") {
        dividend = 1000;
      }

      // new trades without SL and TP only
      if (current_sl == 0 && current_tp == 0) {
        double sl = 0.0; 
        double tp = 0.0;
        
        if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)
        {
          sl = openPrice + (STOP_LOSS_POINTS / dividend);
          tp = openPrice - (TAKE_PROFIT_POINTS / dividend);
        }
        else if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)
        {
          sl = openPrice - (STOP_LOSS_POINTS / dividend);
          tp = openPrice + (TAKE_PROFIT_POINTS / dividend);
        }

        CTrade trade = new CTrade;
        if (trade.PositionModify(ticket, sl, tp))
        {
          printf("SL set to %f; TP set to %f", sl, tp);
        }

        continue;
      }

      double change = 0;
      if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)
      {
        change = currentPrice - openPrice;
      }
      else if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)
      {
        change = openPrice - currentPrice;
      }

      double changePercent = (change / openPrice) * 100;
      changePercent = ceil(changePercent * 100) / 100; // round up to 2 decimals
      //printf("%G", changePercent);

      if (changePercent < startTrail) continue;

      // check multiple
      // use if (n % 2 == 0) for whole number multiples
      double quotient = changePercent / sureProfitPercent;
      if (fmod(quotient, 1.0) != 0.0) continue;

      // change Stop Loss if applicable
      double newSL = 0.0;
      double newTP = 0.0;
      if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)
      {
        newSL = currentPrice + ((percentPriceSL / 100.0) * currentPrice);
        newSL = ceil(newSL * dividend) / dividend; // round up to 5 decimals
        newTP = currentPrice - (TAKE_PROFIT_POINTS / dividend);
        if (newSL >= current_sl && newTP >= current_tp) continue;
      }
      else if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)
      {
        newSL = currentPrice - ((percentPriceSL / 100.0) * currentPrice);
        newSL = ceil(newSL * dividend) / dividend; // round up to 5 decimals
        newTP = currentPrice + (TAKE_PROFIT_POINTS / dividend);
        if (newSL <= current_sl && newTP <= current_tp) continue;
      }
      //printf(current_sl);
      //printf(newSL);
      CTrade trade = new CTrade;
      if (trade.PositionModify(ticket, newSL, newTP))
      { // remove take profit
        printf("SL Changed to %f; TP changes to %f", newSL, newTP);
      }
    }
  }
}
//+------------------------------------------------------------------+
