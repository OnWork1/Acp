class Columns < ActiveAdmin::Component
  builder_method :columns

  def build(*args)
    super
    add_class "grid auto-cols-fr grid-flow-col gap-4 mb-4"
  end

  def column(*args, &block)
    insert_tag Arbre::HTML::Div, *args, &block
  end
end
