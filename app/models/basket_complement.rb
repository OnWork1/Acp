class BasketComplement < ActiveRecord::Base
  has_and_belongs_to_many :deliveries,
    after_add: :add_subscribed_baskets_complement!,
    after_remove: :remove_subscribed_baskets_complement!

  has_many :baskets_basket_complement, dependent: :destroy
  has_many :memberships_basket_complements, dependent: :destroy

  default_scope { order(:name) }

  def annual_price
    (price * deliveries.size).round_to_five_cents
  end

  def annual_price=(annual_price)
    self.price = annual_price / deliveries.size.to_f
  end

  def display_name; name end

  private

  def add_subscribed_baskets_complement!(delivery)
    delivery.add_subscribed_baskets_complement!(self)
  end

  def remove_subscribed_baskets_complement!(delivery)
    delivery.remove_subscribed_baskets_complement!(self)
  end
end
