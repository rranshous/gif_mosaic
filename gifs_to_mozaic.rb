#!/usr/bin/env ruby

require 'pry'
require 'base64'
require 'fileutils'
require 'rmagick'
include Magick

GRAVITIES = [NorthWestGravity, NorthEastGravity,
             SouthWestGravity, SouthEastGravity]

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

MOVIE_DIMS = [1000, 1000]
def create_movie source_dir, target_frame_count
  exploded_sources = Dir[File.join(source_dir, '*.gif')].take(4).sort
  image_streams = exploded_sources.map do |source_path|
    source_frames(source_path).cycle
  end
  movie = ImageList.new
  target_frame_count.times do
    frame = ImageList.new
    image_streams.each do |image_stream|
      frame.push image_stream.next
    end
    frame = frame.montage {
      self.background_color = 'black'
      self.geometry = "#{SUB_IMAGE_DIMS.join('x')}+10+5"
    }
    movie.push frame.first
  end
  movie
end

gif_source_dir = File.expand_path ARGV.shift
output_path = File.expand_path ARGV.shift
frame_count = (ARGV.shift || 100).to_i

movie = create_movie gif_source_dir, frame_count
movie.write output_path
