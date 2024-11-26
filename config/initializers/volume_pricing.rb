Rails.application.config.after_initialize do
  if Spree::Core::Engine.backend_available?
    Rails.application.config.spree_backend.main_menu.add_to_section('settings',
      ::Spree::Admin::MainMenu::ItemBuilder.new('volume_price_models', ::Spree::Core::Engine.routes.url_helpers.admin_volume_price_models_path).
        with_manage_ability_check(::Spree::VolumePriceModel).
        with_match_path('/volume_price_models').
        build
    )
  end
end