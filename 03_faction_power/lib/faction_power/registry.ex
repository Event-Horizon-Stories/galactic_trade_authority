defmodule FactionPower.Registry do
  use Ash.Domain

  resources do
    resource(FactionPower.Trader)
    resource(FactionPower.Shipment)
  end
end
