function [dat, rdb_hdr] = loadpfile(pfile,echo)
% function [dat, rdb_hdr] = loadpfile(pfile,[echo])
%
% Load data for one echo (or all) from Pfile, EXCEPT dabslice=0 slot (which can contain corrupt data).

% This file is part of the TOPPE development environment for platform-independent MR pulse programming.
%
% TOPPE is free software: you can redistribute it and/or modify
% it under the terms of the GNU Library General Public License as published by
% the Free Software Foundation version 2.0 of the License.
%
% TOPPE is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Library General Public License for more details.
%
% You should have received a copy of the GNU Library General Public License
% along with TOPPE. If not, see <http://www.gnu.org/licenses/old-licenses/lgpl-2.0.html>.
% 
% (c) 2016 The Regents of the University of Michigan
% Jon-Fredrik Nielsen, jfnielse@umich.edu

import toppe.*
import toppe.utils.*

% read Pfile header
fid = fopen(pfile,'r','l');
ver = fread(fid,1,'float32');
str = num2str(ver);
fprintf('Pfile version is %s\n', str);
rdbm_rev = str2double(str);
fseek(fid,0,'bof');                 % NB!
rdb_hdr = toppe.utils.read_rdb_hdr(fid,rdbm_rev);

ndat    = rdb_hdr.frame_size;
nslices = rdb_hdr.nslices;
nechoes = rdb_hdr.nechoes;
nviews  = rdb_hdr.nframes;
ncoils  = rdb_hdr.dab(2)-rdb_hdr.dab(1)+1;

fprintf(1,'ndat = %d, nslices = %d, nechoes = %d, nviews = %d, ncoils = %d\n', ndat, nslices, nechoes, nviews, ncoils);

if exist('echo','var')
	ECHOES = echo;
else
	ECHOES = 1:nechoes;
end

if max(ECHOES) > nechoes
	error('max echo is %d', nechoes);
end

%dat = zeros([ndat ncoils nslices nechoes nviews]);
for slice = 2:nslices   % skip first slice (sometimes contains corrupted data)
	for ie = 1:numel(ECHOES)
		echo = ECHOES(ie);
		for view = 1:nviews
			[dattmp pfilesize] = loaddat_ge(fid,rdb_hdr,slice-1,echo-1,view);     % [ndat ncoils]. Skip baseline (0) view.
			dat(:,:,slice-1,ie,view) = dattmp; 
		end
		%fprintf(1,'%d  ',ftell(fid));
	end
end
%fprintf(1,'%d  ',ftell(fid));
fclose(fid);
fprintf(1,'Expected pfilesize = %d\n', pfilesize);
return;

