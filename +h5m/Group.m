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
        

    end
    
end

