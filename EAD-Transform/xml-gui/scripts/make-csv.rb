#!/usr/bin/env ruby

require 'nokogiri'
require 'csv'

target_dir = ARGV[0]
# verify target is directory
if ! File.directory?(target_dir)
  puts "Target must be a directory containing EAD files. Please check your input."
  exit
end
Dir.chdir(target_dir)
target_dir = Dir.pwd
Target_list = Dir.glob(target_dir + '/*.xml')
# verify target contains XML files
if Target_list.empty?
  puts "No EAD/XML files found in target directory. Please check your input."
end

Target_list.each do |target_ead|
  base_name = File.basename(target_ead,".*")
  data = Nokogiri::XML(File.open(target_ead))
  data.remove_namespaces!
  items = data.xpath('//c')
  CSV.open(target_dir + "/#{base_name}.csv", "wb") do |csv|
    csv << ["id","title","extent","dimensions","date","container","desc","scope content note","general note" ]
    items.each do |item|
      item_id = item.xpath('did').attr('id').inner_html
      item_title = item.xpath('did/unittitle').inner_html
      item_extent = item.xpath('did/physdesc/extent').inner_html
      item_dimensions = item.xpath('did/physdesc/dimensions').inner_html
      item_date = item.xpath('did/unitdate').inner_html
      item_container = item.xpath('did/container').inner_html
      item_desc = item.xpath('did/dao/daodesc/p').inner_html
      item_scopecontentnote = item.xpath('scopecontent/p').inner_html
      item_generalnote = item.xpath('odd/p').inner_html
      csv << [item_id, item_title, item_extent, item_dimensions, item_date, item_container, item_desc, item_scopecontentnote, item_generalnote]
    end
  end
end
