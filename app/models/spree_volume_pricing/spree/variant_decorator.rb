module SpreeVolumePricing
  module Spree
    module VariantDecorator
      def self.prepended(base)
        base.has_and_belongs_to_many :volume_price_models
        base.has_many :volume_prices, -> { order(position: :asc) }, dependent: :destroy
        base.has_many :model_volume_prices,
                      -> { order(position: :asc) },
                      class_name: '::Spree::VolumePrice',
                      through: :volume_price_models,
                      source: :volume_prices
        base.accepts_nested_attributes_for :volume_prices,
                                           allow_destroy: true,
                                           reject_if: proc { |volume_price|
                                             volume_price[:amount].blank? && volume_price[:range].blank?
                                           }
      end

      def join_volume_prices(user = nil)
        table = ::Spree::VolumePrice.arel_table
        if user
          ::Spree::VolumePrice.where(
            (table[:variant_id].eq(id)
              .or(table[:volume_price_model_id].in(volume_price_models.ids)))
              .and(table[:role_id].eq(user.id))
          ).order(position: :asc)
        else
          ::Spree::VolumePrice.where(
            (table[:variant_id]
              .eq(id)
              .or(table[:volume_price_model_id].in(volume_price_models.ids)))
              .and(table[:role_id].eq(nil))
          ).order(position: :asc)
        end
      end

      # Calculates the price based on quantity
      def volume_price(quantity, user = nil, order)
        compute_store_specific_volume_price_quantities(:volume_price, price, quantity, user, order)
      end

      # Returns percent of earning
      def volume_price_earning_percent(quantity, user = nil)
        compute_volume_price_quantities(:volume_price_earning_percent, 0, quantity, user)
      end

      # Returns amount of earning
      def volume_price_earning_amount(quantity, user = nil)
        compute_volume_price_quantities(:volume_price_earning_amount, 0, quantity, user)
      end

      protected

      def use_master_variant_volume_pricing?
        ::SpreeVolumePricing::Config[:use_master_variant_volume_pricing] &&
          !(product.master.join_volume_prices.count == 0)
      end

      def compute_volume_price_quantities(type, default_price, quantity, user)
        volume_prices = join_volume_prices(user)
        if volume_prices.count == 0
          if use_master_variant_volume_pricing?
            product.master.send(type, quantity, user)
          else
            return default_price
          end
        else
          volume_prices.each do |volume_price|
            return send("compute_#{type}".to_sym, volume_price) if volume_price.include?(quantity)
          end
          # No price ranges matched
          default_price
        end
      end

      def compute_store_specific_volume_price_quantities(type, default_price, quantity, user, order)
        volume_prices = join_volume_prices(user).where(store_id: order.store_id)
        if volume_prices.count == 0
          if use_master_variant_volume_pricing?
            product.master.send(type, quantity, user)
          else
            return default_price
          end
        else
          volume_prices.each do |volume_price|
            return send("compute_#{type}".to_sym, volume_price) if volume_price.include?(quantity)
          end
          # No price ranges matched
          default_price
        end
      end

      def compute_volume_price(volume_price)
        case volume_price.discount_type
        when 'price'
          volume_price.amount
        when 'dollar'
          price - volume_price.amount
        when 'percent'
          price - (price * (volume_price.amount / 100.0))
        end
      end

      def compute_volume_price_earning_percent(volume_price)
        case volume_price.discount_type
        when 'price'
          diff = price - volume_price.amount
          (diff * 100 / price).round
        when 'dollar'
          (volume_price.amount * 100 / price).round
        when 'percent'
          (volume_price.amount * 100).round
        end
      end
    end
  end
end

::Spree::Variant.prepend SpreeVolumePricing::Spree::VariantDecorator
