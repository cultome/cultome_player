# encoding: utf-8
require 'nokogiri'
require 'musicbrainz'
require 'mp3info'

module CultomePlayer::Extras::LastFm
    module Fingerprinter
        def self.included(base)
            CultomePlayer::Player.command_registry << :identify
            CultomePlayer::Player.command_help_registry[:identify] = {
                help: "Detect the audio file and correct the ID3 Tag",
                params_format: "",
                usage: <<-HELP
It extract the audio fingerprint using the Last.fm fingerprint lib and using his webservices try to identify the correct song. Once detected, the detected song and artist are searched throught Musicbraiz.org in order to correct the file's ID3 tag values.

The correct usage is only type 'identify' when the song you want to identify is playing.

* identify
                HELP
            }
        end

        def identify(param=[])
            song = current_song

            lastfm_response = extract_fingerprint_of(song.path)
            raise "Could not extract the fingerprint of file #{song.path}" if lastfm_response.start_with?("ERROR")

            track_mbid = choose_mbid(lastfm_response)
            raise "Could not identify the song #{song}" if track_mbid.nil?

            mb_response = search_mbid(track_mbid)
            song_details = extract_musicbrainz_details_of(mb_response)

            return "No tags were writed" unless get_confirmation(<<-MSG
The following information was extracted:
   Title:  #{song_details[:name]}
   Artist: #{song_details[:artist]}
   Album:  #{song_details[:album]}
   Track:  #{song_details[:track]}
   Year:   #{song_details[:year]}
   Tags:  #{song_details[:tags]}

Should we write this information to the ID3 tags?
   MSG
                                                                )
            begin
                update_track_information(song, song_details)
                return "Tags were successfuly updated"
            rescue Exception => e
                puts e.message
                puts e.backtrace
                return "A problem ocurr while writing the ID3 tags"
            end
        end

        private

        # Given the response from MusicBrainz webservice, select the better information for the song.
        #
        # @param [Hashie] The MusicBrainz XML response parsed in Hashies.
        # @return [Hash] With the selected information for the song. The has includes the keys: name, artist, album, trac, year, tags, mdbid.
        def extract_musicbrainz_details_of(response)
            artists = extract_mb_artists(response)
            tags = extract_mb_tags(response)
            release = extract_mb_release(response)

            # extraemos el join entre artistas
            artist_join = artists.collect{|a| a[:joinphrase] }.compact
            artist_join = artist_join.empty? ? ", " : artist_join[0]

            details = {
                name: response.recording.title,
                artist: artists.collect{|a| a[:name] }.join(artist_join),
                album: release.title,
                track: release.medium_list.medium.track_list.track.position.to_i,
                year: release.date,
                tags: tags.join(", "),
                mbid: response.recording.id,
            }

        end

        def extract_mb_release(data)
            releases = data.recording.release_list.release

            return releases if releases.class != Array

            releases.sort{|a,b|
                a.date.to_s <=> b.date.to_s
            }.find{|r| r.date.to_s != ""}
        end

        def extract_mb_tags(data)
            name_credits = data.recording.artist_credit.name_credit
            if name_credits.class == Array
                name_credits.collect{ |a|
                    tags = a.artist.tag_list.tag
                    if tags.class == Array
                        tags.collect{|t| t.name }
                    else
                        tags.name
                    end
                }.flatten
            else
                name_credits.artist.tag_list.tag.collect{|t| t.name }
            end
        end

        def extract_mb_artists(data)
            name_credits = data.recording.artist_credit.name_credit
            if name_credits.class == Array
                name_credits.collect{|a| {mbid: a.artist.id, name: a.artist.name, joinphrase: a.joinphrase }}
            else
                [{mbid: name_credits.artist.id, name: name_credits.artist.name}]
            end
        end

        # Select the better match for fp detection returned by the Last.fm webservice.
        #
        # @param response [String] The ws response in XML.
        # @return [String] The musicbrainz id  of the recording that better match the fp identification.
        def choose_mbid(response)
            doc = Nokogiri::XML(response)
            track_mbid = doc.xpath("//track/mbid").collect{|t| t.children.first.to_s }.find{|id| id != ""}

            return track_mbid
        end

        # Execute the Last.fm fingerprint client and calculate the fingerprint of the mp3 file. With the fp request an identification to his servers and return a list of match candiates.
        #
        # @param file_path [String] The absolute path to the mp3 file.
        # @return [String] The webservices response in XML.
        def extract_fingerprint_of(file_path)
            fp_response = %x{lastfm-fpclient "#{file_path}"}
            return fp_response
        end

        # Using the musicbrainz-ruby gem, consult the webservices of musicbrainz to extract information for the given recording mbid.
        #
        # @param mbid [String] The musicbrainz id.
        # @return [Hashie] With the webservice XML response parsed.
        def search_mbid(mbid)
            brainz = MusicBrainz::Client.new(username: 'zooria', password: 'Cu1toMES')
            return brainz.recording(mbid: mbid, inc: 'artists releases discids tags')
        end

        # Write the ID3 tags into the file and update the database information.
        #
        # @param song [CultomePlayer::Model::Song] The song object to update
        # @param info [Hash] The hash with the information to write.
        def update_track_information(song, info)
            update_tag_information(song.path, info)
            update_db_information(song, info)
        end

        # Update the databse with the new track information.
        #
        # @param song [CultomePlayer::Model::Song] The song to be updated.
        # @param info [Hash] The hash with the information to update.
        def update_db_information(song, info)
            song.name = info[:name] unless info[:name].blank?
            song.track = info[:track] unless info[:track].blank?
            song.track = info[:year] unless info[:year].blank?

            song.artist = CultomePlayer::Model::Artist.find_or_create_by_name(name: info[:artist]) unless info[:artist].blank?
            song.album = CultomePlayer::Model::Album.find_or_create_by_name(name: info[:album]) unless info[:album].blank?
            #song.tags << CultomePlayer::Model::Tags.find_or_create_by_name(name: info[:tags]) unless info[:tags].blank?

            return song.save!
        end

        # Write the ID3 tags into the file.
        #
        # @param file_path [String] The absolute path to the mp3 file.
        # @param info [Hash] The hash with the information to write.
        def update_tag_information(file_path, info)
            Mp3Info.open(file_path) do |mp3|
                mp3.tag.title = info[:name]
                mp3.tag.artist = info[:artist]
                mp3.tag.album = info[:album]
                mp3.tag.tracknum = info[:track]
                mp3.tag1["year"] = info[:year]
            end
        end
    end
end
