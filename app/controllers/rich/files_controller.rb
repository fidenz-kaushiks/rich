module Rich
  class FilesController < ApplicationController
    include ApplicationHelper
    include FilesHelper

    before_action :authenticate_rich_user
    before_action :set_rich_file, only: [:show, :update, :destroy]

    layout "rich/application"

    PARENT_FOLDER_ID = 1

    def index
      parent_id = params[:parent_id].nil? ? PARENT_FOLDER_ID : params[:parent_id].to_i
      folder    = StorageFolder.find_by(id: parent_id)

      @items       = folder ? folder.files.all : []
      @rich_asset  = RichFile.new
      current_page = params[:page].to_i
      respond_to do |format|
        format.html
        format.js
      end
    end
    
    def show
      # show is used to retrieve single files through XHR requests after a file has been uploaded
      if params[:id]
        # list all files
        @file = @rich_file
        render :layout => false
      else
        render :text => "File not found"
      end
    end

    def create
      # validate folder level at folder creation
      if params[:current_level].to_i > Rich.options[:folder_level] && params[:simplified_type] == 'folder'
        return
      end

      if params[:simplified_type] == 'folder'
        StorageFolder.create(folder_name: 'new-folder', parent_id: PARENT_FOLDER_ID)
      else
        folder = StorageFolder.first
        file_params = params[:file] || params[:qqfile]
        file = folder.files.attach(file_params)
      end

      @file = folder.files.reload.last
      if file
        response = {  :success => true,
                      :rich_id => @file.id,
                      :parent_id => folder.id,
                      :file_path => thumb_for_file(@file)
                    }
      else
        response = { :success => false,
                     :error => "Could not upload your file:\n- "+file.errors.to_a[-1].to_s,
                     :params => params.inspect }
      end
      render :json => response, :content_type => "text/html"

    end



    def update
    # self.active_storage_object.blob.update(filename: "desired_filename.#{self.active_storage_object.filename.extension}")

      new_filename_without_extension = params[:filename].parameterize
      if new_filename_without_extension.present?
        filename = "#{new_filename_without_extension}.#{@rich_file.blob.filename.extension}"
        udpate   = @rich_file.blob.update(filename: filename)
        render :json => { :success => true, :filename => filename, :uris => @rich_file.id }
      else
        render :nothing => true, :status => 500
      end
    end

    def destroy
      if(params[:id])
        begin
          @rich_file.destroy
          @fileid = params[:id]
        rescue Exception => e
          @error = 'sorry cannot delete'
        end
        # if @rich_file.destroy!
        #   @fileid = params[:id]
        # else
        #   response = {  :success => false,
        #                 :error => 'cannot delete' }
        # end
      end
    end

    def decode_base64_image(obj_hash)
      file = nil
      if obj_hash.try(:match, %r{^data:(.*?);(.*?),(.*)$})
        image_data = split_base64(obj_hash)
        image_data_string = image_data[:data]
        image_data_binary = Base64.decode64(image_data_string)

        temp_img_file = Tempfile.new("")
        temp_img_file.binmode
        temp_img_file << image_data_binary
        temp_img_file.rewind

        img_params = {:filename => "image.#{image_data[:extension]}", :type => image_data[:type], :tempfile => temp_img_file}
        file = img_params
      end
      return file
    end

    def split_base64(uri_str)
      if uri_str.match(%r{^data:(.*?);(.*?),(.*)$})
        uri = Hash.new
        uri[:type] = $1 # "image/gif"
        uri[:encoder] = $2 # "base64"
        uri[:data] = $3 # data string
        uri[:extension] = $1.split('/')[1] # "gif"
        return uri
      else
        return nil
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_rich_file
      folder = StorageFolder.first
      @rich_file = folder.files.find_by(id: params[:id])
    end
  end
end
