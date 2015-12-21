classdef File < h5m.Group
    %h5m.File
    %   Detailed explanation goes here
    
    properties (Constant = true)
        DEFAULT_MODE = 'a'
    end
    
    properties (GetAccess = public, SetAccess = protected)
        filename
        mode
        fid
    end
    
    methods
        
        function self = File(filename_or_fid, mode)
            
            if isa(filename_or_fid,'H5ML.id')
                fid = filename_or_fid;
                arg_filename = H5F.get_name(fid);
                if ~exist('mode','var')
                    mode = h5m.File.DEFAULT_MODE;
                end                
            else
                arg_filename = filename_or_fid;                
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
                    case 'a' % if file exists 'w', otherwise 'w-'
                        if exist(arg_filename, 'file')
                            fcpl = H5P.create('H5P_FILE_CREATE');
                            fid = H5F.create(arg_filename, 'H5F_ACC_TRUNC', fcpl, 'H5P_DEFAULT');
                            H5P.close(fcpl);                            
                        else
                            fcpl = H5P.create('H5P_FILE_CREATE');
                            fid = H5F.create(arg_filename, 'H5F_ACC_EXCL', fcpl, 'H5P_DEFAULT');
                            H5P.close(fcpl);
                        end
                        
                    otherwise
                        error('h5m.File:File(): Unknown mode ''%s''', mode);
                end
                
            end
            
            grp_id = H5G.open(fid, '/');
            self@h5m.Group(grp_id);
            self.fid = fid;
            self.filename = arg_filename;
            self.mode = mode;            
        end
        
        function self = flush(self, flush_global)
            if ~exist('flush_global','var')
                flush_global = true;
            end
            if flush_global
                flush_flag = 'H5F_SCOPE_GLOBAL';
            else
                flush_flag = 'H5F_SCOPE_LOCAL';
            end                
            H5F.flush(self.fid, flush_flag);
        end
        
        function self = close(self)
            H5F.close(self.fid);
        end                
        
        function disp(self)
            disp('h5m.File object:');
            disp(['File: ' self.filename]);
            disp(['Mode: ' self.mode]);
            if self.id < 0
                disp('Status: <closed>');
            else
                disp('Status: <open>');
                disp@h5m.Group(self, true);
            end
        end
        
    end
    
end

