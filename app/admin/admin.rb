ActiveAdmin.register Admin do
  menu parent: :other, priority: 2
  actions :all, except: [:show]

  filter :name
  filter :email
  filter :permission

  includes :last_session, :permission
  index download_links: false do
    column :name
    column :email
    column :last_session_used_at, ->(a) {
      I18n.l(a.last_session_used_at, format: :medium) if a.last_session_used_at
    }
    column :permission, ->(a) {
      link_to a.permission&.name, permissions_path
    }
    if authorized?(:manage, Admin)
      actions class: 'col-actions-2'
    end
  end

  action_item :permissions, only: :index do
    link_to Permission.model_name.human(count: 2), permissions_path
  end

  form do |f|
    f.inputs t('.details') do
      f.input :name
      f.input :email
      f.input :language,
        as: :select,
        collection: ACP.languages.map { |l| [t("languages.#{l}"), l] },
        prompt: true
      if authorized?(:manage, Admin) && f.object != current_admin
        f.input :permission, collection: Permission.all, prompt: true, include_blank: false
      end
    end
    f.inputs do
      f.input :notifications,
        as: :check_boxes,
        collection: Admin.notifications.map { |n| [t("admin.notifications.#{n}"), n] }.sort
    end
    f.actions
  end

  permit_params do
    pp = %i[name email language]
    pp << :permission_id if authorized?(:manage, Admin)
    pp << { notifications: [] }
    pp
  end

  after_create do |admin|
    AdminMailer.with(
      admin: admin,
      action_url: root_url
    ).invitation_email.deliver_later
  end

  config.sort_order = 'name_asc'
end
