require "simplecov"
SimpleCov.start "rails" do
  add_filter %w[config/ bin/ db/ spec/ vendor/]
  track_files "{app,lib}/**/*.rb"
end
