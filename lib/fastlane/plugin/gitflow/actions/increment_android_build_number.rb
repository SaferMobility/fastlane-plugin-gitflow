module Fastlane
  module Actions
    module SharedValues
      ANDROID_BUILD_NUMBER = :ANDROID_BUILD_NUMBER
    end

    class IncrementAndroidBuildNumberAction < Action
      def self.run(params)
        build_file = Helper::GitflowHelper.find_build_gradle(params[:project_module] || 'app')

        search_prefix = params[:search_prefix] || 'versionCode'
        search_regex = /#{Regexp.escape(search_prefix)}\s+(\d+)/

        dry_run = params[:dont_write] || false

        Helper::GitflowHelper.update_by_regex(build_file, "versionCode", search_regex, dry_run) do |current_build|
          new_build = params[:build_number] || (current_build.to_i + 1).to_s

          Actions.lane_context[SharedValues::ANDROID_BUILD_NUMBER] = new_build
        end

        Actions.lane_context[SharedValues::ANDROID_BUILD_NUMBER]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Increment the build number of a module in your Android project (default module is 'app')"
      end

      def self.output
        [
          ['ANDROID_BUILD_NUMBER', 'The new build number']
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :build_number,
                                       type: Integer,
                                       env_name: "FL_ANDROID_BUILD_NUMBER_BUILD_NUMBER",
                                       description: "Change to a specific version",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :search_prefix,
                                       env_name: "FL_ANDROID_BUILD_NUMBER_SEARCH_PREFIX",
                                       description: "The string to look for in the build.gradle file",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :dont_write,
                                       type: Boolean,
                                       env_name: "FL_ANDROID_BUILD_NUMBER_DONT_WRITE",
                                       description: "Don't write the change to the file, only calculate it",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :project_module,
                                       env_name: "FL_ANDROID_BUILD_NUMBER_MODULE",
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
