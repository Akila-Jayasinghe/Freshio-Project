% Freshio Image Preprocessing Script
% Purpose: Noise Reduction and Contrast Enhancement for Fruit Inspection

function processedImage = preprocess_freshio(inputPath)
    % Load Image
    img = imread(inputPath);
    
    % Convert to Double
    img_double = im2double(img);
    
    % Noise Reduction - Gaussian
    filtered_img = imgaussfilt(img_double, 1.0);
    
    % Contrast Enhancement- Unsharp Masking
    enhanced_img = imsharpen(filtered_img, 'Radius', 2, 'Amount', 1.5);
    
    % Normalization
    processedImage = imadjust(enhanced_img, stretchlim(enhanced_img), []);
    
    % Visualization
    subplot(1,2,1), imshow(img), title('Original Image');
    subplot(1,2,2), imshow(processedImage), title('DIP Processed Image');
end