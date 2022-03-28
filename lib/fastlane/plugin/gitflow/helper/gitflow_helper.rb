require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class GitflowHelper
      def self.find_build_gradle(folder)
        found_files = Dir.glob(File.join(folder, 'build.gradle{,.kts}'))

        UI.user_error!("Unable to find `build.gradle[.kts]` in the #{folder == 'app' ? 'chosen' : 'app'} directory") if found_files.empty?
        UI.user_error!("Found too many `build.gradle[.kts]` files in the chosen directory") if found_files.count > 1

        found_files[0]
      end

      def self.find_package_json(folder)
        path = File.join(folder, 'package.json')

        UI.user_error!("Unable to find `package.json` in the #{folder == '.' ? 'chosen' : 'current'} directory") unless File.exist?(path)

        path
      end

      def self.update_by_regex(filename, field_name, pattern, dry_run = false)
        UI.user_error!("Cannot find file '#{filename}'") unless File.exist?(filename)
        file_content = File.read(filename)

        original_value = file_content[pattern, 1]

        UI.user_error!("Unable to find '#{field_name}' in #{filename}") if original_value.nil?

        new_value = yield(original_value).to_s

        if original_value == new_value then
          UI.verbose("Not updating '#{field_name}' because value is unchanged")
          return
        end

        # This lets us get the value and return it without making modifications,
        # then actually update it later.
        if dry_run then
          UI.verbose("DRY RUN. Would be updating #{field_name} from #{original_value} to #{new_value}")
          return
        end


        file_content[pattern, 1] = new_value

        UI.message("Updating #{field_name} from #{original_value} to #{new_value}")

        f = File.new(filename, 'wb') # 'b' is important to keep line endings correct
        f.write(file_content)
        f.close
      end

      def self.supported_version_styles
        ["calver"]
      end

      def self.increment_version_by_style(style_or_new_value, original_value, dont_ask = false, level = nil)
        UI.verbose("Updating version '#{original_value}' using '#{style_or_new_value}'")
        case style_or_new_value
        when "semver"
          # TODO
          original_value
        when "calver"
          split_version = original_value.split('.')
          now = Time.now
          year = now.strftime("%y")
          month = now.strftime("%m")
          release_in_month = 0

          # Node.js drops leading zeros in versions
          if split_version[1].length == 1 then
            split_version[1] = "0#{split_version[1]}"
          end

          if year == split_version[0] && month == split_version[1] then
            release_in_month = (split_version[2] || 0).to_i + 1
          end
          new_version = original_value
          if dont_ask || UI.confirm("Would you like to update the version from '#{original_value}' to '#{year}.#{month}.#{release_in_month}'?") then
            new_version = "#{year}.#{month}.#{release_in_month}"
          end
          new_version
        else
          style_or_new_value
        end
      end
    end
  end
end
