classdef Dataset < h5m.H5Object
    %h5m.Dataset 
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function self = Dataset(id)
            
            % FIXME - check that id represents a dataset!            
            self@h5m.H5Object(id);
        end
        
        function data = read(self)
            data = H5D.read(self.id);
            
            %FIXME - major fix needed here. for now just tranpose
            data = data';
        end
        
    end
    
end

