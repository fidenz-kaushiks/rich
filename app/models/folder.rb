class Folder < ActiveRecord::Base
	belongs_to :parent, class_name: "Folder"
	has_many :children, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy

	scope :folders,   -> (id) { where(parent_id: id) }
end
