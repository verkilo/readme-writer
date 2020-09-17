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
output_file   = (ENV["OUTPUT_FILE"])   ? ENV["OUTPUT_FILE"]   : "./README.md"
repo_name     = (ENV["GITHUB_REPOSITORY"]) ? ENV["GITHUB_REPOSITORY"]     : ""
Liquid::Template.file_system = Liquid::LocalFileSystem.new(File.dirname(template_file))

puts "Template uses: #{template_file}"
puts "Writing to:    #{output_file}"

content = File.read(template_file)
@template = Liquid::Template.parse(content)

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
    f = $2
    type = $1.gsub('-','_')
    puts ".. '#{type}' (#{File.basename(mdfile)})" if ENV["DEBUG"]
    @data[type] = "<!-- #{type} -->\n#{f.strip}\n[Read more](#{mdfile})\n<!-- /#{type} -->"
    next
  end

  # We are finding YAML content with a 'type'...
  if mkd_contents.match(YAML_FRONT_MATTER_REGEXP)
    begin
      data = YAML.load($1)
      next unless data.keys.include?('type')
      type = (data['type'].gsub('-','_') + "s").gsub(/(?<=[s|sh|ch|x|z])s$$/,'es')
      puts ".. '#{type}' in (#{File.basename(mdfile)})" if ENV["DEBUG"]
      @data[type] = Array(@data[type]).push( data.merge({ "filename" => mdfile }) )
    rescue StandardError => e
      puts "YAML Error: #{mdfile}"
      puts "Rescued: #{e.inspect}"
    end
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

output = @template.render( @data )
output.gsub!(/\n{2,}/m,"\n\n")
File.open(output_file,'w').write(output)
puts @template.errors
puts "Done."
