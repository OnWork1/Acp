module Shop
  class Producer < ApplicationRecord
    self.table_name = "shop_producers"

    include TranslatedRichTexts

    default_scope { order(:name) }

    translated_rich_texts :description

    has_many :products, class_name: "Shop::Product"

    validates :name, presence: true
    validates :website_url, format: {
      with: %r{\Ahttps?://.*\z},
      allow_blank: true
    }

    def self.find(*args)
      return NullProducer.instance if args.first == "null"

      super
    end

    def can_update?; true end

    def can_destroy?
      products.none?
    end
  end
end
