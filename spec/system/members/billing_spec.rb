require 'rails_helper'

describe 'Billing' do
  let(:member) { create(:member) }

  before do
    Capybara.app_host = 'http://membres.ragedevert.test'
    login(member)
  end

  it 'list open invoices' do
    create(:invoice, :open, :annual_fee, id: 4242,
      member: member, date: '2018-2-1', annual_fee: 42)

    visit '/'
    click_on 'Facturation'

    expect(page).to have_content('Factures ouvertes')
    expect(page).to have_content('1 facture ouverte')
    expect(page).to have_content(
      ['01.02.2018', 'Facture ouverte #4242 (Cotisation annuelle)', 'CHF 42.00'].join)
  end

  it 'list invoices and payments history' do
    inovice = create(:invoice, :halfday_participation, id: 242,
      member: member, date: '2018-4-12', paid_missing_halfday_works_amount: 120)
    create(:payment, invoice: inovice, member: member, date: '2018-5-1', amount: 120)

    visit '/billing'

    expect(page).to have_content('Historique')
    expect(page).to have_content(
      ['01.05.2018', 'Paiement de la facture #242', '-CHF 120.00'].join)
    expect(page).to have_content(
      ['12.04.2018', 'Facture #242 (½ Journée)', 'CHF 120.00'].join)
  end
end
