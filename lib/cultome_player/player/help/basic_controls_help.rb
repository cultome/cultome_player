
module CultomePlayer::Player
    module BasicControlsHelp
        def self.included(base)
            base.command_help_registry[:play] = {
                help: "Create and inmediatly plays playlists",
                params_format: "(<number>|<criteria>|<object>|<literal>)*",
                usage: <<-HELP
Creates a playlist and make it active right away but it can also play an elements of the focus list.
When a new playlist is created, some other playlist are created, among them the focus list. You can think of the focus list as "The song list last showed in screen".
This playlist allows the player to know what you are meaning when you type a number as parameter. This playlist is dynamic and changes when some song list is displayed in the screen, for example when a search is done (search strawberry) or when an object is showed (show @history).

The parameters provided are used to create the new playlist. Let review how the mix to create the playlist:
    1.  When criteria parameters are used, diferents criterios makes an AND condition, and similar criterios make an OR condition. For example:
        * play a:Gorillaz b:Demon
        Search for songs with artists that contains 'Gorillaz' in theirs names AND 'Demon' in theirs albums names. Different criterios ('a' and 'b') makes an AND condition.
        * play a:Gorillaz a:Sabbath
        Search for songs with artists that contains 'Gorillaz' OR 'Sabbath' in theirs names. Same criterios ('a' and 'a') makes an OR condition.

    2.  When number parameters are used, all the elements in the focus list are played.
        * play 1 4 5
        Plays the first, fourth and fiveth songs in the focus list. But dont add them to the current playlist.

    3.  When object parameters are used, all the elements in the objects are used to create the new playlist.
        * play @history @search

    4.  When literal parameters are used, this are used as all-criterias match, so
        * play one two
        Play song with the strings 'one' or 'two' in their title, artist's name or album's name in it.

Any parameter type and quantity can be used to create a playlist.

                HELP
            }

            base.command_help_registry[:enqueue] = {
                help: "Append the created playlist to the current playlist",
                params_format: "(<number>|<criteria>|<object>|<literal>)*",
                usage: <<-HELP
See 'help play' for more information about parameters.

The only diference with play command is that this command append its results to the current playlist instead of create a new one.
                HELP
            }

            base.command_help_registry[:search] = {
                help: "Find inside library for song with the given criteria.",
                params_format: "(<criteria>|<object>|<literal>)*",
                usage: <<-HELP
See 'help play' for more information about parameters.

The search command search song in the library and display the results in the screen. The results change the focus list.

                HELP
            }

            base.command_help_registry[:pause] = {
                help: "Pause playback.",
                params_format: "",
                usage: <<-HELP
Pause the playback of the current song. This command has a state and is toggled every time is invoked. So if the song is playing and you type 'pause', the playback pause and the state of the player change to PAUSED, when you type again 'pause', the playback resume and the player states is changed to RESUMED.

                HELP
            }

            base.command_help_registry[:stop] = {
                help: "Stops playback.",
                params_format: "",
                usage: <<-HELP
Stop the playback and there ir no way to resume where you were. So using 'play' won't resume the last song played.
                HELP
            }

            base.command_help_registry[:next] = {
                help: "Play the next song in the queue.",
                params_format: "",
                usage: <<-HELP
When next is invoked, the calculation for the next song is made. If shuffle is on, the next song is defined by selecting a song not played yet, if remains any, if not, the complete current playlist is reprogramed to be played again.
                HELP
            }

            base.command_help_registry[:prev] = {
                help: "Play the previous song from the history.",
                params_format: "",
                usage: <<-HELP
Extract the latest song from history and play it. The history object is modified by this action.
                HELP
            }

            base.command_help_registry[:connect] = {
                help: "Add files to the library.",
                params_format: "<path> => <literal>",
                usage: <<-HELP
Tells the player to go to the path and search for mp3 files and add them to the library under the drive name.
    * connect /home/user/music => main

You can add as many drives as you like. Once connected the drive needs not to be connected again, unless disconnected explicitly.

The player dont scan the drive for changes, if you want to update your drive, just type the connect method with the same path and an update will be made instead of a insert. For example, if you connect one drive 'downloads'
    * connect /home/user/download => downloads
And later, new song came to this folder, you can refresh the drive with the next
    * connect /home/user/download => no_matter
The name dont matter as the path is the same. The trailing dashes are ignored. In this forma the new songs are added but the older persist (no duplications).

If you only want to re-connect the drive without scanning for new media just type:
    * connect <drive_name>

                HELP
            }

            base.command_help_registry[:disconnect] = {
                help: "Remove filesfrom the library.",
                params_format: "<literal>",
                usage: <<-HELP
See 'help connect' for more information.

Disconnect a previously connected drive. This mean the songs in this drive are no longer availables to be played or searched.

                HELP
            }

            base.command_help_registry[:ff] = {
                help: "Fast forward the current playback.",
                params_format: "",
                usage: <<-HELP
The amount of time can be determined changing the parameter config["seeker_step"] (default: 500)

                HELP
            }

            base.command_help_registry[:fb] = {
                help: "Fast backward the current playback.",
                params_format: "",
                usage: <<-HELP
The amount of time can be determined changing the parameter config["seeker_step"] (default: 500)

                HELP
            }

            base.command_help_registry[:shuffle] = {
                help: "Check and change the status of shuffle.",
                params_format: "<number>|<literal>",
                usage: <<-HELP
Toggle the shuffling of playback. Without parameter shows the state of the shuffle (on|off).

This command support a variety of true-like values to indicate the shuffle must be turn on, for example all the following turn it on:
    * shuffle on
    * shuffle yes
    * shuffle 1

Same case for turn it off:
    * shuffle off
    * shuffle no
    * shuffle 0

                HELP
            }

            base.command_help_registry[:repeat] = {
                help: "Repeat the current song",
                params_format: "",
                usage: <<-HELP
Start the playback of the current song again from the beginning.

                HELP
            }
        end
    end
end

