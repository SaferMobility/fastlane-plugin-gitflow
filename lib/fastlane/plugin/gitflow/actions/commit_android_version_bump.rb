# Based on https://github.com/fastlane/fastlane/blob/acb7d84e7ac068e424da231c2eca39fe2ec7297d/fastlane/lib/fastlane/actions/commit_version_bump.rb
require 'pathname'

module Fastlane
  module Actions
    module SharedValues
      ANDROID_MODIFIED_FILES = :ANDROID_MODIFIED_FILES
    end

    class << self
      # Add an array of paths relative to the repo root or absolute paths that have been modified by
      # an action.
      #
      # :files: An array of paths relative to the repo root or absolute paths
      def add_modified_files(files)
        modified_files = lane_context[SharedValues::ANDROID_MODIFIED_FILES] || Set.new
        modified_files += files
        lane_context[SharedValues::ANDROID_MODIFIED_FILES] = modified_files
      end
    end

    class CommitAndroidVersionBumpAction < Action
      def self.run(params)
        repo_path = Actions.sh('git rev-parse --show-toplevel').strip
        repo_pathname = Pathname.new(repo_path)

        gradle_build_path = File.expand_path(File.join('.', 'app', 'build.gradle'))
        gradle_build_path_relative = Pathname.new(gradle_build_path).relative_path_from(repo_pathname).to_s

        UI.user_error!("Could not find the specified gradle project: #{gradle_build_path}") unless File.exists?(gradle_build_path)

        fastlane_metadata_path = File.expand_path(File.join('.', 'fastlane', 'metadata'))
        # changelog_file_paths = []
        # Find.find(fastlane_metadata_path) do |path|
        #   changelog_file_paths << path if path ~= /\/changelogs\//
        # end
        changelog_file_paths = Dir.glob("#{fastlane_metadata_path}/**/changelogs/*")

        extra_files = params[:include]
        extra_files += modified_files_relative_to_repo_root(repo_path)

        # create our list of files that we expect to have changed, they should all be relative to the project root, which should be equal to the git workdir root
        expected_changed_files = extra_files
        expected_changed_files << gradle_build_path_relative
        expected_changed_files << changelog_file_paths.map { |path|
          Pathname.new(path).relative_path_from(repo_pathname).to_s
        }

        expected_changed_files.flatten!
	expected_changed_files.uniq!

        # get the list of files that have actually changed in our git workdir
        git_dirty_files = Actions.sh('git diff --name-only HEAD').split("\n") + Actions.sh('git ls-files --other --exclude-standard').split("\n")

        # little user hint
        UI.user_error!("No file changes picked up. Make sure you run the `increment_build_number` action first.") if git_dirty_files.empty?

        # check if the files changed are the ones we expected to change (these should be only the files that have version info in them)
        changed_files_as_expected = Set.new(git_dirty_files.map(&:downcase)).subset?(Set.new(expected_changed_files.map(&:downcase)))
        unless changed_files_as_expected
          unless params[:force]
            error = [
              "Found unexpected uncommitted changes in the working directory. Expected these files to have ",
              "changed: \n#{expected_changed_files.join("\n")}\nBut found these actual changes: ",
              "#{git_dirty_files.join("\n")}\nMake sure you have cleaned up the build artifacts and ",
              "are only left with the changed version files at this stage in your lane, and don't touch the ",
              "working directory while your lane is running. You can also use the :force option to bypass this ",
              "check, and always commit a version bump regardless of the state of the working directory."
            ].join("\n")
            UI.user_error!(error)
          end
        end

        # get the absolute paths to the files
        git_add_paths = expected_changed_files.map do |path|
          updated = path.gsub("$(SRCROOT)", ".").gsub("${SRCROOT}", ".")
          File.expand_path(File.join(repo_pathname, updated))
        end

        # then create a commit with a message
        Actions.sh("git add #{git_add_paths.map(&:shellescape).join(' ')}")

        begin
          command = build_git_command(params)

          Actions.sh(command)

          UI.success("Committed \"#{params[:message]}\" 💾.")
        rescue => ex
          UI.error(ex)
          UI.important("Didn't commit any changes.")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Creates a 'Version Bump' commit. Run after `increment_build_number`"
      end

      def self.output
        [
          ['ANDROID_MODIFIED_FILES', 'The list of paths of modified files']
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_COMMIT_BUMP_MESSAGE",
                                       description: "The commit message when committing the version bump",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :force,
                                       env_name: "FL_FORCE_COMMIT",
                                       description: "Forces the commit, even if other files than the ones containing the version number have been modified",
                                       type: Boolean,
                                       optional: true,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :include,
                                       description: "A list of extra files to be included in the version bump (string array or comma-separated string)",
                                       optional: true,
                                       default_value: [],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :no_verify,
                                      env_name: "FL_GIT_PUSH_USE_NO_VERIFY",
                                      description: "Whether or not to use --no-verify",
                                      type: Boolean,
                                      default_value: false)
        ]
      end

      def self.details
        list = <<-LIST.markdown_list
          The `app/build.gradle` file
          All `fastlane/metadata/*/changelogs/*` files
        LIST

        [
          "This action will create a 'Version Bump' commit in your repo. Useful in conjunction with `increment_build_number`.",
          "It checks the repo to make sure that only the relevant files have changed, specifically these files:".markdown_preserve_newlines,
          list,
          "Then commits those files to the repo.",
          "Customize the message with the `:message` option. It defaults to 'Version Bump'.",
          "If you have other uncommitted changes in your repo, this action will fail."
        ].join("\n")
      end

      def self.authors
        ["kohenkatz"]
      end

      def self.is_supported?(platform)
        platform == :android
      end

      class << self
        def modified_files_relative_to_repo_root(repo_root)
          return [] if Actions.lane_context[SharedValues::ANDROID_MODIFIED_FILES].nil?

          root_pathname = Pathname.new(repo_root)
          all_modified_files = Actions.lane_context[SharedValues::ANDROID_MODIFIED_FILES].map do |path|
            next path unless path =~ %r{^/}
            Pathname.new(path).relative_path_from(root_pathname).to_s
          end
          return all_modified_files.uniq
        end

        def build_git_command(params)
          build_number = Actions.lane_context[Actions::SharedValues::BUILD_NUMBER]

          params[:message] ||= (build_number ? "Version Bump to #{build_number}" : "Version Bump")

          command = [
            'git',
            'commit',
            '-m',
            "\"#{params[:message]}\""
          ]

          command << '--no-verify' if params[:no_verify]

          return command.join(' ')
        end
      end
    end
  end
end
