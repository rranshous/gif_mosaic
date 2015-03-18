#!/usr/bin/env ruby

def explode_gif image_path, out_dir
  cmd = "cd #{out_dir} && convert '#{image_path}' frame%05d.png"
  raise "explode fail" unless system(cmd)
end

image_path=File.expand_path(ARGV.shift)
out_dir=File.expand_path(ARGV.shift)
explode_gif image_path, out_dir

