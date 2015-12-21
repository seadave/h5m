classdef Group < h5m.H5Object
    %h5m.Group 
    %   Detailed explanation goes here
    

    methods
        
        function self = Group(id)            
            % FIXME - check that id represents a group!            
            self@h5m.H5Object(id);        
        end
        
        function keys = keys(self)
            keys = {};
            function keys_getter(~,name)
                keys{end+1} = name;
            end
            self.iterate(@keys_getter);
        end
        
        function obj = get(self, name)
           obj_id = H5O.open(self.id, name, 'H5P_DEFAULT');
           obj_info = H5O.get_info(obj_id);
           switch(obj_info.type)
               % TODO: can we use h5m.Object.wrap_identifier instead?
               case H5ML.get_constant_value('H5G_LINK')
                   error('h5m.Group.get(): Links not yet supported');
               case H5ML.get_constant_value('H5G_GROUP')
                   obj = h5m.Group(H5G.open(self.id,name));
               case H5ML.get_constant_value('H5G_DATASET')
                   obj = h5m.Dataset(H5D.open(self.id,name));
               case H5ML.get_constant_value('H5G_TYPE')
                   error('h5m.Group.get(): Named types not yet supported');
           end
           H5O.close(obj_id);                        
        end
        
        function obj = create_group(self, name_or_path)            
            gcpl = H5P.create('H5P_LINK_CREATE');
            H5P.set_create_intermediate_group(gcpl, 1);
            grp_id = H5G.create(self.id, name_or_path, gcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
            obj = h5m.Group(grp_id);
        end
        
        function obj = require_group(self, name_or_path)
            try
                obj_id = H5O.open(self.id, name_or_path, 'H5P_DEFAULT');
                obj_info = H5O.get_info(obj_id);
                assert(obj_info.type == H5ML.get_constant_value('H5G_GROUP'), ...
                       'h5m.Group.require_group(): Object of non-group type already exists: %s', name_or_path);
                obj = h5m.Group(obj_id);
            catch me
                % FIXME: need to check for certain library errors and re-throw rather than blindly marching on
                obj = self.create_group(name_or_path);
            end
        end
        
        function obj = create_dataset(self, name, data_size, data_type, flip_dims, compression, chunks, max_size, fletcher32, fill_value)
            if ~exist('data_type','var')
                data_type = 'single';
            end
            if ~exist('flip_dims','var')
                flip_dims = true;
            end            
            if ~exist('compression','var')
                compression = false;
            end
            if ~exist('chunks','var')
                chunks = false;
            end
            if ~exist('max_size','var')
                max_size = data_size;
            end
            if ~exist('fletcher32','var')
                fletcher32 = false;
            end
            if ~exist('fill_value','var')
                fill_value = [];
            end
            
            if flip_dims
                flip_fcn = @fliplr;
            else
                flip_fcn = @(d)d;
            end
            
            default_compression_opts = struct('level',9, 'shuffle',true);
            if islogical(compression)
                if compression
                    compression_opts = default_compression_opts;
                else
                    compression_opts = struct('level',0, 'shuffle',false);
                end
            elseif isnumeric(compression)
                compression_opts = default_compression_opts;
                compression_opts.level = compression;
            else
                compression_opts = merge_structs(compression, default_compression_opts);
            end
            
            % force chunks if compression is requested
            if compression_opts.level>0 && ((islogical(chunks) && ~chunks) || isempty(chunks))
                chunks = true;
            end            
            
            if islogical(chunks)
                if chunks
                    error('AUTO CHUNK SIZING NOT YET IMPLEMENTED');
                else
                    chunk_size = [];
                end
            elseif isvector(chunks)
                chunk_size = chunks;
            else
                chunk_size = [];
            end
            
            % create dataspace 
            space_id = H5S.create_simple(numel(data_size), flip_fcn(data_size), flip_fcn(max_size));
        
            % map Matlab types to H5 types
            h5_type = h5m.H5Object.map_matlab_to_h5_type(data_type);
            
            if isstruct(h5_type)
                %% need to create H5T object representing compound type rather than leave as a string
                h5_field_names = fieldnames(h5_type);
                h5_type_ids = structfun(@(str)H5T.copy(str), h5_type, 'UniformOutput', false);
                h5_type_sz = structfun(@(type_id)H5T.get_size(type_id), h5_type_ids);
                h5_field_offsets = cumsum([0;h5_type_sz(1:end-1)]);
                h5_type = H5T.create('H5T_COMPOUND', sum(h5_type_sz));
                for fi = 1:numel(h5_field_names)
                    H5T.insert(h5_type, h5_field_names{fi}, h5_field_offsets(fi), h5_type_ids.(h5_field_names{fi}));
                end               
            end
            
            lcpl = H5P.create('H5P_LINK_CREATE');
            dcpl = H5P.create('H5P_DATASET_CREATE');
            if ~isempty(chunk_size)
                assert(numel(chunk_size) == numel(data_size));
                chunk_size_clipped = min(data_size, chunk_size);
                H5P.set_chunk(dcpl, flip_fcn(chunk_size_clipped));
            end
            if compression_opts.level>0
                H5P.set_deflate(dcpl, compression_opts.level);
            end
            if compression_opts.shuffle
                H5P.set_shuffle(dcpl);
            end
            if fletcher32
                H5P.set_fletcher32(dcpl);
            end
            if ~isempty(fill_value)
                assert(class(fill_value)==data_type,'h5m.Group.create_dataset(): Mismatch between data_type and type of fill_value: %s', class(fill_value));
                H5P.set_fill_value(dcpl, h5_type, fill_value);
            end
            dapl = 'H5P_DEFAULT';
            
            dset_id = H5D.create(self.id, name, h5_type, space_id, lcpl, dcpl, dapl);
            H5P.close(lcpl);
            H5P.close(dcpl);
            H5S.close(space_id);
            % FIXME - should setup function to close these on any type of failure
            
            obj = h5m.Dataset(dset_id);
            obj.attrs.create('__h5m_flip_dims__', flip_dims);
            
        end
        
        function delete(self, name)
            H5L.delete(self.id, name, 'H5P_DEFAULT');
        end
        
        function flag = has(self, name)
            flag = false;
            function iter_flag = match_name(other_name, ~)
                if strcmp(name, other_name)
                    iter_flag = false;
                    flag = true;
                else
                    iter_flag = true;
                end
            end
            self.visititems(@match_name);
        end                
        
        % fcn - function(name, object), if a return value is provided and evaluates to false no more items are visited
        function self = visititems(self, fcn)
            function [status, opdata_out] = fcn_adapter(rel_id, name, opdata_in)
                status = 0;
                opdata_out = [];                
                if strcmp(name,'.')
                    % don't visit the item itself
                    return;
                end                
                obj_id = H5O.open(rel_id, name, 'H5P_DEFAULT');
                obj = h5m.H5Object.wrap_identifier(obj_id);                
                if nargout(fcn)>0 && ~fcn(name, obj)
                    status = 1;
                else
                    fcn(name, obj);
                end                
                H5O.close(obj_id);
            end
            H5O.visit(self.id, 'H5_INDEX_CRT_ORDER', 'H5_ITER_NATIVE', @fcn_adapter, []);
        end
        
        % fcn - function(group, name), if a return value is provided and evaluates to false no more items are visited        
        function self = iterate(self, fcn)
            function [status, opdata_out] = fcn_adapter(rel_id, name, opdata_in)
                status = 0;
                opdata_out = [];
                rel_id_obj = h5m.H5Object.wrap_identifier(rel_id);
                if nargout(fcn)>0 && ~fcn(rel_id_obj, name)
                    status = 1;
                else
                    fcn(rel_id_obj, name);
                end
            end
            H5L.visit(self.id, 'H5_INDEX_CRT_ORDER', 'H5_ITER_NATIVE', @fcn_adapter, []);            
        end
        
        function disp(self, skip_obj_header)
            if ~exist('skip_obj_header', 'var') || ~skip_obj_header
                disp('h5m.Group object:');
            end
            disp('Accessible objects:');
            function disp_child(name, object)
                obj_info = H5O.get_info(object.id);
                switch(obj_info.type)
                    % TODO: can we use h5m.Object.wrap_identifier instead?
                    case H5ML.get_constant_value('H5G_LINK')
                        obj_type = 'Link';
                    case H5ML.get_constant_value('H5G_GROUP')
                        obj_type = 'Group';
                    case H5ML.get_constant_value('H5G_DATASET')
                        obj_type = 'Dataset';
                    case H5ML.get_constant_value('H5G_TYPE')
                        obj_type = 'Type';
                    otherwise
                        obj_type = '<unknown>';
                end
                fprintf('   % -7s: %s\n', obj_type, name);
            end
            self.visititems(@disp_child);
%            FIXME!
%            function disp_links
%            self.iterate
        end
        
    end
    
end

