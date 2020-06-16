raise 'Please install Paperclip: github.com/thoughtbot/paperclip' unless Object.const_defined?(:Paperclip)

module Rich
  module Backends
    module Paperclip
      extend ActiveSupport::Concern

      included do
        has_attached_file :rich_file,
                          styles: proc { |a| a.instance.set_styles },
                          convert_options: proc { |a| Rich.convert_options[a] }
        do_not_validate_attachment_file_type :rich_file
        validates_attachment_presence :rich_file
        validate :check_content_type
        validates_attachment_size :rich_file, less_than: 300.megabyte, message: 'must be smaller than 300MB'

        before_create :clean_file_name

        after_create :cache_style_uris_and_save
        before_update :cache_style_uris
      end

      def filename
        rich_file_file_name
      end

      def set_styles
        if simplified_type == 'image'
          Rich.image_styles
        else
          {}
        end
      end

      def rename!(new_filename_without_extension)
        new_filename = new_filename_without_extension + File.extname(rich_file_file_name)
        rename_files!(new_filename)
        update_column(:rich_file_file_name, new_filename)
        cache_style_uris_and_save
        new_filename
      end

      private

      def rename_files!(new_filename)
        (rich_file.styles.keys + [:original]).each do |style|
          path = rich_file.path(style)
          FileUtils.move path, File.join(File.dirname(path), new_filename)
        end
      end

      def cache_style_uris_and_save
        cache_style_uris
        save!
      end

      def check_content_type
        rich_file.instance_write(:content_type, MIME::Types.type_for(rich_file_file_name)[0].content_type)

        unless Rich.validate_mime_type(rich_file_content_type, simplified_type)
          errors[:base] << "'#{rich_file_file_name}' is not the right type."
        end
      end

      def cache_style_uris
        uris = {}

        rich_file.styles.each do |style|
          uris[style[0]] = rich_file.url(style[0].to_sym, false)
        end

        # manualy add the original size
        uris['original'] = rich_file.url(:original, false)

        self.uri_cache = uris.to_json
      end

      def clean_file_name
        extension = File.extname(rich_file_file_name).gsub(/^\.+/, '')
        filename = rich_file_file_name.gsub(/\.#{extension}$/, '')

        filename = CGI.unescape(filename)

        extension = extension.downcase
        filename = filename.downcase.gsub(/[^a-z0-9]+/i, '-')

        rich_file.instance_write(:file_name, "#{filename}.#{extension}")
      end

      module ClassMethods
      end
    end
  end

  Rich::RichFile.send(:include, Backends::Paperclip)
end
