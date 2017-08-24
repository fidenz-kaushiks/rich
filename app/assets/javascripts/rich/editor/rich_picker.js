// Direct asset picker

var rich = rich || {};
rich.AssetPicker = function(){
	
};

rich.AssetPicker.prototype = {
	
	showFinder: function(dom_id, options){
		// open a popup
		var params = {};
		params.CKEditor = 'picker'; // this is not CKEditor
		params.default_style = options.default_style;
		params.allowed_styles = options.allowed_styles;
		params.insert_many = options.insert_many;
		params.type = options.type || "image";
		params.viewMode = options.view_mode || "grid";
		params.scoped = options.scoped || false;
		params.alpha = options.alpha || true;
		params.file_type = options.file_type || false;
		params.folder_id = options.folder_id || -1;
		params.folder_level = options.folder_level;
		params.custom_image_styles = options.custom_image_styles || [];
		console.log(options);
		if(params.scoped == true) {
			params.scope_type = options.scope_type
			params.scope_id = options.scope_id;
		}
		params.dom_id = dom_id;
		var url = addQueryString(options.richBrowserUrl, params );
		window.open(url, 'filebrowser', "resizable=yes,scrollbars=yes,width=860,height=500")
  },

	setAsset: function(dom_id, asset, id, type, name){
		var split_field_name = $(dom_id).attr('id').split('_')
		if (split_field_name[split_field_name.length - 1] == "id") {
			$(dom_id).val(id);
		} else {
			$(dom_id).val(asset);
		}

    if(type=='image') {
		  $(dom_id).siblings('img.rich-image-preview').first().attr({src: asset});
    }
    else{
		  $(dom_id).siblings('img.rich-image-preview').first().attr({src: "http://icons.iconarchive.com/icons/graphicloads/100-flat/256/home-icon.png"});
    }
    $(dom_id).siblings('p.rich-filename').text(name);
  },

};

// Rich Asset input
var assetPicker = new rich.AssetPicker();