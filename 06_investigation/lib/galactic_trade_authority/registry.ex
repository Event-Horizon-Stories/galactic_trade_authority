defmodule GalacticTradeAuthority.Registry do
  use Ash.Domain

  resources do
    resource(GalacticTradeAuthority.Resources.Trader)
    resource(GalacticTradeAuthority.Resources.Planet)
    resource(GalacticTradeAuthority.Resources.TradeResource)
    resource(GalacticTradeAuthority.Resources.PlanetRule)
    resource(GalacticTradeAuthority.Resources.Contract)
    resource(GalacticTradeAuthority.Resources.Shipment)
    resource(GalacticTradeAuthority.Resources.ShadowReport)
    resource(GalacticTradeAuthority.Resources.AuditRecord)
  end
end
