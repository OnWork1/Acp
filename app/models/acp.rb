class ACP < ApplicationRecord
  include TranslatedAttributes
  include TranslatedRichTexts

  FEATURES = %w[
    absence
    activity
    basket_content
    basket_price_extra
    contact_sharing
    group_buying
    shop
  ]
  FEATURE_FLAGS = %w[]
  LANGUAGES = %w[fr de it]
  CURRENCIES = %w[CHF EUR]
  BILLING_YEAR_DIVISIONS = [1, 2, 3, 4, 12]
  ACTIVITY_I18N_SCOPES = %w[hour_work halfday_work basket_preparation]

  attribute :shop_delivery_open_last_day_end_time, :time_only
  attribute :icalendar_auth_token, :string, default: -> { SecureRandom.hex(16) }

  translated_attributes :invoice_info, :invoice_footer
  translated_attributes :delivery_pdf_footer
  translated_attributes :terms_of_service_url, :statutes_url
  translated_attributes :membership_extra_text
  translated_attributes :group_buying_terms_of_service_url
  translated_attributes :group_buying_invoice_info
  translated_attributes :shop_invoice_info
  translated_attributes :shop_delivery_pdf_footer
  translated_attributes :shop_terms_of_sale_url
  translated_rich_texts :shop_text
  translated_attributes :email_signature, :email_footer
  translated_rich_texts :open_renewal_text
  translated_attributes :basket_price_extra_title, :basket_price_extra_public_title, :basket_price_extra_text
  translated_attributes :basket_price_extra_label, :basket_price_extra_label_detail
  translated_rich_texts :absence_extra_text

  validates :name, presence: true
  validates :host, presence: true
  validates :url, presence: true, format: { with: %r{\Ahttps?://.*\z} }
  validates :logo_url, presence: true, format: { with: %r{\Ahttps://.*\z} }
  validates :email, presence: true
  validates :email_default_host, presence: true, format: { with: %r{\Ahttps://.*\z} }
  validates :email_default_from, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/ }
  validates :activity_phone, presence: true, if: -> { feature?('activity') }
  validates :ccp, format: { with: /\A\d{2}-\d{1,6}-\d{1}\z/, allow_blank: true }
  validates :ccp, :isr_identity, :isr_payment_for, :isr_in_favor_of,
    presence: true, if: :isr_invoice?
  validates :ccp, :isr_identity, :isr_payment_for, :isr_in_favor_of,
    absence: true, unless: :isr_invoice?
  validates :qr_iban, :qr_creditor_name, :qr_creditor_address,
    :qr_creditor_city, :qr_creditor_zip,
    presence: true, if: :qr_invoice?
  validates :qr_iban, :qr_creditor_name, :qr_creditor_address,
    :qr_creditor_city, :qr_creditor_zip,
    absence: true, unless: :qr_invoice?
  validates :tenant_name, presence: true
  validates :fiscal_year_start_month,
    presence: true,
    inclusion: { in: 1..12 }
  validates :trial_basket_count, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :annual_fee, numericality: { greater_than_or_equal_to: 1 }, allow_nil: true
  validates :share_price, numericality: { greater_than_or_equal_to: 1 }, allow_nil: true
  validates :absence_notice_period_in_days,
    numericality: { greater_than_or_equal_to: 1 }
  validates :activity_i18n_scope, inclusion: { in: ACTIVITY_I18N_SCOPES }
  validates :activity_participation_deletion_deadline_in_days,
    numericality: { greater_than_or_equal_to: 1, allow_nil: true }
  validates :activity_availability_limit_in_days,
    numericality: { greater_than_or_equal_to: 0 }
  validates :activity_price,
    numericality: { greater_than_or_equal_to: 0 }
  validates :open_renewal_reminder_sent_after_in_days,
    numericality: { greater_than_or_equal_to: 1, allow_nil: true }
  validates :vat_number, presence: true, if: -> { vat_membership_rate&.positive? }
  validates :vat_membership_rate, numericality: { greater_than: 0 }, if: :vat_number?
  validates :recurring_billing_wday, inclusion: { in: 0..6 }, allow_nil: true
  validates :country_code,
    presence: true,
    inclusion: { in: ISO3166::Country.all.map(&:alpha2) }
  validates :currency_code, presence: true, inclusion: { in: CURRENCIES }
  validates :shop_order_maximum_weight_in_kg,
    numericality: { greater_than_or_equal_to: 1, allow_nil: true }
  validates :shop_order_minimal_amount,
    numericality: { greater_than_or_equal_to: 1, allow_nil: true }

  after_create :create_tenant
  after_create :create_default_deliveries_cycle

  def self.perform(tenant_name)
    enter!(tenant_name)
    yield
  ensure
    exit!
  end

  def self.perform_each
    ACP.pluck(:tenant_name).each do |tenant_name|
      enter!(tenant_name)
      yield
    end
  ensure
    exit!
  end

  def self.enter!(tenant_name)
    acp = ACP.find_by!(tenant_name: tenant_name)
    Apartment::Tenant.switch!(acp.tenant_name)
    Current.reset
    Current.acp = acp
    Sentry.set_tags(acp: tenant_name)
  end

  def self.exit!
    Apartment::Tenant.reset
    Current.reset
  end

  def self.languages; LANGUAGES end
  def self.features
    FEATURES.sort_by { |f| I18n.transliterate I18n.t("features.#{f}") }
  end
  def self.feature_flags; FEATURE_FLAGS end
  def self.billing_year_divisions; BILLING_YEAR_DIVISIONS end
  def self.activity_i18n_scopes; ACTIVITY_I18N_SCOPES end

  def feature?(feature)
    features.include?(feature.to_s)
  end

  def feature_flag?(feature)
    feature_flags.include?(feature.to_s)
  end

  def recurring_billing?
    !!recurring_billing_wday
  end

  def payments_processing?
    credentials(:ebics) || credentials(:bas)
  end

  def billing_year_divisions=(divisions)
    super divisions.map(&:to_i) & BILLING_YEAR_DIVISIONS
  end

  def invoice_type
    ccp? ? 'ISR' : 'QR'
  end

  def isr_invoice?
    invoice_type == 'ISR'
  end

  def qr_invoice?
    invoice_type == 'QR'
  end

  def languages=(languages)
    super languages & self.class.languages
  end

  def languages
    super & self.class.languages
  end

  def default_locale
    if languages.include?(I18n.default_locale.to_s)
      I18n.default_locale.to_s
    else
      languages.first
    end
  end

  def email_from
    Mail::Address.new.tap { |builder|
      builder.address = email_default_from
      builder.display_name = name
    }.to_s
  end

  def members_subdomain
    URI.parse(email_default_host).host.split('.').first
  end

  def url=(url)
    super
    self.host ||= PublicSuffix.parse(URI(url).host).sld
  end

  def phone=(phone)
    super
    self.activity_phone ||= phone
  end

  def basket_price_extra_public_title
    self[:basket_price_extra_public_titles][I18n.locale.to_s].presence || basket_price_extra_title
  end

  def basket_price_extras?
    self[:basket_price_extras].any?
  end

  def basket_price_extras
    self[:basket_price_extras].join(', ')
  end

  def basket_price_extras=(string)
    self[:basket_price_extras] = string.split(',').map(&:presence).compact
  end

  def current_fiscal_year
    FiscalYear.current(start_month: fiscal_year_start_month)
  end

  def fiscal_year_for(date_or_year)
    FiscalYear.for(date_or_year, start_month: fiscal_year_start_month)
  end

  def fy_month_for(date)
    fiscal_year_for(date).month(date)
  end

  def annual_fee?
    annual_fee&.positive?
  end

  def share?
    share_price&.positive?
  end

  def ical_feed?
    ical_feed_auth_token.present?
  end

  def ical_feed_auth_token
    credentials(:icalendar_auth_token)
  end

  def credentials(*keys)
    Rails.application.credentials.dig(tenant_name.to_sym, *keys)
  end

  def group_buying_email
    self[:group_buying_email] || email
  end

  def create_tenant
    Apartment::Tenant.create(tenant_name)
  end

  def create_default_deliveries_cycle
    self.class.perform(tenant_name) do
      DeliveriesCycle.create!(LANGUAGES.map { |locale|
        ["name_#{locale}", I18n.t('deliveries_cycle.default_name', locale: locale)]
      }.to_h)
    end
  end
end
