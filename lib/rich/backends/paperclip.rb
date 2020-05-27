raise "Please install Paperclip: github.com/thoughtbot/paperclip" unless Object.const_defined?(:Paperclip)

module Rich
  module Backends
    module Paperclip
      extend ActiveSupport::Concern

      included do
        has_attached_file :rich_file,
                          :styles => Proc.new {|a| a.instance.set_styles },
                          :convert_options => Proc.new { |a| Rich.convert_options[a] }, unless: :is_a_folder?
        do_not_validate_attachment_file_type :rich_file
        validates_attachment_presence :rich_file, unless: :is_a_folder?
        validate :check_content_type, unless: :is_a_folder?
        validates_attachment_size :rich_file, :less_than=>15.megabyte, :message => "must be smaller than 15MB" , unless: :is_a_folder?

        before_create :clean_file_name, unless: :is_a_folder?

        after_create :cache_style_uris_and_save
        before_update :cache_style_uris
      end

      def filename
        rich_file_file_name
      end

      # used for skipping folders
      def is_a_folder?
        self.rich_file_content_type == 'folder'
      end

      def set_styles
        if self.simplified_type=="image" || self.rich_file_content_type.to_s["image"]
          Rich.image_styles
        elsif self.simplified_type=="video" || self.rich_file_content_type.to_s["video"]
          Rich.video_styles
        else
          {}
        end
      end

      def rename!(new_filename_without_extension)
        unless simplified_type == 'folder'
          new_filename = new_filename_without_extension + File.extname(rich_file_file_name)
          rename_files!(new_filename)
        else
          new_filename = new_filename_without_extension
        end
        update_column(:rich_file_file_name, new_filename)
        cache_style_uris_and_save
        new_filename
      end

      private

      def rename_files!(new_filename)
        (rich_file.styles.keys+[:original]).each do |style|
          path = rich_file.path(style)
          FileUtils.move path, File.join(File.dirname(path), new_filename)
        end
      end

      def cache_style_uris_and_save
        cache_style_uris
        self.save!
      end

      def check_content_type
        unless self.rich_file_content_type == 'folder'
          self.rich_file.instance_write(:content_type, MIME::Types.type_for(rich_file_file_name)[0].content_type)
          if !Rich.validate_mime_type(self.rich_file_content_type, self.simplified_type)
            self.errors[:base] << "'#{self.rich_file_file_name}' is not the right type."
          elsif self.simplified_type == 'all' && Rich.allowed_image_types.include?(self.rich_file_content_type)
            self.simplified_type = 'image'
          elsif self.simplified_type == 'all' && Rich.allowed_video_types.include?(self.rich_file_content_type)
            self.simplified_type = 'video'
          elsif self.simplified_type == 'all' && Rich.allowed_audio_types.include?(self.rich_file_content_type)
            self.simplified_type = 'audio'
          end
        end
      end

      def cache_style_uris
        uris = {}

        rich_file.styles.each do |style|
          uris[style[0]] = rich_file.url(style[0].to_sym, false)
        end

        # manualy add the original size
        uris["original"] = rich_file.url(:original, false)

        self.uri_cache = uris.to_json
      end

      def clean_file_name
        extension = File.extname(rich_file_file_name).gsub(/^\.+/, '')
        filename = rich_file_file_name.gsub(/\.#{extension}$/, '')

        filename = CGI::unescape(filename)

        extension = extension.downcase
        filename = filename.downcase.gsub(/[^a-z0-9]+/i, '-')

        self.rich_file.instance_write(:file_name, "#{filename}.#{extension}")
      end

      module ClassMethods

      end
    end
  end

  RichFile.send(:include, Backends::Paperclip)
end

require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end