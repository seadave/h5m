classdef Dataset < h5m.H5Object
    %h5m.Dataset 
    %   Detailed explanation goes here
    
    properties (Constant)
        FLIP_DIMS_ATTR_NAME = '__h5m_flip_dims__'
    end
    
    properties
    end
    
    methods
        
        function self = Dataset(id)
            
            % FIXME - check that id represents a dataset!            
            self@h5m.H5Object(id);
        end
        
        function data = read(self)
            data = H5D.read(self.id);
            did_flip_dims = self.attrs.has(h5m.Dataset.FLIP_DIMS_ATTR_NAME) && self.attrs.get(h5m.Dataset.FLIP_DIMS_ATTR_NAME);
            if ndims(data)==2 && ~did_flip_dims
                data = data';
            end
        end
        
        function self = write(self, data)
            did_flip_dims = self.attrs.has(h5m.Dataset.FLIP_DIMS_ATTR_NAME) && self.attrs.get(h5m.Dataset.FLIP_DIMS_ATTR_NAME);
            if ndims(data)==2 && ~did_flip_dims
                data = data';
            end
            H5D.write(self.id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);
        end
        
    end
    
end

