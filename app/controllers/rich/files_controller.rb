module Rich
  class FilesController < ApplicationController
    before_filter :authenticate_rich_user
    before_filter :set_rich_file, only: [:show]

    layout 'rich/application'

    def index
      @search = params[:search].present?
      parent_id = params[:folder_id].nil? ? -1 : params[:folder_id].to_i

      @folders = Folder.folders(parent_id)
      @items =  case params[:type]
                when 'image'
                  RichFile.images(parent_id)
                when 'video'
                  RichFile.videos(parent_id)
                when 'file'
                  RichFile.files(parent_id)
                when 'audio'
                  RichFile.audios(parent_id)
                else
                  RichFile.any(parent_id)
                end
      file_type = params[:file_type] || 'false'
      file_type = file_type != 'false' ? file_type.split(",") : []

      @items = @items.where('rich_file_content_type in (?)', file_type) unless file_type.blank?

      if params[:scoped] == 'true'
        @items = @items.where('owner_type = ? AND owner_id = ?', params[:scope_type], params[:scope_id])
      end

      if @search
        search_type = params[:searchtype] == 'filename' ? 'rich_file_file_name' : 'titles'
        @items = @items.where("LOWER(#{search_type}) LIKE LOWER(?)", "%#{params[:search]}%")
      end

      alpha = params[:alpha] || 'true'

      if alpha == 'true' && !@search
        @items.order!(simplified_type: :asc, rich_file_file_name: :asc)
        @folders.order!(folder_name: :asc)
      elsif !@search
        @items.order!(created_at: :desc)
        @folders.order!(created_at: :desc)
      end

      current_page = params[:page].to_i
      per_page = Rich.options[:paginates_per]

      start_point = current_page * per_page
      end_point = (current_page + 1) * per_page
      all = (@folders.to_a + @items.to_a)[start_point, end_point] || []
      _partition = all.partition { |e| e.is_a? Folder }

      @folders = _partition[0]
      @items = _partition[1]
      @custom_styles = RichFile.custom_styles_list

      @rich_asset = RichFile.new

      respond_to do |format|
        format.html
        format.js
      end
    end

    def show
      # show is used to retrieve single files through XHR requests after a file has been uploaded
      if(params[:id])
        @file = @rich_file
        render layout: false
      else
        render text: "File not found"
      end
    end

    def create
      simplified_type = params[:simplified_type]

      @file = simplified_type == 'folder' ? Folder.new : RichFile.new(simplified_type: simplified_type)

      if params[:scoped] == 'true' && simplified_type != 'folder'
        @file.owner_type = params[:scope_type]
        @file.owner_id = params[:scope_id].to_i
      end

      folder_id = params[:folder_id].to_i || -1
      file_params = params[:file] || params[:qqfile]
      custom_image_styles = params[:custom_image_styles]

      if file_params
        file_params.content_type = Mime::Type.lookup_by_extension(file_params.original_filename.split('.').last.to_sym)
        @file.custom_image_styles = custom_image_styles == 'undefined' ? [] : custom_image_styles.split(',').map(&:to_sym) << :rich_thumb
        @file.file_size = params[:file_size]
        @file.folder_id = folder_id
        @file.rich_file = file_params
      else
        @file.folder_name = params[:file_name]
        @file.parent_id = folder_id
      end

      if @file.save
        response = {  success: true,
                      rich_id: @file.id }
      else
        response = { success: false,
                     error: "Could not upload your file:\n- "+@file.errors.to_a[-1].to_s,
                     params: params.inspect }
      end
      render json: response, content_type: "text/html"
    end

    def update
      _id = params[:drag_id] || params[:id]
      file = params[:type] == 'folder' ? Folder.find(_id) : RichFile.find(_id)

      response = Hash.new
      case params[:method]
      when 'drag'
        if file.is_a? Folder
          file.parent_id = params[:id]
        else
          file.folder_id = params[:id]
        end
        file.save!
        response = {  success: true,
                      item: file.id }
      when 'title'
        file.titles = params[:title]
        file.save!
        response = {  success: true, 
                      title: file.titles }
      when 'move'
        parent_folder = params[:move_to_parent] == '-1' ? -1 : Folder.find(params[:move_to_parent]).parent_id
        if file.is_a? Folder
          file.parent_id = parent_folder
        else
          file.folder_id = parent_folder
        end
        file.save!
        response = {  success: true,
                      item: file.id }
      else
        new_filename_without_extension = params[:filename].downcase.parameterize
        if new_filename_without_extension.present?
          unless file.is_a? Folder
            file.custom_image_styles = eval(file.uri_cache).keys
            new_filename = file.rename!(new_filename_without_extension)
            response = {  success: true,
                          filename: new_filename,
                          uris: file.uri_cache }
          else
            file.folder_name = new_filename_without_extension
            file.save!
            response = {  success: true,
                          filename: new_filename_without_extension }
          end
        else
          render nothing: true, status: 500
          return
        end
      end

      render json: response
    end

    def destroy
      id = params[:id]
      if id
        if params[:type] == 'folder'
          @file = Folder.find id
        else
          @file = RichFile.find id
          @file.custom_image_styles = eval(@file.uri_cache).keys
        end
        begin
          @file.destroy
        rescue Exception => e
          @error = 'sorry cannot delete'
        end
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_rich_file
      @rich_file = RichFile.find(params[:id])
    end
  end
end
