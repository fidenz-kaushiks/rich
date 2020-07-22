module Rich
  class FilesController < ApplicationController
    include ApplicationHelper
    include FilesHelper

    before_action :authenticate_rich_user
    before_action :set_rich_file, only: [:show, :update, :destroy]

    layout "rich/application"

    PARENT_FOLDER_ID = 1

    def index
      @parent_id = params[:parent_id].nil? ? PARENT_FOLDER_ID : params[:parent_id].to_i
      folder     = StorageFolder.find_by(id: @parent_id)
      @items     = []
      type       = params[:type]

      per_page     = Rich.options[:paginates_per]
      current_page = (params[:page] || 1).to_i

      if folder
        files   = folder.files.all.order(:created_at)
        folders = folder.children.order(:created_at)

        case type
        when 'image'
          files = files.select {|file| file.image? }
        when 'file'
          files = files.reject {|file| file.image? }
        else
          #default
        end

        if params[:alpha] == 'true'
          files   = files.sort_by {|file| file.blob.filename.downcase}
          folders = folders.sort_by {|folder| folder.folder_name.downcase}
        end

        unless params[:search].blank?
          all_folders = StorageFolder.all

          search_name = params[:search].downcase

          files   = all_folders.map(&:files).flatten.select { |file| file.blob.filename.to_s.downcase.include?(search_name) }
          folders = all_folders.select { |folder| folder.folder_name.downcase.include?(search_name) }
        end

        start_point = (current_page - 1) * per_page
        end_point   = (current_page) * per_page

        @items = ([folders] + [files]).flatten
        @items = @items[start_point, end_point]

        unless @items.nil?
          @items = @items.partition { |item| item.class.name == "Rich::StorageFolder" }
          @items = [@items[0]] + [@items[1]]
        else
          @items = [[],[]]
        end
      end

      @rich_asset = RichFile.new

      current_page = params[:page].to_i
      respond_to do |format|
        format.html
        format.js
      end
    end

    def show
      # show is used to retrieve single files through XHR requests after a file has been uploaded
      # @parent_id = params[:parent_id].nil? ? PARENT_FOLDER_ID : params[:parent_id].to_i
      if params[:id]
        @file = @rich_file
        render layout: false
      else
        render text: "File not found"
      end
    end

    def create
      # validate folder level at folder creation
      if (params[:current_level].to_i + 1) > (Rich.options[:folder_level]) && params[:simplified_type] == 'folder'
        return
      end
      is_file   = false
      is_folder = false
      parent_id = params[:parent_id].nil? ? PARENT_FOLDER_ID : params[:parent_id].to_i

      begin
        if params[:simplified_type] == 'folder'
          item      = StorageFolder.create(folder_name: 'new-folder', parent_id: parent_id)
          is_folder = true
        else
          folder = StorageFolder.find_by(id: parent_id)
          file_params = params[:file] || params[:qqfile]
          is_file = folder.attach(file_params)
          item    = folder.files.reload.order(:id).last
        end

        if is_file || is_folder
          response = {  success: true,
                        rich_id: item.id,
                        parent_id: parent_id,
                        file_path: thumb_for_file(item),
                        is_file: is_file }
        else
          response = {  success: false,
                        error: "Could not upload your file:\n- "+ file.errors.to_a[-1].to_s,
                        params: params.inspect }
        end
      rescue => ex
        response = {  success: false,
                      error: "Could not upload your file:\n- " + ex.message.to_s,
                      params: params.inspect }
        puts ex.message.to_s
      end

      render json: response, content_type: "text/html"
    end

    def update
      new_filename_without_extension = params[:filename].parameterize
      if new_filename_without_extension.present?
        if is_file?
          filename = "#{new_filename_without_extension}.#{@rich_file.blob.filename.to_s.split('.')[1]}"
          udpate   = @rich_file.blob.update(filename: filename)
        else
          filename = new_filename_without_extension
          udpate   = @folder.update(folder_name: filename)
        end

        render :json => { :success => true, :filename => filename, :uris => @rich_file.try(:id) || @folder.try(:id) }
      else
        render :nothing => true, :status => 500
      end
    end

    def destroy
      if(params[:id])
        item = @rich_file || @folder
        begin
          @is_file_item = item.class.name != "Rich::StorageFolder"
          item.destroy
          @item_id = params[:id]
        rescue Exception => e
          @error = 'sorry cannot delete'
        end
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

    def parent_list
      folder_array = get_parent(params[:parent_id].to_i, [1]).sort
      render :json => { :success => true, :folder_array => folder_array }
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_rich_file
      if is_file?
        folder     = StorageFolder.find_by(id: params[:parent_id])
        @rich_file = folder.files.find_by(id: params[:id])
      else
        @folder = StorageFolder.find_by(id: params[:id])
      end
    end

    def is_file?
      params[:type] == 'file'
    end

    def get_parent(id, array)
      if id == 1
        return array
      else
        folder = StorageFolder.find_by(id: id)
        array.insert(0, folder.parent.id)
        get_parent(folder.parent.id, array)
      end
    end
  end
end
