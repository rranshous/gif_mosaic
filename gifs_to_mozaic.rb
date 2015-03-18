#!/usr/bin/env ruby

require 'pry'
require 'base64'
require 'fileutils'
require 'rmagick'
include Magick

GRAVITIES = [NorthWestGravity, NorthEastGravity,
             SouthWestGravity, SouthEastGravity]

def clean_up
  FileUtils.rm_rf "/tmp/frames"
end

SUB_IMAGE_DIMS = [320,240]
def resize_image image
  image.change_geometry!(SUB_IMAGE_DIMS.join('x')) do |cols, rows, img|
    #base = Image.new(*SUB_IMAGE_DIMS) { self.background_color = 'black' }
    img = img.resize(cols, rows)
    #base.composite img, CenterGravity, 0, 0, OverCompositeOp
  end
end

def source_frames source_path
  frames = ImageList.new source_path
  puts "source list: #{frames.length}"
  new_frames = ImageList.new
  base = Image.new(*SUB_IMAGE_DIMS) { self.background_color = 'black' }
  frames.each do |image|
    image = resize_image image
    base.composite! image, CenterGravity, 0, 0, OverCompositeOp
    new_frames.push base.dup
  end
  new_frames
end

COMPOSITE_DIMS = [1000, 1000]
def create_composites source_dir, target_frame_count
  exploded_sources = Dir[File.join(source_dir, '*.gif')].take(4).sort
  image_streams = exploded_sources.map do |source_path|
    source_frames(source_path).cycle
  end
  composite_frames = ImageList.new
  target_frame_count.times.each do |frame_num|
    puts "creating composite frame: #{frame_num}"
    composite_frame = Image.new(*COMPOSITE_DIMS) do
      self.background_color = "black"
    end
    image_streams.zip(GRAVITIES.cycle).each do |image_stream, gravity|
      image = image_stream.next
      composite_frame.composite! image, gravity, 100, 100,
                                 OverCompositeOp
    end
    composite_frames.push composite_frame
  end
  composite_frames
end


gif_source_dir = File.expand_path ARGV.shift
output_path = File.expand_path ARGV.shift
frame_count = (ARGV.shift || 100).to_i

composites = create_composites gif_source_dir, frame_count

puts "writing movie"
composites.write output_path

clean_up
