include CultomePlayer::Core::Importer

RSpec.describe CultomePlayer::Core::Importer do
  it "extracts files informations from a folder" do
    puts import_folder "spec/data/importer"
  end
end

