require 'cgi'
require 'mime/types'
require 'kaminari'

module Rich
  class StorageFolder < ApplicationRecord
    self.table_name = "active_storage_folders"
    has_many_attached :files

    has_many :children, class_name: "StorageFolder", foreign_key: "parent_id"
    belongs_to :parent, class_name: "StorageFolder", optional: true
  end
end
