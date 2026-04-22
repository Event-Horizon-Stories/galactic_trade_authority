defmodule Investigation.RuleEngine do
  alias Investigation.{Contract, Planet, PlanetRule, TradeResource}

  def evaluate(params) do
    route_rules =
      applicable_rules(params.origin_planet_id, params.destination_planet_id, params.resource_id)

    contract = matching_contract(params)
    tax_due = tax_due(params.declared_value || 0, route_rules, contract)
    route_decision = route_decision(route_rules, contract)
    compliance_summary = route_summary(route_rules)

    %{
      route_rules: route_rules,
      contract: contract,
      tax_due: tax_due,
      route_classification: route_classification(route_rules),
      compliance_summary: compliance_summary,
      route_decision: route_decision,
      override_summary: override_summary(route_rules, contract)
    }
  end

  defp applicable_rules(origin_planet_id, destination_planet_id, resource_id) do
    PlanetRule.list!()
    |> Enum.filter(fn rule ->
      rule.resource_id == resource_id and
        ((rule.direction == :export and rule.planet_id == origin_planet_id) or
           (rule.direction == :import and rule.planet_id == destination_planet_id))
    end)
  end

  defp matching_contract(%{contract_id: nil}), do: nil

  defp matching_contract(%{contract_id: contract_id} = params) do
    Contract.list!()
    |> Enum.find(fn contract ->
      contract.id == contract_id and
        contract.trader_id == params.trader_id and
        contract.resource_id == params.resource_id and
        contract.destination_planet_id == params.destination_planet_id
    end)
  end

  defp matching_contract(_params), do: nil

  defp tax_due(declared_value, route_rules, contract) do
    if contract && contract.override_type == :tax_exemption do
      0
    else
      rate =
        route_rules
        |> Enum.filter(&(&1.effect == :tax))
        |> Enum.reduce(0, fn rule, acc -> acc + (rule.tax_rate || 0) end)

      div(declared_value * rate, 100)
    end
  end

  defp route_decision(route_rules, contract) do
    banned? = Enum.any?(route_rules, &(&1.effect == :ban))

    cond do
      banned? && contract && contract.override_type == :restricted_permit ->
        :permitted_by_contract

      banned? ->
        :blocked

      contract && contract.override_type == :tax_exemption ->
        :tax_exempt

      true ->
        :standard
    end
  end

  defp route_classification([]), do: :standard
  defp route_classification(_route_rules), do: :locally_adjusted

  defp route_summary(route_rules) do
    route_rules
    |> Enum.map(&rule_summary/1)
    |> Enum.join("; ")
    |> blank_to_nil()
  end

  defp override_summary(route_rules, nil) do
    route_summary(route_rules)
  end

  defp override_summary(route_rules, contract) do
    [Enum.map(route_rules, &rule_summary/1), contract_summary(contract)]
    |> List.flatten()
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("; ")
    |> blank_to_nil()
  end

  defp rule_summary(rule) do
    planet = find_planet!(rule.planet_id)
    resource = find_resource!(rule.resource_id)
    "#{planet.name} #{rule.direction} #{rule.effect}: #{resource.name} - #{rule.rationale}"
  end

  defp contract_summary(contract) do
    "contract #{contract.contract_code}: #{contract.override_type} - #{contract.rationale}"
  end

  defp find_planet!(planet_id) do
    Planet.list!()
    |> Enum.find(&(&1.id == planet_id))
  end

  defp find_resource!(resource_id) do
    TradeResource.list!()
    |> Enum.find(&(&1.id == resource_id))
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
