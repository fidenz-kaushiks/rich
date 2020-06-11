raise "Please install Paperclip: github.com/thoughtbot/paperclip" unless Object.const_defined?(:Paperclip)

module Rich
  module Backends
    module Storage
      extend ActiveSupport::Concern

      included do
        has_one_attached :rich_file
        validates :photos, presence: true, blob: { content_type: ['image/png', 'image/jpg', 'image/jpeg'], size_range: 1..15.megabytes }
      end

    end
  end

  RichFile.send(:include, Backends::Storage)
end
