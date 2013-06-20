require 'fileutils'

module CultomePlayer
    module InstallationIntegrity

        # Do all the check to guarantize a ready-to-run environment.
        def check_integrity
            check_directories_integrity
            check_config_files_integrity
            check_database_integrity
        end

        # Check if the required directories are created and are accesibles.
        def check_directories_integrity
            FileUtils.mkpath(user_dir) unless File.exist?(user_dir)
            FileUtils.mkpath(db_logs_folder_path) unless Dir.exist?(db_logs_folder_path)
        end

        # Check if the config file is a valid one.
        def check_config_files_integrity
            FileUtils.cp(File.join(project_path, Helper::CONFIG_FILE_NAME), config_file) unless File.exist?(config_file)
        end

        # Check if the database is ready to be used.
        def check_database_integrity
            with_connection do
                max_version = ActiveRecord::Migrator.migrations(migrations_path).max{|m| m.version }.version
                current_version = ActiveRecord::Migrator.current_version

                if max_version > current_version
                    swallow_stdout { ActiveRecord::Migrator.migrate(migrations_path) }
                end

                # checamos dos registros clave
                CultomePlayer::Model::Artist.find_or_create_by_id(id: 0, name: 'Unknown')
                CultomePlayer::Model::Album.find_or_create_by_id(id: 0, name: 'Unknown')
            end
        end
    end
end
