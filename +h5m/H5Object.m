classdef H5Object < handle
    %h5m.H5Object 
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = protected)
        id
        attrs = []
    end

    properties (Dependent = true)
        file
        name
    end
    
    properties
        parent
        ref %FIXME
        regionref %FIXME
    end
    
    methods
        
        function self = H5Object(id)
            self.id = id;
        end
        
        function str = get_h5_obj_type(self)
            %FIXME
        end
    
        function attrs = get.attrs(self)
            if isempty(self.attrs)
                self.attrs = h5m.AttributeManager(self.id);
            end
            attrs = self.attrs;
        end
        
        function file = get.file(self)
            file = h5m.File(H5I.get_file_id(self.id));
        end
            
        function str = get.name(self)
            str = H5I.get_name(self.id);
        end
        
        function par = get.parent(self)
            par = self.file.get(fileparts(self.name));           
        end
        
    end
    
    methods (Static)
        
        function obj = wrap_identifier(id)
            % inspect and wrap a low-level id with the appropriate subclass of H5Object
            info = H5O.get_info(id);
            switch info.type
                case H5ML.get_constant_value('H5O_TYPE_GROUP')
                    obj = h5m.Group(id);
                case H5ML.get_constant_value('H5O_TYPE_DATASET')
                    obj = h5m.Dataset(id);
                otherwise
                    obj = h5m.H5Object(id);
            end            
        end
        
        function h5_type = map_matlab_to_h5_type(matlab_type)
            if ischar(matlab_type)
                switch matlab_type
                    case 'double'
                        h5_type = 'H5T_NATIVE_DOUBLE';
                    case 'single'
                        h5_type = 'H5T_NATIVE_FLOAT';
                    case 'uint64'
                        h5_type = 'H5T_NATIVE_UINT64';
                    case 'int64'
                        h5_type = 'H5T_NATIVE_INT64';
                    case 'uint32'
                        h5_type = 'H5T_NATIVE_UINT';
                    case 'int32'
                        h5_type = 'H5T_NATIVE_INT';
                    case 'uint16'
                        h5_type = 'H5T_NATIVE_USHORT';
                    case 'int16'
                        h5_type = 'H5T_NATIVE_SHORT';
                    case 'uint8'
                        h5_type = 'H5T_NATIVE_UCHAR';
                    case 'int8'
                        h5_type = 'H5T_NATIVE_CHAR';
                    otherwise
                        error('h5m.H5Object.map_matlab_to_h5_type(): Invalid matlab_type = %s', matlab_type)
                end
            elseif isstruct(matlab_type)
                h5_type = structfun(@h5m.H5Object.map_matlab_to_h5_type, matlab_type, 'UniformOutput', false);
            else                
                error('h5m.H5Object.map_matlab_to_h5_type(): Invalid matlab_type = %s', matlab_type)
            end
        end
        
    end
    
end

