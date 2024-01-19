require "rails_helper"

describe "Admin sessions" do
  it "creates a new session from email", sidekiq: :inline do
    admin = create(:admin, email: "thibaud@thibaud.gg")

    visit "/"
    expect(current_path).to eq "/login"
    expect(flash_alert).to eq "Merci de vous authentifier pour accéder à votre compte."

    fill_in "Email", with: " Thibaud@thibaud.gg "
    click_button "Envoyer"

    session = admin.sessions.last

    expect(session.email).to eq "thibaud@thibaud.gg"
    expect(SessionMailer.deliveries.size).to eq 1

    expect(current_path).to eq "/login"
    expect(flash_notice).to eq "Merci! Un email vient de vous être envoyé."

    open_email("thibaud@thibaud.gg")
    current_email.click_link "Accéder à mon compte admin"

    expect(current_path).to eq "/"
    expect(flash_notice).to eq "Vous êtes maintenant connecté."

    delete_session(admin)
    visit "/"

    expect(current_path).to eq "/login"
    expect(flash_alert).to eq "Merci de vous authentifier pour accéder à votre compte."
  end

  it "does not accept blank email" do
    visit "/"
    expect(current_path).to eq "/login"

    fill_in "Email", with: ""
    click_button "Envoyer"

    expect(SessionMailer.deliveries.size).to eq 0

    expect(current_path).to eq "/sessions"
    expect(page).to have_selector("p.inline-errors", text: "n'est pas valide")
  end

  it "does not accept invalid email" do
    visit "/"
    expect(current_path).to eq "/login"

    fill_in "Email", with: "@foo"
    click_button "Envoyer"

    expect(SessionMailer.deliveries.size).to eq 0

    expect(current_path).to eq "/sessions"
    expect(page).to have_selector("p.inline-errors", text: "n'est pas valide")
  end

  it "does not accept unknown email" do
    visit "/"
    expect(current_path).to eq "/login"

    fill_in "Email", with: "unknown@admin.com"
    click_button "Envoyer"

    expect(SessionMailer.deliveries.size).to eq 0

    expect(current_path).to eq "/sessions"
    expect(page).to have_selector("p.inline-errors", text: "Email inconnu")
  end

  it "does not accept old session when not logged in" do
    old_session = create(:session, :admin, created_at: 1.hour.ago)

    visit "/sessions/#{old_session.token}"

    expect(current_path).to eq "/login"
    expect(flash_alert).to eq "Votre lien de connexion n'est plus valide, merci d'en demander un nouveau."
  end

  it "handles old session when already logged in" do
    admin = create(:admin)
    login(admin)
    old_session = create(:session, admin: admin, created_at: 1.hour.ago)

    visit "/sessions/#{old_session.token}"

    expect(current_path).to eq "/"
    expect(flash_notice).to eq "Vous êtes déjà connecté."
  end

  it "logout session without email" do
    admin = create(:admin)
    login(admin)
    admin.sessions.last.update!(email: nil)

    visit "/"

    expect(current_path).to eq "/login"
    expect(flash_alert).to eq "Votre session a expirée, merci de vous authentifier à nouveau."

    visit "/"

    expect(current_path).to eq "/login"
    expect(flash_alert).to eq "Merci de vous authentifier pour accéder à votre compte."
  end

  it "logout expired session" do
    admin = create(:admin)
    login(admin)
    admin.sessions.last.update!(created_at: 1.year.ago)

    visit "/"

    expect(current_path).to eq "/login"
    expect(flash_alert).to eq "Votre session a expirée, merci de vous authentifier à nouveau."

    visit "/"

    expect(current_path).to eq "/login"
    expect(flash_alert).to eq "Merci de vous authentifier pour accéder à votre compte."
  end

  it "update last usage column every hour when using the session" do
    admin = create(:admin)

    travel_to Time.new(2018, 7, 6, 1) do
      login(admin)

      expect(admin.sessions.last).to have_attributes(
        last_used_at: Time.new(2018, 7, 6, 1),
        last_remote_addr: "127.0.0.1",
        last_user_agent: "-")
    end

    travel_to Time.new(2018, 7, 6, 1, 59) do
      visit "/"
      expect(admin.sessions.last).to have_attributes(
        last_used_at: Time.new(2018, 7, 6, 1))
    end

    travel_to Time.new(2018, 7, 6, 2, 0, 1) do
      visit "/"
      expect(admin.sessions.last).to have_attributes(
        last_used_at: Time.new(2018, 7, 6, 2, 0, 1))
    end
  end
end
