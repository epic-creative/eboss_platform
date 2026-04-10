defmodule EBossWeb.PublicPagePatterns do
  @moduledoc """
  Stable vocabulary for composing public-facing pages before full page migration.

  The goal here is to name the recurring section types once, document which ones
  should be repeatable, and map the current home page to those names so follow-up
  stories can migrate markup against an explicit contract.
  """

  @type slot :: %{
          id: atom(),
          label: String.t(),
          description: String.t()
        }

  @type pattern :: %{
          id: atom(),
          slug: String.t(),
          label: String.t(),
          repeatability: :anchor | :repeatable,
          summary: String.t(),
          use_when: String.t(),
          variants: [String.t()],
          required_slots: [slot()],
          optional_slots: [slot()]
        }

  @type home_section :: %{
          id: atom(),
          label: String.t(),
          pattern: atom(),
          selector: String.t(),
          variant: String.t()
        }

  @patterns [
    %{
      id: :hero,
      slug: "hero",
      label: "Hero",
      repeatability: :anchor,
      summary: "Open with one product-defining idea, clear narrative copy, and the first action.",
      use_when:
        "Use once at the top of a public page when the route needs space to establish product posture before supporting proof.",
      variants: ["standard"],
      required_slots: [
        %{
          id: :heading_block,
          label: "Heading block",
          description: "Eyebrow, title, and subtitle that set the page thesis."
        },
        %{
          id: :narrative,
          label: "Narrative copy",
          description: "One or two supporting paragraphs that explain the opening claim."
        },
        %{
          id: :actions,
          label: "Action cluster",
          description:
            "Primary and secondary next steps that move directly into auth or product flow."
        },
        %{
          id: :proof_frame,
          label: "Framed proof panel",
          description: "A single supporting surface that grounds the hero in product reality."
        }
      ],
      optional_slots: [
        %{
          id: :signals,
          label: "Signal badges",
          description: "Short supporting cues that summarize the posture of the route."
        }
      ]
    },
    %{
      id: :proof_band,
      slug: "proof-band",
      label: "Proof band",
      repeatability: :repeatable,
      summary:
        "Turn narrative claims into compact evidence using cards, metrics, or proof statements.",
      use_when:
        "Repeat between larger narrative beats when the page needs concrete proof without resetting into another hero.",
      variants: ["card grid", "metric strip"],
      required_slots: [
        %{
          id: :section_heading,
          label: "Section heading",
          description: "A short label, heading, and supporting line that frame the proof set."
        },
        %{
          id: :proof_items,
          label: "Proof items",
          description: "Two to four proof cards or metrics that confirm the preceding claim."
        }
      ],
      optional_slots: []
    },
    %{
      id: :feature_row,
      slug: "feature-row",
      label: "Feature row",
      repeatability: :repeatable,
      summary:
        "Pair one narrative rail with one supporting frame so a single idea can carry a full section.",
      use_when:
        "Repeat after the hero for continuity, trust, or tempo beats. Reverse the rails when the page needs rhythm changes without inventing a new layout.",
      variants: ["standard", "reverse"],
      required_slots: [
        %{
          id: :copy_rail,
          label: "Copy rail",
          description: "Kicker, heading, narrative copy, and optional signal badges."
        },
        %{
          id: :supporting_frame,
          label: "Supporting frame",
          description: "One framed panel that carries nested cards or structured detail."
        }
      ],
      optional_slots: [
        %{
          id: :signals,
          label: "Signal cluster",
          description: "Compact labels or badges that reinforce the section claim."
        }
      ]
    },
    %{
      id: :cta_band,
      slug: "cta-band",
      label: "CTA band",
      repeatability: :repeatable,
      summary:
        "Resolve a narrative beat into action without changing shell language or material treatment.",
      use_when:
        "Repeat near transitions and endcaps when the page should convert evidence into a clear next step.",
      variants: ["primary-secondary", "with detail cards"],
      required_slots: [
        %{
          id: :heading_block,
          label: "Heading block",
          description: "Eyebrow, title, and supporting line that restate the handoff."
        },
        %{
          id: :actions,
          label: "Action cluster",
          description:
            "Primary and optional secondary actions that lead into auth or the working shell."
        }
      ],
      optional_slots: [
        %{
          id: :details,
          label: "Detail cards",
          description:
            "Supporting cards that reinforce route continuity, system parity, or next-step context."
        }
      ]
    },
    %{
      id: :closing_section,
      slug: "closing-section",
      label: "Closing section",
      repeatability: :anchor,
      summary:
        "End the public narrative by wrapping the final CTA band inside the shell's closing context.",
      use_when:
        "Use once at the end of a public page to close the story, keep the shell visible, and hand the visitor into auth or the dashboard path.",
      variants: ["cta band plus public shell footer"],
      required_slots: [
        %{
          id: :cta_band,
          label: "CTA band",
          description: "A CTA band that resolves the page into a concrete next action."
        },
        %{
          id: :shell_context,
          label: "Shell context",
          description:
            "Footer or route context that keeps the closing moment inside the public shell family."
        }
      ],
      optional_slots: []
    }
  ]

  @home_page_sections [
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

  @spec all() :: [pattern()]
  def all, do: @patterns

  @spec repeatable() :: [pattern()]
  def repeatable do
    Enum.filter(@patterns, &(&1.repeatability == :repeatable))
  end

  @spec fetch!(atom()) :: pattern()
  def fetch!(id) when is_atom(id) do
    Enum.find(@patterns, &(&1.id == id)) ||
      raise ArgumentError, "unknown public section pattern: #{inspect(id)}"
  end

  @spec slug(atom()) :: String.t()
  def slug(id), do: fetch!(id).slug

  @spec repeatability(atom()) :: String.t()
  def repeatability(id) do
    id
    |> fetch!()
    |> Map.fetch!(:repeatability)
    |> Atom.to_string()
  end

  @spec home_page_sections() :: [home_section()]
  def home_page_sections, do: @home_page_sections
end
