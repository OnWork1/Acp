ActiveAdmin.register DeliveryCycle do
  menu false

  breadcrumb do
    links = [ link_to(Delivery.model_name.human(count: 2), deliveries_path) ]
    if params[:action] != "index"
      links << link_to(DeliveryCycle.model_name.human(count: 2), delivery_cycles_path)
    end
    if params["action"].in? %W[edit]
      links << auto_link(resource)
    end
    links
  end

  filter :name_cont,
    label: -> { DeliveryCycle.human_attribute_name(:name) },
    as: :string
  filter :depots, as: :select

  includes :depots
  index download_links: false do
    column :name, ->(dc) { link_to display_name_with_public_name(dc), dc }
    column :next_delivery, ->(dc) { auto_link dc.next_delivery }
    column Current.acp.current_fiscal_year, ->(dc) {
      auto_link dc, dc.current_deliveries_count
    }
    column Current.acp.fiscal_year_for(1.year.from_now), ->(dc) {
      auto_link dc, dc.future_deliveries_count
    }
    if DeliveryCycle.visible?
      column :visible, ->(dc) { status_tag dc.visible? }
    end
    actions class: "col-actions-3"
  end

  sidebar_handbook_link("deliveries#cycles-de-livraisons")

  show do |dc|
    columns do
      column do
        panel "#{deliveries_current_year_title}: #{dc.current_deliveries_count}" do
          if dc.current_deliveries_count.positive?
            table_for dc.current_deliveries, class: "deliveries" do
              column "#", ->(d) { auto_link d, d.number }
              column :date, ->(d) { auto_link d, l(d.date, format: :medium_long) }
            end
          else
            span t("active_admin.empty"), class: "empty"
          end
        end
        panel "#{deliveries_next_year_title}: #{dc.future_deliveries_count}"  do
          if dc.future_deliveries_count.positive?
            table_for dc.future_deliveries, class: "deliveries" do
              column "#", ->(d) { auto_link d, d.number }
              column :date, ->(d) { auto_link d, l(d.date, format: :medium_long) }
            end
          else
            span t("active_admin.empty"), class: "empty"
          end
        end
      end

      column do
        attributes_table do
          row :name
          row :public_name
        end

        if DeliveryCycle.visible?
          attributes_table t(".member_new_form") do
            row(:visible) { status_tag(dc.visible?) }
            if dc.visible?
              table_for dc.depots, class: "depots" do
                column Depot.model_name.human, ->(d) { auto_link d }
                column :visible
              end
            end
          end
        end

        attributes_table t("delivery_cycle.settings") do
          row(:wdays) {
            if dc.wdays.size == 7
              t("active_admin.scopes.all")
            else
              dc.wdays.map { |d| t("date.day_names")[d].capitalize }.to_sentence
            end
          }
          row(:week_numbers) { t("delivery_cycle.week_numbers.#{dc.week_numbers}") }
          row(:months) {
            if dc.months.size == 12
              t("active_admin.scopes.all")
            else
              dc.months.map { |m| t("date.month_names")[m].capitalize }.to_sentence
            end
          }
          row(:results) { t("delivery_cycle.results.#{dc.results}") }
          row(:minimum_gap_in_days) { dc.minimum_gap_in_days }
        end

        active_admin_comments_for(dc)
      end
    end
  end

  form do |f|
    f.inputs do
      translated_input(f, :names, required: true)
      translated_input(f, :public_names,
        required: false,
        hint: t("formtastic.hints.delivery_cycle.public_name"))
    end

    unless DeliveryCycle.basket_size_config?
      f.inputs t("active_admin.resource.show.member_new_form") do
        f.input :member_order_priority,
          collection: member_order_priorities_collection,
          as: :select,
          prompt: true,
          hint: t("formtastic.hints.acp.member_order_priority_html")
        f.input :depots,
          as: :check_boxes,
          disabled: depot_ids_with_only(f.object)
      end
    end

    f.inputs t("delivery_cycle.settings") do
      f.input :wdays,
        as: :check_boxes,
        collection: wdays_collection,
        required: true
      f.input :week_numbers,
        as: :select,
        collection: week_numbers_collection,
        include_blank: false
      f.input :months,
        as: :check_boxes,
        collection: months_collection,
        required: true
      f.input :results,
        as: :select,
        collection: results_collection,
        include_blank: false
      f.input :minimum_gap_in_days
    end

    f.actions
  end

  permit_params(
    :visible,
    :member_order_priority,
    :week_numbers,
    :results,
    :minimum_gap_in_days,
    *I18n.available_locales.map { |l| "name_#{l}" },
    *I18n.available_locales.map { |l| "public_name_#{l}" },
    wdays: [],
    months: [],
    depot_ids: [])

  controller do
    include DeliveryCyclesHelper

    private

    def assign_attributes(resource, attributes)
      if attributes.first[:depot_ids]
        attributes.first[:depot_ids] += depot_ids_with_only(resource).map(&:to_s)
        attributes.first[:depot_ids].uniq!
      end
      super(resource, attributes)
    end
  end

  config.sort_order = :default_scope
  config.paginate = false
end
