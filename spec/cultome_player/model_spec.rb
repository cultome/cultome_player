require 'spec_helper'

describe CultomePlayer::Model do
    describe CultomePlayer::Model::Artist do
        it 'get the artist name' do
            artist = CultomePlayer::Model::Artist.last
            artist.to_s.should match /:::: Artist: #{artist.name} ::::/
        end
    end

    describe CultomePlayer::Model::Similar do
        describe 'similar track' do
            before :all do
                @similar = CultomePlayer::Model::Similar.where('similar_type = ?', 'CultomePlayer::Model::Song').first
            end

            it 'get the similar track artist name' do
                @similar.to_s.should match /\A:::: Song: #{@similar.track}/
            end

            it 'get the similar track album name' do
                @similar.to_s.should match /Artist: #{@similar.artist} ::::\Z/
            end
        end

        it 'get the similar artist name' do
            similar = CultomePlayer::Model::Similar.where('similar_type = ?', 'CultomePlayer::Model::Artist').first
            similar.to_s.should match /\A:::: Artist: #{similar.artist} ::::\Z/
        end
    end

    describe CultomePlayer::Model::Album do
        before :all do
            @album = CultomePlayer::Model::Album.find(5)
        end

        it 'get the album name' do
            @album.to_s.should match /\A:::: Album: #{@album.name}/
        end

        it "get the album's artist" do
            @album.to_s.should match /Artist: #{@album.artists.first.name} ::::\Z/
        end
    end

    describe CultomePlayer::Model::Genre do
        it 'get the genre name' do
            genre = CultomePlayer::Model::Genre.all.first
            genre.to_s.should match /\A:::: Genre: #{genre.name} ::::\Z/
        end
    end

    describe CultomePlayer::Model::Drive do
        before :all do
            @drive = CultomePlayer::Model::Drive.all.first
        end

        it 'get the drive name' do
            @drive.to_s.should match /\A:::: Drive: #{@drive.name}/
        end

        it 'get the songs count in the drive' do
            @drive.to_s.should match /#{@drive.songs.size} songs/
        end

        it 'get the status of the drive' do
            @drive.to_s.should match /Online ::::\Z/
        end
    end
end
