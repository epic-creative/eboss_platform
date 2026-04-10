defmodule EBossWeb.PublicPagePatternsTest do
  use ExUnit.Case, async: true

  alias EBossWeb.PublicPagePatterns

  test "defines the public section vocabulary and repeatable patterns" do
    assert Enum.map(PublicPagePatterns.all(), & &1.id) == [
             :hero,
             :proof_band,
             :feature_row,
             :cta_band,
             :closing_section
           ]

    assert Enum.map(PublicPagePatterns.repeatable(), & &1.id) == [
             :proof_band,
             :feature_row,
             :cta_band
           ]

    assert %{
             slug: "feature-row",
             repeatability: :repeatable,
             variants: ["standard", "reverse"],
             required_slots: required_slots,
             optional_slots: optional_slots
           } = PublicPagePatterns.fetch!(:feature_row)

    assert Enum.map(required_slots, & &1.id) == [:copy_rail, :supporting_frame]
    assert Enum.map(optional_slots, & &1.id) == [:signals]
  end

  test "maps the current home route to the standardized pattern names" do
    assert PublicPagePatterns.home_page_sections() == [
             %{
               id: :home_hero,
               label: "Home hero",
               pattern: :hero,
               selector: "[data-home-hero]",
               variant: "standard"
             },
             %{
               id: :home_proof,
               label: "Home proof strip",
               pattern: :proof_band,
               selector: "[data-home-proof-strip]",
               variant: "card grid"
             },
             %{
               id: :home_continuity,
               label: "Home continuity row",
               pattern: :feature_row,
               selector: ~s([data-home-story="continuity"]),
               variant: "standard"
             },
             %{
               id: :home_tempo,
               label: "Home tempo row",
               pattern: :feature_row,
               selector: ~s([data-home-story="tempo"]),
               variant: "reverse"
             },
             %{
               id: :home_closing,
               label: "Home closing section",
               pattern: :closing_section,
               selector: "[data-home-closing]",
               variant: "cta band plus public shell footer"
             },
             %{
               id: :home_cta,
               label: "Home CTA band",
               pattern: :cta_band,
               selector: "[data-public-cta-frame]",
               variant: "with detail cards"
             }
           ]

    assert PublicPagePatterns.slug(:proof_band) == "proof-band"
    assert PublicPagePatterns.repeatability(:hero) == "anchor"
    assert PublicPagePatterns.repeatability(:cta_band) == "repeatable"
  end
end
