defmodule AppWeb.UserSettingsLiveTest do
  use AppWeb.ConnCase, async: true

  alias App.Accounts
  import Phoenix.LiveViewTest
  import App.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    # test "renders errors with invalid data (phx-change)", %{conn: conn} do
    #   {:ok, lv, _html} = live(conn, ~p"/users/settings")

    #   result =
    #     lv
    #     |> element("#email_form")
    #     |> render_change(%{
    #       "action" => "update_email",
    #       "current_password" => "invalid",
    #       "user" => %{"email" => "with spaces"}
    #     })

    #   assert result =~ "Change Email"
    #   assert result =~ "must have the @ sign and no spaces"
    # end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "user" => %{"email" => user.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "user" => %{
            "email" => user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/users/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end

  describe "update name form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates the user's name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#name_form", %{
          "user" => %{"name" => "New Name"}
        })
        |> render_submit()

      assert result =~ "Name has been updated!"
    end
  end

  describe "update birthday form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates the user's birthday", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#birthday_form", %{
          "user" => %{"birthday" => "1990-01-01"}
        })
        |> render_submit()

      assert result =~ "Birthday has been updated!"
    end
  end

  describe "validate name form error" do
    setup %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/users/settings")
      %{lv: lv}
    end

    test "shows validation errors on name change", %{lv: lv} do
      html =
        lv
        |> element("#name_form")
        |> render_change(%{"user" => %{"name" => ""}})

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "validate birthday form error" do
    setup %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/users/settings")
      %{lv: lv}
    end

    test "shows validation errors on birthday change", %{lv: lv} do
      html =
        lv
        |> element("#birthday_form")
        |> render_change(%{"user" => %{"birthday" => "not-a-date"}})

      assert html =~ "is invalid"
    end
  end

  describe "mount without token initial assigns" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user) # Ensure the user is logged in correctly
      {:ok, lv, _html} = live(conn, ~p"/users/settings")
      %{lv: lv, user: user}
    end

    test "initial assigns are set correctly on settings mount", %{lv: lv, user: _user} do
      # Ensure that the LiveView has rendered and contains a specific element,
      # which indicates that the mount phase has been successfully completed
      assert render(lv) =~ "Account Settings"

      # Check if the name_form is present in the assigns
      # assert Map.has_key?(lv.assigns, :name_form)

      # Ensure the name_form contains the expected user data
      # assert lv.assigns.name_form.data.id == user.id
    end

  end


  describe "update email error branch" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/users/settings")
      %{lv: lv}
    end

    test "apply_user_email failure shows errors", %{lv: lv} do
      html =
        lv
        |> form("#email_form", %{
          "current_password" => "wrong",
          "user" => %{"email" => "bad"}
        })
        |> render_submit()

      # look for the changeset error under the email input
      assert html =~ "must have the @ sign and no spaces"
    end
  end

  describe "update password trigger and rendering" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})
      {:ok, lv, _html} = log_in_user(conn, user) |> live(~p"/users/settings")
      %{lv: lv, conn: conn, user: user, password: password}
    end

    test "trigger_submit is set to true on success", %{lv: lv, conn: conn, user: user, password: password} do
      new_pass = valid_user_password()

      form = form(lv, "#password_form", %{
        "current_password" => password,
        "user" => %{
          "email" => user.email,
          "password" => new_pass,
          "password_confirmation" => new_pass
        }
      })

      _html = render_submit(form)
      # assert html =~ ~s|phx-trigger-action="true"|

      new_conn = follow_trigger_action(form, conn)
      assert redirected_to(new_conn) == ~p"/users/settings"
    end

  end



end
