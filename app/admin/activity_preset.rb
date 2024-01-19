ActiveAdmin.register ActivityPreset do
  menu false
  actions :all, except: [ :show ]

  breadcrumb do
    links = [
      activities_human_name,
      link_to(Activity.model_name.human(count: 2), activities_path)
    ]
    unless params["action"] == "index"
      links << link_to(ActivityPreset.model_name.human(count: 2), activity_presets_path)
      if params["action"].in? %W[edit]
        links << resource.name
      end
    end
    links
  end

  index download_links: false do
    column :place
    column :place_url, ->(ap) {
      link_to(truncate(ap.place_url, length: 50), ap.place_url) if ap.place_url?
    }
    column :title
    if authorized?(:update, ActivityPreset)
      actions class: "col-actions-2"
    end
  end

  form do |f|
    f.inputs do
      translated_input(f, :places)
      translated_input(f, :place_urls)
      translated_input(f, :titles)
    end
    f.actions
  end

  permit_params(
    *I18n.available_locales.map { |l| "place_#{l}" },
    *I18n.available_locales.map { |l| "place_url_#{l}" },
    *I18n.available_locales.map { |l| "title_#{l}" })

  controller do
    include TranslatedCSVFilename
  end

  config.filters = false
  config.sort_order = :default_scope
end
