require 'spec_helper'

describe CultomePlayer::Extras::LastFm::Fingerprinter do

    let(:t){ Test.new }
    let(:mbid){ '369a4aaf-bf6b-4760-9d9e-c7feb75f16cf' }
    let(:song_path){ "/home/csoria/music/Judas Priest/British Steel/08. The Rage.mp3" }
    let(:xml_response){ File.open("#{t.project_path}/spec/data/http/fingerprint.response").readlines.join("\n") }
    let(:mb_response){ File.open('spec/data/obj/the_rage.dat'){|f| Marshal.load(f) }}
    let(:mb_response_to_binge){ File.open('spec/data/obj/to_binge.dat'){|f| Marshal.load(f) }}
    let(:mb_response_hello){ File.open('spec/data/obj/hello.dat'){|f| Marshal.load(f) }}

    before :each do
        t.play([{type: :criteria, criteria: :t, value: 'The Rage'}])
        t.stub(:extract_fingerprint_of){ xml_response }
        t.stub(:search_mbid){ mb_response }
    end

    it 'register command identify' do
        t.should respond_to(:identify)
    end

    it 'extract the mbid from the Last.fm fp detection' do
        t.send(:choose_mbid, xml_response).should eq mbid
    end

    it 'extract artist information from mb response' do
        t.send(:extract_mb_artists, mb_response).should eq [{
            mbid: "6b335658-22c8-485d-93de-0bc29a1d0349",
            name: "Judas Priest"
        }]
    end

    it 'extract tags information from mb response' do
        t.send(:extract_mb_tags, mb_response).should eq ["british", "classic pop and rock", "hard rock", "heavy metal", "metal", "nwobhm"]
    end

    it 'extract release title information from mb response' do
        release = t.send(:extract_mb_release, mb_response)
        release.title.should eq("Metal Works '73-'93")
    end

    it 'extract release date information from mb response' do
        release = t.send(:extract_mb_release, mb_response)
        release.medium_list.medium.track_list.track.position.should eq "11"
    end

    it 'extract release date information from mb response' do
        release = t.send(:extract_mb_release, mb_response)
        release.date.should eq("2002-02-21")
    end

    it 'gets the complete information from mb response' do
        t.send(:extract_musicbrainz_details_of, mb_response).should eq({
                name: "The Rage",
                artist: "Judas Priest",
                album: "Metal Works '73-'93",
                track: 11,
                year: "2002-02-21",
                tags: "british, classic pop and rock, hard rock, heavy metal, metal, nwobhm",
                mbid: mbid,
        })
    end

    it 'raise an error if fp cant be extracted' do
        t.stub(:extract_fingerprint_of){ "ERROR: ws is not available" }
        expect{ t.identify }.to raise_error("Could not extract the fingerprint of file /home/csoria/music/Judas Priest/British Steel/08. The Rage.mp3")

    end

    it 'raise an error if mbid couldnt be extracted' do
        t.stub(:extract_fingerprint_of){ xml_response }
        t.stub(:choose_mbid){ nil }
        expect { t.identify }.to raise_error("Could not identify the song :::: Song: The Rage \\ Artist: Judas Priest \\ Album: British Steel ::::")
    end

    it 'ask user confirmation before write the information to the mp3 file' do
        t.should_receive(:get_confirmation)
        t.identify
    end

    describe 'user confirms writing tags' do
        before :each do
            t.stub(:get_confirmation){ true }
        end

        it 'write the ID3 tags' do
            t.should_receive(:update_track_information)
            t.identify
        end

        it 'returns a message confirming tags were writed' do
            t.stub(:update_track_information){ true }
            t.identify.should eq("Tags were successfuly updated")
        end

        it 'returns a message informing an error if tags couldnt be writed' do
            t.stub(:update_track_information){ raise "Could not be writed!" }
            t.identify.should eq("A problem ocurr while writing the ID3 tags")
        end

    end

    describe 'user denies writing the ID3 tags' do
        before :each do
            t.stub(:get_confirmation){ false }
        end

        it 'write nothing if user denies it' do
            t.should_not_receive(:update_track_information)
            t.identify
        end

        it 'returns a message confirming no tags were writed' do
            t.identify.should eq("No tags were writed")
        end
    end

    it 'join correctly 2 artists with joinphrase' do
        t.send(:extract_musicbrainz_details_of, mb_response_to_binge)[:artist].should eq( "Gorillaz feat. Little Dragon" )

        t.send(:extract_musicbrainz_details_of, mb_response_hello)[:artist].should eq( "Martin Solveig & Dragonette" )
    end

    it 'join correctly the tags' do
        t.send(:extract_musicbrainz_details_of, mb_response)[:tags].should eq( "british, classic pop and rock, hard rock, heavy metal, metal, nwobhm" )
        t.send(:extract_musicbrainz_details_of, mb_response_hello)[:tags].should eq( "dance and electronica, pop and chart" )
        t.send(:extract_musicbrainz_details_of, mb_response_to_binge)[:tags].should eq( "alternative hip-hop, alternative rock, british, electronic, electronica, electropop, english, fictional, hip hop, hip-hop, parlophone, producer, producteur, rock, rock and indie, trip hop, trip rock, trip-hop, uk, united kingdom, downtempo, soul and reggae" )
    end
end
