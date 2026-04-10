defmodule EBossWeb.Dev.DesignSystemLiveTest do
  use ExUnit.Case, async: false

  use EBossWeb, :verified_routes

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint EBossWeb.Endpoint

  setup do
    for app <- [:plug_crypto, :phoenix, :phoenix_html, :phoenix_live_view, :gettext] do
      {:ok, _} = Application.ensure_all_started(app)
    end

    if is_nil(Process.whereis(EBossWeb.Endpoint)) do
      start_supervised!(EBossWeb.Endpoint)
    end

    :ok
  end

  test "anonymous visitors can access the design system preview route" do
    conn = build_conn()
    assert {:ok, view, html} = live(conn, ~p"/dev/design-system")

    assert view.module == EBossWeb.Dev.DesignSystemLive
    assert html =~ "EBoss design system"
    assert has_element?(view, "#review-index")
    assert has_element?(view, "#review-matrix")
    assert has_element?(view, "#panels")
    assert has_element?(view, "#shells")
    assert has_element?(view, "#dashboard-states")
    assert has_element?(view, "#forms")
    assert has_element?(view, "#feedback")
    assert has_element?(view, "#navigation")
  end

  test "design system preview renders shared HEEx primitives and common states" do
    conn = build_conn()
    {:ok, view, _html} = live(conn, ~p"/dev/design-system")
    html = render(view)

    assert html =~ "Shared HEEx review index"
    assert html =~ "Theme and density review matrix"
    assert html =~ "Operator console first, marketing polish second."
    assert html =~ "Workflow shells and page composition"
    assert html =~ "Empty, loading, and error states keep the same operator-grade frame."
    assert html =~ "Field states and action controls"
    assert html =~ "Runtime feedback, flash messages, and semantic status"
    assert html =~ "Primary, secondary, and auth navigation patterns"
    assert html =~ "Authentication shell reference"
    assert html =~ "No escalations in this shell"
    assert html =~ "Nothing is queued for this workspace yet."
    assert html =~ "The latest sync did not complete."
    assert html =~ "Queued for review"
    assert html =~ "Delivery failed"
    assert html =~ "Disabled CTA"

    assert has_element?(view, "tbody#shell-preview-runs")
    assert has_element?(view, "tbody#shell-preview-runs tr#shell-run-queue-sync")
    assert has_element?(view, "#auth-shell-preview")
    assert has_element?(view, "input[name='workspace_slug']")
    assert has_element?(view, "select[name='execution_mode']")
    assert has_element?(view, "textarea[name='review_prompt']")
    assert has_element?(view, "input[name='notify'][type='checkbox']")
    assert has_element?(view, "input[name='operator_email_preview'][aria-invalid='true']")
    assert has_element?(view, "span[aria-disabled='true'][tabindex='-1']", "Disabled CTA")
    assert has_element?(view, "#preview-flash-info .ui-alert[data-tone='primary'][role='alert']")
    assert has_element?(view, "#preview-flash-error .ui-alert[data-tone='danger'][role='alert']")
  end
end
