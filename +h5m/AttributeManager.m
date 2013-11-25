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
            % FIXME - how to test?!?!
            attr_id = H5A.open(self.id, name);
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
        
        
        function self = create(self, name, data, shape, dtype)
            % FIXME - lots of work to do here
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

