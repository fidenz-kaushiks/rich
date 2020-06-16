module Rich
  module FilesHelper
    include Rails.application.routes.url_helpers

    def thumb_for_file(file)
      if file.image?
        rails_representation_url(file.variant(combine_options: {
          auto_orient: true,
          gravity: "center",
          resize: "100x100^",
          crop: "100x100+0+0"
        }).processed, only_path: true).remove("/rich")
      else
        case file.blob.content_type
        when 'application/pdf'
          asset_path 'icons/icon-pdf.png'
        when 'application/msword'
          asset_path 'icons/icon-doc.png'
        when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          asset_path 'icons/icon-docx.png'
        when 'text/html'
          asset_path 'icons/icon-html.png'
        when 'text/css'
          asset_path 'icons/icon-css.png'
        when 'video/x-msvideo'
          asset_path 'icons/icon-avi.png'
        when 'audio/mpeg3' || 'audio/x-mpeg-3' || 'audio/mpeg'
          asset_path 'icons/icon-mp3.png'
        when 'application/zip'
          asset_path 'icons/icon-zip.png'
        when 'text/csv'
          asset_path 'icons/icon-csv.png'
        when 'image/vnd.adobe.photoshop'
          asset_path 'icons/icon-psd.png'
        when 'application/vnd.ms-excel' || 'application/vnd.ms-excel.sheet.binary.macroenabled.12' || ' application/vnd.ms-excel.sheet.macroenabled.12' || 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          asset_path 'icons/icon-xls.png'
        when 'application/vnd.openxmlformats-officedocument.presentationml.presentation' || 'application/vnd.ms-powerpoint' || 'application/vnd.ms-powerpoint.presentation.macroenabled.12'
          asset_path 'icons/icon-ppt.png'
        when 'application/x-rar-compressed'
          asset_path 'icons/icon-rar.png'
        when 'text/plain'
          asset_path 'icons/icon-txt.png'
        when 'video/mp4' || 'application/mp4' || 'audio/mp4'
          asset_path 'icons/icon-mp4.png'
        when 'folder'
          asset_path 'icons/icon-empty.png'
        else
          asset_path 'icons/icon-unknown.png'
        end
      end
    end

    def get_simplified_type
      'image'
    end
  end
end
