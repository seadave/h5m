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
        parent %FIXME
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
        
    end
    
end

