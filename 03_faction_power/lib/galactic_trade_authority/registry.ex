defmodule GalacticTradeAuthority.Registry do
  use Ash.Domain

  resources do
    resource(GalacticTradeAuthority.Planet)
    resource(GalacticTradeAuthority.TradeResource)
    resource(GalacticTradeAuthority.PlanetRule)
    resource(GalacticTradeAuthority.Trader)
    resource(GalacticTradeAuthority.Shipment)
  end
end
