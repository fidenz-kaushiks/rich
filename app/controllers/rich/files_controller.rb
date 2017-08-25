module Rich
  class FilesController < ApplicationController

    before_filter :authenticate_rich_user
    before_filter :set_rich_file, only: [:show]

    layout "rich/application"

    def index
      # byebug
      @type = params[:type]
      @search = params[:search].present?
      # -- v
      # -- file_type is files format filter
      # -- vaidate for rich 'picker' but not 'editor' at JS params
      file_type = params[:file_type] || 'false';
      alpha = params[:alpha] || 'true';
      # --^
      # parent id change
      parent_id = (params[:folder_id].nil?) ? -1 : params[:folder_id].to_i

      # to show specific file types, if have push 'folder' type to array
      file_type = (file_type != 'false') ? file_type.split(",") : []
      # items per page from config
      per_page = Rich.options[:paginates_per]
      current_page = params[:page].to_i

      @items = case @type
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

      if file_type.blank?
        @items.where("rich_file_content_type in (?)", file_type)
      end

      @folders = Folder.folders(parent_id)

      if params[:scoped] == 'true'
        @items = @items.where("owner_type = ? AND owner_id = ?", params[:scope_type], params[:scope_id])
      end

      if @search
        # previous
        # @items = @items.where('rich_file_file_name LIKE ?', "%#{params[:search]}%").where.not(simplified_type: 'folder')

        if params[:searchtype] == 'filename'
          @items = @items.where('rich_file_file_name LIKE ?', "%#{params[:search]}%")
        else
          @items = @items.where('titles LIKE ?', "%#{params[:search]}%")
        end

        # partial_query = "WITH RECURSIVE recu AS (
        #                   SELECT *
        #                     FROM rich_rich_files
        #                     WHERE parent_id = ?
        #                   UNION all
        #                   SELECT c.*
        #                     FROM recu p
        #                     JOIN rich_rich_files c ON c.parent_id = p.id AND p.id != p.parent_id
        #                 )"

        # unless @type == 'all'
        #   partial_query << " SELECT * FROM recu WHERE rich_file_file_name LIKE ? AND simplified_type = ? ORDER BY simplified_type ASC, rich_file_file_name ASC;"
        #   @items = RichFile.find_by_sql [ partial_query, parent_id.to_i, "%#{params[:search].gsub(' ','-')}%", @type]
        # else
        #   partial_query << " SELECT * FROM recu WHERE rich_file_file_name LIKE ? AND NOT simplified_type = 'folder' ORDER BY simplified_type ASC, rich_file_file_name ASC;"
        #   @items = RichFile.find_by_sql [ partial_query, parent_id.to_i, "%#{params[:search].gsub(' ','-')}%"]
        # end

        # manual paginate
        start_point = (current_page) * per_page
        end_point = (current_page + 1) * per_page
        @items = @items[start_point, per_page]
      end

      if alpha == 'true' && !@search
        @items = @items.order("simplified_type ASC").order("rich_file_file_name ASC")
        # @items = @items.order("rich_file_file_name ASC")
      elsif !@search
        @items = @items.order("created_at DESC")
      end

      # byepass search
      unless @search
        @items = @items.page params[:page]
      end

      # stub for new file
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
        render :layout => false
      else
        render :text => "File not found"
      end
    end

    def create
      # validate folder level at folder creation
      simplified_type = params[:simplified_type]

      if (params[:current_level].to_i > Rich.options[:folder_level]) && (simplified_type == 'folder')
        return
      end

      @file = (simplified_type == 'folder') ? Folder.new : RichFile.new(simplified_type: simplified_type)

      if(params[:scoped] == 'true' && simplified_type != 'folder')
        @file.owner_type = params[:scope_type]
        @file.owner_id = params[:scope_id].to_i
      end

      folder_id = params[:folder_id] || -1
      # use the file from Rack Raw Upload
      file_params = params[:file] || params[:qqfile]
      if(file_params)
        file_params.content_type = Mime::Type.lookup_by_extension(file_params.original_filename.split('.').last.to_sym)
        # custom image sizes
        @file.custom_image_styles = (params[:custom_image_styles].split(',').map { |e| e.to_sym } << :rich_thumb) || []
        # custom file size
        @file.file_size = params[:file_size]
        @file.folder_id = folder_id
        @file.rich_file = file_params
      else
        # folder creation
        @file.folder_name = params[:file_name]
        @file.parent_id = folder_id
      end

      if @file.save
        response = {  :success => true,
                      :rich_id => @file.id }
      else
        response = { :success => false,
                     :error => "Could not upload your file:\n- "+@file.errors.to_a[-1].to_s,
                     :params => params.inspect }
      end
      render :json => response, :content_type => "text/html"
    end

    def update
      # id = params[:drag_id] || params[:id]
      # type = params[:type]

      # if(type == 'folder')
      #   file = Folder.find(id)
      # else
      #   file = RichFile.find(id)
      # end

      # case params[:method]
      # when 'drag'
      #   byebug
      #   file.parent_id
      # end





      if params[:drag_id]
        if(params[:type] == 'folder')
          @file = Folder.find(params[:drag_id])
          @file.parent_id = params[:id]
        else
          @file = RichFile.find(params[:drag_id])
          @file.folder_id = params[:id]
        end
        @file.save!
        render :json => { :success => true, :rich_id => params[:drag_id] }

      elsif params[:title]
        @file = RichFile.find(params[:id])
        @file.titles = params[:title]
        @file.save!
        render :json => { :success => true, :title => @file.titles }

      elsif params[:move_to_parent]
        if(params[:type] == 'folder')
          @file = Folder.find(params[:id])
          @file.parent_id = (params[:move_to_parent] == '-1') ? -1 : Folder.find(params[:move_to_parent]).parent_id
        else
          @file = RichFile.find(params[:id])
          @file.folder_id = (params[:move_to_parent] == '-1') ? -1 : Folder.find(params[:move_to_parent]).parent_id
        end
        @file.save!
        render :json => { :success => true, :rich_id => params[:id] }
      else
        if(params[:type] == 'folder')
          @file = Folder.find(params[:id])
        else
          @file = RichFile.find(params[:id])
        end
        new_filename_without_extension = params[:filename].parameterize
        if new_filename_without_extension.present?
          if(params[:type] != 'folder')
            @file.custom_image_styles = eval(@file.uri_cache).keys
            new_filename = @file.rename!(new_filename_without_extension)
            render :json => { :success => true, :filename => new_filename, :uris => @file.uri_cache }
          else
            @file.folder_name = new_filename_without_extension
            @file.save!
            render :json => { :success => true, :filename => new_filename_without_extension }
          end
        else
          render :nothing => true, :status => 500
        end
      end
    end

    def destroy
      id = params[:id]
      if(id)
        if(params[:type] == 'folder')
          @file = Folder.find(id)
        else
          @file = RichFile.find(id)
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
