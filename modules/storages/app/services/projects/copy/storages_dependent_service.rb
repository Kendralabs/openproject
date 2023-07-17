#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Copy
  class StoragesDependentService < ::Copy::Dependency
    def self.human_name
      I18n.t(:label_project_storage_plural)
    end

    def source_count
      source.storages.count
    end

    protected

    def copy_dependency(*)
      source.projects_storages.find_each do |project_storage|
        copied_project_storage = create_project_storage(project_storage)

        if project_storage.project_folder_automatic?
          copy_project_folder(project_storage, copied_project_storage.project)
        end
      end
    end

    private

    def create_project_storage(project_storage)
      attributes = project_storage
        .attributes.dup.except('id', 'project_id', 'created_at', 'updated_at')
        .merge('project_id' => target.id)

      service_result = ::Storages::ProjectStorages::CreateService
        .new(user: User.current)
        .call(attributes)

      copied_storage = service_result.result
      copied_storage.save
      copied_storage
    end

    def copy_project_folder(source_project_storage, destination_project)
      source_folder_name = project_folder_path(source_project_storage.project)
      destination_folder_name = project_folder_path(destination_project)

      Storages::Peripherals::StorageRequests
        .new(storage: source_project_storage.storage)
        .copy_template_folder_command
        .call(source_path: source_folder_name, destination_path: destination_folder_name)
        .on_failure { |result| add_error! source_folder_name, result.to_active_model_errors }
    end

    def project_folder_path(project)
      "#{@group_folder}/#{project.name.gsub('/', '|')} (#{project.id})/"
    end
  end
end
