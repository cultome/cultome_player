module CultomePlayer
  module Player
  	module BuiltinHelp
  		def description_play
  			"Creates a playlist and start playing. Resumes playback."
  		end

			def description_pause
				"Toggle pause."
			end

			def description_stop
				"Stops current playback."
			end

			def description_next
				"Play the next song in current playlist."
			end

			def description_prev
				"Play the last song in history playlist."
			end

			def description_quit
				"Quits the playback and exit the player."
			end

			def description_search
				"Search into the connected music drives."
			end

			def description_show
				"Shows representations of diverse objects in the player."
			end

			def description_enqueue
				"Append a playlist to the queue playlist."
			end

			def description_shuffle
				"Check the state of shuffle. Can turn it on and off."
			end

			def description_connect
				"Add or reconnect a drive to the music library."
			end

			def description_disconnect
				"Disconnect a drive from the music library."
			end

			def description_ff
				"Fast forward 10 seconds the current playback."
			end

			def description_fb
				"Fast backward 10 seconds the current playback."
			end

			def description_repeat
				"Repeat the current playback from the begining."
			end
			
	    def usage_cultome_player
		    cmds_availables = methods.grep(/^description_/).collect do |method_name|
		      [method_name.to_s.gsub("description_", ""), send(method_name)]
		    end

		    border_width = 5
		    cmd_column_width = cmds_availables.reduce(0){|sum, arr| sum > arr[0].length ? sum : arr[0].length}
		    desc_column_width = 90 - border_width - cmd_column_width

		    cmds_availables_formatted = cmds_availables.collect do |arr|
		      "   " + arrange_in_columns(arr, [cmd_column_width, desc_column_width], border_width)
		    end

		    return <<-HELP
usage: <command> [param param ...]

The following commands are availables:
#{cmds_availables_formatted.join("\n")}

The params can be of any of these types:
   criterio     A key:value pair. Only a,b,t are recognized.
   literal      Any valid string. If contains spaces quotes or double quotes are required.
   object       Identifiers preceded with an @.
   number       An integer number.
   path         A string representing a path in filesystem.
   boolean      Can be true, false. Accept some others.
   ip           An IP4 address.

See 'help <command>' for more information on a especific command.

Refer to the README file for a complete user guide.
	    HELP
	  	end

			def usage_play
				return <<-USAGE
usage: play [literal|number|criteria|object]

This command is intelligent, so it reacts depending on its context. 
Without parameters, if the current playlist is empty, play without parameters crate a playlist with all the music in your library and start playing, also if you stop or pause the player, this command resumes the playback where you left it.
With parameters works as if you make a search and then create a playlist from the results.
If you select songs from the *focus* playlist, this command dont replace the *current* playlist, just append the song to the *queue* playlist.

Examples:

Create a playlist with songs that contains "super" in its title, artist name o album name:
	play super

Create a playlist with all the songs in the current album:
	play @album

Create a playlist with songs whose artists contains the string "llica" or "gori":
	play a:llica a:gori

If you use a command that modifies the *focus* playlist, you can play songs associated with their index in the list:
	play 1 5 9

				USAGE
			end

			def usage_pause
				return <<-USAGE
usage: pause [boolean]

Without parameters, toggle pause. Whit a boolean parameter... well, just you what is been told.

Examples:
	
If there is an active playback, pause it:
	pause

If is paused, resume:
	pause

If you wanna make sure is paused:
	pause on

				USAGE
			end

			def usage_stop
				return <<-USAGE
usage: stop

Stop the current playback. If *play* is called after *stop*, the playback will begin again.

Examples:

Stop current playback:
	stop

				USAGE
			end

			def usage_next
				return <<-USAGE
usage: next

Select the next song in the *current* playlist and play it, if there is any or if *repeat* is on.

Examples:

You dont like the music and wanna try lunk with the next:
	next

				USAGE
			end

			def usage_prev
				return <<-USAGE
usage: prev

Select the last song in the *history* playlist and plays it again.

Examples:

"OMG! I love that song, lets hear it again":
	prev

				USAGE
			end

			def usage_quit
				return <<-USAGE
usage: quit

Stop playback and exit player.

Examples:

You wanna quit the player:
	quit

				USAGE
			end

			def usage_search
				return <<-USAGE
usage: search (literal|criteria)

Search in the connected drives for song that fullfil the parameters criteria.
When a search is made, the results go to the *search* and *focus* playlist. From there, they can be manipulated.
To understand the results, I will explain the rules the search algorith uses:
	1. Similar criteria creates an OR filter and differents create AND filter.
		Example:

			search t:tres a:uno a:dos

			This extract songs whose title contains "tres" and whose artist contains "uno" OR "dos" in their names

	2. Literal words form and OR

			search uno dos tres

			This extract songs whose title, artist name or album name contains "uno" OR "dos" OR "tres".

Examples:

Get all my Gorillaz's songs
	search a:gorillaz

Im in love and I wanna hear love-related songs:
	search love

				USAGE
			end

			def usage_show
				return <<-USAGE
usage: show [number|object]

Display a representation of player's objects.
Without parameters show the status of the current playback, if any.

Examples:

See how much time left of this song:
	show

See what songs are in the *focus* playlist:
	show @focus

				USAGE
			end

			def usage_enqueue
				return <<-USAGE
usage: enqueue [literal|number|criteria|object]

Search, pick and extract the song defined in the parameters and creates a playlist that is appended to the *queue* playlist.
Similar to a search with the literal and criteria parameters, but with number takes songs from the *focus* playlist, and with object extract the songs from the respective object.

Examples:

After the current song I want to play all Jugulator album:
	enqueue b:Jugulator

Play te third song in the list after this:
	enqueue 3

				USAGE
			end

			def usage_shuffle
				return <<-USAGE
usage: shuffle [boolean]

Without parameters, check the shuffle state. When parameters are provided, you can turn it on and off.

Examples:

Is shuffling?:
	shuffle

Turn shuffle off:
	shuffle off

				USAGE
			end

			def usage_connect
				return <<-USAGE
usage: connect (literal | path => literal)

This command allows you to create a new drive or reconnect an existing one.
A drive is a logical folder or container that groups songs by path. This player uses this concept to organize your music directories.
You can disconnect it to avoid the music search look in there.

Examples:

To connect a drive you use the following form:
	connect path/to/my/music => my_library

To reconnect the same drive in the future (if you disconnect it for some reason):
	connect my_library

				USAGE
			end

			def usage_disconnect
				return <<-USAGE
usage: disconnect literal

Disconnect a previously connected drive. With the drive disconnected the searches are not made in this drives.

Examples:

Disconnect a temporal download music drive:
	disconnect my_downloads

				USAGE
			end

			def usage_ff
				return <<-USAGE
usage: ff [number]

Fast forward the current playback 10 seconds by default. This time can be customized passing a parameter with the seconds to fast forward.

Examples:

Fas forward 10 seconds:
	ff

Fas forward 35 seconds:
	ff 35

				USAGE
			end

			def usage_fb
				return <<-USAGE
usage: fb [number]

Fast backward the current playback 10 seconds by default. This time can be customized passing a parameter with the seconds to fast backward.

Examples:

Fas backward 10 seconds:
	fb

Fas backward 5 seconds:
	fb 5

				USAGE
			end

			def usage_repeat
				return <<-USAGE
usage: stop

Stop current playback.

Examples

Stop current playback:
	stop

				USAGE
			end


  	end
  end
end