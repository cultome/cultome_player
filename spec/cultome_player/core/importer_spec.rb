
RSpec.describe CultomePlayer::Core::Importer do
  it "extracts files informations from a folder" do
    expect(import_folder("spec/data/importer").size).to be > 0
  end

  it "writes a db file" do
    expect(File.exists? db_file).to be true
  end

  it "doesnt import repeated files" do
    import_folder("spec/data/importer")
    count_before = JSON.load(File.read(db_file)).size

    import_folder("spec/data/importer")
    count_after= JSON.load(File.read(db_file)).size

    expect(count_before).to eq count_after
  end
end

