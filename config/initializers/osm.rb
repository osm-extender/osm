ActionDispatch::Callbacks.to_prepare do
  OSM::API.configure(
    :api_id     => ENV['osmx_osm_id'],
    :api_token  => ENV['osmx_osm_token'],
  )
end