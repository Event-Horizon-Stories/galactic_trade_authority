defmodule ShadowMarketTest do
  use ExUnit.Case

  alias Ash.Error.Invalid
  alias ShadowMarket.ShadowReport

  setup do
    ShadowMarket.reset!()
    :ok
  end

  test "off-ledger evidence can exist without any official shipment match" do
    %{unmatched_report: report} = ShadowMarket.bootstrap_registry!()

    assert report.ledger_status == :unmatched
    assert report.shipment_id == nil
    assert report.report_summary =~ "no official shipment matched"
  end

  test "evidence can reconcile to an official shipment without changing the shipment itself" do
    %{matched_report: report, official_shipment: shipment} = ShadowMarket.bootstrap_registry!()

    assert report.ledger_status == :matched
    assert report.shipment_id == shipment.id
    assert report.report_summary =~ shipment.manifest_number
  end

  test "contradictory evidence is preserved and flagged instead of discarded" do
    %{contradicted_report: report} = ShadowMarket.bootstrap_registry!()

    assert report.ledger_status == :contradicted
    assert report.shipment_id != nil
    assert report.report_summary =~ "conflicts on"
    assert report.report_summary =~ "resource"
  end

  test "a report still needs at least one structured lead" do
    assert_raise Invalid, ~r/expected at least one structured lead/, fn ->
      ShadowReport.record!(%{
        report_number: "SR-5004",
        source_type: :informant
      })
    end
  end
end
