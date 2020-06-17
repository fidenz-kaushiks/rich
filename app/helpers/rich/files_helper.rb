module Rich
  module FilesHelper

    def thumb_for_file(file)
      if file.image?
        get_image_url(file)
      else
        case file.blob.content_type
        when 'application/pdf'
          byebug
          image_path 'icons/icon-pdf.png'
        when 'application/msword'
          image_path 'icons/icon-doc.png'
        when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          image_path 'icons/icon-docx.png'
        when 'text/html'
          image_path 'icons/icon-html.png'
        when 'text/css'
          image_path 'icons/icon-css.png'
        when 'video/x-msvideo'
          image_path 'icons/icon-avi.png'
        when 'audio/mpeg3' || 'audio/x-mpeg-3' || 'audio/mpeg'
          image_path 'icons/icon-mp3.png'
        when 'application/zip'
          image_path 'icons/icon-zip.png'
        when 'text/csv'
          image_path 'icons/icon-csv.png'
        when 'image/vnd.adobe.photoshop'
          image_path 'icons/icon-psd.png'
        when 'application/vnd.ms-excel' || 'application/vnd.ms-excel.sheet.binary.macroenabled.12' || ' application/vnd.ms-excel.sheet.macroenabled.12' || 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          image_path 'icons/icon-xls.png'
        when 'application/vnd.openxmlformats-officedocument.presentationml.presentation' || 'application/vnd.ms-powerpoint' || 'application/vnd.ms-powerpoint.presentation.macroenabled.12'
          image_path 'icons/icon-ppt.png'
        when 'application/x-rar-compressed'
          image_path 'icons/icon-rar.png'
        when 'text/plain'
          image_path 'icons/icon-txt.png'
        when 'video/mp4' || 'application/mp4' || 'audio/mp4'
          image_path 'icons/icon-mp4.png'
        when 'folder'
          image_path 'icons/icon-empty.png'
        else
          image_path 'icons/icon-unknown.png'
        end
      end
    end

    def get_image_url(image_file)
      Rails.application.routes.url_helpers.rails_representation_url(
        image_file.variant(
          combine_options: {
          auto_orient: true,
          gravity: "center",
          resize: "100x100^",
          crop: "100x100+0+0"
        }).processed, only_path: true).remove("/rich")
    end
  end
end
