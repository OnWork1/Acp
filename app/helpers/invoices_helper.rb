module InvoicesHelper
  def entity_type_collection
    Invoice.used_entity_types.map { |type|
      [ t_invoice_entity_type(type), type ]
    }.sort_by { |a| a.first }
  end

  def display_entity(invoice, link: true)
    if link && invoice.entity
      auto_link invoice.entity
    else
      t_invoice_entity_type(invoice.entity_type)
    end
  end

  def t_invoice_entity_type(type)
    case type
    when "ActivityParticipation" then activity_human_name
    when "Shop::Order" then I18n.t("shop.title_orders", count: 1)
    else
      type.constantize.model_name.human
    end
  rescue NameError
    I18n.t("invoices.entity_type.#{type.underscore}")
  end

  def link_to_invoice_pdf(invoice, title: "PDF", &block)
    return unless invoice
    return if invoice.processing?

    link_to invoice_pdf_url(invoice), class: "pdf_link", target: "_blank" do
      block ? block.call : title
    end
  end

  def invoice_pdf_url(invoice)
    if Rails.env.development?
      pdf_invoice_path(invoice)
    else
      rails_blob_path(invoice.pdf_file, disposition: "attachment")
    end
  end
end
