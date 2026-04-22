defmodule GalacticTradeAuthority.Registry do
  @moduledoc """
  The full GTA domain after the course has accumulated every major layer.

  By chapter 7, the same domain shape must operate separately for each tenant,
  so multitenancy becomes part of the legal boundary itself.
  """

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
