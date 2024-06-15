from PIL import Image

def bmp_to_coe(input_path, output_path):
    # Reading BMP images
    img = Image.open(input_path)
    img = img.convert('RGB')  # Make sure the image is in RGB format

    # Open output file
    with open(output_path, 'w') as file:
        # Write COE file header
        file.write('memory_initialization_radix=16;\n')
        file.write('memory_initialization_vector=\n')
        
        # Iterate over each pixel
        for y in range(img.height):
            for x in range(img.width):
                r, g, b = img.getpixel((x, y))
                
                # Color quantization: Reduce color channels from 8 bits to 4 bits
                r, g, b = r >> 4, g >> 4, b >> 4
                
                # Combine RGB values into 12-bit values
                color = (r << 8) + (g << 4) + b
                
                # Convert a 12-bit value to a hexadecimal string
                hex_str = format(color, '03x')
                
                # Write to file without comma after last value
                if y == img.height - 1 and x == img.width - 1:
                    file.write(hex_str + ';\n')
                else:
                    file.write(hex_str + ',\n')

bmp_to_coe('block.bmp', 'block.coe')