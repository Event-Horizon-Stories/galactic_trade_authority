defmodule ShadowMarket.Registry do
  use Ash.Domain

  resources do
    resource(ShadowMarket.Trader)
    resource(ShadowMarket.Planet)
    resource(ShadowMarket.TradeResource)
    resource(ShadowMarket.Shipment)
    resource(ShadowMarket.ShadowReport)
  end
end
