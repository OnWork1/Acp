require 'rails_helper'

describe Email do
  it 'delivers member-activated template', freeze: '2020-01-01' do
    member = create(:member, :inactive, emails: 'john@doe.com')
    basket_size = create(:basket_size,
      activity_participations_demanded_annualy: 3)
    create(:basket_complement, id: 1)
    create(:basket_complement, id: 2)
    Current.acp.update!(
      notification_member_activated: '1',
      trial_basket_count: 4)

    # activate the member
    create(:membership,
      member: member,
      basket_size: basket_size,
      memberships_basket_complements_attributes: {
        '0' => { basket_complement_id: 1, quantity: 1 },
        '1' => { basket_complement_id: 2, quantity: 1 }
      },
      started_on: '2020-02-01',
      ended_on: '2020-12-31')

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to eq(
      from: Current.acp.email_default_from,
      to: 'john@doe.com',
      template: 'member-activated',
      template_data: {
        action_url: 'https://membres.ragedevert.ch',
        fr: true,
        membership_start_date: '1 février 2020',
        membership_end_date: '31 décembre 2020',
        first_delivery_data: '4 février 2020',
        "basket_size_id_#{basket_size.id}": true,
        "depot_id_#{Depot.first.id}": true,
        "basket_complement_id_1": true,
        "basket_complement_id_2": true,
        trial_baskets: 4,
        activity_participations_demanded: 3
      },
      attachments: [])
  end

  it 'delivers member-activity-reminder template' do
    member = create(:member, emails: 'john@doew.com')
    activity = create(:activity,
      date: '24.03.2018',
      start_time: Time.zone.parse('8:30'),
      end_time: Time.zone.parse('12:00'),
      place: 'Thielle',
      title: 'Aide aux champs',
      description: 'Que du bonheur')
    participation = create(:activity_participation,
      member: member,
      activity: activity,
      participants_count: 2)
    create(:activity_participation, :carpooling,
      activity: activity,
      member: create(:member, name: 'Elea Asah'),
      carpooling_phone: '+41765431243',
      carpooling_city: 'La Chaux-de-Fonds')

    Email.deliver_later(:member_activity_reminder, participation)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to eq(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-activity-reminder',
      template_data: {
        activity_date: '24 mars 2018',
        activity_date_long: 'samedi 24 mars 2018',
        activity_period: '8:30-12:00',
        activity_title: 'Aide aux champs',
        activity_description: 'Que du bonheur',
        activity_place_name: 'Thielle',
        activity_participants_count: 2,
        activity_participations_with_carpooling: [
          member_name: 'Elea Asah',
          carpooling_phone: '076 543 12 43',
          carpooling_city: 'La Chaux-de-Fonds'
        ],
        action_url: 'https://membres.ragedevert.ch',
        fr: true
      },
      attachments: [])
  end

  it 'delivers member-activity-validated template' do
    member = create(:member,
      name: 'John Doew',
      emails: 'john@doew.com')
    activity = create(:activity,
      date: '24.03.2018',
      start_time: Time.zone.parse('8:30'),
      end_time: Time.zone.parse('12:00'),
      place: 'Thielle',
      place_url: 'https://google.map/thielle',
      title: 'Aide aux champs',
      description: 'Que du bonheur')
    participation = create(:activity_participation, :validated,
      member: member,
      activity: activity,
      participants_count: 1)

    Email.deliver_later(:member_activity_validated, participation)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to eq(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-activity-validated',
      template_data: {
        activity_date: '24 mars 2018',
        activity_date_long: 'samedi 24 mars 2018',
        activity_period: '8:30-12:00',
        activity_title: 'Aide aux champs',
        activity_description: 'Que du bonheur',
        activity_place: {
          name: 'Thielle',
          url: 'https://google.map/thielle'
        },
        activity_participants_count: 1,
        action_url: 'https://membres.ragedevert.ch',
        fr: true
      },
      attachments: [])
  end

  it 'delivers member-activity-rejected template' do
    member = create(:member,
      name: 'John Doew',
      emails: 'john@doew.com')
    activity = create(:activity,
      date: '24.03.2018',
      start_time: Time.zone.parse('8:30'),
      end_time: Time.zone.parse('12:00'),
      place: 'Thielle',
      place_url: 'https://google.map/thielle',
      title: 'Aide aux champs',
      description: 'Que du bonheur')
    participation = create(:activity_participation, :rejected,
      member: member,
      activity: activity,
      participants_count: 3)

    Email.deliver_later(:member_activity_rejected, participation)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to eq(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-activity-rejected',
      template_data: {
        activity_date: '24 mars 2018',
        activity_date_long: 'samedi 24 mars 2018',
        activity_period: '8:30-12:00',
        activity_title: 'Aide aux champs',
        activity_description: 'Que du bonheur',
        activity_place: {
          name: 'Thielle',
          url: 'https://google.map/thielle'
        },
        activity_participants_count: 3,
        action_url: 'https://membres.ragedevert.ch',
        fr: true
      },
      attachments: [])
  end

  it 'delivers member-invoice-new template' do
    member = create(:member,
      name: 'John Doew',
      emails: 'john@doew.com')
    invoice = create(:invoice, :annual_fee, :open,
      member: member,
      id: 31,
      date: '24.03.2018',
      annual_fee: 62)

    Email.deliver_later(:member_invoice_new, invoice)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to match(hash_including(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-invoice-new',
      template_data: {
        invoice_number: invoice.id,
        invoice_date: '24 mars 2018',
        invoice_amount: 'CHF 62.00',
        overdue_notices_count: 0,
        action_url: 'https://membres.ragedevert.ch/billing',
        annual_fee: true,
        fr: true
      },
      attachments: [
        hash_including(
          name: 'facture-ragedevert-31.pdf',
          content: String,
          content_type: 'application/pdf'),
      ]))
  end

  it 'delivers member-invoice-new template (partially paid)' do
    member = create(:member,
      name: 'John Doew',
      emails: 'john@doew.com')
    invoice = create(:invoice, :annual_fee, :open,
      member: member,
      id: 31,
      date: '24.03.2018',
      annual_fee: 62)
    create(:payment, member: member, amount: 20)

    Email.deliver_later(:member_invoice_new, invoice)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to match(hash_including(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-invoice-new',
      template_data: {
        invoice_number: invoice.id,
        invoice_date: '24 mars 2018',
        invoice_amount: 'CHF 62.00',
        invoice_missing_amount: 'CHF 42.00',
        overdue_notices_count: 0,
        action_url: 'https://membres.ragedevert.ch/billing',
        annual_fee: true,
        fr: true
      },
      attachments: [
        hash_including(
          name: 'facture-ragedevert-31.pdf',
          content: String,
          content_type: 'application/pdf'),
      ]))
  end

  it 'delivers member-invoice-new template (paid)' do
    member = create(:member,
      name: 'John Doew',
      emails: 'john@doew.com')
    invoice = create(:invoice, :annual_fee,
      member: member,
      id: 31,
      date: '24.03.2018',
      annual_fee: 42)
    create(:payment, member: member, amount: 42)

    Email.deliver_later(:member_invoice_new, invoice)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to match(hash_including(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-invoice-new',
      template_data: {
        invoice_number: invoice.id,
        invoice_date: '24 mars 2018',
        invoice_amount: 'CHF 42.00',
        invoice_paid: true,
        overdue_notices_count: 0,
        action_url: 'https://membres.ragedevert.ch/billing',
        annual_fee: true,
        fr: true
      },
      attachments: [
        hash_including(
          name: 'facture-ragedevert-31.pdf',
          content: String,
          content_type: 'application/pdf'),
      ]))
  end

  it 'delivers member-invoice-new template' do
    member = create(:member,
      name: 'John Doew',
      emails: 'john@doew.com')
    invoice = create(:invoice, :annual_fee,
      member: member,
      id: 31,
      date: '24.03.2018',
      overdue_notices_count: 2,
      annual_fee: 42)

    Email.deliver_later(:member_invoice_new, invoice)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to match(hash_including(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-invoice-new',
      template_data: {
        invoice_number: invoice.id,
        invoice_date: '24 mars 2018',
        invoice_amount: 'CHF 42.00',
        invoice_missing_amount: 'CHF 42.00',
        overdue_notices_count: 2,
        action_url: 'https://membres.ragedevert.ch/billing',
        annual_fee: true,
        fr: true
      },
      attachments: [
        hash_including(
          name: 'facture-ragedevert-31.pdf',
          content: String,
          content_type: 'application/pdf'),
      ]))
  end

  it 'delivers member-renewal template' do
    Current.acp.update!(feature_flags: %w[open_renewal])
    travel_to '2020-06-01' do
      member = create(:member, :active, emails: 'john@doew.com')
      membership = member.membership
      next_fy = Current.acp.fiscal_year_for(Date.today.year + 1)
      Delivery.create_all(1, next_fy.beginning_of_year)

      membership.open_renewal!

      expect(email_adapter.deliveries.size).to eq 1
      expect(email_adapter.deliveries.first).to match(hash_including(
        from: Current.acp.email_default_from,
        to: 'john@doew.com',
        template: 'member-renewal',
        template_data: {
          action_url: 'https://membres.ragedevert.ch/membership?hanchor=renewal',
          membership_start_date: '1 janvier 2020',
          membership_end_date: '31 décembre 2020',
          fr: true
        }))
    end
  end

  it 'delivers member-renewal-reminder template' do
    Current.acp.update!(
      feature_flags: %w[open_renewal],
      open_renewal_reminder_sent_after_in_days: 1)
    travel_to '2020-06-01' do
      member = create(:member, :active, emails: 'john@doew.com')
      membership = member.membership
      next_fy = Current.acp.fiscal_year_for(Date.today.year + 1)
      Delivery.create_all(1, next_fy.beginning_of_year)

      membership.open_renewal!
      email_adapter.reset!

      membership.send_renewal_reminder!

      expect(email_adapter.deliveries.size).to eq 1
      expect(email_adapter.deliveries.first).to match(hash_including(
        from: Current.acp.email_default_from,
        to: 'john@doew.com',
        template: 'member-renewal-reminder',
        template_data: {
          action_url: 'https://membres.ragedevert.ch/membership?hanchor=renewal',
          membership_start_date: '1 janvier 2020',
          membership_end_date: '31 décembre 2020',
          fr: true
        }))
    end
  end

  it 'delivers member-validated template' do
    member = create(:member, :pending, emails: 'john@doew.com')
    admin = create(:admin)
    Current.acp.update!(notification_member_validated: '1')

    member.validate!(admin)

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to match(hash_including(
      from: Current.acp.email_default_from,
      to: 'john@doew.com',
      template: 'member-validated',
      template_data: {
        action_url: 'https://membres.ragedevert.ch',
        members_waiting_count: 1,
        fr: true
      }))
  end
end
