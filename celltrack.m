 %% Motion-Based Cell Tracking
% This function performs automatic cell detection based on 
% contrast and motion using a guassian-based adaptive learning algorithm 
% built into the Computer Vision Toolbox. 
% 
%
%   Copyright 2016 Amin Adibi


%Input Parameters:
%filename       the name of the input file, excluding file extension. Input
%               file needs to be an avi video from a stationary camera
%min_cell_dia   minimum cell diameter (in um) for detection. Use this to
%               avoid detecting noise pixels as moving cells.
%max_cell_dia   maximum cell diameter (in um) for detection. Use this to
%               avoid detecting cell aggregates as single cells.
%pixel2um       scale of the image (how many um each pixel is?)

% Outputs:

function binary_out = celltrack(filename, min_cell_dia,...
    max_cell_dia, pixel2um)

minimum_area = (0.5*min_cell_dia/pixel2um)^2*pi(); %default 30
maximum_area = (0.5*max_cell_dia/pixel2um)^2*pi(); %default 150 better to define based on expected cell size and resoulution
%pixel2um = 1.6; % how many uM each pixel is? def1.6

videoSource = vision.VideoFileReader([filename '.avi'],'ImageColorSpace','Intensity','VideoOutputDataType','uint8');
videoFWriter = vision.VideoFileWriter(['output-' filename '.avi'],'FrameRate',30, 'FileFormat','AVI');
videoBiWriter = vision.VideoFileWriter(['output-Bi-' filename '.avi'],'FrameRate',30);

detector = vision.ForegroundDetector(... %detects the foreground using guassian method. See  Matlab Computer Vision Toolbox manuals for more info. 
       'NumTrainingFrames', 50, 'LearningRate', 0.001);

blob = vision.BlobAnalysis(... %detects blobs. See  Matlab Computer Vision Toolbox manuals for more info. 
       'CentroidOutputPort', true, 'AreaOutputPort', false, ...
       'BoundingBoxOutputPort', false, 'EquivalentDiameterSquaredOutputPort'...
       , true,'PerimeterOutputPort', false, ...
       'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', minimum_area, ...
       'MaximumBlobArea', maximum_area);
   
   
eqdiasqr = vision.BlobAnalysis(... %detects the diameters of blobs. See  Matlab Computer Vision Toolbox manuals for more info. 
       'CentroidOutputPort', false, 'AreaOutputPort', false, ...
       'BoundingBoxOutputPort', false, 'EquivalentDiameterSquaredOutputPort'...
       , true,'PerimeterOutputPort', false, ...
       'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', minimum_area, ...
       'MaximumBlobArea', maximum_area);
   
shapeInserter = vision.ShapeInserter('Shape','Circles','BorderColor','White'); %creates a shape around the detected blob
videoPlayer = vision.VideoPlayer();
diameters = 0;
while ~isDone(videoSource)
     frame  = step(videoSource);
     fgMask = step(detector, frame);
     centroid = step(blob, fgMask);
     diameters = [diameters ; pixel2um.*sqrt(step(eqdiasqr, fgMask))];
   %  step(videoBiWriter, bbox);
    
     if ~isempty(centroid) 
         tempsize = size (centroid);
         column = zeros (tempsize(1),1);
         column (:, 1) =  sqrt(step(eqdiasqr, fgMask))./2;
         centroid = [centroid column] ;
         centroid = uint8 (centroid);
     else 
         centroid =  [1, 1, 1];
         centroid = uint8 (centroid);
     end
     out = step(shapeInserter, frame, centroid);
     step(videoPlayer, out);
     step(videoFWriter, out);
end
release(videoPlayer); %closes the files
release(videoSource);
release(videoFWriter);

%The following section creates a histogram of the distribution of 
%all detected cell sizes.
diameters = transpose (diameters);
histo=figure; %the histogram variable
histogram (diameters, 1000);
title(['Detected Cell Size Distribution - Input File Name:' filename]); %creates a title for the histogram
xlabel('Cell Diameter (\mum)') % x-axis label
ylabel('Number of Detected Cells') % y-axis label
saveas(histo, ['histogram-' filename '.png']) %this saves the hitogram on the disk
end
