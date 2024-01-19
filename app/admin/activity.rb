ActiveAdmin.register Activity do
  menu parent: :activities_human_name, priority: 2
  actions :all, except: [ :show ]

  breadcrumb do
    links = [ activities_human_name ]
    unless params["action"] == "index"
      links << link_to(Activity.model_name.human(count: 2), activities_path)
      if params["action"].in? %W[edit]
        links << resource.name
      end
    end
    links
  end

  scope :all
  scope :future, default: true
  scope :past

  filter :place, as: :select, collection: -> { Activity.select(:places).distinct.map(&:place).compact.sort }
  filter :title, as: :select, collection: -> { Activity.select(:titles).distinct.map(&:title).compact.sort }
  filter :date
  filter :during_year,
    as: :select,
    collection: -> { fiscal_years_collection }

  includes :participations
  index do
    column resource_selection_toggle_cell, class: "col-selectable", sortable: false do |a|
      resource_selection_cell(a) if a.can_destroy?
    end
    column :date, ->(a) { l a.date, format: :medium }, sortable: :date
    column :period, ->(a) { a.period }
    column :place, ->(a) { display_place(a) }
    column :title, ->(a) { a.title }
    column :participants_short, ->(a) {
      text = [ a.participations.sum(&:participants_count), a.participants_limit || "∞" ].join("&nbsp;/&nbsp;").html_safe
      link_to text, activity_participations_path(q: { activity_id_eq: a.id }, scope: :all)
    }, class: "align-right"
    if authorized?(:update, Activity)
      actions class: "col-actions-2"
    end
  end

  action_item :activity_presets, only: :index do
    link_to ActivityPreset.model_name.human(count: 2), activity_presets_path
  end

  order_by(:date) do |order_clause|
    [ order_clause.to_sql, "activities.start_time #{order_clause.order}" ].join(", ")
  end

  csv do
    column(:date)
    column(:period)
    column(:place)
    column(:place_url)
    column(:title)
    column(:description)
    column(:participants) { |a| a.participations.sum(&:participants_count) }
    column(:participants_limit)
  end

  form do |f|
    render partial: "bulk_dates", locals: { f: f, resource: resource, context: self }

    f.inputs t("formtastic.inputs.period") do
      f.input :start_time, as: :time_picker, input_html: {
        value: f.object.start_time&.strftime("%H:%M") || "08:00"
      }
      f.input :end_time, as: :time_picker, input_html: {
        value: f.object.end_time&.strftime("%H:%M") || "12:00"
      }
    end
    f.inputs t("formtastic.inputs.place_and_title"), "data-controller" => "preset" do
      if f.object.new_record? && ActivityPreset.any?
        f.input :preset_id,
          collection: ActivityPreset.all + [ ActivityPreset.new(id: 0, place: ActivityPreset.human_attribute_name(:other)) ],
          include_blank: false,
          input_html: { data: { action: "preset#change" } }
      end
      preset_present = f.object.preset.present?
      translated_input(f, :places, input_html: { disabled: preset_present, data: { preset_target: "input" } })
      translated_input(f, :place_urls, input_html: { disabled: preset_present, data: { preset_target: "input" } })
      translated_input(f, :titles, input_html: { disabled: preset_present, data: { preset_target: "input" } })
    end
    f.inputs t(".details") do
      translated_input(f, :descriptions, as: :text, required: false, input_html: { rows: 4 })
      f.input :participants_limit, as: :number
    end
    f.actions
  end

  permit_params(
    :date, :start_time, :end_time,
    :preset_id, :participants_limit,
    :bulk_dates_starts_on, :bulk_dates_ends_on,
    :bulk_dates_weeks_frequency,
    *I18n.available_locales.map { |l| "place_#{l}" },
    *I18n.available_locales.map { |l| "place_url_#{l}" },
    *I18n.available_locales.map { |l| "title_#{l}" },
    *I18n.available_locales.map { |l| "description_#{l}" },
    bulk_dates_wdays: [])

  before_build do |activity|
    activity.preset_id ||= ActivityPreset.first&.id
  end

  controller do
    include TranslatedCSVFilename

    def apply_sorting(chain)
      if params[:scope] == "past" && !params[:order]
        params[:order] = "date_desc"
      end
      super(chain)
    end
  end

  config.sort_order = "date_asc"
  config.batch_actions = true
end
