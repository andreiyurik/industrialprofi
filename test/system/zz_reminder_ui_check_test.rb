require "application_system_test_case"

class ReminderUiCheck < ApplicationSystemTestCase
  test "account emails card and unsubscribe page" do
    user = users(:member)

    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    find(".auth__submit").click
    sleep 0.5

    visit account_path
    sleep 1.2
    save_screenshot(Rails.root.join("tmp/screenshots/account_emails.png"))
    assert_text "Напоминание о продолжении учёбы"

    checkbox = find("input[name='user[reminder_emails]'][type='checkbox']")
    page.execute_script("const cb = document.getElementById('user_reminder_emails'); if (cb.checked) cb.click();")
    puts "CHECKED after uncheck: #{checkbox.checked?}"
    form = checkbox.ancestor("form")
    puts "FORM action=#{form[:action]} method=#{form[:method]} buttons=#{form.all('input[type=submit], button').map { |b| b[:value] || b.text }.inspect}"
    form.find("input[type=submit], button[type=submit]", match: :first).click
    sleep 1.5
    puts "AFTER CLICK url=#{current_url} reminder=#{user.reload.reminder_emails?}"
    save_screenshot(Rails.root.join("tmp/screenshots/account_after_save.png"))
    assert_not user.reload.reminder_emails?

    visit unsubscribe_path(user.generate_token_for(:email_unsubscribe))
    sleep 0.3
    assert_text "Вы отписались от напоминаний"
    save_screenshot(Rails.root.join("tmp/screenshots/unsubscribe.png"))

    visit unsubscribe_path("garbage")
    sleep 0.3
    assert_text "Ссылка не сработала"
    save_screenshot(Rails.root.join("tmp/screenshots/unsubscribe_invalid.png"))
  end
end
