defmodule GalacticTradeAuthority.Registry do
  @moduledoc """
  The Ash domain for the first GTA registry.

  In lesson 1, the Authority recognizes only traders, planets, resources, and
  shipments. Keeping the domain this small makes it easier to see how Ash uses
  domains to define the official boundary of the system.
  """

  use Ash.Domain

  resources do
    resource(GalacticTradeAuthority.Trader)
    resource(GalacticTradeAuthority.Planet)
    resource(GalacticTradeAuthority.TradeResource)
    resource(GalacticTradeAuthority.Shipment)
  end
end
