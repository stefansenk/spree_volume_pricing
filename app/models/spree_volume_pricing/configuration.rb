module SpreeVolumePricing
  class Configuration < Spree::Preferences::Configuration
    preference :use_master_variant_volume_pricing, :boolean, default: false
  end
end