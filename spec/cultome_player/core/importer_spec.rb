require "json"

RSpec.describe CultomePlayer::Core::Importer do
  it "extracts files informations from a folder" do
    expect(import_folder("spec/data/importer").size).to be > 0
  end

  it "writes a db file" do
    expect(File.exists? db_file).to be true
  end
end

