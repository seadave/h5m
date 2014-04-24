classdef Group < h5m.H5Object
    %h5m.Group 
    %   Detailed explanation goes here
    
    properties
    end
    

    methods
        
        function self = Group(id)            
            % FIXME - check that id represents a group!            
            self@h5m.H5Object(id);        
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
            
            if islogical(chunks) && chunks
                error('AUTO CHUNK SIZING NOT YET IMPLEMENTED');
            elseif isvector(chunks)
                chunk_size = chunks;
            end
            
            % create dataspace 
            space_id = H5S.create_simple(numel(data_size), flip_fcn(data_size), flip_fcn(max_size));
        
            % map Matlab types to H5 types
            switch data_type
                case 'double'
                    h5_type_str = 'H5T_NATIVE_DOUBLE';
                case 'single'
                    h5_type_str = 'H5T_NATIVE_FLOAT';
                case 'uint64'
                    h5_type_str = 'H5T_NATIVE_UINT64';
                case 'int64'
                    h5_type_str = 'H5T_NATIVE_INT64';
                case 'uint32'
                    h5_type_str = 'H5T_NATIVE_UINT';
                case 'int32'
                    h5_type_str = 'H5T_NATIVE_INT';
                case 'uint16'
                    h5_type_str = 'H5T_NATIVE_USHORT';
                case 'int16'
                    h5_type_str = 'H5T_NATIVE_SHORT';
                case 'uint8'
                    h5_type_str = 'H5T_NATIVE_UCHAR';
                case 'int8'
                    h5_type_str = 'H5T_NATIVE_CHAR';
                otherwise
                    error('h5m.Group.create_dataset(): Invalid data_type = %s', data_type)
            end                   
            
            lcpl = H5P.create('H5P_LINK_CREATE');
            dcpl = H5P.create('H5P_DATASET_CREATE');
            if ~isempty(chunk_size)
                H5P.set_chunk(dcpl, flip_fcn(chunk_size));
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
                H5P.set_fill_value(dcpl, h5_type_str, fill_value);
            end
            dapl = 'H5P_DEFAULT';
            
            dset_id = H5D.create(self.id, name, h5_type_str, space_id, lcpl, dcpl, dapl);
            H5P.close(lcpl);
            H5P.close(dcpl);
            H5S.close(space_id);
            % FIXME - should setup function to close these on any type of failure
            
            obj = h5m.Dataset(dset_id);
            obj.attrs.create('__h5m_flip_dims__', flip_dims);
            
        end
        
        
        
        % fcn - function(name, object), if a return value if provide and evaluates to false no more items are visited
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
                    fcn(name, obj)
                end                
                H5O.close(obj_id);
            end
            H5O.visit(self.id, 'H5_INDEX_CRT_ORDER', 'H5_ITER_NATIVE', @fcn_adapter, []);
        end        

    end
    
end

