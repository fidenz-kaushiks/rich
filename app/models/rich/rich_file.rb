require 'cgi'
require 'mime/types'
require 'kaminari'

module Rich
  class RichFile < ApplicationRecord
		include Backends::Paperclip

		belongs_to :storage_folder

		scope :images, -> (id) { where("simplified_type in (?)",['image']).where(parent_id: id) }
		scope :videos, -> (id) { where("simplified_type in (?)",['video']).where(parent_id: id) }
		scope :files, -> (id) { where("simplified_type in (?)",['file']).where(parent_id: id ) }
		scope :audios, -> (id) { where("simplified_type in (?)",['audio']).where(parent_id: id) }
		scope :any, -> (id) { where(parent_id: id) }

		# scope :images, -> (id) { where("simplified_type in (?)",['image', 'folder']).where(parent_id: id) }
		# scope :videos, -> (id) { where("simplified_type in (?)",['video', 'folder']).where(parent_id: id) }
		# scope :files, -> (id) { where("simplified_type in (?)",['file', 'folder']).where(parent_id: id ) }
		# scope :audios, -> (id) { where("simplified_type in (?)",['audio', 'folder']).where(parent_id: id) }
		# scope :any, -> (id) { where(parent_id: id) }

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
