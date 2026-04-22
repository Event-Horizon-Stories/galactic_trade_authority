defmodule Order.Registry do
  use Ash.Domain

  resources do
    resource(Order.Trader)
    resource(Order.Planet)
    resource(Order.TradeResource)
    resource(Order.Shipment)
  end
end
