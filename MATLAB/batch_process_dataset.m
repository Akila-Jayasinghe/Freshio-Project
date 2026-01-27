% Batch Process Dataset for Freshio Training
inputDir = 'path_to_your_raw_kaggle_images';
outputDir = 'path_to_save_processed_images';

files = dir(fullfile(inputDir, '*.jpg'));

for i = 1:length(files)
    filename = files(i).name;
    % Process the image using our DIP function
    processed = preprocess_freshio(fullfile(inputDir, filename));
    
    % Save the improved version for AI training
    imwrite(processed, fullfile(outputDir, filename));
    
    fprintf('Processed: %s\n', filename);
end