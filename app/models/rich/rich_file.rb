require 'cgi'
require 'mime/types'
require 'kaminari'

module Rich
  class RichFile < ActiveRecord::Base
		include Backends::Storage
		self.table_name = "active_storage_folders"

		# belongs_to :parent, class_name: "RichFile", optional: true
		# has_many :children, class_name: "RichFile", foreign_key: :parent_id, dependent: :destroy

		# scope :images,  -> (id) { where("simplified_type in (?)",['image', 'folder']).where(parent_id: id) }
		# scope :videos,   -> (id) { where("simplified_type in (?)",['video', 'folder']).where(parent_id: id) }
		# scope :files,   -> (id) { where("simplified_type in (?)",['file', 'folder']).where(parent_id: id ) }
		# scope :audios,   -> (id) { where("simplified_type in (?)",['audio', 'folder']).where(parent_id: id) }
		# scope :any,   -> (id) { where(parent_id: id) }

		paginates_per Rich.options[:paginates_per]

  end
end
