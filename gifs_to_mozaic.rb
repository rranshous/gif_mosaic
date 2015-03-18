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
  image.resize_to_fit(*SUB_IMAGE_DIMS)
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
def create_movie source_dir
  exploded_sources = Dir[File.join(source_dir, '*.gif')].sort
  max_frames = 0
  image_streams = exploded_sources.map do |source_path|
    image_stream = source_frames(source_path)
    max_frames = [image_stream.count, max_frames].max
    image_stream.cycle
  end
  target_frame_count = max_frames
  movie = ImageList.new
  target_frame_count.times.each do |i|
    puts "frame: #{i+1} / #{target_frame_count}"
    frame = ImageList.new
    image_streams.each do |image_stream|
      frame.push image_stream.next
    end
    frame = frame.montage {
      self.background_color = 'black'
      self.geometry = "#{SUB_IMAGE_DIMS.join('x')}+100+100"
    }
    movie.push frame.first
  end
  movie
end

gif_source_dir = File.expand_path ARGV.shift
output_path = File.expand_path ARGV.shift

movie = create_movie gif_source_dir
puts "writing"
movie.write output_path
