defmodule ContractLoopholes.Registry do
  use Ash.Domain

  resources do
    resource(ContractLoopholes.Trader)
    resource(ContractLoopholes.Planet)
    resource(ContractLoopholes.TradeResource)
    resource(ContractLoopholes.PlanetRule)
    resource(ContractLoopholes.Contract)
    resource(ContractLoopholes.Shipment)
  end
end
