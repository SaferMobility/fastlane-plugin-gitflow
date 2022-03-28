module Fastlane
  module Actions
    module SharedValues
      ANDROID_VERSION_NAME = :ANDROID_VERSION_NAME
    end

    class IncrementAndroidVersionNameAction < Action
      def self.run(params)
        build_file = Helper::GitflowHelper.find_build_gradle(params[:project_module] || 'app')

        search_prefix = params[:search_prefix] || 'versionName'
        search_regex = /#{Regexp.escape(search_prefix)}\s+'([.\d]+)'/

        dry_run = params[:dont_write] || false

        Helper::GitflowHelper.update_by_regex(build_file, "versionName", search_regex, dry_run) do |current_version|
          new_version = Helper::GitflowHelper.increment_version_by_style(params[:version_name], current_version)

          Actions.lane_context[SharedValues::ANDROID_VERSION_NAME] = new_version
        end

        Actions.lane_context[SharedValues::ANDROID_VERSION_NAME]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Increment the version name of a module in your Android project (default module is 'app')"
      end

      def self.output
        [
          ['ANDROID_VERSION_NAME', 'The new version name']
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: "FL_ANDROID_VERSION_NAME_VERSION_NAME",
                                       description: "The style of versioning to use, or a specific version number"),
          FastlaneCore::ConfigItem.new(key: :search_prefix,
                                       env_name: "FL_ANDROID_VERSION_NAME_SEARCH_PREFIX",
                                       description: "The string to look for in the build.gradle file",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :dont_write,
                                       type: Boolean,
                                       env_name: "FL_ANDROID_VERSION_NAME_DONT_WRITE",
                                       description: "Don't write the change to the file, only calculate it",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :project_module,
                                       env_name: "FL_ANDROID_VERSION_NAME_MODULE",
                                       description: "Specify the path to the directory that contains your `build.gradle`, if it is not `./app/`",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Could not find Android project directory") if !File.directory?(value) && !Helper.test?
                                       end)
        ]
      end

      def self.authors
        ["kohenkatz"]
      end

      def self.is_supported?(platform)
        platform == :android
      end

    end
  end
end
