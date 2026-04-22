defmodule PlanetaryLaw.Registry do
  use Ash.Domain

  resources do
    resource(PlanetaryLaw.Trader)
    resource(PlanetaryLaw.Planet)
    resource(PlanetaryLaw.TradeResource)
    resource(PlanetaryLaw.PlanetRule)
    resource(PlanetaryLaw.Shipment)
  end
end
