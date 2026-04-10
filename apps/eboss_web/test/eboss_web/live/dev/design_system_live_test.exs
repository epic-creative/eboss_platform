defmodule EBossWeb.Dev.DesignSystemLiveTest do
  use ExUnit.Case, async: true

  use EBossWeb, :verified_routes

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint EBossWeb.Endpoint

  test "anonymous visitors can access the design system preview route" do
    conn = build_conn()
    assert {:ok, view, html} = live(conn, ~p"/dev/design-system")

    assert view.module == EBossWeb.Dev.DesignSystemLive
    assert html =~ "EBoss design system"
    assert has_element?(view, "#review-index")
    assert has_element?(view, "#review-matrix")
    assert has_element?(view, "#panels")
    assert has_element?(view, "#shells")
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
    assert html =~ "Field states and action controls"
    assert html =~ "Runtime feedback, flash messages, and semantic status"
    assert html =~ "Primary, secondary, and auth navigation patterns"
    assert html =~ "Authentication shell reference"
    assert html =~ "No escalations in this shell"
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
