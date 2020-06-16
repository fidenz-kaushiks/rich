module Rich
  class FilesController < ApplicationController
    include ApplicationHelper

    before_action :authenticate_rich_user
    before_action :set_rich_file, only: [:show, :update, :destroy]

    layout "rich/application"

    @@parent_folder = 0

    def index
      parent_id = (params[:parent_id].nil?) ? 1 : params[:parent_id].to_i
      folder = StorageFolder.find_by(id: 1)
      @items = folder ? folder.files.all : []
      @type = params[:type]
      @search = params[:search].present?
      file_type = []
      alpha = ''
      @rich_asset = RichFile.new
      @@parent_folder = parent_id
      # @rich_asset = folder.files.new
      current_page = params[:page].to_i
      respond_to do |format|
        format.html
        format.js
      end
    end
    
    def show
      # show is used to retrieve single files through XHR requests after a file has been uploaded
      if(params[:id])
        # list all files
        @file = @rich_file
        render :layout => false
      else
        render :text => "File not found"
      end
    end

    def create
      # validate folder level at folder creation
      byebug
      if params[:current_level].to_i > Rich.options[:folder_level] && params[:simplified_type] == 'folder'
        return
      end

      parent_id = params[:parent_id]

      folder = StorageFolder.first
      byebug
      file_params = params[:file] || params[:qqfile]
      byebug
      @file = folder.files.attach(file_params)

      # if(params[:scoped] == 'true')
      #   @file.owner_type = params[:scope_type]
      #   @file.owner_id = params[:scope_id].to_i
      # end
      # use the file from Rack Raw Upload
      # file_params = params[:file] || params[:qqfile]
      # if(file_params)
      #   file_params.content_type = Mime::Type.lookup_by_extension(file_params.original_filename.split('.').last.to_sym)
      #   @file.rich_file = file_params
      # else
      #   # folder creation
      #   _resource = decode_base64_image("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVQYV2P4DwABAQEAWk1v8QAAAABJRU5ErkJggg==")
      #   folder_params = Rack::Multipart::UploadedFile.new(_resource[:tempfile].path)
      #   @file.rich_file = folder_params
      #   @file.rich_file_file_name = params[:file_name]
      #   @file.rich_file_content_type = params[:simplified_type]
      # end

      # save its' parent id
      # @file.parent_id = parent_id
      if @file.save
        response = {  :success => true,
                      :rich_id => @file.id,
                      :parent_id => parent_id }
      else
        response = { :success => false,
                     :error => "Could not upload your file:\n- "+@file.errors.to_a[-1].to_s,
                     :params => params.inspect }
      end
      render :json => response, :content_type => "text/html"

    end

    def update
      new_filename_without_extension = params[:filename].parameterize
      if new_filename_without_extension.present?
        new_filename = @rich_file.rename!(new_filename_without_extension)
        render :json => { :success => true, :filename => new_filename, :uris => @rich_file.uri_cache }
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
      @rich_file = RichFile.find(params[:id])
    end
  end
end
