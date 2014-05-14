classdef File < h5m.Group
    %h5m.File
    %   Detailed explanation goes here
    
    properties (Constant = true)
        DEFAULT_MODE = 'a'
    end
    
    properties (GetAccess = public, SetAccess = protected)
        filename
        mode
    end
    
    methods
        
        function self = File(filename_or_fid, mode)
            
            if isa(filename_or_fid,'HTML.id')
                fid = filename_or_fid;
                arg_filename = H5F.get_name(fid);
            else
                arg_filename = filename_or_fid;
                if ~exist('mode','var')
                    mode = h5m.File.DEFAULT_MODE;
                end
                
                if ~exist('mode','var')
                    if exist(arg_filename, 'file')
                        mode = 'r';
                    else
                        mode = 'w-';
                    end
                else
                    if exist(arg_filename, 'file') && strcmp(mode,'a')
                        mode = 'r+';
                    end
                end                
                
                switch mode
                    case 'r' % open existing read only
                        fid = H5F.open(arg_filename, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
                    case 'r+' % open existing read/write
                        fid = H5F.open(arg_filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
                    case 'w' % create file (overwrite)
                        fcpl = H5P.create('H5P_FILE_CREATE');
                        fid = H5F.create(arg_filename, 'H5F_ACC_TRUNC', fcpl, 'H5P_DEFAULT');
                        H5P.close(fcpl);
                    case 'w-' % create file (do not overwrite)
                        fcpl = H5P.create('H5P_FILE_CREATE');
                        fid = H5F.create(arg_filename, 'H5F_ACC_EXCL', fcpl, 'H5P_DEFAULT');
                        H5P.close(fcpl);
                    otherwise
                        error('h5m.File:File(): Unknown mode ''%s''', mode);
                end
                
            end
                        
            grp_id = H5G.open(fid, '/');
            self@h5m.Group(grp_id);
            self.filename = arg_filename;
            self.mode = mode;
            
        end        
        
        function self = flush(self)
            error('Not yet implemented');
        end
        
        function self = close(self)
            error('Not yet implemented');            
        end
        
        
        
    end
    
end

