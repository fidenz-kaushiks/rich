require 'cgi'
require 'mime/types'
require 'kaminari'

module Rich
	class StorageFolder < ApplicationRecord
		self.table_name = "active_storage_folders"
		has_many_attached :files
  end
end
