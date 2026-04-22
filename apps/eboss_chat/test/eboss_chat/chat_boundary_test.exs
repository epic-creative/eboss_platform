defmodule EBossChat.ChatBoundaryTest do
  use EBoss.DataCase, async: false

  alias EBossChat
  alias EBossChat.Service
  alias EBossChat.TestSupport

  @moduletag :boundary

  test "workspace members can read shared sessions and continue them in user-owned workspaces" do
    owner = TestSupport.register_user()
    member = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    _membership = TestSupport.create_workspace_member(owner, workspace, member)

    {:ok, session} = Service.create_session(workspace.id, "Roadmap review thread", actor: owner)
    assert session.title == "Roadmap review thread"

    assert {:ok, %{assistant_message: first_reply}} =
             Service.stream_session_reply(session, "Owner kickoff question", actor: owner)

    assert first_reply.status == :complete
    assert first_reply.total_tokens > 0

    shared_session =
      EBossChat.get_session_in_workspace!(session.id, workspace.id,
        actor: member,
        load: [created_by_user: []]
      )

    assert shared_session.id == session.id

    assert {:ok, %{assistant_message: second_reply}} =
             Service.stream_session_reply(shared_session, "Member follow-up", actor: member)

    assert second_reply.status == :complete
    assert second_reply.body =~ "Member follow-up"

    assert {:ok, messages} =
             EBossChat.list_messages_in_session(session.id, workspace.id,
               actor: owner,
               load: [created_by_user: []]
             )

    assert Enum.map(messages, & &1.role) == [:user, :assistant, :user, :assistant]
    assert Enum.at(messages, 2).created_by_user_id == member.id
    assert Enum.at(messages, 3).total_tokens > 0
  end

  test "organization members can open shared sessions in organization-owned workspaces" do
    owner = TestSupport.register_user()
    admin = TestSupport.register_user()
    member = TestSupport.register_user()
    outsider = TestSupport.register_user()
    {organization, workspace} = TestSupport.create_org_workspace(owner)

    _admin_membership = TestSupport.add_org_member(owner, organization, admin, :admin)
    _member_membership = TestSupport.add_org_member(owner, organization, member, :member)

    {:ok, session} = Service.create_session(workspace.id, "Org planning thread", actor: owner)

    assert {:ok, session_for_admin} =
             EBossChat.get_session_in_workspace(session.id, workspace.id,
               actor: admin,
               load: [created_by_user: []]
             )

    assert session_for_admin.id == session.id

    assert {:ok, %{assistant_message: reply}} =
             Service.stream_session_reply(session, "Org kickoff", actor: member)

    assert reply.body =~ "Org kickoff"

    assert {:error, :not_found} =
             EBossChat.get_session_in_workspace(session.id, workspace.id, actor: outsider)
  end

  test "archive is allowed for the session creator and workspace admins but denied to regular members" do
    owner = TestSupport.register_user()
    admin = TestSupport.register_user()
    member = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    _admin_membership = TestSupport.create_workspace_member(owner, workspace, admin, :admin)
    _member_membership = TestSupport.create_workspace_member(owner, workspace, member, :member)

    {:ok, session} = Service.create_session(workspace.id, "Archive me", actor: owner)

    assert {:error, %Ash.Error.Forbidden{}} = Service.archive_session(session, actor: member)

    assert {:ok, archived_by_admin} = Service.archive_session(session, actor: admin)
    assert archived_by_admin.status == :archived

    assert {:ok, active_sessions} =
             EBossChat.list_active_sessions_in_workspace(workspace.id, actor: owner)

    refute Enum.any?(active_sessions, &(&1.id == session.id))

    {:ok, second_session} = Service.create_session(workspace.id, "Creator archive", actor: owner)
    assert {:ok, archived_by_creator} = Service.archive_session(second_session, actor: owner)
    assert archived_by_creator.status == :archived
  end

  test "only one assistant run can be active per session" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    {:ok, session} = Service.create_session(workspace.id, "Busy thread", actor: owner)

    {:ok, _pending_message} =
      EBossChat.create_chat_message(
        %{
          session_id: session.id,
          workspace_id: workspace.id,
          role: :assistant,
          body: "",
          status: :pending,
          sequence: EBossChat.next_sequence_for_session(session.id),
          created_by_user_id: nil
        },
        authorize?: false
      )

    assert {:error, :session_busy} =
             Service.stream_session_reply(session, "This should not run", actor: owner)
  end

  test "assistant replies persist usage totals and session aggregates" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)

    {:ok, session} =
      Service.create_session(
        workspace.id,
        "Need a deliberately long title seed so truncation stays under the chat limit",
        actor: owner
      )

    assert String.length(session.title) <= 80

    assert {:ok, %{assistant_message: assistant_message}} =
             Service.stream_session_reply(
               session,
               "Summarize the current workspace plans in a concise way",
               actor: owner
             )

    assert assistant_message.provider == "anthropic"
    assert assistant_message.model == "anthropic:claude-haiku-4-5-20251001"
    assert assistant_message.input_tokens > 0
    assert assistant_message.output_tokens > 0

    assert assistant_message.total_tokens ==
             assistant_message.input_tokens + assistant_message.output_tokens

    reloaded_session =
      EBossChat.get_session_in_workspace!(session.id, workspace.id,
        actor: owner,
        load: [:message_count, :total_input_tokens, :total_output_tokens, :total_tokens_sum]
      )

    assert reloaded_session.message_count == 2
    assert reloaded_session.total_input_tokens == assistant_message.input_tokens
    assert reloaded_session.total_output_tokens == assistant_message.output_tokens
    assert reloaded_session.total_tokens_sum == assistant_message.total_tokens

    assert EBossChat.usage_totals_for_sessions([reloaded_session]) == %{
             sessions: 1,
             input_tokens: assistant_message.input_tokens,
             output_tokens: assistant_message.output_tokens,
             total_tokens: assistant_message.total_tokens
           }
  end

  test "assistant replies can use the OpenAI chat model from the catalog" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    {:ok, session} = Service.create_session(workspace.id, "OpenAI thread", actor: owner)
    {:ok, openai_model} = EBossChat.resolve_chat_model("openai_gpt_4o_mini")

    assert {:ok, %{assistant_message: assistant_message}} =
             Service.stream_session_reply(session, "Use the selected OpenAI provider",
               actor: owner,
               chat_model: openai_model
             )

    assert assistant_message.provider == "openai"
    assert assistant_message.model == "openai:gpt-4o-mini"
    assert assistant_message.body =~ "OpenAI mock reply"
  end

  test "chat model catalog is a fixed whitelist and ignores app config overrides" do
    original_models = Application.get_env(:eboss_chat, :chat_models)
    original_default = Application.get_env(:eboss_chat, :default_chat_model_key)

    Application.put_env(:eboss_chat, :chat_models, [])
    Application.put_env(:eboss_chat, :default_chat_model_key, "unsupported_model")

    try do
      assert EBossChat.default_chat_model_key() == "anthropic_haiku_4_5"

      assert Enum.map(EBossChat.chat_model_options(), & &1.key) == [
               "anthropic_haiku_4_5",
               "openai_gpt_4o_mini"
             ]

      assert {:ok, anthropic_model} = EBossChat.resolve_chat_model(nil)
      assert anthropic_model.key == "anthropic_haiku_4_5"
      assert {:error, :unsupported_chat_model} = EBossChat.resolve_chat_model("unsupported_model")
    after
      restore_env(:chat_models, original_models)
      restore_env(:default_chat_model_key, original_default)
    end
  end

  test "failed assistant runs mark the pending assistant message as error" do
    owner = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    {:ok, session} = Service.create_session(workspace.id, "Failure thread", actor: owner)

    assert {:error, "The fake chat runtime rejected this request."} =
             Service.stream_session_reply(session, "please fail chat now", actor: owner)

    {:ok, messages} =
      EBossChat.list_messages_in_session(session.id, workspace.id,
        actor: owner,
        load: [created_by_user: []]
      )

    assert Enum.map(messages, & &1.role) == [:user, :assistant]

    assistant = Enum.at(messages, 1)
    assert assistant.status == :error
    assert assistant.error_message == "The fake chat runtime rejected this request."
    assert assistant.total_tokens == 0
  end

  test "outsiders do not see chat sessions in workspaces they do not belong to" do
    owner = TestSupport.register_user()
    outsider = TestSupport.register_user()
    workspace = TestSupport.create_user_workspace(owner)
    {:ok, _session} = Service.create_session(workspace.id, "Private thread", actor: owner)

    assert {:ok, []} = EBossChat.list_sessions_in_workspace(workspace.id, actor: outsider)
  end

  defp restore_env(key, nil), do: Application.delete_env(:eboss_chat, key)
  defp restore_env(key, value), do: Application.put_env(:eboss_chat, key, value)
end
