#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'
require 'json'
require 'base64'
require 'liquid'
# require 'awesome_print'

YAML_FRONT_MATTER_REGEXP = %r{\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)}m
SECTION_REGEXP = %r{<!-- (.*?) -->(.*?)<!-- \/\1 -->}m

template_file = (ENV["TEMPLATE_FILE"]) ? ENV["TEMPLATE_FILE"] : "./.verkilo/templates/README.liquid"
output_file   = (ENV["OUTPUT_FILE"]) ? ENV["OUTPUT_FILE"] : "./README.md"
repo_name     = (ENV["REPO_NAME"]) ? ENV["REPO_NAME"] : "./README.md"

puts "Template uses: #{template_file}"
puts "Writing to:    #{output_file}"

@template = Liquid::Template.parse(File.read(template_file))
@data = {
  'time' => Time.now.strftime("%F %R %Z"),
  'repo_name' => repo_name
}

FileUtils.cp("./README.liquid", template_file) unless File.exists?(template_file)

mkd_files = Dir["./**/*.md"].sort
puts "README compile (#{Dir.pwd}) scanning #{mkd_files.count} files"

puts "Found:" if ENV["DEBUG"]
mkd_files.each do |mdfile|
  next if (['trash','outdated',output_file,template_file].any? { |word| mdfile.include?(word) })
  mkd_contents = File.read(mdfile)

  # We are finding fenced content...
  if mkd_contents.match(SECTION_REGEXP)
    puts ".. '#{$1}' (#{File.basename(mdfile)})" if ENV["DEBUG"]
    @data[$1] = "<!-- #{$1} -->\n#{$2.strip}\n[Read more](#{mdfile})\n<!-- /#{$1} -->"
    next
  end

  # We are finding YAML content with a 'type'...
  if mkd_contents.match(YAML_FRONT_MATTER_REGEXP)
    data = YAML.load($1)
    next unless data.keys.include?('type')
    type = data['type']
    puts ".. '#{type}' in (#{File.basename(mdfile)})" if ENV["DEBUG"]
    @data[type] = Array(@data[type]).push( data.merge({ "filename" => mdfile }) )
  end
end

puts "\nData types parsed for Template:"
@data.keys.sort.each do |k|
  puts ".. #{k} (#{ @data[k].class })"
end

puts "\nCreating Table of Contents"
@data['toc'] = "## Contents\n\n" + content.scan(/^##\s?(.*)\n/iu).flatten.map do |header|
  next if header == 'Contents'
  indent = ""
  header.gsub!(/#\s?+/) { indent += "  "; "" }
  anchor = header.downcase.gsub(/\W+/,'-').chomp('-')
  "%s* [%s](#%s)\n" % [indent,header,anchor]
end.join

File.open(output_file,'w').write(@template.render( @data ))
puts "Done."
