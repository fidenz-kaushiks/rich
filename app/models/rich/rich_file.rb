require 'cgi'
require 'mime/types'
require 'kaminari'

module Rich
  class RichFile < ApplicationRecord
		include Backends::Paperclip

		belongs_to :storage_folder
		paginates_per Rich.options[:paginates_per]

		def blob
			self
		end

		def record
			storage_folder
		end

		def image?
			simplified_type == 'image'
		end

		def content_type
			rich_file_content_type
		end

		def filename=(name)
			self.rename!(name.split('.')[0])
			self.rich_file_file_name = name
		end
  end
end
