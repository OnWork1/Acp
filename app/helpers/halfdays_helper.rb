module HalfdaysHelper
  def halfday_label(halfday, date: false, description: true)
    labels = [
      halfday.period,
      display_place(halfday),
      display_activity(halfday, description: description)
    ]
    labels.insert(0, l(halfday.date, format: :medium).capitalize) if date
    labels.join(', ')
  end

  def display_place(halfday)
    if halfday.place_url?
      link_to(halfday.place, halfday.place_url)
    else
      halfday.place
    end
  end

  def display_activity(halfday, description: true)
    if description && halfday.description?
      halfday.activity +
        content_tag(:span, class: 'tooltip-toggle', data: { tooltip: halfday.description }) {
          content_tag :i, nil, class: 'fa fa-info-circle'
        }
    else
      halfday.activity
    end
  end

  def halfday_participation_summary(halfday_participation)
    summary = halfday_participation.member.name
    if halfday_participation.participants_count > 1
      summary << " (#{halfday_participation.participants_count})"
    end
    if halfday_participation.pending?
      summary << ' [en attente de validation]'
    elsif halfday_participation.rejected?
      summary << ' [refusée]'
    elsif halfday_participation.validated?
      summary << ' [validée]'
    end
    summary
  end
end
