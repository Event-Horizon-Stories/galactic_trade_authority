defmodule Investigation.Registry do
  use Ash.Domain

  resources do
    resource(Investigation.Trader)
    resource(Investigation.Planet)
    resource(Investigation.TradeResource)
    resource(Investigation.PlanetRule)
    resource(Investigation.Contract)
    resource(Investigation.Shipment)
    resource(Investigation.ShadowReport)
    resource(Investigation.AuditRecord)
  end
end
