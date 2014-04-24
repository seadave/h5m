classdef AttributeManager < handle
    %h5m.AttributeManager
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = protected)
        id
    end
    
    methods
        
        function self = AttributeManager(id)
            self.id = id;
        end
        
        function flag = has(self, name)
            % NOTE: this implemenation iterates over all attributes because H5A.exists does not seem
            % to be exposed by Matlab!
            flag = false;
            function status = check_for_attr_func(loc_id, attr_name)
                if strcmp(name, attr_name)
                    flag = true;
                    status = 1;
                else
                    status = 0;
                end
            end
            H5A.iterate(self.id, 0, @check_for_attr_func);
        end
        
        function data = get(self, name)
            % open the attribute
            attr_id = H5A.open(self.id, name);
            
            % read the data
            data = H5A.read(attr_id);
            
            % perform type dependent coercions
            attr_type_id = H5A.get_type(attr_id);
            attr_space_id = H5A.get_space(attr_id);
            if H5T.detect_class(attr_type_id,'H5T_STRING')
                if H5S.get_simple_extent_ndims(attr_space_id)==0
                    data = data{1};
                end
            end
            H5T.close(attr_type_id);
            H5S.close(attr_space_id);
            
            % close the attribute
            H5A.close(attr_id);
        end
        
        function self = set(self, name)
            % TODO
            error('NotYetImplemented');
        end
        
        function k = keys(self)
            k = {};
            function status = get_attr_names_func(loc_id, attr_name)
                k{end+1} = attr_name;
                status = 0;
            end
            H5A.iterate(self.id, 0, @get_attr_names_func);
        end
        
        function v = values(self)
            v = cellfun(@(k)self.get(k), self.keys(), 'UniformOutput', false);
        end
        
        function self = create(self, name, data)
            
            % make sure it doesn't already exist
            % NOTE: a try/catch is used since the has() method above scans through all attributes
            exists = true;
            try
                H5A.open(self.id, name, 'H5P_DEFAULT');
            catch me
                if ~strcmp(me.identifier,'MATLAB:imagesci:hdf5lib:libraryError')
                    rethrow(me);
                end                
                exists = false;
            end
            assert(~exists,'Attribute %s already exists. Use modify() or delete().', name);

            % construct datatype by inspecting value of data
            switch class(data)
                case 'logical'
                    type_id = H5T.copy('H5T_NATIVE_UINT');  % map logical -> uint32
                    data = uint32(data);
                case 'double'
                    type_id = H5T.copy('H5T_NATIVE_DOUBLE');
                case 'single'
                    type_id = H5T.copy('H5T_NATIVE_FLOAT');
                case 'int64'
                    type_id = H5T.copy('H5T_NATIVE_LLONG');
                case 'uint64'
                    type_id = H5T.copy('H5T_NATIVE_ULLONG');
                case 'int32'
                    type_id = H5T.copy('H5T_NATIVE_INT');
                case 'uint32'
                    type_id = H5T.copy('H5T_NATIVE_UINT');
                case 'int16'
                    type_id = H5T.copy('H5T_NATIVE_SHORT');
                case 'uint16'
                    type_id = H5T.copy('H5T_NATIVE_USHORT');
                case 'int8'
                    type_id = H5T.copy('H5T_NATIVE_SCHAR');
                case 'uint8'
                    type_id = H5T.copy('H5T_NATIVE_UCHAR');
                case 'char'
                    type_id = H5T.copy('H5T_C_S1');
                    if ~isempty(data)
                        % Don't do this when working with empty strings.
                        H5T.set_size(type_id, numel(data));
                    end
                    H5T.set_strpad(type_id, 'H5T_STR_NULLTERM');
                otherwise
                    error('Invalid type for attribute: %s', class(data));
            end

            % construct dataspace by inspecting value of data
            if isempty(data)
                space_id = H5S.create('H5S_NULL');
            elseif ischar(data)
                if isrow(data)
                    space_id = H5S.create('H5S_SCALAR');
                else
                    error('Invalid shape for char value for attribute:');
                end
            else
                if isscalar(data)
                    space_id = H5S.create('H5S_SCALAR');
                elseif isvector(data)
                    dims = numel(data);
                    space_id = H5S.create_simple(1,dims,dims);
                else
                    dims = fliplr(size(data));
                    space_id = H5S.create_simple(ndims(data),dims,dims);
                end
                
            end
            
            acpl = H5P.create('H5P_ATTRIBUTE_CREATE');
            attr_id = H5A.create(self.id, name, type_id, space_id, acpl);
            H5A.write(attr_id, 'H5ML_DEFAULT', data);
            
        end
        
        function sref = subsref(self,s)
            % obj(i) is equivalent to obj.Data(i)
            switch s(1).type
                % Use the built-in subsref for dot notation
                case '.'
                    sref = builtin('subsref',self,s);
                case '()'
                    if length(s)<2
                        assert(numel(s.subs)==1, 'h5m.AttributeManager.subsref', 'Attribute access requires exactly one name');
                        sref = get(self, s.subs{1});
                        return
                    else
                        sref = builtin('subsref',self,s);
                    end
                    % No support for indexing using '{}'
                case '{}'
                    error('h5m.AttributeManager.subsref',...
                        'Not a supported subscripted reference')
            end
        end
        
    end
    
end

