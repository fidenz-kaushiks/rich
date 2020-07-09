module Rich
  module FilesHelper

    def thumb_for_file(item, size=:thumb)
      if item.class.name == 'Rich::StorageFolder'
        get_icon_url 'icons/icon-empty.png'
      elsif item.image?
        if item.class.name == 'Rich::RichFile'
          item.rich_file.url(size.to_sym)
        else
          get_image_url(item, "100X100")
        end
      else
        case item.blob.content_type
        when 'application/pdf'
          get_icon_url 'icons/icon-pdf.png'
        when 'application/msword'
          get_icon_url 'icons/icon-doc.png'
        when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          get_icon_url 'icons/icon-docx.png'
        when 'text/html'
          get_icon_url 'icons/icon-html.png'
        when 'text/css'
          get_icon_url 'icons/icon-css.png'
        when 'video/x-msvideo'
          get_icon_url 'icons/icon-avi.png'
        when 'audio/mpeg3' || 'audio/x-mpeg-3' || 'audio/mpeg'
          get_icon_url 'icons/icon-mp3.png'
        when 'application/zip'
          get_icon_url 'icons/icon-zip.png'
        when 'text/csv'
          get_icon_url 'icons/icon-csv.png'
        when 'image/vnd.adobe.photoshop'
          get_icon_url 'icons/icon-psd.png'
        when 'application/vnd.ms-excel' || 'application/vnd.ms-excel.sheet.binary.macroenabled.12' || ' application/vnd.ms-excel.sheet.macroenabled.12' || 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          get_icon_url 'icons/icon-xls.png'
        when 'application/vnd.openxmlformats-officedocument.presentationml.presentation' || 'application/vnd.ms-powerpoint' || 'application/vnd.ms-powerpoint.presentation.macroenabled.12'
          get_icon_url 'icons/icon-ppt.png'
        when 'application/x-rar-compressed'
          get_icon_url 'icons/icon-rar.png'
        when 'text/plain'
          get_icon_url 'icons/icon-txt.png'
        when 'video/mp4' || 'application/mp4' || 'audio/mp4'
          get_icon_url 'icons/icon-mp4.png'
        when 'folder'
          get_icon_url 'icons/icon-empty.png'
        else
          get_icon_url 'icons/icon-unknown.png'
        end
      end
    end

    def get_image_url(image_file, ratio)
      Rails.application.routes.url_helpers.rails_representation_url(
        image_file.variant(
          combine_options: {
          auto_orient: true,
          gravity: "center",
          resize: ratio+"^",
          crop: "#{ratio}+0+0"
        }).processed, only_path: true).remove("/rich")
    end

    def get_icon_url(icon)
      ActionController::Base.helpers.asset_path(icon)
    end
  end
end
