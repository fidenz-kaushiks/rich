require 'cgi'
require 'mime/types'
require 'kaminari'

module Rich
  class StorageFolder < ApplicationRecord
    self.table_name = "active_storage_folders"

    has_many :children, class_name: "StorageFolder", foreign_key: "parent_id"
    belongs_to :parent, class_name: "StorageFolder", optional: true

    if Rich.options[:use_active_storage]
      has_many_attached :files

      def attach(file)
        files.attach(file)
      end
    else
      has_many :files, class_name: "RichFile"

      def attach(file_params)
        file = RichFile.new
        file_params.content_type = Mime::Type.lookup_by_extension(file_params.original_filename.split('.').last.to_sym)
        file.simplified_type     = image_mime_types.include?(file_params.content_type) ? 'image' : 'file'
        file.rich_file           = file_params
        file.storage_folder_id   = self.id
        file.save
      end
    end

    private

    def image_mime_types
      ['image/jpeg', 'image/png', 'image/apng', 'image/bmp', 'image/gif', 'image/x-icon', 'image/svg+xml', 'image/tiff', 'image/webp']
    end
  end
end
