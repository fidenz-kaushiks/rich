require 'cgi'
require 'mime/types'
require 'kaminari'

module Rich
  class RichFile < ActiveRecord::Base
		include Backends::Paperclip

		belongs_to :folder

		def custom_image_styles=(value)
		  @custom_image_styles = value
		end

		def custom_image_styles
			@custom_image_styles || []
		end

		def file_size=(value)
		  @file_size = value
		end

		def file_size
			@file_size || Rich.file_size
		end

		validate :image_size
		def image_size
			if rich_file_file_size > file_size
				errors[:base] << "must be smaller than #{file_size}"
			end
		end

		scope :images,  -> (id) { where("simplified_type in (?)",['image']).where(folder_id: id) }
		scope :videos,   -> (id) { where("simplified_type in (?)",['video']).where(folder_id: id) }
		scope :files,   -> (id) { where("simplified_type in (?)",['file']).where(folder_id: id ) }
		scope :audios,   -> (id) { where("simplified_type in (?)",['audio']).where(folder_id: id) }
		scope :any,   -> (id) { where(folder_id: id) }

		paginates_per Rich.options[:paginates_per]
  end
end
