module Fastlane
  module Actions
    module SharedValues
      NODE_PACKAGE_VERSION = :NODE_PACKAGE_VERSION
    end

    class IncrementNodePackageVersionAction < Action
      def self.run(params)
        build_file = Helper::GitflowHelper.find_package_json(params[:directory] || '.')

        require 'json'
        file_contents = File.read(build_file)
        package_json = JSON.parse(file_contents)
        current_version = package_json['version']

        new_version = Helper::GitflowHelper.increment_version_by_style(params[:version_name], current_version)

        dry_run = params[:dont_write] || false

        sh("npm version --no-git-tag-version #{new_version}") unless dry_run

        Actions.lane_context[SharedValues::NODE_PACKAGE_VERSION] = new_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Increment the version of a Node.js project (in package.json)"
      end

      def self.output
        [
          ['NODE_PACKAGE_VERSION', 'The new version']
        ]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version_name,
                                        env_name: "FL_NODE_PACKAGE_VERSION_PACKAGE_VERSION",
                                        description: "The style of versioning to use, or a specific version number"),
          FastlaneCore::ConfigItem.new(key: :dont_write,
                                        type: Boolean,
                                        env_name: "FL_NODE_PACKAGE_VERSION_DONT_WRITE",
                                        description: "Don't write the change to the file, only calculate it",
                                        optional: true),
          FastlaneCore::ConfigItem.new(key: :directory,
                                        env_name: "FL_NODE_PACKAGE_VERSION_DIRECTORY",
                                        description: "Specify the path to the directory that contains your `pagkage.json`, if it is not the current directory",
                                        optional: true,
                                        verify_block: proc do |value|
                                          UI.user_error!("Could not find Node.js project directory") if !File.directory?(value) && !Helper.test?
                                        end)
        ]
      end

      def self.authors
        ["kohenkatz"]
      end

      def self.is_supported?(platform)
        platform == :node
      end

    end
  end
end
