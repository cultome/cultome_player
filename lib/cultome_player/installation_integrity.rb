require 'fileutils'

module CultomePlayer
    module InstallationIntegrity
        def check_integrity
            check_directories_integrity
            check_config_files_integrity
            check_database_integrity
        end

        def check_directories_integrity
            FileUtils.mkpath(user_dir) unless File.exist?(user_dir)
            FileUtils.mkpath(db_logs_folder_path) unless Dir.exist?(db_logs_folder_path)
        end

        def check_config_files_integrity
            FileUtils.cp(File.join(project_path, Helper::CONFIG_FILE_NAME), config_file) unless File.exist?(config_file)
        end

        def check_database_integrity
            with_connection do
                max_version = ActiveRecord::Migrator.migrations(migrations_path).max{|m| m.version }.version
                current_version = ActiveRecord::Migrator.current_version

                if max_version > current_version
                    def capture_stdout
                        s = StringIO.new
                        oldstd = $stdout
                        $stdout = s
                        yield
                        s.string
                    ensure
                        $stdout = oldstd
                    end

                    capture_stdout { ActiveRecord::Migrator.migrate(migrations_path) }
                end

                # checamos dos registros clave
                CultomePlayer::Model::Artist.find_or_create_by_id(id: 0, name: 'Unknown')
                CultomePlayer::Model::Album.find_or_create_by_id(id: 0, name: 'Unknown')
            end
        end
    end
end
