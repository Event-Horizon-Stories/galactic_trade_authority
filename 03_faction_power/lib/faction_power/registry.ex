defmodule FactionPower.Registry do
  use Ash.Domain

  resources do
    resource(FactionPower.Planet)
    resource(FactionPower.TradeResource)
    resource(FactionPower.PlanetRule)
    resource(FactionPower.Trader)
    resource(FactionPower.Shipment)
  end
end
