function L_SFM = bwboundaries_SFM(varargin) %#codegen
%BWBOUNDARIES Trace region boundaries in binary image.
%   B = BWBOUNDARIES(BW) traces the exterior boundary of objects, as well
%   as boundaries of holes inside these objects. It also descends into the
%   outermost objects (parents) and traces their children (objects
%   completely enclosed by the parents). BW must be a binary image where
%   nonzero pixels belong to an object and 0-pixels constitute the
%   background. B is a P-by-1 cell array, where P is the number of objects
%   and holes. Each cell contains a Q-by-2 matrix, where Q is the number of
%   boundary pixels for the corresponding region. Each row of these Q-by-2
%   matrices contains the row and column coordinates of a boundary pixel.
%   The coordinates are ordered in a clockwise direction.
%
%   B = BWBOUNDARIES(BW,CONN) specifies the connectivity to use when
%   tracing parent and child boundaries. CONN may be either 8 or 4. The
%   default value for CONN is 8.


if coder.target('MATLAB')
    matlab.images.internal.errorIfgpuArray(varargin{:});
    args = matlab.images.internal.stringToChar(varargin);
else
    args = varargin;
end
[BW, conn, ~] = parseInputs(args{:});

[~, L] = findObjectBoundaries(BW, conn);

[~, labeledHoles] = findHoleBoundaries(BW, conn);

L_SFM{1} = L;
L_SFM{2} = labeledHoles;


%--------------------------------------------------------------------------
function [BW, conn, findHoles] = parseInputs(varargin)

narginchk(1,4);

% Validate BW
BW_in = varargin{1};
validateattributes(BW_in, {'numeric','logical'}, {'real','2d','nonsparse'}, ...
    mfilename, 'BW', 1);

% Convert if it is not already logical
if ~islogical(BW_in)
    BW = (BW_in ~= 0); % handle NaN's as 1's
else
    BW = BW_in;
end

if nargin < 2
    % defaults
    conn = 8;
    findHoles = true;
else
    if ischar(varargin{2})
        indexOfOptions = 2;
        conn = 8; % default
    else
        indexOfOptions = 3;
        % Validate conn
        conn = varargin{2};
        validateattributes(conn, {'double'}, {}, mfilename, 'CONN', 2);
        % conn must be 4 or 8
        coder.internal.errorIf(conn~=4 && conn~=8, ...
            'images:bwboundaries:badScalarConn');
    end
    % Validate options
    if (nargin > 2) || ischar(varargin{2})
        validStrings = {'noholes', 'holes'};
        string = validatestring(varargin{indexOfOptions}, validStrings, ...
            mfilename, 'OPTION', indexOfOptions);
        findHoles = strcmp(string,'holes');
    else
        findHoles = true;
    end
end

%--------------------------------------------------------------------------
function [B, L] = findObjectBoundaries(BW, conn)

L = bwlabel(BW, conn);
if isempty(coder.target)
    B = images.internal.builtins.bwboundaries( L, conn);
else
    % M code for C code generation
    finder = images.internal.coder.BoundaryFinder(L, conn);
    B = finder.findBoundaries();
end

%--------------------------------------------------------------------------
function [B, L] = findHoleBoundaries(BW, conn)

% Avoid topological errors.  If objects are 8 connected, then holes
% must be 4 connected and vice versa.
if (conn == 4)
    backgroundConn = 8;
else
    backgroundConn = 4;
end

% Turn holes into objects
BWcomplement = imcomplement(BW);

% clear unwanted "hole" objects from the border
BWholes = imclearborder(BWcomplement, backgroundConn);

% get the holes!
L = bwlabel(BWholes, backgroundConn);
if isempty(coder.target)
    B = images.internal.builtins.bwboundaries(L, backgroundConn);
else
    % M code for C code generation
    finder = images.internal.coder.BoundaryFinder(L, backgroundConn);
    B = finder.findBoundaries();
end


