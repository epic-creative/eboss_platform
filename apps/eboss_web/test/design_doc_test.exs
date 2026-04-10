defmodule EBossWeb.DesignDocTest do
  use ExUnit.Case, async: true

  @design_doc Path.expand("../../../DESIGN.md", __DIR__)

  test "DESIGN.md codifies the shared EBoss visual DNA in concrete terms" do
    design_doc = File.read!(@design_doc)

    assert design_doc =~ "## Visual Thesis"
    assert design_doc =~ "## Shared Visual DNA"
    assert design_doc =~ "operator console"
    assert design_doc =~ "## Off-Brand Rejections"
    assert design_doc =~ "startup pitch deck"
  end

  test "DESIGN.md distinguishes dashboard, auth, and public surface expression" do
    design_doc = File.read!(@design_doc)

    assert design_doc =~ "## Surface Expression"
    assert design_doc =~ "### Dashboard surfaces"
    assert design_doc =~ "### Auth surfaces"
    assert design_doc =~ "### Public surfaces"
  end
end
