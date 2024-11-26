module Spree
  module Admin
    class VolumePricesController < Spree::Admin::BaseController
      def destroy
        @volume_price = current_store.volume_prices.find(params[:id])
        @volume_price.destroy
      end
    end
  end
end
